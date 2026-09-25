require "rails_helper"

RSpec.describe "Countries", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/countries" do
    it "rejects a request with no session" do
      get "/api/v1/countries"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      # The endpoint returns the whole table, so the examples build the only rows
      # in it — through the factory, not from a seed.
      let!(:countries) do
        [
          create(:country, code: "US", name: "United States", currency: "USD"),
          create(:country, code: "IN", name: "India", currency: "INR")
        ]
      end

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns each country as code, name, and currency" do
        get "/api/v1/countries"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          { "code" => "US", "name" => "United States", "currency" => "USD" },
          { "code" => "IN", "name" => "India", "currency" => "INR" }
        )
      end

      it "orders countries by code" do
        get "/api/v1/countries"

        expect(json_body.map { |country| country["code"] }).to eq(%w[IN US])
      end

      it "exposes nothing beyond code, name, and currency" do
        get "/api/v1/countries"

        expect(json_body.first.keys).to contain_exactly("code", "name", "currency")
      end
    end
  end
end
