require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/dashboard/summary" do
    it "rejects a request with no session" do
      get "/api/v1/dashboard/summary"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns the active headcount and per-country totals" do
        canada = create(:country, code: "CA", name: "Canada", currency: "CAD")
        india = create(:country, code: "IN", name: "India", currency: "INR")
        create(:employment_contract, employee: create(:employee), country: canada, start_date: Date.current - 5.days)
        create(:employment_contract, employee: create(:employee), country: canada, start_date: Date.current - 5.days)
        create(:employment_contract, employee: create(:employee), country: india, start_date: Date.current - 5.days)
        create(
          :employment_contract,
          employee: create(:employee),
          country: india,
          start_date: Date.current - 20.days,
          end_date: Date.current - 1.day
        )

        get "/api/v1/dashboard/summary"

        expect(response).to have_http_status(:ok)
        expect(json_body).to eq(
          "total_active_employees" => 3,
          "country_totals" => [
            { "country_code" => "CA", "country_name" => "Canada", "currency" => "CAD",
              "employee_count" => 2, "total_compensation" => BigDecimal("10000.0000").as_json },
            { "country_code" => "IN", "country_name" => "India", "currency" => "INR",
              "employee_count" => 1, "total_compensation" => BigDecimal("5000.0000").as_json }
          ]
        )
      end

      it "exposes nothing beyond the overview fields" do
        create(:employment_contract, employee: create(:employee), start_date: Date.current - 5.days)

        get "/api/v1/dashboard/summary"

        expect(response).to have_http_status(:ok)
        expect(json_body.keys).to contain_exactly("total_active_employees", "country_totals")
        expect(json_body["country_totals"].first.keys).to contain_exactly(
          "country_code", "country_name", "currency", "employee_count", "total_compensation"
        )
      end

      it "reports no active employees when no contract is active today" do
        get "/api/v1/dashboard/summary"

        expect(response).to have_http_status(:ok)
        expect(json_body).to eq("total_active_employees" => 0, "country_totals" => [])
      end
    end
  end
end
