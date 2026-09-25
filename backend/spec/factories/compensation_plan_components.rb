FactoryBot.define do
  factory :compensation_plan_component do
    compensation_plan
    salary_component
    amount { 5000 }
  end
end
