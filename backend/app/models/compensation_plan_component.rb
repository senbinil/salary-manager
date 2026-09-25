# The amount a plan pays for one salary component. The word lives on
# SalaryComponent and the amount lives here, so the same component carries a
# different amount on every plan. Amounts are monthly system-wide (principle 6),
# so there is no frequency column, and no currency: the contract's currency
# decides that (§3).
class CompensationPlanComponent < ApplicationRecord
  belongs_to :compensation_plan
  belongs_to :salary_component

  # Zero is allowed - it says "this plan pays nothing for that word" - but a
  # negative amount would silently subtract from a total.
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # D0.5. The database holds the same rule under a unique index; this one is here
  # to report the clash as a validation error instead of an exception.
  validates :salary_component_id, uniqueness: { scope: :compensation_plan_id }
end
