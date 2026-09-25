require "rails_helper"

RSpec.describe "CORS", type: :request do
  # The default allowed origin, documented in config/initializers/cors.rb. Pinned
  # as a literal rather than read back from ENV so the expectation has a source
  # of truth independent of the code that parses CORS_ORIGINS.
  let(:allowed_origin) { "http://localhost:5173" }
  let(:blocked_origin) { "https://evil.example.com" }

  # Rack 3 requires lowercase response header names, so read them in lowercase
  # rather than relying on the header hash being case-insensitive.
  def cors_header(name)
    response.headers[name.downcase]
  end

  def origin_header(origin)
    { "Origin" => origin }
  end

  describe "preflight from the allowed origin" do
    before do
      options "/api/v1/login",
        headers: origin_header(allowed_origin).merge(
          "Access-Control-Request-Method" => "POST",
          "Access-Control-Request-Headers" => "content-type"
        )
    end

    it "is answered by the CORS middleware rather than rejected by Rodauth" do
      expect(response).to have_http_status(:ok)
    end

    it "grants the origin and allows credentials" do
      expect(cors_header("Access-Control-Allow-Origin")).to eq(allowed_origin)
      expect(cors_header("Access-Control-Allow-Credentials")).to eq("true")
    end

    it "grants the method and header the SPA sends" do
      expect(cors_header("Access-Control-Allow-Methods")).to include("POST")
      expect(cors_header("Access-Control-Allow-Headers")).to eq("content-type")
    end
  end

  describe "an actual request from the allowed origin" do
    before do
      post "/api/v1/login",
        params: { email: "person@example.com", password: "secret123" },
        as: :json,
        headers: origin_header(allowed_origin)
    end

    it "grants the origin and allows credentials" do
      expect(cors_header("Access-Control-Allow-Origin")).to eq(allowed_origin)
      expect(cors_header("Access-Control-Allow-Credentials")).to eq("true")
    end

    it "varies on Origin so caches cannot share the response" do
      expect(cors_header("Vary")).to include("Origin")
    end
  end

  describe "an origin that is not allowed" do
    it "grants nothing on a preflight" do
      options "/api/v1/login",
        headers: origin_header(blocked_origin).merge("Access-Control-Request-Method" => "POST")

      expect(cors_header("Access-Control-Allow-Origin")).to be_nil
    end

    it "grants nothing on an actual request" do
      post "/api/v1/login",
        params: { email: "person@example.com", password: "secret123" },
        as: :json,
        headers: origin_header(blocked_origin)

      expect(cors_header("Access-Control-Allow-Origin")).to be_nil
    end
  end

  describe "a path outside the versioned API" do
    it "leaves the health check out of the CORS policy" do
      get "/up", headers: origin_header(allowed_origin)

      expect(response).to have_http_status(:ok)
      expect(cors_header("Access-Control-Allow-Origin")).to be_nil
    end
  end
end
