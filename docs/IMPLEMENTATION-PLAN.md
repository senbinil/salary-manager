# Implementation Plan — Employee-Specific Compensation

This plan replaces the v0.5 implementation plan, preserved at [archive/IMPLEMENTATION-PLAN-v0.5.md](./archive/IMPLEMENTATION-PLAN-v0.5.md). The current architecture is [ARCHITECTURE.md](./ARCHITECTURE.md); the rationale and decision trail are in [ADR-0001](./decisions/ADR-0001-employee-specific-compensation.md).

## Status

Phases 1–9 below are implemented. The dashboard lists all employees with current contract fields, total compensation, status, and server-backed pagination. Employee drill-down selects the active contract for an active employee and the most recent ended contract for an inactive employee. Payroll, reporting, and dashboard filters remain future work. `EmployeeCompensation` supports nested component assignment at the model layer, but no HTTP contract write route was added.

## Delivery approach

Work on a feature branch, in the phases below. Keep each phase reviewable and use Conventional Commits. Use test-first commits within each application: commit the frontend test before its UI feature, and commit the backend spec before its backend feature. Never commit, push, or merge directly to main.

## Phase 1 — Record and publish the architecture decision

- Preserve the v0.5 architecture and implementation plan in docs/archive.
- Publish the v0.6 architecture and this implementation sequence.
- Record why shared plan amounts fail for employee-specific pay, why per-employee plans were rejected, and why the plan tag and salary component vocabulary remain reusable.
- Rewrite the salary-component relationship guide and update the documentation index.
- Done when all current docs describe the v0.6 model and the archived versions remain discoverable.

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
- Keep the list paginated and include no report-period selector, cross-currency conversion, payroll calculation, or aggregate report endpoint.

## Deferred — sample dashboard seed data

The implementation discussion selected a sample dataset of about 100 employees with sample contracts. The agreed reset scope was all employees, employment contracts, and employee compensation data, while preserving accounts and reference data, with a warning before the reset. This seed change is not part of the current implementation: `backend/db/seeds.rb` remains the Rails template stub. Treat the dataset and reset behavior as pending until a seed feature is implemented and reviewed.

## Verification

- Run targeted model specs after Phase 3 and request specs after Phase 5.
- Run backend bin/ci after API integration.
- Run frontend lint and tests after each UI slice.
- Run git diff --check before each phase commit.
