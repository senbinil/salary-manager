# An employment record: who is paid, and where they sit in the organization.
# Deliberately not the account - a user is not necessarily an employee, and most
# employees never sign in - so the link to an account is optional, and the two
# have separate lifecycles (closing a login is not terminating employment).
class Employee < ApplicationRecord
  belongs_to :user, class_name: "Account", optional: true
  belongs_to :department
  belongs_to :designation

  validates :name, presence: true
  validates :user, uniqueness: true, allow_nil: true
end
