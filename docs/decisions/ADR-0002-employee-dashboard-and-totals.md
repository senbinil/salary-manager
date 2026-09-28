# ADR-0002: Employee dashboard and compensation summaries

- Status: Accepted
- Date: 2026-09-27
- Related: [Architecture v0.7](../ARCHITECTURE.md), [implementation plan](../IMPLEMENTATION-PLAN.md)

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
| Dashboard filters | Filter the roster server-side by exactly five controls: a case-insensitive name substring, department, designation, employment status, and contract country. Return to the first page when a filter changes, offer a Clear filters action, and populate the dropdowns from the reference index endpoints. | Implemented |
| Dashboard overview aggregates | Add an organization-wide `GET /api/v1/dashboard/summary` returning the active-employee count and, per contract country, the active headcount and the sum of the compensation on active contracts. Keep each country's total in that country's currency, group by contract country only, and ignore the roster filters. | Implemented |
| Sample data | Deliver production-like employees through the `sample_data` rake task rather than the seed. It requires an explicit confirmation, refuses to run in the test environment, names each employee with a generated real name, and only ever inserts - leaving accounts and manually created employees alone. | Implemented |

## Consequences

- The dashboard remains an all-employee roster rather than an active-only view.
- Current status and current compensation come from the same active-contract date rule.
- The total is a direct sum in one contract currency. It is not net pay, a payroll result, or an FX-normalized report.
- The list API supplies a currency code beside the decimal total so clients do not infer currency from employment country.
- The detail UI selects one contract automatically. The nested contract API still exposes full history and single-contract reads, but the page does not provide a contract-history selector.
- No reporting period, stored report, payroll run, or contract write route was added in these phases. The roster filters arrived later, in the slice recorded above; the organization-wide overview aggregate was added later still, and is a current-state summary rather than a stored report.
- The sample-data entry is delivered as two rake tasks rather than a seed change, so a fresh clone still has a template-only `db/seeds.rb` apart from the sign-in accounts.

## Implementation sequence

The compensation model and contract response were established first. The employee total helper was then implemented at the model layer and exposed through the employee detail API when the detail page needed it. The dashboard list API and column followed. Backend specs and frontend tests were committed before their corresponding feature commits, with backend and frontend work kept in separate test/feature pairs.

The sample-data work landed as the `sample_data` rake task: `db/seeds.rb` creates only the sign-in accounts, and `SampleData::EmployeeSeeder` owns the employee dataset. It was later revised to name employees with generated real names instead of numbered `Sample Employee NNNNN` rows. That prefix was the only marker identifying a previous load's rows, so the `clear` task and the replace-then-insert behaviour went with it: loading is now additive, and a clean roster means resetting the database.
