import axios from 'axios'
import { screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { renderWithRouter } from '../test/render.jsx'
import Home from './Home.jsx'

vi.mock('axios', () => ({
  default: { get: vi.fn() },
}))

const homeRoutes = [{ path: '/', Component: Home }]

beforeEach(() => {
  axios.get.mockResolvedValue({
    data: {
      data: [
        {
          id: 1,
          name: 'Ada Lovelace',
          department_id: 3,
          designation_id: 5,
          user_id: null,
        },
        {
          id: 2,
          name: 'Grace Hopper',
          department_id: 4,
          designation_id: 6,
          user_id: null,
        },
      ],
      pagination: {
        page: 1,
        limit: 20,
        count: 2,
        pages: 1,
        from: 1,
        to: 2,
        previous: null,
        next: null,
      },
    },
  })
})

describe('Home employee dashboard', () => {
  it('shows employees in a table with their names', async () => {
    renderWithRouter(homeRoutes)

    expect(
      await screen.findByRole('heading', { level: 1, name: 'Employees' }),
    ).toBeInTheDocument()

    const table = await screen.findByRole('table', { name: 'Employee list' })
    expect(screen.getByRole('columnheader', { name: 'Name' })).toBeInTheDocument()
    expect(screen.getByRole('row', { name: /Ada Lovelace/ })).toBeInTheDocument()
    expect(screen.getByRole('row', { name: /Grace Hopper/ })).toBeInTheDocument()
    expect(table).toBeInTheDocument()
  })

  it('loads employee data from the employee list endpoint', async () => {
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })

    expect(axios.get).toHaveBeenCalledWith('/api/v1/employees')
  })
})
