# Payroll Design v0.5

This document supersedes the v0.4 design, whose full text is preserved at [`archive/ARCHITECTURE-v0.4.md`](./archive/ARCHITECTURE-v0.4.md). **v0.5 retires the payroll-run and deduction model.** There is no payroll run, no persisted payroll result, and no deductions — compensation is defined on the contract and reported directly. The v0.1–v0.3 lineage is recorded in [`archive/ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md).

---

## 1. Design Principles & Explicit Assumptions

1. **The Employment Contract is the source of truth** for how an employee is compensated.
2. **One active employment contract per employee** — enforced by `end_date` + a partial unique index.
3. **One contract currency.** All compensation amounts are expressed in it, and component amounts carry no currency of their own.
4. **FX belongs to reporting only** — never to setup.
5. **Salary components are reusable across countries** (shared vocabulary).
6. **Compensation amounts are monthly.** No `pay_frequency` column exists — one value would only restate this principle.
7. **Nothing is frozen.** There is no payroll run and no persisted payroll result; reporting is a live projection over current contracts and plans (§6).
8. **Money is stored at a fixed scale** — `decimal(16,4)` — and displayed rounded to the currency's ISO 4217 minor unit.

---

## 2. Domain Overview

```
User
 |
Employee
 |
Employment Contract   (one contract currency)
 |
Compensation Plan
 |
Compensation Components
 |
Reporting Dashboard
```

`Compensation Components` is **two** entities working together (§5.6, §5.7): a reusable `SalaryComponent` definition, plus a `CompensationPlanComponent` assignment that gives it an amount. That split is deliberate and is explained in [`SALARY-COMPONENT-RELATIONSHIPS.md`](./SALARY-COMPONENT-RELATIONSHIPS.md).

There is **no execution step**. Nothing sits between setup and reporting — the dashboard reads setup directly (§6).

---

## 3. Currency Rule

- `EmploymentContract.currency` is the **single currency** for the employee's compensation.
- It **defaults to** the employment `country`'s currency and **may be overridden** (e.g. an expat in India paid in USD has `currency = USD`; the contract country remains India for reporting).
- `CompensationPlanComponent.amount` is **always expressed in the contract currency** — no per-component currency field exists.
- Consequence: an employee's compensation is always expressed in one currency, so the "foreign-currency salary" case is satisfied by a contract-currency override, not by per-component FX.

---

## 4. Relationships

```mermaid
erDiagram
    USER ||--o| EMPLOYEE : "has optional account"
    DEPARTMENT ||--o{ EMPLOYEE : "employs"
    DESIGNATION ||--o{ EMPLOYEE : "holds"
    COUNTRY ||--o{ EMPLOYMENT_CONTRACT : "employs in"
    EMPLOYEE ||--o{ EMPLOYMENT_CONTRACT : "has (one active)"
    EMPLOYMENT_CONTRACT }o--|| COMPENSATION_PLAN : "assigned"
    COMPENSATION_PLAN ||--o{ COMPENSATION_PLAN_COMPONENT : "assigns"
    COMPENSATION_PLAN_COMPONENT }o--|| SALARY_COMPONENT : "uses"
```

Textual summary:

- **User → Employee** (optional, one-to-one)
- **Department → Employee** (one-to-many; every employee belongs to exactly one department)
- **Designation → Employee** (one-to-many; every employee holds exactly one designation)
- **Country → Employment Contract** (one-to-many)
- **Employee → Employment Contract** (one-to-many over time; **one active**)
- **Employment Contract → Compensation Plan** (many-to-one)
- **Compensation Plan → Compensation Plan Component** (one-to-many)
- **Compensation Plan Component → Salary Component** (many-to-one)

Every edge above is a persisted foreign key. Exchange rates are **not** part of the domain model — they are reporting input, not a relationship between domain entities (§8).

---

## 5. Entity Definitions

### 5.1 User

```
User
----
id            bigint PK
name          string
email         string (unique)
role          enum: hr | manager | employee
```

An employee **may** have a user account (a user is not necessarily an employee).

### 5.2 Employee

```
Employee
--------
id            bigint PK
user_id       bigint FK → users, nullable, unique
name          string
department_id bigint FK → departments, not null
designation_id bigint FK → designations, not null
```

> `country` is deliberately absent. Employment country lives on the active `EmploymentContract`; an employee's location is derived from it. Termination is represented by setting the contract's `end_date`.

An employee may have multiple `EmploymentContract` records over time; each contract belongs to one employee. The contract date ranges must not overlap (§7).

### 5.3 Employment Contract (source of truth)

```
EmploymentContract
------------------
id                    bigint PK
employee_id           bigint FK → employees, not null
country_code          string FK → countries, not null
currency              char(3), not null       # defaults to country.currency, overridable
compensation_plan_id  bigint FK → compensation_plans, not null
start_date            date, not null
end_date              date, nullable           # null = open-ended
```

Constraints:

- `CHECK (end_date IS NULL OR end_date > start_date)` — a contract cannot start and end on the same day.
- Partial unique index: `UNIQUE (employee_id) WHERE end_date IS NULL` — at most one open-ended contract per employee.
- Application-level check: contract date ranges for an employee must not overlap.

### 5.4 Country (reference data)

```
Country
-------
code         char(2) PK  # ISO 3166-1 alpha-2
name         string
currency     char(3)     # ISO 4217
```

> A contract may override `Country.currency` (§3), so countries alone may not describe every currency used by compensation. Phase 7 must settle an FX pair source that covers displayed contract data (§8).

### 5.5 Compensation Plan

```
CompensationPlan
----------------
id            bigint PK
name          string
```

Contains one or more `CompensationPlanComponent`s.

### 5.6 Compensation Plan Component (assignment)

```
CompensationPlanComponent
-------------------------
id                    bigint PK
compensation_plan_id  bigint FK → compensation_plans
salary_component_id   bigint FK → salary_components
amount                decimal(16,4)   # in contract currency
```

> No `currency` field — the amount is always in the owning contract's currency (§3).

> No `frequency` field either — compensation amounts are monthly system-wide (principle 6), so a one-value column would only restate an assumption the system already makes.

> **Edited in place.** Amounts are not effective-dated, so changing an amount changes the compensation shown by the dashboard on its next read (§6.5).

### 5.7 Salary Component (shared vocabulary)

```
SalaryComponent
---------------
id            bigint PK
name          string
category      enum: earning | allowance | contribution
```

- `earning` and `allowance` are the categories that count toward an employee's reported compensation (§6.2).
- `contribution` (e.g. employer-side PF) is **not** part of it, and remains deferred (§9).

A `SalaryComponent` stores **no amount of its own** — it is vocabulary, and the amount lives on the assignment that uses it (§5.6).

### 5.8 Exchange Rate Snapshot (rate store)

```
ExchangeRateSnapshot
--------------------
id              bigint PK
period_month    date       # first day of the month these rates serve
from_currency   char(3)
to_currency     char(3)
rate            decimal(16,10)
rate_date       date       # as-of date of the rate
source          string     # e.g. "ECB", "openexchangerates", "manual"
```

A stored rate is attributable: `rate_date` and `source` record when it was true and where it came from. A conversion uses only a stored snapshot; a pair without one shows no figure (§8).

> **Owned by the month, not a run.** `(period_month, from_currency, to_currency)` is unique. In v0.4 this table hung off `payroll_run_id`; with runs retired the month is the owner — rates are written on the first dashboard load of the month and reused for the rest of it (§8).

### 5.9 Department

```
Department
----------
id            bigint PK
name          string
```

Every employee belongs to a department (`Employee.department_id`, §5.2) — required, so an employee always has a department for filtering. Department is a lookup used for organization and report filters; it does not affect compensation amounts.

### 5.10 Designation

```
Designation
-----------
id            bigint PK
name          string
```

A **designation** (a.k.a. job title) is a lookup table, referenced by the required `Employee.designation_id` (§5.2). Keeping it a relation rather than free text makes it stable and filterable: reports group and filter by `Designation.name` without typos or duplicates. Designation does not affect compensation amounts.

---

## 6. Reporting

### 6.1 Scope

The v0.5 dashboard lists all employees; it has no reporting-month or reporting-period selector and does not limit the employee list to employees with an active contract. Viewers can combine filters over employee and contract fields, then open an employee's contract records.

Compensation travels with each employment contract as its assigned `CompensationPlanComponent` entries and associated `SalaryComponent` details. Contract responses supply those components; there is no aggregate report endpoint. The dashboard drill-down and employee contract view use the same component breakdown.

### 6.2 Compensation detail

When shown, a contract's compensation figure is the sum of its assigned components whose category counts toward pay (`earning`, `allowance`). There is no gross/net distinction, and no payable or net figure exists. `contribution` components are excluded from compensation totals because they are not compensation (§5.7). The component breakdown remains available with the contract.

### 6.3 Contract currency

Component amounts use their contract's currency. Keep contract figures in that currency; any future combined total must group by contract currency rather than add unlike currencies.

### 6.4 Normalized view

A user may select a reporting currency for a normalized view. Convert each displayed contract figure at full precision, then round it to the reporting currency's ISO 4217 exponent (§8). A missing rate hides the affected converted figure and marks its currency unavailable. The dashboard does not select contracts by reporting period.

### 6.5 Nothing is frozen — by design

Reporting is a **read-only projection**. There is no payroll run, no persisted result, and no snapshot of reported figures — deliberately.

- Dashboard data is read from employee and contract records and their assigned plan components; no report result is persisted.
- **Nothing is effective-dated.** Editing a plan amount or a contract changes the compensation shown by the dashboard on its next read: there is no version history or frozen figure to fall back on. The only input that does not drift is FX, which is fixed once captured for a month (§8).
- A change is therefore either a **factual correction** — fixing a wrong contract or a mistyped rate — or a **genuine retroactive edit**. The model cannot tell the two apart.

The design keeps **no audit trail and no effective-dating**: v0.5 cannot prove what contract compensation the dashboard showed on a past date. That is accepted, not overlooked.

---

## 7. Active Contract Resolution

- A contract is **active on date D** iff `start_date <= D` and (`end_date IS NULL` or `D <= end_date`).
- **One active contract per employee** is enforced by the partial unique index (`UNIQUE (employee_id) WHERE end_date IS NULL`) plus an application-level non-overlap check on date ranges.
- The all-employee dashboard does not apply the `active` scope to determine which employees appear. `EmploymentContract.active(date)` remains available for date-specific contract lookups. Period-overlap scoping is out of scope for v0.5 and may be reconsidered if future work adds historical-period reporting (§9).
- Termination = setting the contract `end_date`. Proration for mid-period hire/termination is deferred (§9).

---

## 8. FX Handling

FX is **outside** setup entirely.

- **Setup:** one currency per contract; component amounts carry no currency (§3).
- **Display:** contract compensation in its currency; optional FX conversion produces a normalized display.

Rules:

- **Pair-set source:** settle this in Phase 7. A contract currency may override its country's currency (§3), so a `Country.currency`-based set alone can omit a currency used by the dashboard. The source must cover currencies present in displayed contract data.
- **Reporting currencies are a configured list**, not something derived from compensation data. The set is system configuration, not a property of any country or contract.
- **Capture point:** rates are fetched **once per calendar month, on the first dashboard load of that month**, and stored per pair keyed to the month (§5.8). Every later dashboard load in that month reuses them, so conversions use the same monthly rates for every user and page load.
- **Rounding:** a converted amount is rounded to the reporting currency's ISO 4217 exponent for display — the exponent is reporting configuration, not a `Country` attribute (§5.4).
- **No live fallback.** A conversion uses **only** a stored snapshot for `(period_month, pair)`. A missing pair shows **no converted figure** for the affected contract and flags the currency as _rate unavailable_. There is no estimated branch and no fabricated rate.
- A reporting currency registered mid-month starts being captured at the **next** load; until then it shows no normalized figure.

---

## 9. Deferred Items

Deliberately out of scope, by decision — not open questions:

- Payment processing
- Country-specific tax engines
- `contribution` category components (employer-side)
- Pay frequencies other than `monthly`
- Proration for mid-period hire/termination
- Mid-period plan switches — for now a contract's `compensation_plan_id` is treated as stable; no rule defines a switch's effect on past periods.
- Period-overlap scoping — selecting contracts whose date ranges intersect a reporting period is out of scope for v0.5. The dashboard has no reporting-period selection; overlap rules may be reconsidered if future work adds historical-period reporting.

> Payroll approvals are **not** listed: they governed a payroll run's status workflow, and runs are retired (§2).
