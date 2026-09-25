require "rails_helper"

# require_role! has no production caller until the management endpoints land in
# Phase 8, so it is exercised through an anonymous controller. The role it reads
# comes from the account, which is stubbed — a controller spec has no Rodauth
# middleware behind it to supply `rodauth`.
RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action -> { require_role!(:hr, :manager) }

    def index
      render json: { ok: true }
    end
  end

  let(:account) { build(:account, :verified) }

  before do
    allow(controller).to receive(:current_account).and_return(account)
  end

  def json_body
    JSON.parse(response.body)
  end

  context "with no session" do
    let(:account) { nil }

    it "answers 401 rather than 403, so the client can tell them apart" do
      get :index

      expect(response).to have_http_status(:unauthorized)
      expect(json_body["reason"]).to eq("login_required")
      expect(json_body["error"]).to eq("Please login to continue")
    end
  end

  context "with a role that is not allowed" do
    it "forbids the action" do
      get :index

      expect(response).to have_http_status(:forbidden)
      expect(json_body["reason"]).to eq("insufficient_role")
      expect(json_body["error"]).to be_present
    end
  end

  context "with an allowed role" do
    let(:account) { build(:account, :verified, :hr) }

    it "lets the action run" do
      get :index

      expect(response).to have_http_status(:ok)
      expect(json_body).to eq("ok" => true)
    end
  end

  context "with any one of the allowed roles" do
    let(:account) { build(:account, :verified, :manager) }

    it "lets the action run" do
      get :index

      expect(response).to have_http_status(:ok)
    end
  end
end
