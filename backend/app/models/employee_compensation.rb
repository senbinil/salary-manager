# Employee-specific compensation values attached to one historical contract.
# The plan classifies this record for filtering; it does not supply the amounts.
class EmployeeCompensation < ApplicationRecord
  belongs_to :employment_contract, inverse_of: :employee_compensation
  belongs_to :compensation_plan, inverse_of: :employee_compensations
  has_many :employee_compensation_components, inverse_of: :employee_compensation

  validates :employment_contract_id, uniqueness: true
  validates :employee_compensation_components, length: { minimum: 1 }
end
