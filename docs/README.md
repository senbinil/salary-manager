# Payroll Design — Documentation Index

Design documentation for the payroll / compensation system: HR defines how the organization compensates employees, and reporting works across countries and currencies.

There is no implementation yet — this repository is design-only.

---

## Start here

**[`ARCHITECTURE.md`](./ARCHITECTURE.md) — Payroll Design v0.5 (canonical).** This is the current design. Everything else either supports it or is historical.

| Order | Document                                                                   | What it is                                                                                                               |
| ----- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| 1     | [`ARCHITECTURE.md`](./ARCHITECTURE.md)                                     | **Canonical design (v0.5).** Domain model, entity definitions, reporting, currency rule, active-contract resolution, FX. |
| 2     | [`SALARY-COMPONENT-RELATIONSHIPS.md`](./SALARY-COMPONENT-RELATIONSHIPS.md) | Why `SalaryComponent` (the word) and `CompensationPlanComponent` (the money) are separate entities.                      |

> Document 2 is a companion to `ARCHITECTURE.md` and is **kept in sync with it**.

⚠️ **v0.5 is a deliberate contraction.** It retires payroll runs and deductions, so the dashboard reads employee and contract data directly, with no report-period selector, persisted result, or audit trail. Nothing is effective-dated, so editing a plan changes the compensation shown on the next read; FX rates are fixed per monthly snapshot (§8).

---

## Version lineage

| Version | File                                                           | Status      | Summary                                                                                                                                                           |
| ------- | -------------------------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v0.1    | [`ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) | Superseded  | First high-level overview: User → Employee → Contract → Plan → Components, plus local payroll calculation, two reporting views, and FX placement.                 |
| v0.2    | [`ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) | Superseded  | Consolidated v0.1 into a numbered reference; added an entity summary, a mermaid ERD, and 8 open questions.                                                        |
| v0.3    | [`ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) | Superseded  | Detailed the entities; split `SalaryComponent` (definition) from `CompensationPlanComponent` (assignment).                                                        |
| v0.4    | [`ARCHITECTURE-v0.4.md`](./archive/ARCHITECTURE-v0.4.md)       | Superseded  | Full payroll model: deduction plans and rules, payroll runs, entries and line breakdowns, per-run FX snapshots, ISO 4217 rounding. **Retired wholesale in v0.5.** |
| v0.5    | [`ARCHITECTURE.md`](./ARCHITECTURE.md)                         | **Current** | Overhaul: drops payroll runs and deductions entirely. Compensation is defined on the contract and reported directly.                                              |

---

## The archive

`archive/` is a **historical, non-normative record** — do not implement from it. It holds the superseded design plus the material that supports it:

- [`archive/ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) — what v0.1 → v0.3 changed and the decision behind each change.
- [`archive/ARCHITECTURE-v0.4.md`](./archive/ARCHITECTURE-v0.4.md) — the complete v0.4 design, including the retired deduction and payroll-run model.
- [`archive/RESOLUTION-LOG-v0.4.md`](./archive/RESOLUTION-LOG-v0.4.md) — the v0.4 review log: its 14 findings and their resolutions.
- [`archive/DATA-FLOW-v0.4.md`](./archive/DATA-FLOW-v0.4.md) — the v0.4 payroll-run walkthrough.
- [`archive/SALARY-COMPONENT-RELATIONSHIPS-v0.4.md`](./archive/SALARY-COMPONENT-RELATIONSHIPS-v0.4.md) — the two-sided (pay + deduct) version of the component guide.
- [`archive/README-v0.4.md`](./archive/README-v0.4.md) — the v0.4-era index.
- [`archive/ARCHITECTURE-ILLUSTRATIONS.md`](./archive/ARCHITECTURE-ILLUSTRATIONS.md) — illustrative figures from v0.1/v0.2. **These belong to the retired model**: they are payroll-entry and deduction totals, which v0.5 no longer produces.

---

## The design in one paragraph

The **Employment Contract** is the source of truth: it names the employment country, a single contract currency, and the assigned compensation plan. The **compensation plan** assigns amounts to reusable `SalaryComponent` definitions through `CompensationPlanComponent`s. Every employee belongs to a `Department` and holds a `Designation` (job title) — both are lookup relations used for filtering; neither affects compensation. The dashboard lists all employees, supports combined employee and contract filters, and drills down to contract records with their component breakdown. It has no reporting-period selector or aggregate report endpoint. There is no payroll run, persisted report result, or deduction calculation.

---

## Settled decisions

The four original v0.5 questions were settled on 2026-09-24:

1. **Dashboard data is read from employee and contract records** — no per-period report snapshot and no audit trail.
2. **FX is fetched once per month**, on the first dashboard load; a missing pair shows no figure rather than a fabricated rate. Phase 7 must settle a pair source that covers contract currency overrides (§3).
3. **Plan edits take effect on the next read** — an amount change is made in place and changes the compensation shown by the dashboard; there is no effective-dating.
4. **No payable figure** — compensation has no net/payable calculation. The dashboard can show the contract component breakdown; a payable concept would require a `SalaryComponent.category`.

## Pending implementation details

- Define the nested contract response and component data shape for the dashboard drill-down.
- Settle the combined filter set for employee and contract fields.
- Resolve how the dashboard receives captured FX rates without an aggregate report endpoint.

Everything deliberately out of scope is listed in **§9 Deferred Items** of `ARCHITECTURE.md`.
