# Salary Component Relationships Explained

This guide accompanies the current [architecture](./ARCHITECTURE.md) and [ADR-0001](./decisions/ADR-0001-employee-specific-compensation.md).

## The three roles

Each model answers a different question:

| Model | Responsibility |
| --- | --- |
| CompensationPlan | Which reusable tag groups this employee compensation for filtering? |
| SalaryComponent | What is this component called, and what category is it? |
| EmployeeCompensationComponent | How much is this component worth for this specific contract? |

A CompensationPlan does not contain amounts. SalaryComponent is shared vocabulary and does not contain amounts. EmployeeCompensationComponent is the employee-specific assignment that owns the amount.

## Relationship path

Employee → EmploymentContract → EmployeeCompensation → EmployeeCompensationComponent → SalaryComponent

EmployeeCompensation also belongs to a CompensationPlan tag.

- An employee can have multiple contracts over time.
- Each contract has one employee compensation record.
- Each employee compensation has one plan tag and one or more amount-bearing component rows.
- A salary component may be reused by many employee compensation records; each record has its own amount.
- Component amounts use the currency on their employment contract.

## Example

Alex and Bea can both use the “Engineering” compensation plan tag while having different contract amounts:

| Employee | Plan tag | Salary component | Contract currency | Employee-specific amount |
| --- | --- | --- | --- | ---: |
| Alex | Engineering | Base Salary | USD | 100,000 |
| Bea | Engineering | Base Salary | USD | 125,000 |

The plan groups the records for filtering; it does not force the amounts to match. Changing Alex’s amount does not change Bea’s amount. Changing the plan tag changes classification only.

## Categories and display

Employee-specific rows support every existing SalaryComponent category: earning, allowance, and contribution. Contract detail returns the component breakdown with each component’s amount, name, and category. If a combined compensation total is displayed, earning and allowance count toward it; contribution remains a separate line.

## Why this split

Putting an amount on CompensationPlan would make every employee using that plan share one value. Creating one plan per employee would duplicate tags and make plans less useful for filtering. Putting an amount on SalaryComponent would make shared vocabulary hold employee-specific data. Keeping the definition, tag, and employee amount separate avoids those problems.
