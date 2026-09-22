# AGENTS.md — backend

Guidance for AI coding agents working in the `backend/` Rails app.

## Commands

Run all commands from the `backend/` directory.

| Task | Command |
|------|---------|
| Setup | `bin/setup` (installs gems, prepares DB, starts server; add `--skip-server` to skip) |
| Run dev server | `bin/dev` |
| Full CI pipeline | `bin/ci` (setup + style + security + tests) |
| Tests | `bin/rails test` |
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

## Conventions

- Ruby style follows `rubocop-rails-omakase`; keep `bin/rubocop` clean.
- Do not commit secrets; use `config/credentials.yml.enc` / `RAILS_MASTER_KEY` (Kamal injects it from `.kamal/secrets`).
- DB names: `backend_development`, `backend_test` (`config/database.yml`).
- Generated scaffolding (job queue, cache, cable, deploy) is intact and expected to stay.

## Current State & Pitfalls

- `config/routes.rb` has no app routes yet — only the `/up` health check.
- No models or custom controllers exist yet; `ApplicationController` is the default `ActionController::API` subclass.
- PostgreSQL must be running before `bin/setup` / `bin/dev`; `bin/rails test` wipes the test DB.
- `backend/` is the app root for all Rails/Bundler commands; running them from the repo root will fail.
- Ruby is pinned by `.ruby-version` (4.0.5); keep it in sync with the Dockerfile `RUBY_VERSION` arg.
