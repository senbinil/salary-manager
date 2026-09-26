FactoryBot.define do
  factory :employee_compensation do
    compensation_plan

    after(:build) do |compensation|
      if compensation.employee_compensation_components.empty?
        compensation.employee_compensation_components << build(
          :employee_compensation_component,
          employee_compensation: compensation
        )
      end
    end
  end
end
