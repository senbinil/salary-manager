FactoryBot.define do
  factory :compensation_plan do
    sequence(:name) { |n| "Plan #{n}" }
  end
end
