# Frontend

The frontend is a React 19 single-page application built with Vite. It provides a sign-in page, a session-gated application shell, a paginated employee table, employee contract drill-down, and a not-found page. The employee table shows department, designation, current contract country and start date, total compensation for active employees, and status. The detail page selects the current contract for active employees or the most recent ended contract for inactive employees. For an active employee with a total, the detail page also offers a display currency: it defaults to the contract currency, lists only the targets the conversion API reports as available, and shows the converted total with the rate's observation date. The native total stays visible with an explanation when a rate is missing or the request fails, and inactive employees never request a conversion. The dashboard filters the employee table by name, department, designation, employment status, and contract country. Above the table it also shows the organization-wide overview as two strips of country cards that scroll sideways: compensation per country, each labelled in that country's own currency, and employees per country, whose badge carries the organization-wide active-employee total. The overview is organization-wide, so the table's filters do not narrow it.

The app uses cookie-session authentication through the Rails API. During development, Vite proxies `/api` requests to the backend at `http://localhost:3000`; start the backend separately.

## Setup and run

Use the Node version in `.nvmrc`, then run:

```sh
npm ci
npm run dev
```

## Deployment

Production serves the built SPA from an nginx image built by `Dockerfile` and deployed with [Kamal](https://kamal-deploy.org) (`config/deploy.yml`), pushed to Docker Hub. Kamal's proxy terminates TLS for the site host and forwards to nginx on port 80; the image itself carries no runtime configuration. The site is deployed at `https://diciq.site`. The shared topology and the backend's half of the deployment are in [`../docs/DEPLOYMENT.md`](../docs/DEPLOYMENT.md).

The browser calls the API cross-origin, so the API origin is a **build-time** value: `builder.args.VITE_API_URL` feeds the Docker build, Vite inlines it into the bundle, and `src/api/client.js` uses it to set axios's `baseURL` and `withCredentials`. Changing the API origin therefore needs a rebuild, not a restart.

Kamal 2 has no `.env` file support of its own, so `bin/kamal` loads `.env` and `.env.production` with dotenv before starting Kamal, and `config/deploy.yml` interpolates its values from there:

```sh
DOCKERHUB_USER=...              # Docker Hub user; also the image namespace
DEPLOY_HOST=...                 # the VPS, the same one the API deploys to
SITE_HOST=diciq.site            # public host for the SPA; the proxy requests a TLS certificate for it
API_URL=https://api.diciq.site  # public API origin, no trailing slash and no /api/v1
KAMAL_REGISTRY_PASSWORD=...
KAMAL_SSH_KEY=~/.ssh/deploy_key # private key Kamal connects with; ~/.ssh/id_rsa is the fallback
```

That file is gitignored and excluded from the image by `.dockerignore`; only `KAMAL_REGISTRY_PASSWORD` is mapped by name in `.kamal/secrets`. `bin/kamal` runs on the Ruby in `.ruby-version` (the `frontend` gemset) rather than a globally installed Kamal.

```sh
bin/kamal setup    # first deploy: proxy route, TLS certificate, image, container
bin/kamal deploy   # later releases
bin/kamal logs -f  # tail the container logs
```

nginx serves `index.html` with `no-cache` and the hashed files under `/assets/` as immutable, so a deploy only needs the new document. A deploy is healthy when `curl -fsS https://diciq.site/` and `https://diciq.site/dashboard` both answer 200.

## Checks

```sh
npm run lint
npm run test:run
npm run build
```

See [`AGENTS.md`](./AGENTS.md) for frontend conventions and testing details.
