import axios from 'axios'
import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { renderWithRouter } from '../test/render.jsx'
import Home from './Home.jsx'

vi.mock('axios', () => ({
  default: { get: vi.fn() },
}))

const homeRoutes = [{ path: '/', Component: Home }]

const employees = [
  { id: 1, name: 'Ada Lovelace' },
  ...Array.from({ length: 19 }, (_, index) => ({
    id: index + 2,
    name: `Employee ${index + 2}`,
  })),
  { id: 21, name: 'Grace Hopper' },
  ...Array.from({ length: 5 }, (_, index) => ({
    id: index + 22,
    name: `Employee ${index + 22}`,
  })),
]

beforeEach(() => {
  axios.get.mockReset()
  axios.get.mockImplementation((url, { params = { page: 1, limit: 20 } } = {}) => {
    if (url !== '/api/v1/employees') {
      throw new Error(`Unexpected request: ${url}`)
    }

    const start = (params.page - 1) * params.limit
    const pageEmployees = employees.slice(start, start + params.limit)

    return Promise.resolve({
      data: {
        data: pageEmployees,
        pagination: {
          page: params.page,
          limit: params.limit,
          count: employees.length,
          pages: Math.ceil(employees.length / params.limit),
          from: pageEmployees.length > 0 ? start + 1 : null,
          to: start + pageEmployees.length,
          previous: params.page > 1 ? params.page - 1 : null,
          next: start + pageEmployees.length < employees.length ? params.page + 1 : null,
        },
      },
    })
  })
})

describe('Home employee dashboard', () => {
  it('shows employee names and requests the default first page', async () => {
    renderWithRouter(homeRoutes)

    const table = await screen.findByRole('table', { name: 'Employee list' })

    expect(screen.getByRole('heading', { level: 1, name: 'Employees' })).toBeInTheDocument()
    expect(screen.getByRole('columnheader', { name: 'Name' })).toBeInTheDocument()
    expect(screen.getByRole('row', { name: /Ada Lovelace/ })).toBeInTheDocument()
    expect(table).toBeInTheDocument()
    expect(axios.get).toHaveBeenCalledWith('/api/v1/employees', {
      params: { page: 1, limit: 20 },
    })
  })

  it('requests the next page when the user advances pagination', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.click(screen.getByRole('button', { name: 'Go to next page' }))

    expect(
      await screen.findByRole('row', { name: /Grace Hopper/ }),
    ).toBeInTheDocument()
    await waitFor(() => {
      expect(axios.get).toHaveBeenCalledWith('/api/v1/employees', {
        params: { page: 2, limit: 20 },
      })
    })
  })

  it('sends a selected page size and returns to the first page', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.click(screen.getByRole('button', { name: 'Go to next page' }))
    await screen.findByRole('row', { name: /Grace Hopper/ })

    await user.click(screen.getByRole('combobox'))
    expect(await screen.findByRole('option', { name: '100' })).toBeInTheDocument()
    await user.click(await screen.findByRole('option', { name: '50' }))

    await waitFor(() => {
      expect(axios.get).toHaveBeenCalledWith('/api/v1/employees', {
        params: { page: 1, limit: 50 },
      })
    })
    expect(
      await screen.findByRole('row', { name: /Ada Lovelace/ }),
    ).toBeInTheDocument()
  })
})
