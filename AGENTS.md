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
- Keep build output and dependencies untracked (`node_modules`, logs, coverage) — each app has its own `.gitignore`, plus a root `.agentignore`.

## Documentation

- `README.md` (root) and each app's `README.md` are placeholders/stubs. Update them as real documentation lands rather than duplicating content in agent files.
