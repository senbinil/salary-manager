# Review Resolution Log (v0.4)

> **RETIRED — non-normative.** The v0.4 review log. v0.5 retired the payroll-run and deduction model that these findings resolve, so the findings no longer apply. Kept as the record. Relative links below refer to the v0.4 layout and may not resolve.

- **Date:** 2026-09-23
- **Source:** Lead-architect review of the payroll design (v0.1–v0.3)
- **Findings, open questions, and known issues applied in:** [`ARCHITECTURE.md`](./ARCHITECTURE.md) v0.4

This log tracks every finding from the architectural review and the decision taken to resolve it, plus the open questions and known issues that were resolved afterwards. Section references point to `ARCHITECTURE.md` (v0.4), whose section numbering is unchanged from v0.3.

| #   | Review finding                                                                                                      | Decision                                                                                                                                                                                                               | Section          |
| --- | ------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| 1   | "Percentage of Gross" not representable — `salary_component_id` is required but gross-based rules have no component | Add `basis_type` (`gross` / `component`); `salary_component_id` is nullable when `basis_type = gross`                                                                                                                  | §5.8, §5.9       |
| 2   | Currency contradiction — component has its own `currency`, but payroll is single-currency                           | **One payroll currency per contract.** Remove `CompensationPlanComponent.currency`; all component amounts are in the contract currency. The "foreign-currency salary" case is handled by setting the contract currency | §3, §5.3, §5.6   |
| 3   | `calculation_type`/`rate` under-specified (units, percent-of-what)                                                  | Split into `calculation_type` (`fixed` / `percentage`) **and** `basis_type` (`gross` / `component`). `rate` is a decimal; percentage rates are stored as the percent value (e.g. `12.0` = 12%)                         | §5.8, §6         |
| 4   | Deduction ordering unresolved                                                                                       | Add `sequence` to `DeductionRule`; rules are applied in ascending `sequence` order                                                                                                                                     | §5.8, §6.3       |
| 5   | No component-level breakdown in `PayrollEntry`                                                                      | Add `PayrollEntryLine` to freeze a full earning/deduction breakdown per entry                                                                                                                                          | §5.12            |
| 6   | "Active contract" under-defined (no `end_date`, no resolution rule)                                                 | Add `end_date` (nullable) to contract; define active-contract resolution and enforce "one active" with a partial unique index                                                                                          | §5.3, §7         |
| 7   | Redundant/conflicting currency & country fields                                                                     | Remove `Employee.country` (employment country lives on the contract) and `CompensationPlanComponent.currency`. Contract currency defaults to country currency, overridable                                             | §5.2, §5.3, §5.6 |
| 8   | `pay_frequency` field vs. "monthly" assumption                                                                      | Keep `pay_frequency` on the contract as an enum, currently constrained to `monthly`; run period = calendar month                                                                                                       | §5.3, §5.10      |
| 9   | FX snapshot lacks rate metadata                                                                                     | Add `rate_date` and `source`; define the audited-report fallback rule                                                                                                                                                  | §5.13, §9        |
| 10  | Run idempotency & scope edge cases                                                                                  | Define run scope (all employees active during the period) and re-run semantics (new run, history preserved); proration deferred                                                                                        | §7, §8           |
| 11  | `PayrollResult` entity silently dropped                                                                             | Stated as a derived projection, not persisted                                                                                                                                                                          | §5.11            |
| 12  | ERD mixes persisted and transient relationships                                                                     | Annotated: `PayrollRun → EmploymentContract` is a transient read, not a persisted FK                                                                                                                                   | §4               |
| 13  | Status workflow vs. deferred approvals/payment                                                                      | Keep `DRAFT → CALCULATED → APPROVED → PAID`; `APPROVED`/`PAID` are placeholders, workflow deferred                                                                                                                     | §5.10, §10       |
| 14  | Rounding fixed at "2 decimals" ignores currency minor units                                                         | Round using the currency's ISO 4217 minor unit; store money as `decimal(16,4)`                                                                                                                                         | §6.4             |

---

## Deltas not raised as findings

The table above records the 14 findings raised in the review. Three further v0.3 → v0.4 changes were intentional but were **not** review findings, and are recorded here so the delta set is complete:

