require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "POST /create-account" do
    it "creates an account and reports success" do
      expect {
        post "/create-account",
          params: { email: email, password: password, "password-confirm": password },
          as: :json
      }.to change(Account, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end
  end

  describe "POST /login" do
    before do
      create(:account, :verified, email: email, password: password)
    end

    it "logs in with valid credentials" do
      post "/login", params: { email: email, password: password }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end

    it "rejects an invalid password" do
      post "/login", params: { email: email, password: "wrong-password" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["error"]).to be_present
    end
  end

  describe "POST /logout" do
    before do
      create(:account, :verified, email: email, password: password)
      post "/login", params: { email: email, password: password }, as: :json
    end

    it "logs out the current session" do
      post "/logout", as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end
  end
end
