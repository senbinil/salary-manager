# Backend

The backend is an API-only Rails application using PostgreSQL, RSpec, and Rodauth cookie-session authentication. Run Rails and Bundler commands from this directory.

## Setup and run

Start PostgreSQL, then run:

```sh
bin/setup --skip-server
bin/dev
```

The API is available at `http://localhost:3000`. Application endpoints use `/api/v1`; Rodauth serves authentication routes under the same prefix.

Running `bin/rails db:seed` from this directory creates the sign-in accounts to
work with - `dev@example.com`, `manager@example.com` and `hr@example.com`, each
with a different role. It is idempotent, leaves an existing account alone, and
runs in every environment, warning before it writes in production.

Their password comes from `credentials.default_password`. The seed refuses to run
without it rather than falling back to a password in the repository, which is
public - add it with `bin/rails credentials:edit` when it is missing.

Neither sample employees nor reference data are part of the seed: a load test
wants thousands of employees, so they come from the `sample_data` tasks, which
create the reference data they need, replace whatever the loader created before,
and never touch an employee named any other way.

```sh
CONFIRM_SAMPLE_DATA=yes bin/rails 'sample_data:load[10000]'
CONFIRM_SAMPLE_DATA=yes bin/rails sample_data:clear
```

The load goes in through batched `insert_all`, so 10,000 employees - about 60,000
rows with their contracts, compensations and components - takes seconds. See
`lib/sample_data/employee_seeder.rb`.

## Background jobs

Active Job runs on Solid Queue, which keeps a database per environment (`backend_development_queue`, `backend_test_queue`, `backend_production_queue`). `bin/setup` and `bin/rails db:prepare` create them along with the application databases.

Development starts the Solid Queue supervisor inside Puma, so enqueued jobs are processed without a separate process:

```sh
bin/rails runner 'FetchExchangeRateSnapshotsJob.perform_later'
```

`bin/jobs` runs the supervisor on its own and is what a dedicated worker machine would use. The monthly exchange-rate import is scheduled in `config/recurring.yml` for production only, so run it by hand locally as above.

## Current API

The application exposes `GET /api/v1/me` (id, email and role), `GET /api/v1/dashboard/summary` for the organization-wide overview, read endpoints for employees, reference data and compensation plans, nested employee employment-contract index/show endpoints, and `POST /api/v1/exchange_rates/convert` for current-month currency conversion. Contract responses include employee-specific compensation with the plan tag and component amounts. See [`doc/openapi.yml`](./doc/openapi.yml) for the full route and schema reference.

The employee list endpoint uses server-side pagination, accepts `filter[name_cont]`, `filter[department_id]`, `filter[designation_id]`, `filter[employment_status]` and `filter[country_code]` (see `EmployeeQuery`; unknown keys are ignored, a malformed value answers 400), and reports active-contract status, location, start date, total compensation, and the contract currency for that total. The employee show endpoint also returns the current total or `null` when the employee has no active contract. The frontend adds an employee table with its filter controls, a current-contract drill-down, and a dashboard overview rendering the summary endpoint. The model supports nested component attributes on `EmployeeCompensation`, but no HTTP contract write endpoint currently accepts them. Accounts carry a role (`employee`, `manager`, `hr`) and `ApplicationController#require_role!` is the guard for it, but no endpoint restricts by role yet. The dashboard overview endpoint reports the active-employee count and, per contract country, the active headcount and the compensation total in that country's currency. Payroll and stored/historical reporting endpoints are not implemented; the overview is a current-state aggregate.

## Checks

```sh
bundle exec rspec
bin/rubocop
bin/ci
```

`bin/ci` runs setup, RuboCop, security audits, RSpec, and seed verification. See [`AGENTS.md`](./AGENTS.md) for backend-specific conventions and operational notes.

## Deployment

Production runs as a Docker container managed by [Kamal](https://kamal-deploy.org) (`config/deploy.yml`), with Thruster as the in-container server and Kamal's proxy terminating TLS for the API host. The image is pushed to Docker Hub. The shared topology and the frontend's half of the deployment are in [`../docs/DEPLOYMENT.md`](../docs/DEPLOYMENT.md).

Kamal 2 has no `.env` file support of its own - its dotenv handling covers only `.kamal/secrets-common` and `.kamal/secrets`. So `bin/kamal` loads `backend/.env` and `backend/.env.production` (with dotenv) before starting Kamal, and `config/deploy.yml` interpolates its host values from the result. That makes `.env.production` the only file to maintain per deployment:

```sh
DOCKERHUB_USER=...              # Docker Hub user; also the image namespace
DEPLOY_HOST=...                 # the VPS
API_HOST=api.diciq.site        # public API host; the proxy requests a TLS certificate for it
FRONTEND_ORIGIN=https://diciq.site
DB_HOST=...                     # container name of the shared Postgres accessory
DB_USER=backend
KAMAL_REGISTRY_PASSWORD=...
BACKEND_DATABASE_PASSWORD=...
KAMAL_SSH_KEY=~/.ssh/deploy_key   # private key Kamal connects with; ~/.ssh/id_rsa is the fallback
```

The file is gitignored and excluded from the image by `.dockerignore`. Real environment variables win over it, so `DEPLOY_HOST=1.2.3.4 bin/kamal deploy` still overrides the file. `.kamal/secrets` only maps the two passwords (`KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD`, `BACKEND_DATABASE_PASSWORD=$BACKEND_DATABASE_PASSWORD`) and takes `RAILS_MASTER_KEY` from `config/master.key`, which is gitignored and excluded from the image. `KAMAL_SSH_KEY` takes a different route: the `ssh:` block in `config/deploy.yml` passes it to net-ssh as the private key Kamal authenticates with, so it is never injected into a container.

The Postgres service is the accessory that another Kamal service already runs on the same host, so `config/deploy.yml` defines no `accessories:`. `DB_HOST` names that container on the shared `kamal` docker network, and `DB_USER` is a dedicated role owning `backend_production` plus its `_cache`, `_queue` and `_cable` siblings. The three non-primary databases are created on first boot by the entrypoint's `db:prepare`, provided the role has `CREATEDB`; otherwise create them before the first deploy. Production does not use `DATABASE_URL`, because it only overrides the primary configuration.

```sh
bin/kamal setup         # first deploy: proxy, TLS certificate, image, container
bin/kamal app logs -f   # expect "Started Supervisor" from SOLID_QUEUE_IN_PUMA
bin/kamal console       # Rails console in the running container
```

`bin/kamal deploy` ships later releases, and the entrypoint migrates the database on boot. `bin/kamal app logs`, `bin/kamal console` and `bin/kamal dbc` are the day-to-day commands. The API answers at `https://api.diciq.site`, where Kamal's proxy checks `GET /up` on every deploy.

The entrypoint runs `db:prepare` but never `db:seed`, and the exchange-rate import only fires from `config/recurring.yml`, so the one-off tasks are run by hand. `--reuse` runs them in the container that is already up, with its injected secrets:

```sh
bin/kamal app exec --reuse "bin/rails db:seed"                                               # sign-in accounts, idempotent
bin/kamal app exec --reuse "env CONFIRM_SAMPLE_DATA=yes bin/rails 'sample_data:load[10000]'"   # load-test employees
bin/kamal app exec --reuse "bin/rails runner 'FetchExchangeRateSnapshotsJob.perform_now'"      # current-month rates
```

`CORS_ORIGINS` is fed from `FRONTEND_ORIGIN` in `.env.production` and must be a full URL. A sibling subdomain is still a different origin, so the browser needs that policy even when both apps share a domain.
