require "rails_helper"

RSpec.describe "Compensation plans", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/compensation_plans" do
    it "rejects a request with no session" do
      get "/api/v1/compensation_plans"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      # Insert order and name order differ, so the ordering example means
      # something.
      let!(:standard) { create(:compensation_plan, name: "Standard") }
      let!(:executive) { create(:compensation_plan, name: "Executive") }

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns each plan as id and name" do
        get "/api/v1/compensation_plans"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          { "id" => standard.id, "name" => "Standard" },
          { "id" => executive.id, "name" => "Executive" }
        )
      end

      it "orders plans by name" do
        get "/api/v1/compensation_plans"

        expect(json_body.map { |plan| plan["name"] }).to eq([ "Executive", "Standard" ])
      end

      it "exposes nothing beyond id and name" do
        get "/api/v1/compensation_plans"

        expect(json_body.first.keys).to contain_exactly("id", "name")
      end
    end
  end
end
