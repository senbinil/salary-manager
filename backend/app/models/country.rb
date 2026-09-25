# Seeded ISO 3166-1 reference data. The two-letter code is the natural key, so
# the table carries no surrogate id column.
class Country < ApplicationRecord
  self.primary_key = "code"

  validates :name, presence: true, uniqueness: true
  validates :currency, presence: true
end
