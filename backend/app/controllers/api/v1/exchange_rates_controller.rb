module Api
  module V1
    # Converts a decimal amount with a rate already stored for the current month.
    class ExchangeRatesController < ApplicationController
      before_action :authenticate!

      def convert
        amount = decimal_amount(params[:amount])
        from_currency = params[:from_currency]
        to_currency = params[:to_currency]

        unless amount && currency_code?(from_currency) && currency_code?(to_currency)
          return render json: { error: "Amount and currency codes are invalid" }, status: :unprocessable_entity
        end

        result = ExchangeRateConversionService.new(
          amount: amount,
          from_currency: from_currency,
          to_currency: to_currency
        ).call

        render json: result
      end

      private

      def decimal_amount(value)
        return unless value.is_a?(String) || value.is_a?(Numeric)

        amount = BigDecimal(value.to_s)
        amount if amount.finite? && amount >= 0
      rescue ArgumentError, TypeError
        nil
      end

      def currency_code?(value)
        value.is_a?(String) && value.match?(/\A[A-Za-z]{3}\z/)
      end
    end
  end
end
