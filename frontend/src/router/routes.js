import RootLayout from '../layouts/RootLayout.jsx'
import Home from '../pages/Home.jsx'
import Login from '../pages/Login.jsx'
import NotFound from '../pages/NotFound.jsx'
import { paths } from './paths.js'
import { requireAuth } from './requireAuth.js'
import { redirectIfSignedIn } from './redirectIfSignedIn.js'
import SessionFallback from './SessionFallback.jsx'

/**
 * The app's route tree. `main.jsx` hands this to `createBrowserRouter` and the
 * tests hand it to `createMemoryRouter`, so both exercise the same tree.
 *
 * Sign-in is a top-level route rather than a child of `RootLayout`: the product
 * chrome belongs to signed-in screens. The signed-in side is a pathless layout
 * route, which keeps the shell around both the dashboard and the 404 — and its
 * loader is what keeps anonymous visitors out of both, with `SessionFallback`
 * standing in while that check is in flight.
 *
 * The same check runs in the other direction: the sign-in route turns away a
 * visitor who already has a session, so the gate alone decides who sees the
 * form.
 */
export const routes = [
  {
    path: paths.login,
    Component: Login,
    loader: redirectIfSignedIn,
    HydrateFallback: SessionFallback,
  },
  {
    Component: RootLayout,
    loader: requireAuth,
    HydrateFallback: SessionFallback,
    children: [
      { path: paths.dashboard, Component: Home },
      { path: '*', Component: NotFound },
    ],
  },
]
