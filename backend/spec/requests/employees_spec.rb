require "rails_helper"

RSpec.describe "Employees", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/employees" do
    it "rejects a request with no session" do
      get "/api/v1/employees"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      let!(:department) { create(:department) }
      let!(:designation) { create(:designation) }

      # Insert order and name order differ, so the ordering example means
      # something. Zoe is created first, so an unordered response would list Zoe
      # first.
      let!(:zoe) { create(:employee, name: "Zoe", department: department, designation: designation) }
      let!(:ada) { create(:employee, name: "Ada", department: department, designation: designation) }

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns the first page with employee and pagination data" do
        get "/api/v1/employees"

        expect(response).to have_http_status(:ok)
        expect(json_body["data"]).to contain_exactly(
          { "id" => ada.id, "name" => "Ada", "department_id" => department.id,
            "department_name" => department.name, "designation_id" => designation.id,
            "designation_name" => designation.name, "user_id" => nil,
            "employment_status" => "inactive", "country_name" => nil, "contract_start_date" => nil,
            "total_compensation" => nil, "total_compensation_currency" => nil },
          { "id" => zoe.id, "name" => "Zoe", "department_id" => department.id,
            "department_name" => department.name, "designation_id" => designation.id,
            "designation_name" => designation.name, "user_id" => nil,
            "employment_status" => "inactive", "country_name" => nil, "contract_start_date" => nil,
            "total_compensation" => nil, "total_compensation_currency" => nil }
        )
        expect(json_body["pagination"]).to include(
          "page" => 1,
          "limit" => 20,
          "count" => 2,
          "pages" => 1,
          "from" => 1,
          "to" => 2
        )
        expect(json_body["pagination"]).not_to have_key("previous")
        expect(json_body["pagination"]).not_to have_key("next")
      end

      it "returns the requested page and navigation metadata" do
        get "/api/v1/employees", params: { page: 2, limit: 1 }

        expect(response).to have_http_status(:ok)
        expect(json_body["data"].map { |employee| employee["name"] }).to eq(%w[Zoe])
        expect(json_body["pagination"]).to include(
          "page" => 2,
          "limit" => 1,
          "count" => 2,
          "pages" => 2,
          "from" => 2,
          "to" => 2,
          "previous" => 1
        )
        expect(json_body["pagination"]).not_to have_key("next")
      end

      it "caps a client-requested page size at 100" do
        get "/api/v1/employees", params: { limit: 101 }

        expect(response).to have_http_status(:ok)
        expect(json_body["pagination"]["limit"]).to eq(100)
      end

      it "returns an empty data page when the requested page is out of range" do
        get "/api/v1/employees", params: { page: 3, limit: 1 }

        expect(response).to have_http_status(:ok)
        expect(json_body["data"]).to eq([])
        expect(json_body["pagination"]).to include(
          "page" => 3,
          "count" => 2,
          "pages" => 2,
          "from" => 0,
          "to" => 0,
          "previous" => 2
        )
      end

      it "orders employees by name" do
        get "/api/v1/employees"

        expect(json_body["data"].map { |employee| employee["name"] }).to eq(%w[Ada Zoe])
      end

      # The link is optional, so nil is the common case — check the other one.
      it "reports the linked account when an employee has one" do
        account = create(:account, :verified)
        zoe.update!(user: account)

        get "/api/v1/employees"

        expect(json_body["data"].find { |employee| employee["id"] == zoe.id }["user_id"]).to eq(account.id)
      end

      it "includes display names and current employment status" do
        get "/api/v1/employees"

        expect(json_body["data"].first.keys).to contain_exactly(
          "id", "name", "department_id", "department_name", "designation_id", "designation_name",
          "user_id", "employment_status", "country_name", "contract_start_date",
          "total_compensation", "total_compensation_currency"
        )
      end

      it "reports contract details only while the employee has an active contract" do
        country = create(:country)
        active_contract = create(
          :employment_contract,
          employee: ada,
          country: country,
          start_date: Date.current - 10.days
        )
        create(
          :employment_contract,
          employee: zoe,
          start_date: Date.current - 30.days,
          end_date: Date.current - 1.day
        )

        get "/api/v1/employees"

        rows = json_body["data"].index_by { |employee| employee["id"] }
        expect(rows[ada.id]).to include(
          "employment_status" => "active",
          "country_name" => country.name,
          "contract_start_date" => active_contract.start_date.as_json,
          "total_compensation" => active_contract.total_compensation.as_json,
          "total_compensation_currency" => active_contract.currency
        )
        expect(rows[zoe.id]).to include(
          "employment_status" => "inactive",
          "country_name" => nil,
          "contract_start_date" => nil,
          "total_compensation" => nil,
          "total_compensation_currency" => nil
        )
      end

      it "returns the total and currency for an active contract in the employee list" do
        contract = create(
          :employment_contract,
          employee: ada,
          start_date: Date.current - 10.days,
          currency: "USD"
        )
        components = contract.employee_compensation.employee_compensation_components
        components.first.update!(amount: BigDecimal("10000.1250"))
        create(
          :employee_compensation_component,
          employee_compensation: contract.employee_compensation,
          salary_component: create(:salary_component, category: :allowance),
          amount: BigDecimal("250.2500")
        )

        get "/api/v1/employees"

        row = json_body["data"].find { |employee| employee["id"] == ada.id }
        expect(row).to include(
          "total_compensation" => BigDecimal("10250.3750").as_json,
          "total_compensation_currency" => "USD"
        )
      end

      describe "filtering" do
        let!(:research) { create(:department, name: "Research") }
        let!(:grace) do
          create(:employee, name: "Grace", department: research, designation: designation)
        end

        it "filters the page by the supported parameters" do
          get "/api/v1/employees", params: {
            filter: { name_cont: "gra", department_id: research.id, designation_id: designation.id }
          }

          expect(response).to have_http_status(:ok)
          expect(json_body["data"].map { |employee| employee["name"] }).to eq([ "Grace" ])
          expect(json_body["pagination"]["count"]).to eq(1)
        end

        it "filters by department id" do
          get "/api/v1/employees", params: { filter: { department_id: research.id } }

          expect(response).to have_http_status(:ok)
          expect(json_body["data"].map { |employee| employee["name"] }).to eq([ "Grace" ])
        end

        # The permitted set is an allow list, so a filter cannot reach past the
        # query object into pagination or the rest of the params.
        it "ignores filter keys outside the supported set" do
          get "/api/v1/employees", params: { filter: { limit: 1, unknown: "Research" } }

          expect(response).to have_http_status(:ok)
          expect(json_body["data"].map { |employee| employee["name"] }).to eq(%w[Ada Grace Zoe])
          expect(json_body["pagination"]["limit"]).to eq(20)
        end

        it "answers 400 when the filter is not an object" do
          get "/api/v1/employees", params: { filter: "name_cont" }

          expect(response).to have_http_status(:bad_request)
          expect(json_body["error"]).to eq("filter must be an object")
        end

        it "answers 400 with the message for an invalid filter value" do
          get "/api/v1/employees", params: { filter: { department_id: "engineering" } }

          expect(response).to have_http_status(:bad_request)
          expect(json_body["error"]).to eq("department_id must be an integer")
        end
      end
    end
  end

  describe "GET /api/v1/employees/:id" do
    let!(:employee) { create(:employee, name: "Ada") }

    it "rejects a request with no session" do
      get "/api/v1/employees/#{employee.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns the employee identified by the id" do
        get "/api/v1/employees/#{employee.id}"

        expect(response).to have_http_status(:ok)
        expect(json_body).to eq(
          "id" => employee.id,
          "name" => "Ada",
          "department_id" => employee.department_id,
          "department_name" => employee.department.name,
          "designation_id" => employee.designation_id,
          "designation_name" => employee.designation.name,
          "user_id" => nil,
          "employment_status" => "inactive",
          "country_name" => nil,
          "contract_start_date" => nil,
          "total_compensation" => nil
        )
      end

      it "includes the active contract's total compensation" do
        contract = create(
          :employment_contract,
          employee: employee,
          start_date: Date.current - 1.day,
          end_date: Date.current + 1.day
        )
        compensation = contract.employee_compensation
        compensation.employee_compensation_components.first.update!(amount: BigDecimal("10000.1250"))
        create(
          :employee_compensation_component,
          employee_compensation: compensation,
          salary_component: create(:salary_component, category: :allowance),
          amount: BigDecimal("250.2500")
        )
        create(
          :employee_compensation_component,
          employee_compensation: compensation,
          salary_component: create(:salary_component, category: :contribution),
          amount: BigDecimal("500.1000")
        )

        get "/api/v1/employees/#{employee.id}"

        expect(response).to have_http_status(:ok)
        expect(json_body["total_compensation"]).to eq(BigDecimal("10750.4750").as_json)
      end

      it "answers 404 for an employee that does not exist" do
        get "/api/v1/employees/0"

        expect(response).to have_http_status(:not_found)
        expect(json_body["error"]).to be_present
      end
    end
  end
end
