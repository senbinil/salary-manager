import { screen, within } from '@testing-library/react'
import { renderWithRouter } from '../test/render.jsx'
import RootLayout from './RootLayout.jsx'

function ChildPage() {
  return <p>page content</p>
}

const layoutRoutes = [
  {
    path: '/',
    Component: RootLayout,
    children: [{ index: true, Component: ChildPage }],
  },
]

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
