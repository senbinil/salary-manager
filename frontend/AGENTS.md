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
| Tests | `npm run test:run` |
| Tests (watch) | `npm test` |
| Coverage | `npm run test:coverage` |

Run `npm run lint` and `npm run test:run` before considering work complete.

## Stack

- **React 19** + **Vite 8** with `@vitejs/plugin-react` (JavaScript, not TypeScript).
- ESLint flat config (`eslint.config.js`): `@eslint/js`, `eslint-plugin-react-hooks`, `eslint-plugin-react-refresh`; `dist/` is globally ignored.
- Node version pinned by `.nvmrc` (24.21.0).
- Testing: **Vitest** (`jsdom`) + **React Testing Library**; `src/test/setup.js` registers jest-dom matchers and RTL cleanup.
- Entry point: `src/main.jsx` renders `<App />` from `src/App.jsx`.

## Conventions

- JavaScript + JSX only — no TypeScript yet.
- Keep `npm run lint` clean.
- Tests are colocated with the code they cover (`src/App.test.jsx`) and use `describe`/`it`/`expect` as globals (`test.globals` in `vite.config.js`).
- No routing or state libraries installed yet (no React Router, Redux, etc.) — do not assume them.

## Pitfalls

- The Vite scaffold ships demo assets (`src/assets/*`, `App.css`); replace them rather than building on top.
- No API client or dev-server proxy is configured yet; the backend is a separate Rails API on its own port.
- Vitest sets `skipFull: true` on the `text` coverage reporter whenever it detects an AI agent, which hides every 100%-covered file and can leave the table with no rows; `vite.config.js` pins `skipFull: false` so the table always lists files.
