# An employment record: who is paid, and where they sit in the organization.
# Deliberately not the account - a user is not necessarily an employee, and most
# employees never sign in - so the link to an account is optional, and the two
# have separate lifecycles (closing a login is not terminating employment).
class Employee < ApplicationRecord
  belongs_to :user, class_name: "Account", optional: true
  belongs_to :department
  belongs_to :designation
  has_many :employment_contracts
  has_many :active_employment_contracts, -> { active }, class_name: "EmploymentContract"

  # Sums all component amounts on the current contract, in that contract's currency.
  def total_compensation
    contract = active_employment_contracts.order(start_date: :desc).first
    contract&.employee_compensation&.employee_compensation_components&.sum(:amount)
  end

  validates :name, presence: true
  validates :user, uniqueness: true, allow_nil: true
end
