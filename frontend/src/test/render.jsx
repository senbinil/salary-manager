import CssBaseline from '@mui/material/CssBaseline'
import { ThemeProvider } from '@mui/material/styles'
import { render } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { theme } from '../theme/index.js'

/**
 * Render a route tree the way `main.jsx` renders it in the browser — inside the
 * MUI theme — but with `createMemoryRouter` in place of `createBrowserRouter`
 * so each test can pick its own starting URL.
 *
 * @param {Array} routes Route objects, usually the `routes` array from `src/router/routes.js`.
 * @param {{ route?: string }} [options] Starting URL, defaulting to `/`.
 * @returns The React Testing Library result plus the memory `router` it built.
 */
export function renderWithRouter(routes, { route = '/' } = {}) {
  const router = createMemoryRouter(routes, { initialEntries: [route] })

  return {
    ...render(
      <ThemeProvider theme={theme} defaultMode="light">
        <CssBaseline />
        <RouterProvider router={router} />
      </ThemeProvider>,
    ),
    router,
  }
}
