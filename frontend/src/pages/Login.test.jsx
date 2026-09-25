import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import axios from 'axios'
import { renderWithRouter } from '../test/render.jsx'
import Login from './Login.jsx'

// axios is the system boundary, so stubbing it is how these tests see what the
// form sends and feed failures back without standing up a server.
vi.mock('axios', () => ({ default: { post: vi.fn() } }))

function DashboardStub() {
  return <h1>Salary management</h1>
}

const loginRoutes = [
  { path: '/', Component: Login },
  { path: '/dashboard', Component: DashboardStub },
]

/** Fill the form and submit it. Pass an empty string to leave a field blank. */
async function signIn({
  email = 'person@example.com',
  password = 'secret123',
} = {}) {
  const user = userEvent.setup()

  if (email) await user.type(screen.getByLabelText(/email/i), email)
  if (password) await user.type(screen.getByLabelText(/^password/i), password)

  await user.click(screen.getByRole('button', { name: /sign in/i }))

  return user
}

/** What axios rejects with when the API answers with an error body. */
function rejection(status, data) {
  return { response: { status, data } }
}

describe('Login', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('asks for an email address and a password', () => {
    renderWithRouter(loginRoutes)

    expect(
      screen.getByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/^password/i)).toBeInTheDocument()
  })

  it('will not submit an empty form', async () => {
    renderWithRouter(loginRoutes)

    await signIn({ email: '', password: '' })

    expect(await screen.findByText(/email is required/i)).toBeInTheDocument()
    expect(screen.getByText(/password is required/i)).toBeInTheDocument()
    expect(axios.post).not.toHaveBeenCalled()
  })

  it('will not submit while the password is missing', async () => {
    renderWithRouter(loginRoutes)

    await signIn({ password: '' })

    expect(await screen.findByText(/password is required/i)).toBeInTheDocument()
    expect(screen.queryByText(/email is required/i)).not.toBeInTheDocument()
    expect(axios.post).not.toHaveBeenCalled()
  })

  it('submits the credentials to the API', async () => {
    axios.post.mockResolvedValue({ data: { success: 'You have been logged in' } })
    renderWithRouter(loginRoutes)

    await signIn()

    await waitFor(() =>
      expect(axios.post).toHaveBeenCalledWith('/api/v1/login', {
        email: 'person@example.com',
        password: 'secret123',
      }),
    )
  })

  it('moves to the dashboard once signed in', async () => {
    axios.post.mockResolvedValue({ data: { success: 'You have been logged in' } })
    const { router } = renderWithRouter(loginRoutes)

    await signIn()

    await waitFor(() => expect(router.state.location.pathname).toBe('/dashboard'))
  })

  it('stays on the form when the API rejects the credentials', async () => {
    axios.post.mockRejectedValue(rejection(401, { error: 'invalid credentials' }))
    const { router } = renderWithRouter(loginRoutes)

    await signIn()

    expect(await screen.findByRole('alert')).toBeInTheDocument()
    expect(router.state.location.pathname).toBe('/')
  })

  it('shows the message the API sent', async () => {
    axios.post.mockRejectedValue(
      rejection(401, { error: 'There was an error logging in' }),
    )
    renderWithRouter(loginRoutes)

    await signIn()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /there was an error logging in/i,
    )
  })

  it('joins every message the API sent', async () => {
    axios.post.mockRejectedValue(
      rejection(401, {
        error: 'There was an error logging in',
        'field-error': ['password', 'invalid password'],
      }),
    )
    renderWithRouter(loginRoutes)

    await signIn()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /there was an error logging in invalid password/i,
    )
  })

  it('falls back to a generic message when the API says nothing useful', async () => {
    axios.post.mockRejectedValue(new Error('Network Error'))
    renderWithRouter(loginRoutes)

    await signIn()

    expect(await screen.findByRole('alert')).toHaveTextContent(
      /invalid credentials/i,
    )
  })

  it('disables the button while the request is in flight', async () => {
    axios.post.mockReturnValue(new Promise(() => {}))
    renderWithRouter(loginRoutes)

    await signIn()

    await waitFor(() =>
      expect(screen.getByRole('button', { name: /sign in/i })).toBeDisabled(),
    )
  })

  it('lets a retry through after a failure', async () => {
    axios.post.mockRejectedValueOnce(
      rejection(401, { error: 'invalid credentials' }),
    )
    axios.post.mockResolvedValueOnce({
      data: { success: 'You have been logged in' },
    })
    const { router } = renderWithRouter(loginRoutes)

    const user = await signIn()
    expect(await screen.findByRole('alert')).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: /sign in/i }))

    await waitFor(() => expect(router.state.location.pathname).toBe('/dashboard'))
  })

  // The password starts masked and the toggle is the only way to read it back.
  // The button's name says what the next click does, so it flips with the state.
  describe('password visibility', () => {
    it('keeps the password masked until the toggle is used', async () => {
      renderWithRouter(loginRoutes)

      const user = userEvent.setup()

      expect(screen.getByLabelText(/^password/i)).toHaveAttribute(
        'type',
        'password',
      )

      await user.click(screen.getByRole('button', { name: /show password/i }))

      expect(screen.getByLabelText(/^password/i)).toHaveAttribute(
        'type',
        'text',
      )
      expect(
        screen.getByRole('button', { name: /hide password/i }),
      ).toBeInTheDocument()
    })

    it('masks the password again when toggled back', async () => {
      renderWithRouter(loginRoutes)

      const user = userEvent.setup()
      await user.click(screen.getByRole('button', { name: /show password/i }))
      await user.click(screen.getByRole('button', { name: /hide password/i }))

      expect(screen.getByLabelText(/^password/i)).toHaveAttribute(
        'type',
        'password',
      )
      expect(
        screen.getByRole('button', { name: /show password/i }),
      ).toBeInTheDocument()
    })
  })
})
