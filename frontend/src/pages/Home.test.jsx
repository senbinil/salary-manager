import { screen } from '@testing-library/react'
import { renderWithRouter } from '../test/render.jsx'
import Home from './Home.jsx'

const homeRoutes = [{ path: '/', Component: Home }]

describe('Home', () => {
  it('introduces the page with a top-level heading', () => {
    renderWithRouter(homeRoutes)

    expect(
      screen.getByRole('heading', { level: 1, name: /salary management/i }),
    ).toBeInTheDocument()
  })

  it('describes what the page will hold', () => {
    renderWithRouter(homeRoutes)

    expect(screen.getByText(/payroll/i)).toBeInTheDocument()
  })
})
