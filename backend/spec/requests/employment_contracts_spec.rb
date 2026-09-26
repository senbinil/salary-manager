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

  def assign_compensation(contract, plan:, lines:)
    compensation = contract.employee_compensation
    compensation.update!(compensation_plan: plan)

    first_line = compensation.employee_compensation_components.first
    first_line.update!(
      salary_component: lines.first.fetch(:salary_component),
      amount: lines.first.fetch(:amount)
    )

    lines.drop(1).each do |line|
      create(
        :employee_compensation_component,
        employee_compensation: compensation,
        salary_component: line.fetch(:salary_component),
        amount: line.fetch(:amount)
      )
    end
  end

  def contract_payload(contract)
    compensation = contract.employee_compensation
    components = compensation.employee_compensation_components
      .includes(:salary_component)
      .sort_by { |line| line.salary_component.name }

    {
      "id" => contract.id,
      "employee_id" => contract.employee_id,
      "country_code" => contract.country_code,
      "currency" => contract.currency,
      "compensation_plan_id" => compensation.compensation_plan_id,
      "start_date" => contract.start_date.as_json,
      "end_date" => contract.end_date&.as_json,
      "employee_compensation" => {
        "id" => compensation.id,
        "compensation_plan" => {
          "id" => compensation.compensation_plan_id,
          "name" => compensation.compensation_plan.name
        },
        "components" => components.map do |line|
          {
            "amount" => line.amount.as_json,
            "salary_component" => {
              "id" => line.salary_component_id,
              "name" => line.salary_component.name,
              "category" => line.salary_component.category
            }
          }
        end
      }
    }
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
      let!(:plan) { create(:compensation_plan, name: "Engineering") }
      let!(:base_salary) { create(:salary_component, name: "Base Salary", category: :earning) }
      let!(:housing) { create(:salary_component, name: "Housing Allowance", category: :allowance) }
      let!(:contribution) { create(:salary_component, name: "Employer Contribution", category: :contribution) }
      let!(:later_contract) do
        create(
          :employment_contract,
          employee: employee,
          country: country,
          currency: "USD",
          start_date: Date.new(2027, 1, 1)
        )
      end
      let!(:earlier_contract) do
        create(
          :employment_contract,
          employee: employee,
          country: country,
          start_date: Date.new(2026, 1, 1),
          end_date: Date.new(2026, 12, 31)
        )
      end
      let!(:other_employee_contract) do
        create(
          :employment_contract,
          start_date: Date.new(2025, 1, 1),
          end_date: Date.new(2025, 12, 31)
        )
      end

      before do
        assign_compensation(
          earlier_contract,
          plan: plan,
          lines: [
            { salary_component: base_salary, amount: BigDecimal("70000.2500") },
            { salary_component: housing, amount: BigDecimal("20000.5000") },
            { salary_component: contribution, amount: BigDecimal("5000.2500") }
          ]
        )
        assign_compensation(
          later_contract,
          plan: plan,
          lines: [ { salary_component: base_salary, amount: BigDecimal("85000.7500") } ]
        )
        # The same plan and component can have a different amount for another employee.
        assign_compensation(
          other_employee_contract,
          plan: plan,
          lines: [ { salary_component: base_salary, amount: BigDecimal("100000.0000") } ]
        )
        sign_in
      end

      it "returns each employee's contracts with that contract's compensation" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(response).to have_http_status(:ok)
        expect(json_body).to eq([ contract_payload(earlier_contract), contract_payload(later_contract) ])
      end

      it "orders the employee's contract history by start date" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        expect(json_body.map { |contract| contract["id"] }).to eq([ earlier_contract.id, later_contract.id ])
      end

      it "includes every existing salary component category in the employee breakdown" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        components = json_body.first.dig("employee_compensation", "components")
        expect(components.map { |line| line.dig("salary_component", "category") })
          .to contain_exactly("earning", "allowance", "contribution")
      end

      it "preserves contract fields and adds the employee compensation object" do
        get "/api/v1/employees/#{employee.id}/employment_contracts"

        contract = json_body.first
        expect(contract.keys).to contain_exactly(
          "id", "employee_id", "country_code", "currency", "compensation_plan_id",
          "start_date", "end_date", "employee_compensation"
        )
        expect(contract.fetch("employee_compensation").keys)
          .to contain_exactly("id", "compensation_plan", "components")
        expect(contract.dig("employee_compensation", "compensation_plan").keys)
          .to contain_exactly("id", "name")
        expect(contract.dig("employee_compensation", "components").first.keys)
          .to contain_exactly("amount", "salary_component")
        expect(contract.dig("employee_compensation", "components").first.fetch("salary_component").keys)
          .to contain_exactly("id", "name", "category")
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
      let!(:salary_component) do
        create(:salary_component, name: "Contract Base Salary", category: :earning)
      end

      before do
        assign_compensation(
          contract,
          plan: contract.employee_compensation.compensation_plan,
          lines: [ { salary_component: salary_component, amount: BigDecimal("1250.7500") } ]
        )
        sign_in
      end

      it "returns the selected contract with employee-specific compensation" do
        get "/api/v1/employees/#{contract.employee_id}/employment_contracts/#{contract.id}"

        expect(response).to have_http_status(:ok)
        expect(json_body).to eq(contract_payload(contract))
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
