require "rails_helper"
require "net/http"

RSpec.describe FrankfurterClient do
  describe "#fetch_rates" do
    it "requests v2 monthly history with provider attribution and returns the parsed rows" do
      response = instance_double(
        Net::HTTPOK,
        code: "200",
        body: '[{"date":"2026-09-01","base":"USD","quote":"INR","rate":83.25,"providers":["ECB"]}]'
      )
      requested_uri = nil
      allow(Net::HTTP).to receive(:get_response) do |uri|
        requested_uri = uri
        response
      end

      rates = described_class.new.fetch_rates(
        base: "USD",
        from: Date.new(2026, 9, 1),
        to: Date.new(2026, 9, 30)
      )

      expect(requested_uri.host).to eq("api.frankfurter.dev")
      expect(requested_uri.path).to eq("/v2/rates")
      expect(URI.decode_www_form(requested_uri.query).to_h).to include(
        "base" => "USD",
        "from" => "2026-09-01",
        "to" => "2026-09-30",
        "expand" => "providers"
      )
      expect(rates).to eq(
        [{
          "date" => "2026-09-01",
          "base" => "USD",
          "quote" => "INR",
          "rate" => 83.25,
          "providers" => ["ECB"]
        }]
      )
    end

    it "raises a provider error for unsuccessful or malformed responses" do
      response = instance_double(Net::HTTPNotFound, code: "404", body: "missing")
      allow(Net::HTTP).to receive(:get_response).and_return(response)

      expect {
        described_class.new.fetch_rates(base: "USD", from: Date.current.beginning_of_month, to: Date.current)
      }.to raise_error(FrankfurterClient::Error)
    end
  end
end
