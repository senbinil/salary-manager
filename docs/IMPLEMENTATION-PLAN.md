# Implementation Plan — Payroll v0.5

This turns [`ARCHITECTURE.md`](./ARCHITECTURE.md) into an ordered set of build phases. It is a plan, not a spec: each phase below states its goal, the schema/logic it adds, the endpoints it exposes, and its definition of done. Entity definitions and rules live in `ARCHITECTURE.md`; this document only sequences the work and names the decisions to make along the way.

---

## How to use this plan

- **One slice at a time.** A phase is delivered as one or more thin slices. Each slice follows the repo's TDD shape: the spec commit lands first ("Red on purpose"), then the implementation commit, with Conventional Commits. Confirm each slice's test seams (route-level + shell-level integration) before writing its specs.
- **Backend first, frontend after.** Phases 1–7 build the API and domain; Phases 8–9 build the UI on top of it. A frontend screen can be pulled earlier and paired with its backend phase if the user prefers vertical slices — the dependency graph below marks what each screen needs.
- **Respect the deferred list.** `ARCHITECTURE.md` §9 is authoritative: no payment processing, no tax engines, no `contribution` amounts in reporting, no non-monthly frequencies, no proration, no mid-period plan switches. A phase that drifts into one of those is out of scope.

---

## Conventions the phases assume

| Concern | Convention |
| --- | --- |
| API prefix | `/api/v1`, application routes via `namespace :api { namespace :v1 { ... } }` in `config/routes.rb` (auth stays on Rodauth, which bypasses the router) |
| Controllers | `Api::V1::*Controller`, inheriting from `ApplicationController` (which already owns `current_account` + `authenticate!`) |
| Tests | RSpec request specs (`spec/requests/`) for endpoints, model specs for constraints/validations, FactoryBot factories; run `bundle exec rspec` |
| Money | plain `decimal(16,4)` columns — no money gem; rounding happens only at report/display time (§8) |
| Frontend | data-mode routes in `src/router/routes.js` with paths in `src/router/paths.js`, TanStack Query v5 + axios, MUI v9, Vitest + RTL (`npm run test:run`) |

---

## Phase dependency graph

```mermaid
flowchart LR
    P0[P0: decisions]
    P1[P1: reference data]
    P2[P2: users & roles]
    P3[P3: employees]
    P4[P4: components & plans]
    P5[P5: contracts]
    P6[P6: native report]
    P7[P7: FX + normalized]
    P8[P8: FE management]
    P9[P9: FE dashboard]

    P0 --> P1 & P2 & P4
    P1 & P2 --> P3
    P1 & P3 & P4 --> P5
    P4 & P5 --> P6
    P1 & P6 --> P7
    P3 & P4 & P5 --> P8
    P6 & P7 --> P9
```

---

## Phase 0 — Decisions before any code

Nothing is built here. Resolve these five points; each later phase names which decision it depends on.

### D0.1 — Account ↔ User mapping

The design's `User` (name, email, role) and Rodauth's `accounts` table describe the same person, but only one exists in code today. Two options:

- **A. Extend `accounts` (recommended).** Add `name` and `role` columns to `accounts` and treat `Account` as the design's `User`. `Employee.user_id` points at `accounts`. Rodauth ignores columns it doesn't know, so this is additive. One identity table, and `GET /api/v1/me` already returns the account.
- **B. Separate `users` table.** Keep `accounts` auth-only; add `users` (name, role, `account_id` unique, 1:1) and point `Employee.user_id` at `users`. More faithful to "a user is not necessarily an employee", at the cost of a join on every request.

Phase 2 is written for **option A**; note the delta if B is chosen.

### D0.2 — Country data source

`Country` (`code`, `name`, `currency`) is reference data that everything else keys off, and nothing populates it yet — Phase 1 ships the table and its read endpoint, and Phase 8 lists countries as read-only. Decide the source: a committed `db/seeds` list of ISO 3166-1 alpha-2 + ISO 4217 currency pairs (recommended), or a one-time import. Scope is small and stable, so a committed list is preferred over a runtime fetch.

### D0.3 — Reporting-currency configuration

§8 makes reporting currencies a **configured list**, not derived from data. Decide the store: a small DB table (recommended — runtime config, changed by an admin, no redeploy) vs. an env var/credentials list (deploy-time only). Phase 7 reads this.

### D0.4 — FX provider

