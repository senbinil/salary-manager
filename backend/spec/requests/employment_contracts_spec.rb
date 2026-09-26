require "rails_helper"

RSpec.describe "Employment contracts", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  def sign_in
    create(:account, :verified, email: email, password: password)
    post "/api/v1/login", params: { email: email, password: password }, as: :json
  end

  describe "GET /api/v1/employees/:employee_id/employment_contracts" do
    let!(:employee) { create(:employee) }

    it "requires a signed-in account" do
      get "/api/v1/employees/#{employee.id}/employment_contracts"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "when signed in" do
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

      before { sign_in }

      it "returns this employee's contracts with the public fields" do
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
          }
        )
      end

      it "orders the employee's contracts by start date" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(json_body.map { |contract| contract["id"] }).to eq([ earlier_contract.id, later_contract.id ])
      end

      it "returns only the documented contract fields" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(json_body.first.keys).to contain_exactly(
          "id", "employee_id", "country_code", "currency", "compensation_plan_id", "start_date", "end_date"
        )
      end

      it "answers 404 when the employee does not exist" do
        get "/api/v1/employees/0/employment_contracts"

        expect(response).to have_http_status(:not_found)
        expect(json_body["error"]).to be_present
      end
    end
  end

  describe "GET /api/v1/employees/:employee_id/employment_contracts/:id" do
    let!(:contract) { create(:employment_contract) }

    it "requires a signed-in account" do
      get "/api/v1/employees/#{contract.employee_id}/employment_contracts/#{contract.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "when signed in" do
      before { sign_in }

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

      it "answers 404 when the employee does not exist" do
        get "/api/v1/employees/0/employment_contracts/#{contract.id}"

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
