import RootLayout from '../layouts/RootLayout.jsx'
import Home from '../pages/Home.jsx'
import NotFound from '../pages/NotFound.jsx'
import { paths } from './paths.js'

/**
 * The app's route tree. `main.jsx` hands this to `createBrowserRouter` and the
 * tests hand it to `createMemoryRouter`, so both exercise the same tree.
 *
 * Not-found is a child of the layout rather than a sibling route: unknown URLs
 * keep the app shell instead of dropping to a bare page.
 */
export const routes = [
  {
    path: paths.home,
    Component: RootLayout,
    children: [
      { index: true, Component: Home },
      { path: '*', Component: NotFound },
    ],
  },
]
