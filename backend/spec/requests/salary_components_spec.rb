require "rails_helper"

RSpec.describe "Salary components", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/salary_components" do
    it "rejects a request with no session" do
      get "/api/v1/salary_components"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      # Insert order and name order differ, so the ordering example means
      # something.
      let!(:housing) { create(:salary_component, name: "Housing Allowance", category: :allowance) }
      let!(:basic) { create(:salary_component, name: "Basic Salary", category: :earning) }

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns each component as id, name, and category" do
        get "/api/v1/salary_components"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          { "id" => basic.id, "name" => "Basic Salary", "category" => "earning" },
          { "id" => housing.id, "name" => "Housing Allowance", "category" => "allowance" }
        )
      end

      it "orders components by name" do
        get "/api/v1/salary_components"

        expect(json_body.map { |component| component["name"] }).to eq([ "Basic Salary", "Housing Allowance" ])
      end

      it "exposes nothing beyond id, name, and category" do
        get "/api/v1/salary_components"

        expect(json_body.first.keys).to contain_exactly("id", "name", "category")
      end
    end
  end
end
