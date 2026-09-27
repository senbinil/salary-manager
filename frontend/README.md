# Frontend

The frontend is a React 19 single-page application built with Vite. It provides a sign-in page, a session-gated application shell, a paginated employee table, employee contract drill-down, and a not-found page. The employee page shows department, designation, current employment status, and active contract details. Dashboard filters are a later slice.

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
