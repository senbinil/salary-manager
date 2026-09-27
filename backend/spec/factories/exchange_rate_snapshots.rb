FactoryBot.define do
  factory :exchange_rate_snapshot do
    period_month { Date.current.beginning_of_month }
    base_currency { "USD" }
    quote_currency { "INR" }
    rate { BigDecimal("83.250000000000") }
    rate_date { Date.current.beginning_of_month }
    source { "Frankfurter" }
    provider_attribution { ["ECB"] }
  end
end
