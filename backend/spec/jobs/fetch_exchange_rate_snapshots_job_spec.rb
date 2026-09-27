require "rails_helper"

RSpec.describe FetchExchangeRateSnapshotsJob do
  let(:client) { instance_double(FrankfurterClient) }
  let(:period_month) { Date.current.beginning_of_month }

  before do
    allow(FrankfurterClient).to receive(:new).and_return(client)
  end

  it "stores the first available in-month rate for each quote currency" do
    contract = create(:employment_contract, currency: "USD", start_date: Date.current - 1.day)
    allow(client).to receive(:fetch_rates).with(
      base: "USD", from: period_month, to: Date.current
    ).and_return([
      { "date" => (period_month + 2.days).iso8601, "base" => "USD", "quote" => "INR", "rate" => "83.5", "providers" => [ "ECB" ] },
      { "date" => (period_month + 1.day).iso8601, "base" => "USD", "quote" => "INR", "rate" => "83.25", "providers" => [ "ECB" ] },
      { "date" => (period_month + 1.day).iso8601, "base" => "USD", "quote" => "EUR", "rate" => "0.91", "providers" => [ "BUNDESBANK" ] },
      { "date" => (period_month - 1.day).iso8601, "base" => "USD", "quote" => "GBP", "rate" => "0.8", "providers" => [ "ECB" ] }
    ])

    described_class.perform_now

    expect(ExchangeRateSnapshot.pluck(:base_currency, :quote_currency, :rate, :rate_date)).to contain_exactly(
      [ "USD", "INR", BigDecimal("83.25"), period_month + 1.day ],
      [ "USD", "EUR", BigDecimal("0.91"), period_month + 1.day ]
    )
    expect(contract).to be_persisted
  end

  it "fetches once per distinct currency used by active contracts" do
    create(:employment_contract, currency: "USD", start_date: Date.current - 1.day)
    create(:employment_contract, currency: "USD", start_date: Date.current - 1.day)
    create(:employment_contract, currency: "CAD", start_date: Date.current + 1.day)
    create(
      :employment_contract,
      currency: "EUR",
      start_date: Date.current - 2.days,
      end_date: Date.current - 1.day
    )
    allow(client).to receive(:fetch_rates).with(
      base: "USD", from: period_month, to: Date.current
    ).and_return([])

    described_class.perform_now

    expect(client).to have_received(:fetch_rates).with(
      base: "USD", from: period_month, to: Date.current
    ).once
    expect(client).not_to have_received(:fetch_rates).with(
      base: "CAD", from: period_month, to: Date.current
    )
    expect(client).not_to have_received(:fetch_rates).with(
      base: "EUR", from: period_month, to: Date.current
    )
  end

  it "does not overwrite a pair already captured for the month" do
    create(:employment_contract, currency: "USD", start_date: Date.current - 1.day)
    existing = create(:exchange_rate_snapshot, rate: BigDecimal("82.0"))
    allow(client).to receive(:fetch_rates).and_return([
      { "date" => period_month.iso8601, "base" => "USD", "quote" => "INR", "rate" => "83.25", "providers" => [ "ECB" ] }
    ])

    described_class.perform_now

    expect(existing.reload.rate).to eq(BigDecimal("82.0"))
    expect(ExchangeRateSnapshot.count).to eq(1)
  end

  it "does not persist partial rates if fetching one active contract currency fails" do
    create(:employment_contract, currency: "USD", start_date: Date.current - 1.day)
    create(:employment_contract, currency: "CAD", start_date: Date.current - 1.day)
    allow(client).to receive(:fetch_rates).with(base: "USD", from: period_month, to: Date.current).and_return([
      { "date" => period_month.iso8601, "base" => "USD", "quote" => "INR", "rate" => "83.25", "providers" => [ "ECB" ] }
    ])
    allow(client).to receive(:fetch_rates).with(base: "CAD", from: period_month, to: Date.current)
      .and_raise(FrankfurterClient::Error, "provider unavailable")

    expect { described_class.perform_now }.to raise_error(FrankfurterClient::Error)
    expect(ExchangeRateSnapshot.count).to eq(0)
  end
end
