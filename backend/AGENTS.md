# AGENTS.md — backend

Guidance for AI coding agents working in the `backend/` Rails app.

## Commands

Run all commands from the `backend/` directory.

| Task | Command |
|------|---------|
| Setup | `bin/setup` (installs gems, prepares DB, starts server; add `--skip-server` to skip) |
| Run dev server | `bin/dev` |
| Full CI pipeline | `bin/ci` (setup + style + security + tests) |
| Tests | `bundle exec rspec` |
| Single spec | `bundle exec rspec spec/requests/health_check_spec.rb` |
| Lint / style | `bin/rubocop` |
| Security audit | `bin/bundler-audit` |
| Brakeman scan | `bin/brakeman` |
| Console | `bin/rails console` |

Run `bin/ci` before considering work complete — it runs rubocop, bundler-audit, brakeman, tests, and seed verification.

## Stack & Architecture

- **Ruby 4.0.5**, **Rails ~> 8.1**, **PostgreSQL** (`pg`).
- API-only: `config.api_only = true`. Controllers inherit from `ActionController::API`; there are no views or helpers. Return JSON, not rendered templates.
- Database-backed state services: **Solid Queue** (Active Job), **Solid Cache**, **Solid Cable** (Action Cable).
- Deployment: **Kamal** (`config/deploy.yml`) with **Thruster** as the proxy; production image in `Dockerfile`.
- Security tooling: **Brakeman**, **bundler-audit**, **rubocop-rails-omakase** (no custom rubocop config).
- Testing: **RSpec** (`rspec-rails`) with **FactoryBot** (`factory_bot_rails`); specs live in `spec/`, factories in `spec/factories/`.
- CORS: **`rack-cors`**, configured in `config/initializers/cors.rb`. Allows the origins in `CORS_ORIGINS` (comma-separated; defaults to the Vite dev origins) with credentials, scoped to `/api/v1/*`.

## Conventions

- Ruby style follows `rubocop-rails-omakase`; keep `bin/rubocop` clean.
- Do not commit secrets; use `config/credentials.yml.enc` / `RAILS_MASTER_KEY` (Kamal injects it from `.kamal/secrets`).
- Tests are **RSpec** specs in `spec/` (the Minitest `test/` scaffold was removed). `rails generate` emits specs, and FactoryBot methods are available in specs via `rails_helper`.
- DB names: `backend_development`, `backend_test` (`config/database.yml`).
- Generated scaffolding (job queue, cache, cable, deploy) is intact and expected to stay.

## Current State & Pitfalls

- `config/routes.rb` has no app routes yet — only the `/up` health check.
- No models or custom controllers exist yet; `ApplicationController` is the default `ActionController::API` subclass.
- PostgreSQL must be running before `bin/setup` / `bin/dev`; running specs wipes and reloads `backend_test` from `db/schema.rb`.
- `backend/` is the app root for all Rails/Bundler commands; running them from the repo root will fail.
- Ruby is pinned by `.ruby-version` (4.0.5); keep it in sync with the Dockerfile `RUBY_VERSION` arg.
- CORS is inert in development: `vite.config.js` proxies `/api` to this server, so requests are same-origin and no CORS check happens. The policy only matters once the frontend is served from its own origin. `spec/requests/cors_spec.rb` covers it.
- `CORS_ORIGINS` is read at boot, so changing it needs a restart. Pass **full URLs** (`https://app.example.com`): a bare host such as `app.example.com` is accepted but compiled by rack-cors into a scheme-agnostic regex that rejects every port. A `*` value raises `Rack::Cors::Resource::CorsMisconfigurationError` at boot — credentialed CORS cannot use a wildcard.
- The spec pins `http://localhost:5173`, so CI must not set `CORS_ORIGINS` (or must include that origin).
- `Rack::Cors` must stay inserted with `insert_before 0`. `rodauth-rails` appends its middleware last, and Rodauth's JSON feature answers a bare `OPTIONS` on its paths with **400**, so ordering the CORS middleware after Rodauth would break browser preflight while ordinary requests kept working. Check with `bin/rails middleware`: `Rack::Cors` must appear above `Rodauth::Rails::Middleware`.
