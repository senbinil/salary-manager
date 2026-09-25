# Payroll Design — Preserved Illustrations (v0.1 / v0.2)

> **HISTORICAL — non-normative.** These figures come from the **retired** v0.4 model: they are payroll-entry and deduction totals, which v0.5 no longer produces. The current design is [`../ARCHITECTURE.md`](../ARCHITECTURE.md) (**v0.5**). Do not implement from this file — and if you cite it, do not "correct" its numbers either.

---

## Why this file exists

The v0.1 and v0.2 documents carried a worked illustration whose India deduction total (₹20,000) does **not** follow from the India deduction plan printed beside it, which yields ₹18,900. That mismatch is **intentional**, and it is the reason this file outlived the condensing of the archive.

From [`../RESOLUTION-LOG.md`](../RESOLUTION-LOG.md) — _"v0.1/v0.2 India illustration documented"_, decision: **keep the figures and document why they are what they are**:

> Those figures are **load-bearing and must not be "corrected"**: the same documents' native-currency view reports 50 INR employees with ₹5,000,000 gross and ₹4,000,000 net — exactly 50 × (₹100,000 / ₹80,000). Replacing the per-employee deduction figure with the rule-derived ₹18,900 would make the aggregate inconsistent. The illustration is therefore a round-number one, and both archived docs now say so.

In the retired v0.4 design, §11 ("Resolved in v0.4 — known issues") cited this file, and its reporting example depended on the same aggregate figures.

Everything below is reproduced from `ARCHITECTURE-v0.1.md` and `ARCHITECTURE-v0.2.md`, both now superseded.

---

## 1. The India deduction plan (context)

v0.1 stated it as text; v0.2 restated it as a table. They describe the same plan.

**v0.1 form:**

```text
India Deduction Plan

Employee Tax
→ 10% of Gross

Provident Fund
→ 12% of Base Salary

Insurance
→ Fixed ₹500
```

**v0.2 form — §2.7, India Deduction Plan:**

| Deduction      | Type             | Rate / Amount |
| -------------- | ---------------- | ------------- |
| Employee Tax   | % of Gross       | 10%           |
| Provident Fund | % of Base Salary | 12%           |
| Insurance      | Fixed            | ₹500          |

Applied to a ₹100,000 gross on a ₹70,000 base, this plan yields **₹18,900** deductions and **₹81,100** net — the arithmetic used by the canonical worked example. It is _not_ what the illustration below shows.

## 2. Local calculation (v0.1, verbatim)

> Each employee is calculated in their payroll currency.

```text
India employee
Currency: INR

Gross:
₹100,000

Deductions:
₹20,000

Net:
₹80,000

Germany employee
Currency: EUR

Gross:
€5,000

Deductions:
€1,000

Net:
€4,000
```

> **Illustrative figures.** These deduction totals are round numbers chosen so the aggregated reporting example further down stays round — 50 INR employees × ₹100,000 / ₹80,000 gives exactly the ₹5,000,000 gross and ₹4,000,000 net shown there. They are therefore _not_ the arithmetic result of the India deduction plan above, which for a ₹100,000 gross on a ₹70,000 base yields ₹18,900 deductions and ₹81,100 net. Treat this block as an illustration of _local_ calculation, not as worked arithmetic.

v0.2 restated the identical figures in table form (₹100,000 / ₹20,000 / **₹80,000** for India; €5,000 / €1,000 / **€4,000** for Germany) and carried the same illustrative-figures note.

## 3. The aggregate reporting example (v0.1, verbatim)

### 3.1 Native currency view — the source of the 50 × figures

```text
Payroll Summary

INR
----------------
Employees: 50
Gross: ₹5,000,000
Net: ₹4,000,000


EUR
----------------
Employees: 30
Gross: €150,000
Net: €120,000


USD
----------------
Employees: 20
Gross: $100,000
Net: $80,000
```

> No FX needed.

This is the block that makes ₹20,000 load-bearing: 50 employees × ₹80,000 net = ₹4,000,000 exactly.

### 3.2 Normalized reporting view

```text
Reporting Currency:
USD

System converts:

INR  ──▶ USD
EUR  ──▶ USD
```

Result:

```text
Payroll Summary (USD)

India:
$46,000

Germany:
$129,600

USA:
$80,000

----------------
Total:
$255,600
```

> Conversion is applied to **net** pay, so the figures reconcile: ₹4,000,000 × 0.0115 + €120,000 × 1.08 + $80,000 = **$255,600**.

v0.2 restated the same normalized view ($46,000 / $129,600 / $80,000 → **$255,600**) with the same net-based reconciliation line.

---

## Invariants to preserve

Treat these as fixed. Changing any one of them breaks the aggregate:

- **Per India employee:** ₹100,000 gross, ₹20,000 deductions, **₹80,000 net** — round-number illustration, _not_ rule-derived.
- **50 INR employees:** ₹5,000,000 gross, **₹4,000,000 net** = 50 × ₹80,000.
- **Per Germany employee:** €5,000 gross, €1,000 deductions, €4,000 net; **30 employees** → €150,000 gross, €120,000 net.
- **Per USA employee:** $100,000 gross, $80,000 net; **20 employees** → $100,000 gross, $80,000 net.
- **Normalized total (net-based, USD):** ₹4,000,000 × 0.0115 + €120,000 × 1.08 + $80,000 = **$255,600**.
- **The rule-derived figures (₹18,900 / ₹81,100) are the correct arithmetic** and belong to the worked example in canonical §6.5 — keep the two sets of numbers visibly distinct rather than reconciling them.

---

**See also:** [`ARCHITECTURE-HISTORY.md`](./ARCHITECTURE-HISTORY.md) · [`../ARCHITECTURE.md`](../ARCHITECTURE.md) · [`../RESOLUTION-LOG.md`](../RESOLUTION-LOG.md)
