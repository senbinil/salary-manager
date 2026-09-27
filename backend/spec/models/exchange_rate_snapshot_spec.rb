require "rails_helper"

RSpec.describe ExchangeRateSnapshot do
  it "requires a period, currency pair, positive rate, date, and source" do
    snapshot = build(
      :exchange_rate_snapshot,
      period_month: nil,
      base_currency: nil,
      quote_currency: nil,
      rate: nil,
      rate_date: nil,
      source: nil
    )

    expect(snapshot).not_to be_valid
    expect(snapshot.errors.attribute_names).to include(
      :period_month, :base_currency, :quote_currency, :rate, :rate_date, :source
    )
  end

  it "rejects non-positive rates and rate dates outside the snapshot month" do
    snapshot = build(
      :exchange_rate_snapshot,
      rate: 0,
      rate_date: Date.current.beginning_of_month - 1.day
    )

    expect(snapshot).not_to be_valid
    expect(snapshot.errors[:rate]).to be_present
    expect(snapshot.errors[:rate_date]).to be_present
  end

  it "allows only one snapshot for a currency pair in a month" do
    existing = create(:exchange_rate_snapshot)
    duplicate = build(
      :exchange_rate_snapshot,
      period_month: existing.period_month,
      base_currency: existing.base_currency,
      quote_currency: existing.quote_currency
    )

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:quote_currency]).to be_present
  end
end
