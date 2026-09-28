# Salary Manager Architecture v0.7

This document supersedes v0.6, preserved at [archive/ARCHITECTURE-v0.6.md](./archive/ARCHITECTURE-v0.6.md). Earlier versions remain listed in the [documentation index](./README.md).

## 1. Why the compensation model changed

In v0.5, an employment contract selected a reusable compensation plan, and the plan owned the amounts for its salary components. Every employee assigned the same plan therefore received the same component amounts. That shared-amount approach cannot represent the real differences in compensation between employees. Creating a separate plan for every employee would duplicate plan data and make the plan a poor filter.

In v0.6, amounts moved to an employee's compensation record on their employment contract. A compensation plan remains as a named tag for filtering, and salary components remain shared vocabulary. In v0.7, monthly exchange-rate snapshots and a separate conversion API add optional currency conversion without changing compensation records or native totals.

## 2. Design principles

1. An employee may have many employment contracts over time. At most one contract is active on a given date; the application checks that contract date ranges do not overlap.
2. Each employment contract has exactly one employee compensation record. Each record has a plan tag and one or more employee-specific component amounts.
3. A contract has one currency. All component amounts on its employee compensation use that currency; component rows do not store currency.
4. Compensation plans are reusable labels for filtering. They do not own component amounts.
5. Salary components are reusable definitions containing a name and category. They do not own amounts.
6. Employee compensation supports all existing categories: earning, allowance, and contribution. The current total compensation summary sums every category.
7. Amounts retain decimal precision 16, scale 4. Compensation data has no effective date or reporting-period field, and the dashboard design has no month selector.
8. The dashboard is a live view of employee and contract data. There is no payroll run, persisted report result, reporting-period selector, or aggregate report endpoint. FX conversion is a separate read operation using monthly stored snapshots.

## 3. Relationships

| Relationship | Meaning |
| --- | --- |
| Employee → EmploymentContract | One-to-many over time; contracts belong to one employee. |
| EmploymentContract → EmployeeCompensation | Required one-to-one. A unique foreign key on employee compensation prevents multiple records for one contract; model validation requires the record. |
| EmployeeCompensation → CompensationPlan | Many-to-one; the plan is a filter tag. |
| EmployeeCompensation → EmployeeCompensationComponent | One-to-many, with at least one component required. |
| EmployeeCompensationComponent → SalaryComponent | Many-to-one; the salary component supplies shared name and category. |
| EmploymentContract → Country | Many-to-one; country describes the employment location. |

## 4. Entity responsibilities

### Employee

An employee has an optional account, a required department and designation, and historical employment contracts. Country remains on the contract.

### EmploymentContract

The existing contract name and fields remain: employee, country, currency, start date, and end date. The plan foreign key moves off this table. Currency defaults from the country on create and can be overridden.

Constraints retain the existing end-after-start check, one open-ended contract partial unique index, and application-level non-overlap validation. The existing active(date = today) scope remains the point-in-time contract lookup.

### EmployeeCompensation

One required record belongs to each contract and to one compensation plan. It has one or more employee compensation components. The record is specific to that contract; changing another employee's compensation does not affect it.

### EmployeeCompensationComponent

Each row belongs to one employee compensation and one salary component. It owns the decimal(16,4) amount. The database and model enforce one row per salary component within an employee compensation, and amounts cannot be negative.

### CompensationPlan

A plan has a unique name and is attached to employee compensation as a reusable filter tag. It has no amount-bearing component assignments.

### SalaryComponent

A salary component is reusable vocabulary: unique name and category (earning, allowance, or contribution). Amounts exist only on employee compensation component rows.

## 5. Compensation and currency

The contract currency is the currency for every amount in its employee compensation. For example, a contract in India may use USD; the contract retains India as its country and USD as its currency. No component has a separate currency.

The component breakdown can contain all existing categories. The current total compensation helper sums every component amount, including earning, allowance, and contribution, on the selected active contract. It is a direct sum in the contract currency; it is not a net-pay, tax, or payable calculation. Employee endpoints return this native total. A separate conversion API can produce a display amount using the current month's stored snapshot; it does not change the compensation data or native total.

Amounts are not effective-dated within a contract. Editing an employee compensation component changes that contract's next response. A compensation-plan tag change only changes classification and filtering; it does not change component amounts.

## 6. Dashboard and API behavior

The dashboard roster includes all employees, whether active or inactive. An employee is active when a contract includes today's date, with both start and end dates inclusive and a null end date treated as ongoing. The paginated table shows name, department, designation, active contract country and start date, total compensation, and status; status is the last column. Contract fields and compensation are blank for employees without a current active contract.

The table is filtered by exactly five controls, combined with AND: a case-insensitive name substring, department id, designation id, employment status (active or inactive), and contract country code. The country filter follows the same rule as the status filter — an active employee matches on the current contract's country, an inactive one on an ended contract — and both ids and country codes come from the reference index endpoints. An unknown filter key is ignored and a malformed value answers 400. Filtering happens server-side, so the paginated result shrinks rather than filtering one fetched page.

