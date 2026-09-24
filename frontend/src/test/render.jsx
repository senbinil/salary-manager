import CssBaseline from '@mui/material/CssBaseline'
import { ThemeProvider } from '@mui/material/styles'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { theme } from '../theme/index.js'

/**
 * Render a route tree the way `main.jsx` renders it in the browser — inside the
 * MUI theme and a React Query provider — but with `createMemoryRouter` in place
 * of `createBrowserRouter` so each test can pick its own starting URL.
 *
 * The query client is built per call so cached data and mutation state cannot
 * leak from one test into the next, and retries are off so a test asserting a
 * failure sees it once rather than after React Query's backoff.
 *
 * @param {Array} routes Route objects, usually the `routes` array from `src/router/routes.js`.
 * @param {{ route?: string }} [options] Starting URL, defaulting to `/`.
 * @returns The React Testing Library result plus the memory `router` and `queryClient` it built.
 */
export function renderWithRouter(routes, { route = '/' } = {}) {
  const router = createMemoryRouter(routes, { initialEntries: [route] })
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
  })

  return {
    ...render(
      <ThemeProvider theme={theme} defaultMode="light">
        <CssBaseline />
        <QueryClientProvider client={queryClient}>
          <RouterProvider router={router} />
        </QueryClientProvider>
      </ThemeProvider>,
    ),
    router,
    queryClient,
  }
}
