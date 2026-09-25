FactoryBot.define do
  factory :employment_contract do
    employee
    country
    compensation_plan
    start_date { Date.new(2026, 1, 1) }
    # currency is deliberately not set here: the model copies it from the country
    # (§3), so every example runs on that rule unless it overrides the currency.
  end
end
