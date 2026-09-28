# Implementation Plan — Salary Manager

This plan extends the v0.6 implementation plan, preserved at [archive/IMPLEMENTATION-PLAN-v0.6.md](./archive/IMPLEMENTATION-PLAN-v0.6.md), and the v0.5 plan at [archive/IMPLEMENTATION-PLAN-v0.5.md](./archive/IMPLEMENTATION-PLAN-v0.5.md). The current architecture is [ARCHITECTURE.md](./ARCHITECTURE.md); compensation and FX decisions are recorded in [ADR-0001](./decisions/ADR-0001-employee-specific-compensation.md), [ADR-0002](./decisions/ADR-0002-employee-dashboard-and-totals.md), and [ADR-0003](./decisions/ADR-0003-monthly-fx-snapshots-and-conversion.md).

## Status

Phases 1–17 below are implemented. The dashboard lists all employees with current contract fields, total compensation, status, and server-backed pagination, and filters the roster by name, department, designation, employment status, and contract country. An organization-wide overview reports the active-employee count and per-country headcount and compensation totals, shown on the dashboard as two sideways-scrolling strips of per-country cards. Employee drill-down selects the active contract for an active employee and the most recent ended contract for an inactive employee. The backend imports monthly exchange-rate snapshots and exposes a separate conversion endpoint. Active employee details show the native total and an optional converted total. Payroll and reporting remain future work. `EmployeeCompensation` supports nested component assignment at the model layer, but no HTTP contract write route was added.

## Delivery approach

Work on a feature branch, in the phases below. Keep each phase reviewable and use Conventional Commits. Use test-first commits within each application: commit the frontend test before its UI feature, and commit the backend spec before its backend feature. The FX backend was split into model, client, conversion service, importer job, and API phases, each delivered separately. Never commit, push, or merge directly to main.

## Phase 1 — Record and publish the architecture decision

- Preserve the v0.5 architecture and implementation plan in docs/archive.
- Publish the v0.6 architecture and this implementation sequence.
- Record why shared plan amounts fail for employee-specific pay, why per-employee plans were rejected, and why the plan tag and salary component vocabulary remain reusable.
- Rewrite the salary-component relationship guide and update the documentation index.
- Done when the then-current docs described the v0.6 model and earlier versions remained discoverable.

## Phase 2 — Model specs

- Add specs for the required contract-to-employee-compensation association, required plan tag, minimum one component, amount validation, component ownership, and uniqueness per salary component.
- Update employee and contract specs/factories for the one-to-one compensation relationship.
- Remove specs for the retired plan-owned amount model.
- Commit the specs before changing production models.
- Done when the new specs express the intended constraints, even though they initially fail.

## Phase 3 — Schema and models

- Add employee_compensations with a unique, non-null employment_contract_id and a required compensation_plan_id.
- Add employee_compensation_components with employee_compensation_id, salary_component_id, and amount decimal(16,4); enforce unique component per compensation and foreign keys.
- Remove compensation_plan_id from employment_contracts and drop compensation_plan_components. No backfill is needed because there are no existing records to preserve.
- Add model associations and validations; keep contract currency and historical dates unchanged.
- Update factories and remove the retired model/factory.
- Done when migrations roll forward and back, model specs pass, and schema constraints match the architecture.

## Phase 4 — Contract response specs

- Rewrite index and show request specs for employee-specific amounts, all salary component categories, plan tag ID/name, ordering, retained top-level fields, and employee scoping.
- Keep authentication, index ordering, and 404 behavior, including a contract owned by another employee.
- Commit the request specs before changing response serialization.
- Done when the examples define the new nested response and preserved behavior.

## Phase 5 — API serialization and OpenAPI

- Query compensation through the contract's employee_compensation association.
- Add employee_compensation to contract JSON with plan ID/name and component amount and salary component details. Derive the compatibility compensation_plan_id field from employee compensation.
- Keep the existing routes and add no report endpoint. No contract write route currently exists; do not add one.
- Update OpenAPI and verify the documented schema matches actual JSON.
- Done when request specs, OpenAPI review, backend CI, and git diff --check pass.

## Phase 6 — Employee list and dashboard

