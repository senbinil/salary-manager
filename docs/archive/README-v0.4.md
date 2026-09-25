# Payroll Design — Documentation Index (v0.4)

> **RETIRED — non-normative.** The v0.4-era index. Superseded by [`../README.md`](../README.md). It links to files that have since been removed, so links below may not resolve.

Design documentation for the payroll / compensation system: HR defines how the organization compensates employees, payroll is calculated from those rules, and reporting works across countries and currencies.

There is no implementation yet — this repository is design-only.

---

## Start here

**[`ARCHITECTURE.md`](./ARCHITECTURE.md) — Payroll Design v0.4 (canonical).** This is the current design. Everything else either supports it or is historical.

| Order | Document                                                                   | What it is                                                                                                                           |
| ----- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 1     | [`ARCHITECTURE.md`](./ARCHITECTURE.md)                                     | **Canonical design (v0.4).** Domain model, entity definitions, calculation engine, rounding, active-contract resolution, FX.         |
| 2     | [`DATA-FLOW.md`](./DATA-FLOW.md)                                           | End-to-end walkthrough with concrete record IDs — one employee through setup, a payroll run, and reporting.                          |
| 3     | [`SALARY-COMPONENT-RELATIONSHIPS.md`](./SALARY-COMPONENT-RELATIONSHIPS.md) | Focused explanation of the shared-vocabulary model (`SalaryComponent` across the pay side and the deduct side).                      |
| 4     | [`RESOLUTION-LOG.md`](./RESOLUTION-LOG.md)                                 | The 14 architectural-review findings plus the open questions and known issues resolved in v0.4 — each with its decision and section. |

> Documents 2 and 3 are companions to `ARCHITECTURE.md` and are **kept in sync with it**. Any design change must be propagated to them.

---

## Version lineage

| Version | File                                                           | Status      | Summary                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------- | -------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| v0.1    | [`ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) | Superseded  | First high-level overview: User → Employee → Contract → Plan → Components, plus local payroll calculation, the two reporting views, and FX placement.                                                                                                                                                                                                                                                                                                                                                                                                         |
| v0.2    | [`ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) | Superseded  | Consolidated v0.1 into a structured reference; added an entity summary, a mermaid ERD, and 8 open questions.                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| v0.3    | [`ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) | Superseded  | Detailed the entities; split `SalaryComponent` (definition) from `CompensationPlanComponent` (assignment); introduced `DeductionRuleBasis`; closed the v0.2 open questions.                                                                                                                                                                                                                                                                                                                                                                                   |
| v0.4    | [`ARCHITECTURE.md`](./ARCHITECTURE.md)                         | **Current** | Review-resolved, plus the four questions v0.3 left open and the known issues raised since: `basis_type` + `sequence` on deduction rules, `PayrollEntryLine`, contract `end_date` with a partial unique index, ISO 4217 minor-unit rounding, one payroll currency per contract, FX rate metadata, allowances valid as bases, per-line rounding, `DeductionPlan` defined (§5.14), `DeductionRule.rate` split into `fixed_amount` / `rate`, `PayrollRun.supersedes_run_id`, the reporting-currency set defined, and the v0.1/v0.2 India illustration documented. |

The `archive/` folder is a **historical record and is non-normative**. It holds two files, both condensed from the original five version documents:

- [`archive/ARCHITECTURE-HISTORY.md`](./archive/ARCHITECTURE-HISTORY.md) — what each version (v0.1 → v0.3) changed and the decision behind it.
- [`archive/ARCHITECTURE-ILLUSTRATIONS.md`](./archive/ARCHITECTURE-ILLUSTRATIONS.md) — the v0.1/v0.2 illustrative figures, preserved verbatim because they are load-bearing for the aggregate reporting example.

Both are retained for traceability only — do not implement from them.

---

## The design in one paragraph

The **Employment Contract** is the source of truth: it names the employment country, a single payroll currency, and the assigned compensation and deduction plans. The **compensation plan** assigns amounts to reusable `SalaryComponent` definitions; the **deduction plan** holds ordered `DeductionRule`s that apply either to gross or to specific components via `DeductionRuleBasis`. A `PayrollRun` reads every employee's active contract, computes gross and deductions in the contract currency, and persists a `PayrollEntry` together with a `PayrollEntryLine` breakdown that records not only each amount but the basis and rate that produced it. FX never touches payroll — it is applied only when producing normalized reports, using rates snapshotted per run.

---

## Known open items

**None.** §11 Open Questions of `ARCHITECTURE.md` is empty, and both documentation gaps previously listed here were closed in v0.4:

- `DeductionPlan` now has a `§5.14` definition block (`id`, `country_code`, `name`).
- The v0.1/v0.2 India illustration is documented in both archived docs as a round-number illustration whose figures are load-bearing for the aggregate reporting example.

Everything deliberately left out of scope is listed in **§10 Deferred Items** of `ARCHITECTURE.md` — those are intentional deferrals (approvals, payment processing, tax engines, proration, non-monthly frequencies), not open questions.
