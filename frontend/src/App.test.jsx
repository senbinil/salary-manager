import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import App from './App.jsx'

describe('App', () => {
  it('renders the getting started heading', () => {
    render(<App />)

    expect(
      screen.getByRole('heading', { name: /get started/i }),
    ).toBeInTheDocument()
  })

  it('starts the counter at zero', () => {
    render(<App />)

    expect(screen.getByRole('button', { name: /count is/i })).toHaveTextContent(
      'Count is 0',
    )
  })

  it('increments the counter when clicked', async () => {
    const user = userEvent.setup()
    render(<App />)

    await user.click(screen.getByRole('button', { name: /count is 0/i }))

    expect(screen.getByRole('button', { name: /count is 1/i })).toBeInTheDocument()
  })
})
