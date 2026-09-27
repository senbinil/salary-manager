# Implementation Plan — Employee-Specific Compensation

This plan replaces the v0.5 implementation plan, preserved at [archive/IMPLEMENTATION-PLAN-v0.5.md](./archive/IMPLEMENTATION-PLAN-v0.5.md). The current architecture is [ARCHITECTURE.md](./ARCHITECTURE.md); the rationale and decision trail are in [ADR-0001](./decisions/ADR-0001-employee-specific-compensation.md).

## Status

Phases 1–5 of the v0.6 model and API sequence are complete. In Phase 6, the employee API pagination and the first frontend slice are complete: the dashboard fetches the default API page and displays employee names in a table. Browser-facing table pagination controls, filters, and contract drill-down remain future slices. A follow-up adds nested component attributes to `EmployeeCompensation` at the model layer only; no HTTP contract write route was added. The phases below record the delivery sequence.

## Delivery approach

Work on a feature branch, in the phases below. Keep each phase reviewable, use Conventional Commits, and commit specs before their implementation. Never commit, push, or merge directly to main.

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

The frontend dashboard is being delivered in focused slices. The initial employee table is name-only; pagination controls, filters, and contract drill-down follow separately.

### Slice 6.1 — Paginate the employee API (complete)

- Add Pagy offset pagination to `GET /api/v1/employees`, retaining name ordering with id as a stable tie-breaker.
- Accept one-based `page` and `limit` query parameters. Default to 20 employees per page and cap client-requested pages at 100.
- Return selected employee records under `data` and Pagy metadata under `pagination`; keep the employee `show` endpoint unchanged.
- Request specs and OpenAPI document the paginated list response.

### Slice 6.2 — Basic employee table (complete)

- Fetch the default page from the paginated employee endpoint and display employee names in a table.
- Keep the table name-only for this first slice; do not add dashboard filters or contract drill-down here.
- Show loading, error, and empty states.

### Slice 6.3 — Table pagination controls (next)

- Add page navigation and a page-size selector to the employee table.
- Send one-based `page` and the selected `limit` to the API; keep the selector within the API maximum of 100.
- Defer combined employee/contract filters and contract drill-down to a later slice. Add no report endpoint.

## Verification

- Run targeted model specs after Phase 3 and request specs after Phase 5.
- Run backend bin/ci after API integration.
- Run frontend lint and tests after each UI slice.
- Run git diff --check before each phase commit.