The dashboard was delivered in focused slices. Its current table shows organizational details and current-contract status while keeping all employees in the roster.

### Slice 6.1 — Paginate the employee API (complete)

- Add Pagy offset pagination to `GET /api/v1/employees`, retaining name ordering with id as a stable tie-breaker.
- Accept one-based `page` and `limit` query parameters. Default to 20 employees per page and cap client-requested pages at 100.
- Return selected employee records under `data` and Pagy metadata under `pagination`; keep the employee `show` endpoint unchanged.
- Request specs and OpenAPI document the paginated list response.

### Slice 6.2 — Basic employee table (complete)

- Fetch the default page from the paginated employee endpoint and display employee names in a table.
- Keep the first table slice name-only; add contract details in Slice 6.4.
- Show loading, error, and empty states.

### Slice 6.3 — Table pagination controls (complete)

- Add page navigation and a page-size selector to the employee table.
- Send one-based `page` and the selected `limit` to the API; keep the selector within the API maximum of 100.
- Add no combined employee/contract filters or report endpoint in this slice.

### Slice 6.4 — Employee table details (complete)

- Add department, designation, current active contract country, and current contract start date to the employee list API and table.
- Keep inactive employees in the list. Derive status from whether a contract is active today; show a dash for current-contract fields when inactive.
- Place the status column last.

## Phase 7 — Employee contract drill-down (complete)

- Link each dashboard employee name to the employee detail page.
- Show the active contract for an active employee. For an inactive employee, show their most recent ended contract; show an informational empty state if no matching contract exists.
- Reuse the existing employee and nested contract read APIs; add no contract write route.
- Keep contract information and compensation plan side by side on medium and larger screens and stack them on small screens. Align component amounts, show each category as a chip, and emphasize contract values and compensation amounts.
- Retain the API's full contract history even though the detail page selects one contract automatically.

## Phase 8 — Employee total compensation (complete)

- Add `EmploymentContract#total_compensation` to sum every employee-specific component amount without category filtering, and `Employee#total_compensation` to delegate to the current active contract.
- Return `nil` when there is no active contract. If multiple active contracts exist despite overlap validation, choose the one with the latest start date.
- Expose the employee total on `GET /api/v1/employees/:id` as a decimal string or `null`; keep the helper on the model and out of unrelated API responses.
- Show the total on the active employee detail page, formatted in the active contract currency. Do not show a current total on an inactive employee's historical contract page.

## Phase 9 — Dashboard total compensation (complete)

- Add `total_compensation` and `total_compensation_currency` to employee list items. Both are `null` without an active contract; use the active contract currency rather than inferring currency from country.
- Eager-load active compensation components while listing employees so the page can calculate each summary without a separate aggregate endpoint.
- Add a currency-formatted Total compensation column before the final Status column. Inactive employees show a dash.
- Keep the list paginated; do not add a report-period selector, converted totals, payroll calculation, or aggregate report endpoint in this dashboard phase.

## Phase 10 — Monthly FX snapshot model (complete)

- Store one positive rate per calendar month and currency pair, with `period_month` fixed to the first of the month and `rate_date` constrained to an observation within that month.
- Keep source and provider attribution with each snapshot. Enforce currency-pair uniqueness per month and reject same-currency pairs.
- Commit model specs before the schema and model feature.

## Phase 11 — Frankfurter client (complete)

- Add a small HTTP adapter for Frankfurter's public v2 rates endpoint, with a configurable base URL and request timeout.
- Validate HTTP status and response shape at the client boundary; leave monthly selection and persistence to the importer.
- Commit client specs before the adapter implementation.

## Phase 12 — Snapshot conversion service (complete)

- Convert amounts using only the current month's stored snapshot for the requested source/target pair.
- Return the original amount with rate 1 for matching currencies; return null conversion data for a missing pair and include currently available target currencies.
- Keep external provider calls out of the conversion service. Commit service specs before implementation.

## Phase 13 — Monthly snapshot importer (complete)

- For the run date, fetch rates using currencies on contracts active that day as base currencies, from the first of the month through the run date.
- Store the earliest available observation per pair for that month. Fetch all bases before writing and use a transaction; a unique conflict preserves an existing snapshot.
- Schedule the production job at 02:00 on the last calendar day of each month. Commit job specs before implementation.

