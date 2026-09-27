# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project

**salary-manager** — salary management application, a monorepo with two apps:

| App | Stack | Scoped guidance |
|-----|-------|-----------------|
| `backend/` | Rails ~> 8.1 API-only + PostgreSQL | `backend/AGENTS.md` |
| `frontend/` | React 19 + Vite (JavaScript) | `frontend/AGENTS.md` |

Area-specific commands, conventions, and pitfalls live in each app's `AGENTS.md`. This file only covers what's shared repo-wide.

## Shared conventions

- Use Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, …).
- Never commit secrets. Rails secrets go in `backend/config/credentials.yml.enc`; frontend env vars in gitignored `.env` files.
- `backend/.env.production` holds the live deploy credentials and host values, and is listed in the root `.agentignore`. Never read, print, copy or summarize it, and never inline its values into a tracked file. Its keys are documented in `backend/README.md`; if a deploy fails on a missing value, ask the user to check that key rather than opening the file.
- Keep build output and dependencies untracked (`node_modules`, logs, coverage) — each app has its own `.gitignore`, plus a root `.agentignore`.

## Git workflow

- Always do work on a feature branch. Never commit, push, or merge work directly to `main`.
- After the user confirms a branch was merged, fetch `origin` and create the next feature branch from `origin/main` without setting `main` as its upstream (for example, `git switch --no-track -c feat/<name> origin/main`).
- Before committing or pushing, verify the current branch with `git branch --show-current`. Before pushing, verify the push target/upstream and ensure it is the feature branch, never `main`; use an explicit feature-branch ref when needed.
- Integrate work through a feature-branch PR or leave the merge to the user. Do not push or merge to `main` directly.

## Documentation

- Root and app-level `README.md` files are user-facing project documentation. Keep setup and current feature descriptions accurate; put agent-specific commands and conventions in the scoped `AGENTS.md` files.
