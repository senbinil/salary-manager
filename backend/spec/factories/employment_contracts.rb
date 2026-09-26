FactoryBot.define do
  factory :employment_contract do
    employee
    country
    compensation_plan
    start_date { Date.new(2026, 1, 1) }
    # currency is deliberately not set here: the model copies it from the country
    # (§3), so every example runs on that rule unless it overrides the currency.
    after(:build) do |contract|
      unless contract.employee_compensation
        contract.employee_compensation = build(:employee_compensation, employment_contract: contract)
      end
    end
  end
end