## Phase 14 — Separate conversion API (complete)

- Add authenticated `POST /api/v1/exchange_rates/convert`, independent of employee controllers, and document its request and response in OpenAPI.
- Accept a finite, non-negative amount and three-letter currency codes. Return available target currencies and either the current-month conversion, a same-currency result, or null conversion fields when no snapshot exists.
- Commit request specs before adding the controller and route. Do not fetch provider rates during an API request.

## Phase 15 — Employee detail FX display

- Add conversion display only to active employee details. Keep the native contract-currency total and show the selected converted amount beside it; use the contract currency as the initial target.
- Request the conversion endpoint for the contract currency to populate available targets, and offer only currencies returned by the API. Show the rate observation date for converted values.
- If no rate is available or the request fails, retain the native total and explain that conversion is unavailable. Do not request conversion for inactive employees.
- Follow frontend test-first commits. Cover available currencies, target selection, converted amount and date, missing rates, request failures, and inactive employees.

## Phase 16 — Dashboard filters (complete)

- Accept `filter[name_cont]`, `filter[department_id]`, `filter[designation_id]`, `filter[employment_status]`, and `filter[country_code]` on the employee list endpoint. Combine the supplied filters, ignore unknown keys, and answer 400 for a malformed value.
- Apply the status rule to the country filter: an active employee matches on the current contract's country, an inactive employee on an ended contract's.
- Commit request specs before the query object, and document the parameters in OpenAPI.
- Add the five dashboard controls plus Clear filters. Reset to the first page whenever a filter changes, keep the typed name value untrimmed in state and trim it only in the request, and feed the dropdowns from the reference index endpoints.
- Follow frontend test-first commits: each control, the combined request, clearing, and the empty result.

## Phase 17 — Dashboard overview aggregates (complete)

- Add authenticated `GET /api/v1/dashboard/summary`, an organization-wide overview of the active workforce: the number of employees with a contract active today, and per contract country the active headcount and the sum of the compensation on those active contracts.
- Reuse the active-contract rule and the total's all-category sum. Keep each country's total in that country's currency; do not convert to a common base and do not split a country by contract currency.
- Return only countries with at least one active employee, ordered by code. The overview is organization-wide and ignores the roster filters.
- Commit the query spec before the query object, and the request spec before the controller and route. Document the endpoint in OpenAPI.
- Show the overview on the dashboard as two strips of country cards that scroll sideways: one for compensation, each card in that country's own currency, and one for headcount, whose badge carries the organization-wide active-employee total. The ledger's columns and pagination stay as they were, restyled only.
- Feed both strips from the one summary request, so a failing summary shows its own message and leaves the employee table usable.
- Commit the frontend spec before the widgets. Give each strip paging buttons that page one card and go inert at each end.

## Sample data

The sample employee dataset is delivered through rake tasks, not the seed. `db/seeds.rb` creates only the three sign-in accounts and reads their password from `credentials.default_password`; employee rows stay out of it, because `db:seed:replant` runs the seed against the test database in CI and any employee it created would break specs that assert exact counts.

```sh
CONFIRM_SAMPLE_DATA=yes bin/rails 'sample_data:load[10000]'
```

The task demands the confirmation variable and refuses to run in the test environment. `load` is additive: it inserts the requested employees, names each one with a generated first and last name, and never deletes anything, so loading twice leaves two sets behind and a clean roster means resetting the database. `SampleData::EmployeeSeeder` inserts in batches of 500, so 10,000 employees - about 60,000 rows with their contracts, compensations and components - takes seconds. Reference data is created on the way in, which is what makes it optional to seed anything else locally.

## Verification

- Run targeted model specs after Phase 3 and request specs after Phase 5.
- Run backend bin/ci after API integration.
- Run frontend lint and tests after each UI slice.
- Run git diff --check before each phase commit.

The FX phase decisions and implementation state are summarized in [ADR-0003](./decisions/ADR-0003-monthly-fx-snapshots-and-conversion.md). The end-to-end application and FX data flows are described in [WORKFLOW-AND-OVERVIEW.md](./WORKFLOW-AND-OVERVIEW.md).
