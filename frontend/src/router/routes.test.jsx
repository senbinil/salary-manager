import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderWithRouter } from '../test/render.jsx'
import { routes } from './routes.js'

describe('routes', () => {
  it('serves the sign-in page at the root path', () => {
    renderWithRouter(routes)

    expect(
      screen.getByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
  })

  it('keeps the sign-in page outside the app shell', () => {
    renderWithRouter(routes)

    expect(screen.queryByRole('banner')).not.toBeInTheDocument()
  })

  it('wraps the home page in the app shell at /dashboard', () => {
    renderWithRouter(routes, { route: '/dashboard' })

    expect(screen.getByRole('banner')).toBeInTheDocument()
    expect(screen.getByRole('main')).toBeInTheDocument()
    expect(
      screen.getByRole('heading', { level: 1, name: /salary management/i }),
    ).toBeInTheDocument()
  })

  it('renders the not-found page for an unknown path', () => {
    renderWithRouter(routes, { route: '/unknown' })

    expect(
      screen.getByRole('heading', { level: 1, name: /page not found/i }),
    ).toBeInTheDocument()
  })

  it('keeps the app shell around the not-found page', () => {
    renderWithRouter(routes, { route: '/unknown' })

    expect(screen.getByRole('banner')).toBeInTheDocument()
    expect(screen.getByRole('main')).toBeInTheDocument()
  })

  it('returns to the sign-in page from the not-found page', async () => {
    const user = userEvent.setup()
    const { router } = renderWithRouter(routes, { route: '/unknown' })

    await user.click(screen.getByRole('link', { name: /back to sign in/i }))

    expect(router.state.location.pathname).toBe('/')
    expect(
      screen.getByRole('heading', { level: 1, name: /sign in/i }),
    ).toBeInTheDocument()
  })
})
