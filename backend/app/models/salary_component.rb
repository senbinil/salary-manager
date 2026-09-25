# Shared vocabulary: the words a compensation plan can attach an amount to. Only
# the definition lives here - no amount - so the same component can carry a
# different amount on every plan (see CompensationPlanComponent).
class SalaryComponent < ApplicationRecord
  # earning and allowance count toward reported compensation; contribution does
  # not (§6.2). The integers are persisted, so they must stay stable.
  enum :category, { earning: 0, allowance: 1, contribution: 2 }

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
end
