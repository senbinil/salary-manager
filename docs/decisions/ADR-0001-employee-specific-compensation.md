# ADR-0001: Store compensation amounts per employee contract

- Status: Accepted
- Date: 2026-09-26
- Supersedes: The compensation ownership described by architecture v0.5

## Context

In v0.5, an employment contract selected a compensation plan, and CompensationPlanComponent stored the amount for each SalaryComponent. Plans were reusable, so two employees assigned the same plan necessarily received identical component amounts.

Actual compensation can differ by employee even when employees share a classification such as a plan. Creating a separate compensation plan for every employee would duplicate plan records, turn a reusable filter into an employee-specific record, and make plan maintenance harder.

## Decision

- Keep Employee has many historical EmploymentContracts.
- Give each EmploymentContract one required EmployeeCompensation.
- Store the plan reference on EmployeeCompensation as a reusable filter tag.
- Store amounts on EmployeeCompensationComponent, scoped to that employee compensation.
- Keep CompensationPlan as a named tag and SalaryComponent as shared name/category vocabulary.
- Remove CompensationPlanComponent and its plan-owned amount path. No existing records require backfill.
- Keep contract currency as the currency for all components on that contract.

## Alternatives considered

1. Keep shared plan amounts: rejected because employees assigned the same plan would continue to share identical amounts.
2. Create a distinct plan for every employee: rejected because it duplicates labels and amounts and makes filtering less meaningful.
3. Put amounts on SalaryComponent: rejected because a shared component definition cannot hold different employee amounts.

## Consequences

- Compensation changes are isolated to one contract's employee compensation.
- Changing the plan tag does not change amounts.
- Contract responses gain an employee_compensation object; the existing top-level compensation_plan_id remains for compatibility and is derived from that object.
- Database schema changes remove the old plan-component table and move the plan foreign key. No data migration is needed.
- Amount history within a contract remains out of scope; edits change the next response.

## Documentation trail

The full v0.5 architecture and implementation plan remain in docs/archive. The current model and sequencing are documented in docs/ARCHITECTURE.md and docs/IMPLEMENTATION-PLAN.md. The salary-component relationship guide is updated to explain the new ownership boundary.
