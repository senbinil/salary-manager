FactoryBot.define do
  factory :employee do
    sequence(:name) { |n| "Employee #{n}" }
    department
    designation
  end
end
