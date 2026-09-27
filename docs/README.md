# Salary Manager — Documentation Index

These documents describe the current employee-specific compensation design and preserve earlier decisions for review.

## Start here

| Document | Purpose |
| --- | --- |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Current v0.6 domain model, compensation ownership, currency, dashboard and API behavior. |
| [IMPLEMENTATION-PLAN.md](./IMPLEMENTATION-PLAN.md) | Focused implementation phases and verification steps. |
| [SALARY-COMPONENT-RELATIONSHIPS.md](./SALARY-COMPONENT-RELATIONSHIPS.md) | How plans, employee-specific amounts, and shared salary component definitions relate. |
| [decisions/ADR-0001-employee-specific-compensation.md](./decisions/ADR-0001-employee-specific-compensation.md) | Why shared plan amounts were replaced and the alternatives considered. |
| [decisions/ADR-0002-employee-dashboard-and-totals.md](./decisions/ADR-0002-employee-dashboard-and-totals.md) | Decisions for employee status, contract drill-down, and current compensation summaries. |

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

The dashboard lists all employees and shows current contract status, contract location and start date, and total compensation when a contract is active today. The total sums every component category in the active contract's currency. Clicking an employee opens the active contract when the employee is active, or the most recent ended contract when inactive. No payroll, reporting-period selector, or aggregate report endpoint is implemented.

## Implementation state

The backend has paginated employee and nested employment-contract read routes. Employee responses include a current total when the employee has an active contract; the list response also includes its currency code. `EmployeeCompensation` supports model-level nested component assignment, but no HTTP contract write endpoint accepts it. The frontend provides the employee table and contract drill-down. Dashboard filters, payroll, and reporting remain future work. See the implementation plan and ADR-0002 for phase status and decisions.
