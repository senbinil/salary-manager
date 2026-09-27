# Frontend

The frontend is a React 19 single-page application built with Vite. It provides a sign-in page, a session-gated application shell, a paginated employee table, employee contract drill-down, and a not-found page. The employee table shows department, designation, current contract country and start date, total compensation for active employees, and status. The detail page selects the current contract for active employees or the most recent ended contract for inactive employees. For an active employee with a total, the detail page also offers a display currency: it defaults to the contract currency, lists only the targets the conversion API reports as available, and shows the converted total with the rate's observation date. The native total stays visible with an explanation when a rate is missing or the request fails, and inactive employees never request a conversion. Dashboard filters are a later slice.

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
