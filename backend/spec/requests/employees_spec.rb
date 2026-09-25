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

      it "returns each employee with its ids" do
        get "/api/v1/employees"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          { "id" => ada.id, "name" => "Ada", "department_id" => department.id,
            "designation_id" => designation.id, "user_id" => nil },
          { "id" => zoe.id, "name" => "Zoe", "department_id" => department.id,
            "designation_id" => designation.id, "user_id" => nil }
        )
      end

      it "orders employees by name" do
        get "/api/v1/employees"

        expect(json_body.map { |employee| employee["name"] }).to eq(%w[Ada Zoe])
      end

      # The link is optional, so nil is the common case — check the other one.
      it "reports the linked account when an employee has one" do
        account = create(:account, :verified)
        zoe.update!(user: account)

        get "/api/v1/employees"

        expect(json_body.find { |employee| employee["id"] == zoe.id }["user_id"]).to eq(account.id)
      end

      it "exposes nothing beyond id, name, department_id, designation_id, and user_id" do
        get "/api/v1/employees"

        expect(json_body.first.keys).to contain_exactly(
          "id", "name", "department_id", "designation_id", "user_id"
        )
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
          "designation_id" => employee.designation_id,
          "user_id" => nil
        )
      end

      it "answers 404 for an employee that does not exist" do
        get "/api/v1/employees/0"

        expect(response).to have_http_status(:not_found)
        expect(json_body["error"]).to be_present
      end
    end
  end
end
