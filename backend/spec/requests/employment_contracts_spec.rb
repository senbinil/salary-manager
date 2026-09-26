require "rails_helper"

RSpec.describe "Employment contracts", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/employees/:employee_id/employment_contracts" do
    let!(:employee) { create(:employee) }

    it "rejects a request with no session" do
      get "/api/v1/employees/#{employee.id}/employment_contracts"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      let!(:country) { create(:country, code: "IN", name: "India", currency: "INR") }
      let!(:plan) { create(:compensation_plan, name: "Standard") }
      let!(:later_contract) do
        create(
          :employment_contract,
          employee: employee,
          country: country,
          compensation_plan: plan,
          currency: "USD",
          start_date: Date.new(2027, 1, 1)
        )
      end
      let!(:earlier_contract) do
        create(
          :employment_contract,
          employee: employee,
          country: country,
          compensation_plan: plan,
          start_date: Date.new(2026, 1, 1),
          end_date: Date.new(2026, 12, 31)
        )
      end
      let!(:other_employee_contract) do
        create(:employment_contract, start_date: Date.new(2025, 1, 1))
      end

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns each contract with its public fields" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          {
            "id" => earlier_contract.id,
            "employee_id" => employee.id,
            "country_code" => "IN",
            "currency" => "INR",
            "compensation_plan_id" => plan.id,
            "start_date" => "2026-01-01",
            "end_date" => "2026-12-31"
          },
          {
            "id" => later_contract.id,
            "employee_id" => employee.id,
            "country_code" => "IN",
            "currency" => "USD",
            "compensation_plan_id" => plan.id,
            "start_date" => "2027-01-01",
            "end_date" => nil
          },
        )
      end

      it "orders this employee's contracts by start date" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(json_body.map { |contract| contract["id"] }).to eq([ earlier_contract.id, later_contract.id ])
      end

      it "exposes only the contract fields clients need" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(json_body.first.keys).to contain_exactly(
          "id", "employee_id", "country_code", "currency", "compensation_plan_id", "start_date", "end_date"
        )
      end
    end
  end

  describe "GET /api/v1/employees/:employee_id/employment_contracts/:id" do
    let!(:contract) { create(:employment_contract) }

    it "rejects a request with no session" do
      get "/api/v1/employees/#{contract.employee_id}/employment_contracts/#{contract.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns the contract identified by the id" do
        get "/api/v1/employees/#{contract.employee_id}/employment_contracts/#{contract.id}"

        expect(response).to have_http_status(:ok)
        expect(json_body).to eq(
          "id" => contract.id,
          "employee_id" => contract.employee_id,
          "country_code" => contract.country_code,
          "currency" => contract.currency,
          "compensation_plan_id" => contract.compensation_plan_id,
          "start_date" => "2026-01-01",
          "end_date" => nil
        )
      end

      it "answers 404 for a contract that does not exist" do
        get "/api/v1/employees/#{contract.employee_id}/employment_contracts/0"

        expect(response).to have_http_status(:not_found)
        expect(json_body["error"]).to be_present
      end

      it "answers 404 when the contract belongs to another employee" do
        other_contract = create(:employment_contract)

        get "/api/v1/employees/#{contract.employee_id}/employment_contracts/#{other_contract.id}"

        expect(response).to have_http_status(:not_found)
        expect(json_body["error"]).to be_present
      end
    end
  end
end