Phase 7 introduces an adapter behind a fixed interface (`from`, `to` → `{ rate, rate_date, source }`). Decide now whether the first provider is ECB, openexchangerates, or manual entry — the adapter signature is identical; only the implementation differs. Manual is a valid v1 and satisfies "no live fallback, no fabricated rate" by construction.

### D0.5 — Component-assignment uniqueness

`CompensationPlanComponent` links a plan to a `SalaryComponent` with an amount. Decide whether a plan may assign the same component twice (e.g. two bonuses). Recommended: `UNIQUE (compensation_plan_id, salary_component_id)` — one amount per word per plan. Phase 4 encodes the choice.

---

## Phase 1 — Reference data: `Country`, `Department`, `Designation`

**Goal.** Land the three lookup tables that everything else keys off, and their read endpoints.

- Migrations:
  - `countries`: `code char(2) PK`, `name`, `currency char(3)`.
  - `departments`: `id`, `name`.
  - `designations`: `id`, `name`.
- Populating `countries` is deferred to **D0.2** — this phase ships the table empty, and the read endpoints return whatever it holds.
- Models + FactoryBot factories + model specs (presence/uniqueness as applicable).
- Endpoints (read-only for now; management CRUD is Phase 8): `GET /api/v1/countries`, `GET /api/v1/departments`, `GET /api/v1/designations`.
- **Done when:** the three tables exist, the three endpoints return their lists, and specs are green — the endpoint specs build their rows with factories, so nothing depends on seed data.

---

## Phase 2 — Users & roles (extends `accounts`)

**Goal.** Give the account a profile (`name`) and a role, and add role-based authorization.

