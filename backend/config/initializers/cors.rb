# Be sure to restart your server when you modify this file.

# CORS policy for the JSON API. A deployed frontend lives on a different origin
# from this API, so it needs an explicit allow-list: Rodauth authenticates with
# a cookie session (`_backend_session`), and credentialed CORS forbids a `*`
# origin. Setting CORS_ORIGINS to `*` therefore fails at boot with
# Rack::Cors::Resource::CorsMisconfigurationError instead of silently opening
# the API to every site.
#
# Read more: https://github.com/cyu/rack-cors
#
# Development is same-origin (frontend/vite.config.js proxies /api to this
# server), so this policy is dormant there and only takes effect once the
# frontend is served from its own origin.

# Comma-separated list of allowed origins; unset or blank falls back to the Vite
# dev server origins. Read at boot, so changing it requires a restart.
cors_origins = ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
cors_origins = %w[http://localhost:5173 http://localhost:4173] if cors_origins.empty?

# `insert_before 0` is load-bearing, not stylistic. rodauth-rails appends
# Rodauth::Rails::Middleware to the end of the stack in a railtie initializer
# declared `after: :load_config_initializers`, so position 0 puts this middleware
# above it. It has to run first: Rodauth's JSON feature answers a bare OPTIONS on
# its paths with 400, so ordering this after Rodauth would break preflight in
# browsers while ordinary requests kept working.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Full URLs, not bare hosts. rack-cors matches a value containing a scheme
    # literally and exactly, including the port; a bare host such as
    # "example.com" is compiled to a scheme-agnostic regex that accepts no port
    # at all. Full URLs cover the dev port and pin the scheme. (The upstream
    # rodauth-rails docs use the bare-host form.)
    origins(*cors_origins)

    # Scoped to the versioned API so the /up health check and any future
    # non-API routes stay outside the policy. (Upstream docs use resource "*".)
    resource "/api/v1/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true
  end
end
