# Salary Manager

Salary and compensation management: define how an organization compensates its employees, and report that compensation across countries and currencies. The **employment contract** is the source of truth — one active contract per employee, one contract currency, and a compensation plan that assigns amounts to reusable salary components. Reporting is a live projection over current contracts and plans (no payroll run, no frozen results).

## What the app does

**Implemented today**

- Cookie-session authentication under `/api/v1` (create account, sign in, sign out, reset password, change login, close account), provided by [Rodauth](https://rodauth.jeremyevans.net).
- `GET /api/v1/me` — the session probe the frontend uses to gate signed-in screens.
- A React shell: sign-in page, an authenticated dashboard behind a session gate, and sign-out from the app bar.

**Designed, not yet built**

The compensation domain — employees, contracts, compensation plans/components, and cross-currency reporting — is fully specified but not implemented. See [`docs/`](./docs/README.md).

## Documentation

| Document | What it means |
| --- | --- |
| [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) | **Canonical design (v0.5).** Domain model, entity definitions, reporting, currency rule, active-contract resolution, and FX handling. |
| [`docs/IMPLEMENTATION-PLAN.md`](./docs/IMPLEMENTATION-PLAN.md) | Phased plan that sequences the design into ordered build phases, with the decisions to settle first. |
| [`docs/SALARY-COMPONENT-RELATIONSHIPS.md`](./docs/SALARY-COMPONENT-RELATIONSHIPS.md) | Why `SalaryComponent` (the word) and `CompensationPlanComponent` (the amount) are two entities. |
| [`docs/README.md`](./docs/README.md) | Index, version lineage (v0.1 → v0.5), and the non-normative archive. |
| [`backend/AGENTS.md`](./backend/AGENTS.md) · [`frontend/AGENTS.md`](./frontend/AGENTS.md) | Per-app conventions, commands, and pitfalls for agents. |

## API documentation

The HTTP API is specified as OpenAPI 3.0 in [`backend/doc/openapi.yml`](./backend/doc/openapi.yml).

Rendered, browsable docs are built from it and deployed to GitHub Pages: **<https://senbinil.github.io/salary-manager/>** (rebuilt on every push to `main` that touches `backend/doc/`).

## Stack

Monorepo: `backend/` (API) and `frontend/` (UI).

| App | Stack |
| --- | --- |
| `backend/` | Ruby 4.0.5 · Rails 8.1.3.1 (API-only) · PostgreSQL · Rodauth (cookie-session auth) · Rack::Cors · Solid Queue / Cache / Cable · RSpec + FactoryBot · Puma, deployed with Kamal |
| `frontend/` | Node 24 · React 19 · Vite · React Router 8 (data mode) · TanStack Query v5 · axios · MUI v9 · lucide-react · Vitest + Testing Library |

## CI

| Workflow | Runs when | Checks |
| --- | --- | --- |
| `backend.yml` | `backend/**` changes | Brakeman + bundler-audit security scans, RuboCop lint, RSpec tests (Postgres) |
| `frontend.yml` | `frontend/**` changes | ESLint, Vitest coverage, Vite build |
| `docs.yml` | `backend/doc/**` changes on `main` | Builds `openapi.yml` with Redocly, deploys to GitHub Pages |

## Repository layout

```
backend/    Rails API — auth (Rodauth), /api/v1 endpoints, OpenAPI spec in doc/
frontend/   React SPA — sign-in, authenticated shell, dashboard gate
docs/       Design documentation (canonical v0.5 + implementation plan + archive)
```