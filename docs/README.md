# Salary Manager — Documentation Index

These documents describe the current employee-specific compensation design and preserve earlier decisions for review.

## Start here

| Document | Purpose |
| --- | --- |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Current v0.6 domain model, compensation ownership, currency, dashboard and API behavior. |
| [IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md) | Focused implementation phases and verification steps. |
| [SALARY-COMPONENT-RELATIONSHIPS.md](./SALARY-COMPONENT-RELATIONSHIPS.md) | How plans, employee-specific amounts, and shared salary component definitions relate. |
| [decisions/ADR-0001-employee-specific-compensation.md](./decisions/ADR-0001-employee-specific-compensation.md) | Why shared plan amounts were replaced and the alternatives considered. |

## Version lineage

| Version | Document | Status |
| --- | --- | --- |
| v0.1–v0.3 | [ARCHITECTURE-HISTORY.md](./archive/ARCHITECTURE-HISTORY.md) | Historical |
| v0.4 | [ARCHITECTURE-v0.4.md](./archive/ARCHITECTURE-v0.4.md) and related archive docs | Superseded |
| v0.5 | [ARCHITECTURE-v0.5.md](./archive/ARCHITECTURE-v0.5.md), [IMPLEMENTATION-PLAN-v0.5.md](./archive/IMPLEMENTATION-PLAN-v0.5.md) | Superseded; shared plan-owned amounts |
| v0.6 | [ARCHITECTURE.md](./ARCHITECTURE.md), [IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md) | Current |

The archive is historical and non-normative. Use the current architecture and implementation plan when changing the application.

## Current design in brief

An employee may have multiple historical EmploymentContracts. Each contract has one EmployeeCompensation. That record carries a CompensationPlan tag for filtering and owns employee-specific component rows with amounts. SalaryComponent remains shared name/category vocabulary. The plan no longer supplies pay values, so employees using the same plan can have different compensation.

The planned dashboard will include all employees and use a contract active today for a current compensation summary when one exists. Contract drill-down will retain history and compensation detail. The API adds compensation to existing nested contract responses; it has no aggregate report endpoint or reporting-period selector.

## Implementation state

The backend has employee and nested employment-contract read routes. `EmployeeCompensation` supports model-level nested component assignment, but no HTTP contract write endpoint accepts it. The frontend currently has a placeholder Home page rather than an employee dashboard; dashboard UI work remains a later slice. See the implementation plan for phase status.
