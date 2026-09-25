FactoryBot.define do
  factory :designation do
    sequence(:name) { |n| "Designation #{n}" }
  end
end
