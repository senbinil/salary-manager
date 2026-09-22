# AGENTS.md — frontend

Guidance for AI coding agents working in the `frontend/` React app.

## Commands

Run all commands from the `frontend/` directory.

| Task | Command |
|------|---------|
| Install deps | `npm install` |
| Dev server | `npm run dev` |
| Build | `npm run build` |
| Preview build | `npm run preview` |
| Lint | `npm run lint` |

## Stack

- **React 19** + **Vite 8** with `@vitejs/plugin-react` (JavaScript, not TypeScript).
- ESLint flat config (`eslint.config.js`): `@eslint/js`, `eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`; `dist/` is globally ignored.
- Node version pinned by `.nvmrc` (24.21.0).
- Entry point: `src/main.jsx` renders `<App />` from `src/App.jsx`.

## Conventions

- JavaScript + JSX only — no TypeScript yet.
- Keep `npm run lint` clean.
- No routing or state libraries installed yet (no React Router, Redux, etc.) — do not assume them.

## Pitfalls

- The Vite scaffold ships demo assets (`src/assets/*`, `App.css`); replace them rather than building on top.
- No API client or dev-server proxy is configured yet; the backend is a separate Rails API on its own port.