- **`DeductionRuleBasis.percentage` renamed to `weight`.** v0.3 §4.9 already described the column as an optional weighted basis; v0.4 renames it to state what it holds (the fraction of that component included in the basis) and defaults it to `1.0`. See §5.9.
- **`EmploymentContract.country` renamed to `country_code`.** The field now names its reference target explicitly (`FK → countries.code`) instead of shadowing the table it points at. Related to finding #7 but not itself listed there. See §5.3.
- **`Compensation View` dropped.** The read-only projection introduced in v0.2 §2.12 does not appear in v0.3 or v0.4. It was never a persisted entity and added no behaviour beyond walking the contract → plan → components chain, which §12 already describes. (Contrast with finding #11, which covers `PayrollResult`.)

---

## Resolved in v0.4

The 14 findings above and the four open questions v0.3 left behind were settled together in v0.4. The questions are recorded separately here because they are design decisions rather than editorial fixes — they change the model, not only its wording.

### Q1 — May a `basis_type = component` rule reference an allowance?

**Decision: yes — any gross-contributing category (`earning`, `allowance`); `contribution` is rejected.**

v0.3 was internally inconsistent here. §6.2 defined gross as `earning + allowance`, but §6.3's formula used a helper named `earning_amount` and its prose said "that component's earning amount", implying earnings-only, while §5.9's FK carried no category restriction at all. Practically, deductions are often assessed on gross wages including allowances (Indian ESI, for example), so the implied restriction was artificial.

The helper is renamed `component_amount(x)` and defined as the component's amount _as included in gross_. A `contribution` component has no `component_amount` — it is excluded from gross (§5.7) and deferred (§10) — so the engine rejects such a rule as a configuration error.

→ §6.3

### Q2 — Per-line or end-of-run rounding?

**Decision: per-line, at computation time. The question was deleted as already answered.**

§6.4 already decided this; the residual ambiguity was whether `rate` is itself rounded. §6.4 now states explicitly that `rate` is used at full stored precision (`decimal(16,6)`) and never pre-rounded, and that `net` is the sum of the rounded lines — so no residual rounding difference exists to reconcile. v0.3 §11 Q2 is removed.

→ §6.4

### Q3 — May a duplicate run for the same period reuse the prior run's FX snapshots?

**Decision: no. Snapshots are never shared between runs; carrying a rate forward must be recorded.**

§9 already implied this, since an audited report "uses only snapshots belonging to the same run" — but §8 permits duplicate runs for a period, which makes the reuse case reachable and currently indistinguishable from a manually entered rate. v0.4 states the rule explicitly: a run owns its snapshots and a re-run takes fresh ones, which is what allows an audited report to be produced without first deciding which run for a period is authoritative. A deliberate carry-forward remains allowed, but `ExchangeRateSnapshot.source` must record its origin (e.g. `"carried forward from run 900"`).

→ §9

### Q4 — Should entries freeze the contract snapshot?

**Decision: yes, on both levels — which plans were in force, and how each line was derived.**

v0.3 stored only `label` + `amount` and the component/rule ids on `PayrollEntryLine`. That answers "what was this line and how much", but not "how was it derived": the applied rate, the resolved basis, and the weight were all discarded. Combined with the transient contract read (§4), nothing recorded which contract or plan versions were in force.

v0.4 adds:

- `PayrollEntry.employment_contract_id`, `.compensation_plan_id`, `.deduction_plan_id` — **frozen values, not FKs**, so that later correction or retirement of a plan cannot retroactively alter a past run.
- `PayrollEntryLine.basis_amount`, `.rate`, `.basis_type` — which makes each historical line **reproducible** (`basis_amount × rate / 100 = amount`) rather than merely labelled, matching the guarantee `ExchangeRateSnapshot` already provides for FX.

→ §5.11, §5.12

---

## Resolved in v0.4 — known issues

Three open questions and two documentation gaps in `README.md` were also closed in v0.4.

### The `DeductionRule.rate` split

**Decision: split the column into `fixed_amount` and `rate`.**

One `decimal(16,6)` column held either a currency amount (when `calculation_type = fixed`) or a percent value (when `percentage`). A row could not be interpreted without reading a sibling column, and a currency amount and a percentage shared one scale. v0.4 uses `fixed_amount decimal(16,4)` and `rate decimal(16,6)`, constrained so exactly one is non-null and it matches `calculation_type`. The unit now lives in the column name.

→ §5.8, §6.3, §6.5

### "Each reporting currency in use" defined

**Decision: reporting currencies are a configured list, and a run snapshots (entry currencies present in the run × configured reporting currencies).**

§9 required a snapshot "for every currency pair needed" without defining that set, so the number of rows a run writes was unspecified and the effect of registering a new reporting currency was undefined. v0.4 states the set explicitly. Because the snapshot set is fixed when a run executes, adding a reporting currency later leaves past runs untouched — a report in the new currency over an old run correctly falls back to the estimated (not audited) path.

→ §9

### Supersession mechanism defined

**Decision: add `PayrollRun.supersedes_run_id`.**

§8 permitted duplicate runs for a period and said they were "flagged in reporting", but no mechanism existed to do so. v0.4 adds a nullable, **unique** self-FK. Uniqueness caps supersession at one successor per run, so chains are linear and cannot branch. Reporting prefers the chain head — the run that no other run supersedes — and superseded runs stay queryable but are excluded from default reporting.

→ §5.10, §8

### `DeductionPlan` defined

**Decision: `id`, `country_code`, `name`.**

It was the only one of the 14 §4 ERD entities without a `§5.x` definition block, leaving undeclared both its primary key (referenced by two FKs) and its country link. v0.4 defines it as a country-scoped catalogue of deduction rules that carries no amounts of its own. It is appended as **§5.14** rather than inserted after §5.4, so the existing §5.x numbering — referenced throughout this log and by both companion docs — stays stable.

→ §5.14

### v0.1/v0.2 India illustration documented

**Decision: keep the figures and document why they are what they are.**

The archived v0.1/v0.2 illustrations show the India employee with ₹20,000 deductions and ₹80,000 net, which does not follow from the India deduction plan shown beside them (₹18,900 / ₹81,100).

Those figures are **load-bearing and must not be "corrected"**: the same documents' native-currency view reports 50 INR employees with ₹5,000,000 gross and ₹4,000,000 net — exactly 50 × (₹100,000 / ₹80,000). Replacing the per-employee deduction figure with the rule-derived ₹18,900 would make the aggregate inconsistent. The illustration is therefore a round-number one, and the preserved copy says so.

→ [`archive/ARCHITECTURE-ILLUSTRATIONS.md`](./archive/ARCHITECTURE-ILLUSTRATIONS.md)
