# Imports the earliest available rate for each active contract currency pair in
# the current month. Fetches are completed before writing so a provider failure
# cannot leave only some base currencies stored for the month.
class FetchExchangeRateSnapshotsJob < ApplicationJob
  def perform(date = Date.current)
    as_of = date.to_date
    period_month = as_of.beginning_of_month
    client = FrankfurterClient.new

    rate_rows = active_base_currencies(as_of).flat_map do |base_currency|
      client.fetch_rates(base: base_currency, from: period_month, to: as_of).filter_map do |row|
        snapshot_attributes(row, base_currency:, period_month:, as_of:)
      end
    end

    snapshots = first_monthly_rates(rate_rows).map do |attributes|
      attributes.merge(period_month: period_month)
    end

    ExchangeRateSnapshot.transaction do
      ExchangeRateSnapshot.insert_all(
        snapshots,
        unique_by: :idx_exchange_rate_snapshots_period_pair,
        record_timestamps: true
      ) if snapshots.any?
    end
  end

  private

  def active_base_currencies(date)
    EmploymentContract.active(date).distinct.order(:currency).pluck(:currency).map(&:upcase)
  end

  def snapshot_attributes(row, base_currency:, period_month:, as_of:)
    return unless row["base"].to_s.upcase == base_currency

    quote_currency = row["quote"].to_s.upcase
    return unless quote_currency.match?(/\A[A-Z]{3}\z/) && quote_currency != base_currency

    rate_date = Date.iso8601(row["date"].to_s)
    return unless rate_date.between?(period_month, as_of)

    rate = BigDecimal(row["rate"].to_s)
    return unless rate.finite? && rate.positive?

    {
      base_currency: base_currency,
      quote_currency: quote_currency,
      rate: rate,
      rate_date: rate_date,
      source: "Frankfurter",
      provider_attribution: Array(row["providers"]).map(&:to_s).uniq
    }
  rescue ArgumentError, TypeError
    nil
  end

  def first_monthly_rates(rate_rows)
    rate_rows
      .group_by { |attributes| [ attributes[:base_currency], attributes[:quote_currency] ] }
      .values
      .map { |pair_rates| pair_rates.min_by { |attributes| attributes[:rate_date] } }
  end
end
