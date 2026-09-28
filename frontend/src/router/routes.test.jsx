import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import axios from 'axios'
import { renderWithRouter } from '../test/render.jsx'
import { routes } from './routes.js'

// The signed-in area probes the API for the current session before it renders,
// and the shell ends that session from the app bar, so axios is the system
// boundary these tests stub.
vi.mock('axios', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

const employeeListResponse = {
  data: {
    data: [],
    pagination: {
      page: 1,
      limit: 20,
      count: 0,
      pages: 0,
      from: null,
      to: null,
      previous: null,
      next: null,
    },
  },
}

// The dashboard's filter dropdowns load reference data alongside the table.
const filterEndpoints = [
  '/api/v1/departments',
  '/api/v1/designations',
  '/api/v1/countries',
]

// The dashboard also loads its organization-wide overview.
const dashboardSummaryResponse = {
  data: { total_active_employees: 0, country_totals: [] },
}

describe('routes', () => {
  beforeEach(() => {
    vi.resetAllMocks()
    // A live session and an empty employee page let the signed-in area render.
    axios.get.mockImplementation((url) => {
      if (url === '/api/v1/employees') {
        return Promise.resolve(employeeListResponse)
      }
      if (filterEndpoints.includes(url)) {
        return Promise.resolve({ data: [] })
      }
      if (url === '/api/v1/dashboard/summary') {
        return Promise.resolve(dashboardSummaryResponse)
      }
      return Promise.resolve({ data: { id: 1, email: 'person@example.com' } })
    })
  })

  it('serves the sign-in page at the root path', async () => {
    axios.get.mockRejectedValue({ response: { status: 401 } })
    renderWithRouter(routes)

    expect(
      await screen.findByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
  })

  it('keeps the sign-in page outside the app shell', async () => {
    axios.get.mockRejectedValue({ response: { status: 401 } })
    renderWithRouter(routes)

    expect(
      await screen.findByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
    expect(screen.queryByRole('banner')).not.toBeInTheDocument()
  })

  it('wraps the home page in the app shell at /dashboard', async () => {
    renderWithRouter(routes, { route: '/dashboard' })

    expect(
      await screen.findByRole('heading', {
        level: 1,
        name: /dashboard/i,
      }),
    ).toBeInTheDocument()
    expect(screen.getByRole('banner')).toBeInTheDocument()
    expect(screen.getByRole('main')).toBeInTheDocument()
  })

  it('renders the not-found page for an unknown path', async () => {
    renderWithRouter(routes, { route: '/unknown' })

    expect(
      await screen.findByRole('heading', { level: 1, name: /page not found/i }),
    ).toBeInTheDocument()
  })

  it('keeps the app shell around the not-found page', async () => {
    renderWithRouter(routes, { route: '/unknown' })

    expect(await screen.findByRole('banner')).toBeInTheDocument()
    expect(screen.getByRole('main')).toBeInTheDocument()
  })

  it('returns to the dashboard from the not-found page', async () => {
    const user = userEvent.setup()
    const { router } = renderWithRouter(routes, { route: '/unknown' })

    await user.click(
      await screen.findByRole('link', { name: /back to dashboard/i }),
    )

    await waitFor(() =>
      expect(router.state.location.pathname).toBe('/dashboard'),
    )
    expect(
      await screen.findByRole('heading', {
        level: 1,
        name: /dashboard/i,
      }),
    ).toBeInTheDocument()
  })

  it('sends a signed-out visitor from the dashboard to sign-in', async () => {
    axios.get.mockRejectedValue({ response: { status: 401 } })
    const { router } = renderWithRouter(routes, { route: '/dashboard' })

    await waitFor(() => expect(router.state.location.pathname).toBe('/'))
    expect(
      screen.getByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
  })

  it('sends the visitor to sign-in when the session cannot be checked', async () => {
    // An unreachable API is not proof of a session, so the area stays closed.
    axios.get.mockRejectedValue(new Error('Network Error'))
    const { router } = renderWithRouter(routes, { route: '/dashboard' })

    await waitFor(() => expect(router.state.location.pathname).toBe('/'))
    expect(
      screen.queryByRole('heading', { level: 1, name: /dashboard/i }),
    ).not.toBeInTheDocument()
  })

  it('shows a loading state while the session is being checked', async () => {
    // Never settles, so the gate is still waiting for the length of the test.
    axios.get.mockReturnValue(new Promise(() => {}))
    renderWithRouter(routes, { route: '/dashboard' })

    expect(
      await screen.findByLabelText(/checking your session/i),
    ).toBeInTheDocument()
    expect(
      screen.queryByRole('heading', { level: 1, name: /dashboard/i }),
    ).not.toBeInTheDocument()
  })

  it('sends a signed-in visitor from sign-in to the dashboard', async () => {
    const { router } = renderWithRouter(routes)

    await waitFor(() =>
      expect(router.state.location.pathname).toBe('/dashboard'),
    )
    expect(
      await screen.findByRole('heading', {
        level: 1,
        name: /dashboard/i,
      }),
    ).toBeInTheDocument()
  })

  it('signs a visitor out of the dashboard and back to sign-in', async () => {
    // The cookie session is real until the sign-out call ends it: the probe
    // answers while it lives, and fails once the visitor is out.
    let signedIn = true
    axios.get.mockImplementation((url) => {
      if (url === '/api/v1/employees') {
        return Promise.resolve(employeeListResponse)
      }
      if (filterEndpoints.includes(url)) {
        return Promise.resolve({ data: [] })
      }
      if (url === '/api/v1/dashboard/summary') {
        return Promise.resolve(dashboardSummaryResponse)
      }
      return signedIn
        ? Promise.resolve({ data: { id: 1, email: 'person@example.com' } })
        : Promise.reject({ response: { status: 401 } })
    })
    axios.post.mockImplementation(() => {
      signedIn = false
      return Promise.resolve({ data: { success: 'You have been logged out' } })
    })
    const user = userEvent.setup()
    const { router } = renderWithRouter(routes, { route: '/dashboard' })

    await user.click(await screen.findByRole('button', { name: /sign out/i }))

    // The loader for the sign-in route is async, so the router's state moves a
    // tick before the page it renders does — wait for the page, not the URL.
    expect(
      await screen.findByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
    await waitFor(() => expect(router.state.location.pathname).toBe('/'))
    expect(axios.post).toHaveBeenCalledWith('/api/v1/logout', {})
  })
})
