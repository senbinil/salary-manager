# Shared vocabulary for compensation component names and categories. Employee-
# specific amounts live on EmployeeCompensationComponent.
class SalaryComponent < ApplicationRecord
  # The persisted integer values must stay stable.
  enum :category, { earning: 0, allowance: 1, contribution: 2 }

  has_many :employee_compensation_components, inverse_of: :salary_component

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
end
