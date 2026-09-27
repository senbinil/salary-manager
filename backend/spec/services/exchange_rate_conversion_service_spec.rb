require "rails_helper"

RSpec.describe ExchangeRateConversionService do
  it "converts an amount using this month's stored pair rate" do
    rate_date = Date.current.beginning_of_month + 1.day
    create(
      :exchange_rate_snapshot,
      base_currency: "USD",
      quote_currency: "INR",
      rate: BigDecimal("83.250000000000"),
      rate_date: rate_date
    )
    create(
      :exchange_rate_snapshot,
      base_currency: "USD",
      quote_currency: "EUR",
      rate: BigDecimal("0.910000000000"),
      rate_date: rate_date
    )

    result = described_class.new(
      amount: BigDecimal("100.1250"),
      from_currency: "USD",
      to_currency: "INR"
    ).call

    expect(result).to include(
      amount: BigDecimal("100.1250"),
      from_currency: "USD",
      to_currency: "INR",
      converted_amount: BigDecimal("8335.406250000000"),
      rate: BigDecimal("83.250000000000"),
      rate_date: rate_date,
      available_target_currencies: %w[EUR INR USD]
    )
  end

  it "returns the amount unchanged when source and target currencies match" do
    result = described_class.new(
      amount: BigDecimal("100.1250"),
      from_currency: "USD",
      to_currency: "USD"
    ).call

    expect(result).to include(
      converted_amount: BigDecimal("100.1250"),
      rate: BigDecimal("1"),
      rate_date: nil,
      available_target_currencies: [ "USD" ]
    )
  end

  it "returns no converted amount when this month's pair rate is missing" do
    result = described_class.new(
      amount: BigDecimal("100.1250"),
      from_currency: "USD",
      to_currency: "INR"
    ).call

    expect(result).to include(
      converted_amount: nil,
      rate: nil,
      rate_date: nil,
      available_target_currencies: [ "USD" ]
    )
  end

  it "does not use a pair rate from the previous month" do
    create(
      :exchange_rate_snapshot,
      period_month: Date.current.last_month.beginning_of_month,
      base_currency: "USD",
      quote_currency: "INR",
      rate_date: Date.current.last_month.end_of_month
    )

    result = described_class.new(
      amount: BigDecimal("100.1250"),
      from_currency: "USD",
      to_currency: "INR"
    ).call

    expect(result).to include(
      converted_amount: nil,
      rate: nil,
      rate_date: nil,
      available_target_currencies: [ "USD" ]
    )
  end
end
