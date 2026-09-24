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
- Testing: **Vitest** (`jsdom`) + **React Testing Library**; `src/test/setup.js` registers jest-dom matchers and RTL cleanup; `src/test/render.jsx` exports `renderWithRouter(routes, { route })` for anything that needs a router.
- Entry point: `src/main.jsx` builds `createBrowserRouter(routes)` and renders `<RouterProvider />` under `ThemeProvider` + `CssBaseline`.
- Routing: **React Router 8** in data mode — `createBrowserRouter` / `RouterProvider` / `Outlet` all come from the `react-router` package (there is no `react-router-dom`).

## Conventions

- JavaScript + JSX only — no TypeScript yet.
- Keep `npm run lint` clean.
- Tests are colocated with the code they cover (`src/theme/theme.test.jsx`) and use `describe`/`it`/`expect` as globals (`test.globals` in `vite.config.js`).
- `src/router/routes.js` owns the route tree and is the single source of truth: `main.jsx` passes it to `createBrowserRouter` and tests pass it to `createMemoryRouter`, so both exercise the same tree. Route paths belong in `src/router/paths.js`; link by name, not by literal.
- `src/main.jsx` is coverage-excluded wiring — keep router/provider setup there rather than adding thin modules that only exist to be covered.
- Page and layout components live in `src/pages/` and `src/layouts/` and default-export a single PascalCase component.

## Pitfalls

- The Vite scaffold demo (`App.jsx`, `App.css`, `src/assets/*`, `public/icons.svg`, `src/index.css`) has been deleted; `CssBaseline` owns the global resets. Don't reintroduce scaffold assets.
- `react-refresh/only-export-components` is an **error** and covers every `.jsx` file, including `src/test/render.jsx` (only `*.test.*`/`*.spec.*` names are skipped, and `.js` files are not scanned). A module that exports a non-component must not also declare a top-level PascalCase component, or lint fails with `localComponents`.
- Keep route path constants in a `.js` file or a component-free module — a `.jsx` module exporting both components and constants hits the same rule.
- No API client or dev-server proxy is configured yet; the backend is a separate Rails API on its own port (its auth endpoints live under `/api/v1` and are cookie-session based).
- Vitest sets `skipFull: true` on the `text` coverage reporter whenever it detects an AI agent, which hides every 100%-covered file and can leave the table with no rows; `vite.config.js` pins `skipFull: false` so the table always lists files.
