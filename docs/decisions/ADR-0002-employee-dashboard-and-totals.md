# ADR-0002: Employee dashboard and compensation summaries

- Status: Accepted
- Date: 2026-09-27
- Related: [Architecture v0.6](../ARCHITECTURE.md), [implementation plan](../IMPLEMENTATION-PLAN.md)

## Context

The employee dashboard started as a paginated name list. It now presents current employment status and contract details, supports a contract drill-down, and shows a current compensation total. The product decisions below were made incrementally during those implementation phases.

## Decisions by phase

| Phase | Decision | Implementation state |
| --- | --- | --- |
| Dashboard roster | Keep every employee in the list. Mark an employee active only when a contract includes today; an inactive employee remains visible. | Implemented |
| Dashboard details | Show department, designation, active contract country and start date, total compensation, and status. Keep Status as the last column; show a dash for current-contract values when inactive. | Implemented |
| Employee drill-down | An active employee opens their current active contract. An inactive employee opens their most recent ended contract. If no matching contract exists, show an informational message. | Implemented |
| Detail page layout | Place contract information and compensation side by side on medium and large screens and stack them on small screens. Align compensation amounts, show component categories as chips, and emphasize contract and amount values. | Implemented |
| Compensation helper | Calculate the employee's total from the current active contract only. Include every component category, including earning, allowance, and contribution. Return `nil` without an active contract. | Implemented |
| Overlap fallback | Contract date ranges are validated against overlap. If bad data nevertheless produces multiple active contracts, use the one with the latest start date for status and total selection. | Implemented |
| Employee detail API | Expose `total_compensation` as a decimal string or `null` on the employee show response so the detail page can display the total. | Implemented |
| Dashboard total API | Include `total_compensation` and `total_compensation_currency` in each employee list item. Use the active contract's currency; return `null` for both fields when inactive. | Implemented |
| Dashboard total display | Format the total using the contract currency and the browser's locale. Do not display a current total for an inactive employee. | Implemented |
| Sample data | Plan for about 100 employees with sample contracts. Before seeding, clear all employees, contracts, compensation records, and linked component rows; preserve accounts and reference data and display a warning. | Deferred; not in current `main` implementation |

## Consequences

- The dashboard remains an all-employee roster rather than an active-only view.
- Current status and current compensation come from the same active-contract date rule.
- The total is a direct sum in one contract currency. It is not net pay, a payroll result, or an FX-normalized report.
- The list API supplies a currency code beside the decimal total so clients do not infer currency from employment country.
- The detail UI selects one contract automatically. The nested contract API still exposes full history and single-contract reads, but the page does not provide a contract-history selector.
- No reporting period, dashboard filter, aggregate report endpoint, payroll run, or contract write route was added in these phases.

## Implementation sequence

The compensation model and contract response were established first. The employee total helper was then implemented at the model layer and exposed through the employee detail API when the detail page needed it. The dashboard list API and column followed. Backend specs and frontend tests were committed before their corresponding feature commits, with backend and frontend work kept in separate test/feature pairs.

The sample-data reset policy is recorded for a future seed feature only. `backend/db/seeds.rb` remains the Rails template stub in the current implementation.
