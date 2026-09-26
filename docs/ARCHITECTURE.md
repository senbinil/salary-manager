# Salary Manager Architecture v0.6

This document supersedes v0.5, preserved at [archive/ARCHITECTURE-v0.5.md](./archive/ARCHITECTURE-v0.5.md). Earlier versions remain listed in the [documentation index](./README.md).

## 1. Why the compensation model changed

In v0.5, an employment contract selected a reusable compensation plan, and the plan owned the amounts for its salary components. Every employee assigned the same plan therefore received the same component amounts. That shared-amount approach cannot represent the real differences in compensation between employees. Creating a separate plan for every employee would duplicate plan data and make the plan a poor filter.

In v0.6, amounts belong to an employee's compensation record on their employment contract. A compensation plan remains as a named tag for filtering. Salary components remain shared vocabulary. This separates reusable classification from employee-specific pay values.

## 2. Design principles

1. An employee may have many employment contracts over time. At most one contract is active on a given date; the application checks that contract date ranges do not overlap.
2. Each employment contract has exactly one employee compensation record. Each record has a plan tag and one or more employee-specific component amounts.
3. A contract has one currency. All component amounts on its employee compensation use that currency; component rows do not store currency.
4. Compensation plans are reusable labels for filtering. They do not own component amounts.
5. Salary components are reusable definitions containing a name and category. They do not own amounts.
6. Employee compensation supports all existing categories: earning, allowance, and contribution.
7. Amounts retain decimal precision 16, scale 4. Existing monthly compensation semantics remain unchanged.
8. The dashboard is a live view of employee and contract data. There is no payroll run, persisted report result, reporting-period selector, or aggregate report endpoint.

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

The component breakdown can contain all existing categories. If a compensation total is shown, earning and allowance count toward it; contribution remains a separate component and is not included in that total. This model change does not add net-pay or payable calculations.

Amounts are not effective-dated within a contract. Editing an employee compensation component changes that contract's next response. A compensation-plan tag change only changes classification and filtering; it does not change component amounts.

## 6. Dashboard and API behavior

The dashboard roster includes all employees. For the current compensation summary it uses the employee's contract active today, when one exists; employees without an active contract remain in the roster without current-contract compensation. Employee drill-down retains access to the employee's contract history.

The existing authenticated contract routes remain:

- GET /api/v1/employees/:employee_id/employment_contracts
- GET /api/v1/employees/:employee_id/employment_contracts/:id

Index ordering, authentication, employee scoping, and 404 behavior remain unchanged. No report endpoint or new route is added.

Contract responses keep their existing fields, including top-level compensation_plan_id for compatibility. That ID is derived from the associated employee compensation. Responses add employee_compensation containing its ID, a compensation_plan object with ID and name, and components with amount plus salary component ID, name, and category. All categories are included, ordered by compensation amount descending. Amount serialization retains the existing decimal JSON format.

## 7. Schema transition

There are no existing records to preserve. The schema change adds employee_compensations and employee_compensation_components, moves the plan foreign key from employment_contracts to employee_compensations, and removes compensation_plan_components. No data backfill is required. Foreign keys use the database's normal restriction behavior; deleting a contract does not cascade-delete its compensation.

## 8. Reporting and FX

There is no reporting-period selection or aggregate report endpoint. Combined employee and contract filters operate over employee and contract data; the contract drill-down carries its own compensation detail.

FX remains a reporting concern, not setup data. If normalized display is implemented, it uses the v0.5 monthly rate snapshot decisions preserved in the archive: configured reporting currencies, captured rates, no live fallback, and ISO 4217 display rounding. The employee-specific compensation change does not change those rules.

## 9. Deferred items

- Payment processing and payroll runs.
- Country-specific tax engines.
- Net-pay or payable calculations.
- Pay frequencies other than the existing monthly semantics.
- Mid-period hire or termination proration.
- Effective-dated component changes within one contract.
- Historical-period overlap reporting.

## 10. Decision history

The reason and alternatives for this change are recorded in [ADR-0001: Employee-specific compensation](./decisions/ADR-0001-employee-specific-compensation.md). The previous architecture and implementation sequence are preserved in the archive and remain historical, not implementation guidance.
