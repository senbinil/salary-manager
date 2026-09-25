require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:email) { "person@example.com" }
  let(:password) { "secret123" }

  def json_body
    JSON.parse(response.body)
  end

  describe "POST /api/v1/create-account" do
    def create_account
      post "/api/v1/create-account",
        params: { email: email, password: password, "password-confirm": password },
        as: :json
    end

    it "creates an account and reports success" do
      expect { create_account }.to change(Account, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end

    it "creates the account already verified and logs it in" do
      create_account

      expect(Account.find_by(email: email).status).to eq("verified")
      expect(response.cookies["_backend_session"]).to be_present
    end

    it "lets the new account log in without verifying it first" do
      create_account
      post "/api/v1/logout", as: :json

      post "/api/v1/login", params: { email: email, password: password }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end
  end

  describe "POST /api/v1/verify-account" do
    it "is not routed because account verification is disabled" do
      post "/api/v1/verify-account", params: { key: "some-key" }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/login" do
    before do
      create(:account, :verified, email: email, password: password)
    end

    it "logs in with valid credentials" do
      post "/api/v1/login", params: { email: email, password: password }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end

    it "rejects an invalid password" do
      post "/api/v1/login", params: { email: email, password: "wrong-password" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["error"]).to be_present
    end
  end

  describe "POST /api/v1/logout" do
    before do
      create(:account, :verified, email: email, password: password)
      post "/api/v1/login", params: { email: email, password: password }, as: :json
    end

    it "logs out the current session" do
      post "/api/v1/logout", as: :json

      expect(response).to have_http_status(:ok)
      expect(json_body["success"]).to be_present
    end
  end

  describe "GET /api/v1/me" do
    it "rejects a request with no session" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
      expect(json_body["error"]).to eq("Please login to continue")
    end

    context "with a session" do
      let!(:account) { create(:account, :verified, email: email, password: password) }

      before do
        post "/api/v1/login", params: { email: email, password: password }, as: :json
      end

      it "reports the signed-in account" do
        get "/api/v1/me"

        expect(response).to have_http_status(:ok)
        expect(json_body["id"]).to eq(account.id)
        expect(json_body["email"]).to eq(email)
      end

      it "exposes nothing beyond the account's id and email" do
        get "/api/v1/me"

        expect(json_body.keys).to contain_exactly("id", "email")
      end
    end

    context "after signing out" do
      before do
        create(:account, :verified, email: email, password: password)
        post "/api/v1/login", params: { email: email, password: password }, as: :json
        post "/api/v1/logout", as: :json
      end

      it "rejects the request again" do
        get "/api/v1/me"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the account was closed after signing in" do
      let!(:account) { create(:account, :verified, email: email, password: password) }

      before do
        post "/api/v1/login", params: { email: email, password: password }, as: :json
        account.update!(status: :closed)
      end

      it "reports the session as signed out" do
        get "/api/v1/me"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "unversioned auth routes" do
    it "does not expose login outside the versioned namespace" do
      post "/login", params: { email: email, password: password }, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
