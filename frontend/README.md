# Frontend

The frontend is a React 19 single-page application built with Vite. It provides a sign-in page, a session-gated application shell, an employee page with department, designation, current employment status, active contract details, and server-backed pagination, plus a not-found page. Dashboard filters and employee drill-down are later slices.

The app uses cookie-session authentication through the Rails API. During development, Vite proxies `/api` requests to the backend at `http://localhost:3000`; start the backend separately.

## Setup and run

Use the Node version in `.nvmrc`, then run:

```sh
npm ci
npm run dev
```

## Checks

```sh
npm run lint
npm run test:run
npm run build
```

See [`AGENTS.md`](./AGENTS.md) for frontend conventions and testing details.
