FactoryBot.define do
  factory :salary_component do
    sequence(:name) { |n| "Component #{n}" }
    category { :earning }
  end
end