- Migration per **D0.1 option A**: add `name` and `role` (`enum: hr | manager | employee`) to `accounts`. (Option B: new `users` table + factory instead.)
- `Account` model: `enum :role`, validation on `name` presence (keep `status` enum untouched — see the model's own comment about not re-declaring `status`).
- Extend `GET /api/v1/me` to return `{ id, email, name, role }`; update its request spec (the existing "no extra keys" example changes to the new shape).
- Add `require_role!(*roles)` to `ApplicationController` as a `before_action` helper (renders 403, mirroring the `authenticate!` style), with specs.
- **Done when:** migration applied, `me` returns the profile, a role-restricted probe endpoint is blocked/allowed correctly, specs green.

---

## Phase 3 — Employees

**Goal.** Model the employee and its required `Department`/`Designation` links.

- Migration:
  - `employees`: `id`, `user_id` (nullable, unique FK → `accounts`), `name`, `department_id` (not null FK), `designation_id` (not null FK).
- `Employee` model: belongs_to associations, validations (`department_id`/`designation_id` presence), `user` unique.
- Endpoints under `/api/v1/employees`: index/show/create/update (destroy if the design warrants it — flag as a slice-level decision; termination is `end_date`, not delete).
- **Done when:** CRUD works end to end, validations are specified, specs green. (Phases 1 and 2 must precede.)

---

## Phase 4 — Salary vocabulary & plans

**Goal.** Land the split vocabulary/assignment model: `SalaryComponent`, `CompensationPlan`, `CompensationPlanComponent`.

- Migrations:
  - `salary_components`: `id`, `name`, `category enum: earning | allowance | contribution`.
  - `compensation_plans`: `id`, `name`.
  - `compensation_plan_components`: `id`, `compensation_plan_id` FK, `salary_component_id` FK, `amount decimal(16,4)`, `frequency enum: monthly`. Apply the **D0.5** uniqueness choice.
- Models: `SalaryComponent`, `CompensationPlan` (`has_many :compensation_plan_components`), `CompensationPlanComponent` (amount presence/non-negative; **no currency column** — §3).
- Endpoints: `salary_components` CRUD, `compensation_plans` CRUD, and a nested assignment path (e.g. `POST /api/v1/compensation_plans/:id/compensation_plan_components`).
- Optionally seed a starter vocabulary (Basic Salary, Housing Allowance, Bonus, PF) — decide per slice.
- **Done when:** a plan with components round-trips through the API, constraints enforced, specs green.

---

## Phase 5 — Employment Contracts & active-contract resolution

**Goal.** Land the source of truth and the rule that picks *the* active contract.

- Migration:
  - `employment_contracts`: `id`, `employee_id` FK (not null), `country_code` FK (not null), `currency char(3)` (not null), `pay_frequency enum: monthly`, `compensation_plan_id` FK, `start_date` (not null), `end_date` (nullable).
  - `CHECK (end_date IS NULL OR end_date > start_date)`.
  - Partial unique index `UNIQUE (employee_id) WHERE end_date IS NULL` (one open-ended contract per employee).
- `EmploymentContract` model: `belongs_to :country, :compensation_plan, :employee`; default `currency` from `country.currency` on create (§3); application-level non-overlap validation.
- Resolution service (a PORO, e.g. `ActiveContract`) with the §7 predicates — `active_on?(date)`, `covers?(period)` — fully spec'd, since reporting in Phases 6–7 depends on it.
- Endpoints: contracts CRUD (nested under `/api/v1/employees/:id/contracts` or flat `/api/v1/contracts` — pick one in the slice).
- **Done when:** the partial unique index + CHECK hold, non-overlap is validated, the resolution service is green, CRUD works.

---

## Phase 6 — Native reporting (backend)

**Goal.** The first report: live projection, no FX.

- Report service (PORO, e.g. `CompensationReport`): for a period, select in-scope employees via the §6.1/§7 rules, sum `earning` + `allowance` `CompensationPlanComponent` amounts per contract, group by contract currency.
- No gross/net, no payable, no `contribution` (§6.2) — the only figure is total compensation per currency.
- Endpoint: `GET /api/v1/reports` with a period parameter; returns the native view (§6.3). Shape is a slice decision (grouped by currency, with employee-level detail for drill-down).
- **Done when:** the native report is correct for seeded fixtures (including an employee with a `contribution` component that must be excluded), specs green. No FX anywhere.

---

## Phase 7 — FX & normalized reporting

**Goal.** Rate snapshots + the normalized view, exactly per §8.

- Migration:
  - `exchange_rate_snapshots`: `id`, `period_month` (first day of month), `from_currency`, `to_currency`, `rate decimal(16,10)`, `rate_date`, `source`. Unique `(period_month, from_currency, to_currency)`.
- Reporting-currency config per **D0.3**.
- **Decide the ISO 4217 exponent source** used to round the normalized report — it is no longer a `Country` attribute (§5.4), so this phase must state where the exponent comes from.
- Rate capture service: on the first dashboard load of a month, compute the pair set (distinct `Country` currencies × configured reporting currencies, minus identity pairs) and fill missing pairs via the **D0.4** adapter. Reuse for the rest of the month; no live fallback.
- Normalized report: convert each contract-currency total at full precision, round to the target currency's ISO 4217 exponent, then sum; a missing pair shows **no figure** and the total carries a flag (`N currencies unavailable`) — never an estimate.
- Endpoint: `GET /api/v1/reports?currency=USD` (normalized), alongside the Phase 6 native shape.
- **Done when:** first-load capture fills the month's pairs once, repeated loads reuse them, a missing pair flags instead of fabricating, rounding matches ISO 4217, specs green.

---

## Phase 8 — Frontend: management screens

**Goal.** The screens HR needs to maintain reference data and records, wired to Phases 1–5.

- New paths in `src/router/paths.js`, route entries in `src/router/routes.js` under `RootLayout` (so the shell + auth gate already apply), each gated by role where the backend enforces one.
- Screens, one slice each: departments & designations, countries (read-only), employees, salary components, plans (+ component assignment), contracts. Reuse the existing MUI theme, `lucide-react` icons, and the `errorMessage()` convention from `src/api/errorMessage.js`.
- **Done when:** each screen renders real API data through TanStack Query, mutations round-trip, and the jsdom specs pass (`npm run test:run`).

---

## Phase 9 — Frontend: reporting dashboard

**Goal.** The dashboard that consumes Phases 6–7.

- A reporting page with the native view (grouped by currency) and a normalized toggle with a reporting-currency selector, rendering the missing-pair flag from Phase 7.
- Read-only: no run, no freeze, no audit trail — reflect that the numbers are live projections (§6.5).
- **Done when:** the dashboard reflects backend fixtures, currency selection drives the normalized view, flag states render, specs green.

---

## Definition of done (every phase)

- Migrations reversible and committed; `db/schema.rb` updated.
- Models carry the design's constraints as validations/DB constraints, each specified.
- Endpoints are under `/api/v1`, covered by request specs (auth + happy + failure paths).
- No Phase pulls in anything from `ARCHITECTURE.md` §9.

---

## Out of scope (do not build)

`ARCHITECTURE.md` §9, restated so no phase reintroduces it: payment processing, country-specific tax engines, `contribution` amounts in reporting, non-monthly pay frequencies, mid-period hire/termination proration, and mid-period plan switches. There is no payroll run and no persisted result — reporting is recomputed on read, with no audit trail and no effective-dating.
