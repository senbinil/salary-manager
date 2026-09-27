require "rails_helper"

RSpec.describe "Exchange rate conversions", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "POST /api/v1/exchange_rates/convert" do
    let(:params) do
      { amount: "100.1250", from_currency: "USD", to_currency: "INR" }
    end

    it "rejects a request with no session" do
      post "/api/v1/exchange_rates/convert", params: params, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns a decimal conversion, rate date, and available targets" do
        rate_date = Date.current.beginning_of_month + 1.day
        create(
          :exchange_rate_snapshot,
          base_currency: "USD",
          quote_currency: "INR",
          rate: BigDecimal("83.25"),
          rate_date: rate_date
        )
        create(
          :exchange_rate_snapshot,
          base_currency: "USD",
          quote_currency: "EUR",
          rate: BigDecimal("0.91"),
          rate_date: rate_date
        )

        post "/api/v1/exchange_rates/convert", params: params, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_body).to include(
          "amount" => BigDecimal("100.1250").as_json,
          "from_currency" => "USD",
          "to_currency" => "INR",
          "converted_amount" => BigDecimal("8335.40625").as_json,
          "rate" => BigDecimal("83.25").as_json,
          "rate_date" => rate_date.as_json,
          "available_target_currencies" => %w[EUR INR USD]
        )
      end

      it "returns an unavailable conversion while preserving the requested pair" do
        post "/api/v1/exchange_rates/convert", params: params, as: :json

        expect(response).to have_http_status(:ok)
        expect(json_body).to include(
          "converted_amount" => nil,
          "rate" => nil,
          "rate_date" => nil,
          "available_target_currencies" => [ "USD" ]
        )
      end

      it "rejects invalid amounts and currency codes" do
        post "/api/v1/exchange_rates/convert",
          params: { amount: "NaN", from_currency: "USD", to_currency: "INR" },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)

        post "/api/v1/exchange_rates/convert",
          params: { amount: "100", from_currency: "US", to_currency: "INR" },
          as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
