# One provider rate per currency pair and calendar month. A snapshot keeps the
# first available observation in that month so later scheduled imports cannot
# change a conversion already used by the application.
class ExchangeRateSnapshot < ApplicationRecord
  validates :period_month, :base_currency, :quote_currency, :rate, :rate_date, :source, presence: true
  validates :base_currency, :quote_currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :quote_currency, uniqueness: { scope: %i[period_month base_currency] }
  validates :rate, numericality: { greater_than: 0 }
  validate :period_month_is_first_of_month
  validate :rate_date_is_in_period
  validate :currencies_are_distinct

  scope :for_period, ->(date) { where(period_month: date.to_date.beginning_of_month) }
  scope :for_pair, ->(base_currency, quote_currency) {
    where(base_currency: base_currency, quote_currency: quote_currency)
  }

  private

  def period_month_is_first_of_month
    return if period_month.blank? || period_month == period_month.beginning_of_month

    errors.add(:period_month, "must be the first day of the month")
  end

  def rate_date_is_in_period
    return if period_month.blank? || rate_date.blank? || rate_date.between?(period_month, period_month.end_of_month)

    errors.add(:rate_date, "must fall within the snapshot month")
  end

  def currencies_are_distinct
    return if base_currency.blank? || quote_currency.blank? || base_currency != quote_currency

    errors.add(:quote_currency, "must differ from the base currency")
  end
end
