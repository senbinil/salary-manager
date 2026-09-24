import { screen } from '@testing-library/react'
import { renderWithRouter } from '../test/render.jsx'
import NotFound from './NotFound.jsx'

const notFoundRoutes = [{ path: '*', Component: NotFound }]

describe('NotFound', () => {
  it('explains that the page is missing', () => {
    renderWithRouter(notFoundRoutes, { route: '/missing' })

    expect(
      screen.getByRole('heading', { level: 1, name: /page not found/i }),
    ).toBeInTheDocument()
  })

  it('links back to the sign-in page', () => {
    renderWithRouter(notFoundRoutes, { route: '/missing' })

    expect(
      screen.getByRole('link', { name: /back to sign in/i }),
    ).toHaveAttribute('href', '/')
  })
})
