import RootLayout from '../layouts/RootLayout.jsx'
import Home from '../pages/Home.jsx'
import Login from '../pages/Login.jsx'
import NotFound from '../pages/NotFound.jsx'
import { paths } from './paths.js'
import { requireAuth } from './requireAuth.js'

/**
 * The app's route tree. `main.jsx` hands this to `createBrowserRouter` and the
 * tests hand it to `createMemoryRouter`, so both exercise the same tree.
 *
 * Sign-in is a top-level route rather than a child of `RootLayout`: the product
 * chrome belongs to signed-in screens. The signed-in side is a pathless layout
 * route, which keeps the shell around both the dashboard and the 404 — and its
 * loader is what keeps anonymous visitors out of both.
 */
export const routes = [
  { path: paths.login, Component: Login },
  {
    Component: RootLayout,
    loader: requireAuth,
    children: [
      { path: paths.dashboard, Component: Home },
      { path: '*', Component: NotFound },
    ],
  },
]
