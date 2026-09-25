# Lookup data: the organization's designations (job titles), referenced by
# Employee.designation_id. A relation rather than free text, so reports can group
# and filter by name without typos or duplicates.
class Designation < ApplicationRecord
  validates :name, presence: true, uniqueness: true
end
