# AGENTS.md — backend

Guidance for AI coding agents working in the `backend/` Rails app.

## Commands

Run all commands from the `backend/` directory.

| Task | Command |
|------|---------|
| Setup | `bin/setup` (installs gems, prepares DB, starts server; add `--skip-server` to skip) |
| Run dev server | `bin/dev` |
| Full CI pipeline | `bin/ci` (setup + style + security + tests) |
| Tests | `bundle exec rspec` |
| Single spec | `bundle exec rspec spec/requests/health_check_spec.rb` |
| Lint / style | `bin/rubocop` |
| Security audit | `bin/bundler-audit` |
| Brakeman scan | `bin/brakeman` |
| Console | `bin/rails console` |

Run `bin/ci` before considering work complete — it runs rubocop, bundler-audit, brakeman, tests, and seed verification.

## Stack & Architecture

- **Ruby 4.0.5**, **Rails ~> 8.1**, **PostgreSQL** (`pg`).
- API-only: `config.api_only = true`. Controllers inherit from `ActionController::API`; there are no views or helpers. Return JSON, not rendered templates.
- Database-backed state services: **Solid Queue** (Active Job), **Solid Cache**, **Solid Cable** (Action Cable).
- Deployment: **Kamal** (`config/deploy.yml`) with **Thruster** as the proxy; production image in `Dockerfile`.
- Security tooling: **Brakeman**, **bundler-audit**, **rubocop-rails-omakase** (no custom rubocop config).
- Testing: **RSpec** (`rspec-rails`) with **FactoryBot** (`factory_bot_rails`); specs live in `spec/`, factories in `spec/factories/`.
- CORS: **`rack-cors`**, configured in `config/initializers/cors.rb`. Allows the origins in `CORS_ORIGINS` (comma-separated; defaults to the Vite dev origins) with credentials, scoped to `/api/v1/*`.

## Conventions

- Ruby style follows `rubocop-rails-omakase`; keep `bin/rubocop` clean.
- Do not commit secrets; use `config/credentials.yml.enc` / `RAILS_MASTER_KEY` (Kamal injects it from `.kamal/secrets`).
- Tests are **RSpec** specs in `spec/` (the Minitest `test/` scaffold was removed). `rails generate` emits specs, and FactoryBot methods are available in specs via `rails_helper`.
- DB names: `backend_development`, `backend_test` (`config/database.yml`), each with its own `queue` database for Solid Queue.
- Generated scaffolding (job queue, cache, cable, deploy) is intact and expected to stay.

## Jobs and Solid Queue

- Solid Queue keeps a database per environment: `backend_development_queue`, `backend_test_queue`, `backend_production_queue`. Schemas come from `db/queue_schema.rb`, and each `queue` entry sets `migrations_paths: db/queue_migrate` so application migrations never run against it. `bin/rails db:prepare` creates them; CI's `db:test:prepare` creates the test one. Each `queue` entry also sets `url: ENV["DATABASE_URL"]`, because that variable only overrides the primary config — without it, CI (which passes `DATABASE_URL`) keeps the credentials-file user for the queue database and aborts with `DatabaseConnectionError`.
- `db/queue_schema.rb` is a schema dump, not a migration: it is byte-identical to solid_queue's install template and is loaded whenever a queue database is created, so a fresh install needs no migration. Schema changes arrive only with a newer gem version — run `bin/rails solid_queue:update` (the migration lands in `db/queue_migrate`, matching `migrations_paths`) and then `bin/rails db:migrate`. The copied migration skips what already exists and is meant to be adapted, for example `algorithm: :concurrently` for the jobs index on PostgreSQL. Bumping the gem does not update the dump by itself.
- Development uses the Solid Queue adapter and starts the supervisor inside Puma (`plugin :solid_queue` in `config/puma.rb`), so enqueued jobs are processed with no `bin/jobs` process. Production opts in through `SOLID_QUEUE_IN_PUMA`; `bin/jobs` stays the alternative for a dedicated worker machine (the commented-out `job:` role in `config/deploy.yml`). The supervisor exits if the queue database is unreachable at boot, and the plugin then stops Puma with it.
- `config/recurring.yml` schedules `FetchExchangeRateSnapshotsJob` in production only. Locally, enqueue it by hand — `bin/rails runner 'FetchExchangeRateSnapshotsJob.perform_later'` — and the running dev server's worker picks it up.
- `spec/jobs/fetch_exchange_rate_snapshots_job_queue_spec.rb` is the only spec that exercises the queue: it stays transactional (the worker's own connection sees none of the example's rows, so the job finds no contracts and writes nothing), swaps the adapter to `:solid_queue` in an `around` hook, runs `SolidQueue::Worker` with `mode = :inline` so its loop ends once no ready executions are left, and removes the queue rows in `after`. Keep enqueue-based coverage there instead of taking the suite off the default `:test` adapter.

## Current State & Pitfalls

- `config/routes.rb` owns `/up`, `/api/v1/me`, read-only reference-data and employee endpoints, and nested employment-contract index/show endpoints. See `doc/openapi.yml` for the full list. Rodauth auth routes are **not** in this file — its middleware serves them under the same `/api/v1` prefix, so never add a Rails `namespace`/`scope` for them. `EmployeeCompensation` supports nested component attributes at the model layer, but no HTTP contract write endpoint accepts them.
- App controllers live under `Api::V1::` and inherit `ApplicationController < ActionController::API`, which owns the private `current_account` helper and the `authenticate!` guard. `Api::V1::MeController` is the worked example: `before_action :authenticate!` answers with Rodauth's 401 body (`reason: "login_required"`, `error: "Please login to continue"`), which is the signal the frontend treats as signed out.
- `authenticate!` resolves the account instead of trusting the session id, so an account closed or deleted after login reads as signed out rather than crashing on a nil account. A protected action must render an explicit payload — never the account record, which would leak `password_hash` and `status`.
- `rodauth` is available in any controller: `rodauth-rails` includes its controller methods via `on_load(:action_controller)` (API-only apps fire that too), and `RodauthApp` runs as middleware, so it sets `env["rodauth"]` and reloads remembered logins on **every** request rather than only on auth paths.
- PostgreSQL must be running before `bin/setup` / `bin/dev`; running specs wipes and reloads `backend_test` from `db/schema.rb`.
- `backend/` is the app root for all Rails/Bundler commands; running them from the repo root will fail.
- Ruby is pinned by `.ruby-version` (4.0.5); keep it in sync with the Dockerfile `RUBY_VERSION` arg.
- CORS is inert in development: `vite.config.js` proxies `/api` to this server, so requests are same-origin and no CORS check happens. The policy only matters once the frontend is served from its own origin. `spec/requests/cors_spec.rb` covers it.
- `CORS_ORIGINS` is read at boot, so changing it needs a restart. Pass **full URLs** (`https://app.example.com`): a bare host such as `app.example.com` is accepted but compiled by rack-cors into a scheme-agnostic regex that rejects every port. A `*` value raises `Rack::Cors::Resource::CorsMisconfigurationError` at boot — credentialed CORS cannot use a wildcard.
- The spec pins `http://localhost:5173`, so CI must not set `CORS_ORIGINS` (or must include that origin).
- `Rack::Cors` must stay inserted with `insert_before 0`. `rodauth-rails` appends its middleware last, and Rodauth's JSON feature answers a bare `OPTIONS` on its paths with **400**, so ordering the CORS middleware after Rodauth would break browser preflight while ordinary requests kept working. Check with `bin/rails middleware`: `Rack::Cors` must appear above `Rodauth::Rails::Middleware`.
