# A named, reusable tag for filtering employee compensation records. A plan
# classifies compensation but does not own its component amounts.
class CompensationPlan < ApplicationRecord
  has_many :employee_compensations, inverse_of: :compensation_plan

  validates :name, presence: true, uniqueness: true
end
