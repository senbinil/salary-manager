# A named bundle of amounts. The plan itself carries only a name - its content is
# the CompensationPlanComponents that assign amounts to salary components, so a
# plan read without them says nothing about what it pays.
class CompensationPlan < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
