# Salary Manager

Salary Manager is a monorepo for managing employee contracts and employee-specific compensation. The backend is a Rails API; the frontend is a React application.

## Current state

- The backend provides cookie-session authentication and read endpoints for employees, reference data, and nested employment contracts.
- Each employment contract has one `EmployeeCompensation`. Compensation plans are reusable filter tags; component amounts belong to that contract's compensation and use the contract currency.
- `EmployeeCompensation` supports nested component assignment at the model layer. There are no HTTP contract create/update endpoints.
- The frontend provides sign-in, a session-gated shell, and a placeholder Home page. The employee dashboard and reporting UI are future work.
- There is no payroll run, aggregate report endpoint, reporting-month selector, or currency-normalization feature.

## API documentation

The [OpenAPI 3.0 source](./backend/doc/openapi.yml) defines current HTTP routes and response schemas. Browse the [rendered API documentation](https://senbinil.github.io/salary-manager/); GitHub Pages publishes it from `main` when the API spec, docs build configuration, or workflow changes, and it can also be rebuilt manually.

## Run locally

Start PostgreSQL, then run the backend from `backend/`:

```sh
bin/setup --skip-server
bin/dev
```

In another terminal, start the frontend from `frontend/`:

```sh
npm ci
npm run dev
```

Backend verification uses `cd backend && bin/ci`. Frontend checks use `cd frontend && npm run lint`, `npm run test:run`, and `npm run build`.

## Stack

| App | Main technologies |
| --- | --- |
| Backend | Ruby 4.0.5, Rails 8.1, PostgreSQL, Rodauth, RSpec, FactoryBot |
| Frontend | Node 24, React 19, Vite 8, React Router 8, TanStack Query, axios, MUI, Vitest, React Testing Library |

## CI

GitHub Actions runs checks when changes touch each app:

- **Backend** (`backend.yml`): Brakeman, bundler-audit, RuboCop, and RSpec with PostgreSQL.
- **Frontend** (`frontend.yml`): ESLint, Vitest coverage, and the Vite production build.
- **API docs** (`docs.yml`): builds and publishes the OpenAPI documentation to GitHub Pages from `main` when its source or build configuration changes; it also supports a manual run.

## Repository layout

- `backend/` — Rails API, backend specs, and the OpenAPI source at `backend/doc/openapi.yml`.
- `frontend/` — React single-page application and frontend specs.
- `docs/` — current architecture and implementation documents, decision records, and archived documentation.

## Documentation

- [Architecture v0.6](./docs/ARCHITECTURE.md) — current model and behavior.
- [Implementation plan](./docs/IMPLEMENTATION-PLAN.md) — completed model/API sequence and future dashboard slice.
- [Salary component relationships](./docs/SALARY-COMPONENT-RELATIONSHIPS.md) — plan tags, shared component definitions, and employee-specific amounts.
- [ADR-0001](./docs/decisions/ADR-0001-employee-specific-compensation.md) — rationale and alternatives for the compensation model.
- [Documentation index and version history](./docs/README.md).
- [Backend guidance](./backend/AGENTS.md) and [frontend guidance](./frontend/AGENTS.md).
