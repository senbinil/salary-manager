# The employee-specific amount assigned to one reusable salary component.
# Currency comes from the owning employment contract.
class EmployeeCompensationComponent < ApplicationRecord
  belongs_to :employee_compensation, inverse_of: :employee_compensation_components
  belongs_to :salary_component, inverse_of: :employee_compensation_components

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :salary_component_id, uniqueness: { scope: :employee_compensation_id }
end
