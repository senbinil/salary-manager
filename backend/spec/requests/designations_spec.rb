require "rails_helper"

RSpec.describe "Designations", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "GET /api/v1/designations" do
    it "rejects a request with no session" do
      get "/api/v1/designations"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
    end

    context "with a session" do
      # The endpoint returns the whole table, so the examples build the only rows
      # in it — through the factory, not from a seed. Engineer is created first, so
      # insert order and name order differ and the ordering example means something.
      let!(:engineer) { create(:designation, name: "Engineer") }
      let!(:analyst) { create(:designation, name: "Analyst") }

      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "returns each designation as id and name" do
        get "/api/v1/designations"

        expect(response).to have_http_status(:ok)
        expect(json_body).to contain_exactly(
          { "id" => analyst.id, "name" => "Analyst" },
          { "id" => engineer.id, "name" => "Engineer" }
        )
      end

      it "orders designations by name" do
        get "/api/v1/designations"

        expect(json_body.map { |designation| designation["name"] }).to eq(%w[Analyst Engineer])
      end

      it "exposes nothing beyond id and name" do
        get "/api/v1/designations"

        expect(json_body.first.keys).to contain_exactly("id", "name")
      end
    end
  end
end