Total compensation is the sum of every component category on the current active contract. An employee without an active contract has no current total. The employee list response returns `total_compensation` and `total_compensation_currency`; both are null when there is no active contract. The currency is the contract currency, which may differ from the country's default. The employee detail response returns `total_compensation` as a decimal string or null. These employee endpoints return native contract-currency totals and do not apply FX conversion.

Selecting an employee opens its detail page. The page selects the active contract for an active employee and the most recent ended contract for an inactive employee. If no applicable contract is found, it shows an informational message. The contract and compensation panels are side by side on medium and larger screens and stacked on narrow screens. Component categories use chips; contract values, component values, and the active-contract total use bold emphasis. The total is shown only for an active contract. An active employee's page also offers a display-currency selector built from the targets the conversion endpoint reports; the converted total and its rate date appear beside the native total, which stays visible with an explanation when a rate is missing or the request fails. Inactive employees request no conversion.

The contract endpoints continue to expose an employee's contract history, ordered by start date, and a single contract scoped to that employee. The current detail UI selects one contract automatically instead of offering a contract-history selector. The employee list responds to `page`, `limit`, and the `filter[...]` parameters above, and answers 400 for an invalid filter value.

The existing authenticated contract routes remain:

- GET /api/v1/employees/:employee_id/employment_contracts
- GET /api/v1/employees/:employee_id/employment_contracts/:id

Index ordering, authentication, employee scoping, and 404 behavior remain unchanged. No report endpoint is added.

Contract responses keep their existing fields, including top-level compensation_plan_id for compatibility. That ID is derived from the associated employee compensation. Responses add employee_compensation containing its ID, a compensation_plan object with ID and name, and components with amount plus salary component ID, name, and category. All categories are included, ordered by compensation amount descending. Amount serialization retains the existing decimal JSON format.

The separate authenticated `POST /api/v1/exchange_rates/convert` endpoint accepts an amount and three-letter source and target currency codes. It uses the current month's stored snapshot, returns available targets for the source currency, and does not call the provider. Matching currencies return the input amount with rate 1 and no rate date. If a requested pair has no current-month snapshot, the conversion amount, rate, and rate date are null. Invalid amounts or currency codes return 422. The employee detail page consumes this endpoint for active employees; the employee endpoints themselves do not convert.

## 7. Schema transition

There are no existing records to preserve. The schema change adds employee_compensations and employee_compensation_components, moves the plan foreign key from employment_contracts to employee_compensations, and removes compensation_plan_components. No data backfill is required. Foreign keys use the database's normal restriction behavior; deleting a contract does not cascade-delete its compensation.

## 8. FX snapshots and conversion

Exchange-rate snapshots are separate from employee compensation and are used only when a client requests a converted display amount. A snapshot is unique for `(period_month, base_currency, quote_currency)`. `period_month` is the first day of the calendar month used to look up the rate; `rate_date` is the provider observation date and must fall within that month. The record also keeps the positive rate, source, and provider attribution.

In production, `FetchExchangeRateSnapshotsJob` is scheduled for 02:00 on the last calendar day of each month. It finds distinct currencies on contracts active on the run date and fetches those currencies as base currencies from Frankfurter's public v2 rates endpoint, requesting observations from the first of the month through the run date. For each currency pair, it stores the earliest available observation in the month. Provider requests finish before the database write, and inserts are transactional. The unique monthly-pair index makes later runs or retries preserve an already stored snapshot rather than overwrite it.

`ExchangeRateConversionService` reads only snapshots for the current month. The conversion endpoint reports target currencies present for the requested base currency, plus the base currency itself. Same-currency conversions return the original amount with a rate of 1; a missing pair produces no converted value. There is no live request or prior-month fallback. `rate_date` records which provider observation supplied a conversion.

The endpoint is independent of employee controllers. Employee detail pages show native contract-currency totals and, for active employees, an optional converted total. There is no reporting-period selector, aggregate report endpoint, or stored report result.

## 9. Deferred items

- Payment processing and payroll runs.
- Country-specific tax engines.
- Net-pay or payable calculations.
- Pay-frequency rules; the current models do not store a pay frequency.
- Payroll calculations and proration.
- Effective-dated component changes within one contract.
- Historical-period overlap reporting.

## 10. Decision history

The reason and alternatives for the compensation ownership change are recorded in [ADR-0001: Employee-specific compensation](./decisions/ADR-0001-employee-specific-compensation.md). Dashboard, drill-down, and total-summary decisions are recorded in [ADR-0002](./decisions/ADR-0002-employee-dashboard-and-totals.md). FX model, provider, importer, conversion API, and UI decisions are recorded in [ADR-0003](./decisions/ADR-0003-monthly-fx-snapshots-and-conversion.md). Earlier architecture and implementation plans are preserved in the archive and remain historical, not implementation guidance.
