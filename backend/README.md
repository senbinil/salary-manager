# Backend

The backend is an API-only Rails application using PostgreSQL, RSpec, and Rodauth cookie-session authentication. Run Rails and Bundler commands from this directory.

## Setup and run

Start PostgreSQL, then run:

```sh
bin/setup --skip-server
bin/dev
```

The API is available at `http://localhost:3000`. Application endpoints use `/api/v1`; Rodauth serves authentication routes under the same prefix.

## Current API

The application exposes `GET /api/v1/me`, read endpoints for employees and reference data, and nested employee employment-contract index/show endpoints. Contract responses include employee-specific compensation with the plan tag and component amounts. See [`doc/openapi.yml`](./doc/openapi.yml) for the full route and schema reference.

The model supports nested component attributes on `EmployeeCompensation`, but no HTTP contract write endpoint currently accepts them. The employee dashboard, payroll, and reporting endpoints are not implemented.

## Checks

```sh
bundle exec rspec
bin/rubocop
bin/ci
```

`bin/ci` runs setup, RuboCop, security audits, RSpec, and seed verification. See [`AGENTS.md`](./AGENTS.md) for backend-specific conventions and operational notes.
