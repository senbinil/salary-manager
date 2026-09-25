import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import axios from 'axios'
import { renderWithRouter } from '../test/render.jsx'
import RootLayout from './RootLayout.jsx'

// axios is the system boundary, so stubbing it is how these tests see what the
// shell sends and feed failures back without standing up a server.
vi.mock('axios', () => ({ default: { post: vi.fn() } }))

function ChildPage() {
  return <p>page content</p>
}

function SignInStub() {
  return <h1>Sign in</h1>
}

const layoutRoutes = [
  {
    path: '/',
    Component: RootLayout,
    children: [{ index: true, Component: ChildPage }],
  },
]

// The shell lives at a real path here so these tests can watch it send the
// visitor back to sign-in — a move the layout makes with the router, not with
// its own URL.
const signedInRoutes = [
  {
    path: '/dashboard',
    Component: RootLayout,
    children: [{ index: true, Component: ChildPage }],
  },
  { path: '/', Component: SignInStub },
]

/** What axios rejects with when the API answers with an error body. */
function rejection(status, data) {
  return { response: { status, data } }
}

describe('RootLayout', () => {
  it('shows the product name in the header', () => {
    renderWithRouter(layoutRoutes)

    expect(screen.getByRole('banner')).toHaveTextContent(/amce payroll/i)
  })

  it('renders the matched child route in the main region', () => {
    renderWithRouter(layoutRoutes)

    expect(
      within(screen.getByRole('main')).getByText('page content'),
    ).toBeInTheDocument()
  })
})

describe('signing out', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('ends the session at the API and returns to sign-in', async () => {
    axios.post.mockResolvedValue({ data: { success: 'You have been logged out' } })
    const user = userEvent.setup()
    const { router } = renderWithRouter(signedInRoutes, { route: '/dashboard' })

    await user.click(screen.getByRole('button', { name: /sign out/i }))

    await waitFor(() => expect(router.state.location.pathname).toBe('/'))
    expect(axios.post).toHaveBeenCalledWith('/api/v1/logout', {})
    expect(
      screen.getByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
  })

  // Rodauth is configured `only_json?`, so a request without a JSON body is not
  // an API call at all: it answers 400 as HTML instead of ending the session.
  it('sends a JSON request, the only kind Rodauth accepts', async () => {
    axios.post.mockResolvedValue({ data: { success: 'You have been logged out' } })
    const user = userEvent.setup()
    renderWithRouter(signedInRoutes, { route: '/dashboard' })

    await user.click(screen.getByRole('button', { name: /sign out/i }))

    await waitFor(() =>
      expect(axios.post).toHaveBeenCalledWith('/api/v1/logout', {}),
    )
  })

  it('sends one sign-out while the first is still in flight', async () => {
    axios.post.mockReturnValue(new Promise(() => {}))
    const user = userEvent.setup()
    const { router } = renderWithRouter(signedInRoutes, { route: '/dashboard' })

    await user.click(screen.getByRole('button', { name: /sign out/i }))

    await waitFor(() =>
      expect(screen.getByRole('button', { name: /sign out/i })).toBeDisabled(),
    )
    expect(axios.post).toHaveBeenCalledTimes(1)
    expect(router.state.location.pathname).toBe('/dashboard')
  })

  it('stays signed in and repeats what the API said when sign-out fails', async () => {
    axios.post.mockRejectedValue(
      rejection(401, { error: 'There was an error logging out' }),
    )
    const user = userEvent.setup()
    const { router } = renderWithRouter(signedInRoutes, { route: '/dashboard' })

    await user.click(screen.getByRole('button', { name: /sign out/i }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /there was an error logging out/i,
    )
    expect(router.state.location.pathname).toBe('/dashboard')
  })

  it('falls back to a generic message when the API says nothing useful', async () => {
    axios.post.mockRejectedValue(new Error('Network Error'))
    const user = userEvent.setup()
    renderWithRouter(signedInRoutes, { route: '/dashboard' })

    await user.click(screen.getByRole('button', { name: /sign out/i }))

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /could not sign out/i,
    )
  })
})
