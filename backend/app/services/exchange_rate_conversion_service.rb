# Converts a decimal amount with the current month's stored exchange rate.
# It does not fetch rates: the snapshot importer owns all provider access.
class ExchangeRateConversionService
  def initialize(amount:, from_currency:, to_currency:, date: Date.current)
    @amount = BigDecimal(amount.to_s)
    @from_currency = from_currency.to_s.upcase
    @to_currency = to_currency.to_s.upcase
    @date = date.to_date
  end

  def call
    result = {
      amount: @amount,
      from_currency: @from_currency,
      to_currency: @to_currency,
      converted_amount: nil,
      rate: nil,
      rate_date: nil,
      available_target_currencies: available_target_currencies
    }

    return result.merge(converted_amount: @amount, rate: BigDecimal("1")) if @from_currency == @to_currency

    snapshot = snapshot_scope.find_by(quote_currency: @to_currency)
    return result unless snapshot

    result.merge(
      converted_amount: @amount * snapshot.rate,
      rate: snapshot.rate,
      rate_date: snapshot.rate_date
    )
  end

  private

  def snapshot_scope
    ExchangeRateSnapshot.for_period(@date).where(base_currency: @from_currency)
  end

  def available_target_currencies
    (snapshot_scope.distinct.pluck(:quote_currency) + [ @from_currency ]).uniq.sort
  end
end
