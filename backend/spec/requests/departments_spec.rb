require "rails_helper"

RSpec.describe "Departments", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/departments" do
    it "rejects a request with no session" do
      get "/api/v1/departments"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      # The endpoint returns the whole table, so the examples build the only rows
      # in it — through the factory, not from a seed. Finance is created first, so
      # insert order and name order differ and the ordering example means something.
      let!(:finance) { create(:department, name: "Finance") }
      let!(:engineering) { create(:department, name: "Engineering") }

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns each department as id and name" do
        get "/api/v1/departments"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          { "id" => engineering.id, "name" => "Engineering" },
          { "id" => finance.id, "name" => "Finance" }
        )
      end

      it "orders departments by name" do
        get "/api/v1/departments"

        expect(json_body.map { |department| department["name"] }).to eq(%w[Engineering Finance])
      end

      it "exposes nothing beyond id and name" do
        get "/api/v1/departments"

        expect(json_body.first.keys).to contain_exactly("id", "name")
      end
    end
  end
end
