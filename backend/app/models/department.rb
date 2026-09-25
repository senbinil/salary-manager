# Lookup data: the organization's departments, referenced by Employee.department_id.
# A relation rather than free text, so reports can group and filter by name.
class Department < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
