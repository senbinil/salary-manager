# Payroll Design — Version History (v0.1 → v0.3)

> **HISTORICAL — non-normative.** This file records how the design evolved and why. It is not a design document. The current design is [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (**v0.5**); the v0.4 design it was written against is preserved at [`ARCHITECTURE-v0.4.md`](./ARCHITECTURE-v0.4.md). Do not implement from this file.

This file condenses the three superseded documents previously kept as `ARCHITECTURE-v0.1.md` … `ARCHITECTURE-v0.3.md`. It preserves the traceability those files existed to provide — what each version changed and the decision behind it — without restating the superseded entity schemas themselves; only the current definitions in `../ARCHITECTURE.md` are normative.

The illustrative figures those documents carried are preserved in [`ARCHITECTURE-ILLUSTRATIONS.md`](./ARCHITECTURE-ILLUSTRATIONS.md); they belong to the retired payroll-run/deduction model, which v0.5 no longer produces.

---

## v0.1 — High-Level Overview

The first pass: one linear chain, deliberately simple.

- Domain chain: `User → Employee → Employment Contract → Compensation Plan → Salary Components → Payroll Calculation → Deduction Plan → Payroll Result → Reporting Dashboard`.
- **Payroll calculation stays local** — each employee is calculated in their own payroll currency, and no conversion happens during calculation.
- Reporting was defined as **two views**: _native currency_ (group by currency, no FX) and _normalized_ (choose a reporting currency, convert). **FX belongs to the reporting layer**, never to payroll.
- Two FX-storage options were weighed: _Simple_ (fetch the rate live when the dashboard loads) versus _Auditable_ (store an FX snapshot per payroll run). The auditable option was marked "better" and became the model.
- First sketches of `PayrollRun`, `PayrollEntry` and `ExchangeRateSnapshot`.
- Deferred from the start: payroll runs, approvals, payment processing, country-specific tax engines.

## v0.2 — Structured Reference

Consolidated v0.1 into a numbered reference; added an entity summary, a mermaid ERD, and an end-to-end flow.

- Added **Design Principles**, a formal **entity summary**, and **PayrollResult** / **CompensationView** to the entity list. Both were later dropped: `PayrollResult` is not persisted (finding #11) and `CompensationView` was never a persisted entity — neither appears in `../ARCHITECTURE.md`.
- Recorded that a **deduction plan is attached to the Employment Contract**, never to the run — the run reads the active contract's plan at calculation time. The "Employee Payroll Profile" alternative floated at the time was dropped; §5.3 attaches both plans to the contract alone.

## v0.3 — Entity Detail and the Shared Vocabulary

Detailed every entity and introduced the split that defines the model.

- **`SalaryComponent` split in two:** a reusable `SalaryComponent` definition, separate from a `CompensationPlanComponent` assignment carrying the amount, currency and frequency. This is the "shared vocabulary" design — components are reusable across countries.
- Added **`DeductionRule`** and **`DeductionRuleBasis`** (rule → one or more `SalaryComponent`s, extensible with a percentage/weight) to answer "what is a deduction's base?".
- Added **`Country`** as a seeded reference table.
- Decisions:

  | Decision                | v0.3 answer                                     |
  | ----------------------- | ----------------------------------------------- |
  | Rounding                | 2 decimal places ⚠️ _later replaced_            |
  | Pay frequency           | Monthly — a run's period spans a calendar month |
  | Component reuse         | Via the definition/assignment split             |
  | Deduction basis mapping | Via `DeductionRuleBasis`                        |
  | Run scope               | A `PayrollRun` processes all employees          |
