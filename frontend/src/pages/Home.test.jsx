import axios from 'axios'
import { screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { renderWithRouter } from '../test/render.jsx'
import Home from './Home.jsx'

vi.mock('axios', () => ({
  default: { get: vi.fn() },
}))

const homeRoutes = [{ path: '/', Component: Home }]

const employee = (id, name, details = {}) => ({
  id,
  name,
  department_name: 'Engineering',
  designation_name: 'Software Engineer',
  employment_status: 'inactive',
  country_name: null,
  contract_start_date: null,
  ...details,
})

const employees = [
  employee(1, 'Ada Lovelace', {
    designation_name: 'Principal Engineer',
    employment_status: 'active',
    country_name: 'United States',
    contract_start_date: '2022-07-01',
  }),
  ...Array.from({ length: 19 }, (_, index) =>
    employee(index + 2, `Employee ${index + 2}`),
  ),
  employee(21, 'Grace Hopper', {
    department_name: 'Research',
    designation_name: 'Computer Scientist',
    employment_status: 'active',
    country_name: 'United States',
    contract_start_date: '2020-05-01',
  }),
  ...Array.from({ length: 5 }, (_, index) =>
    employee(index + 22, `Employee ${index + 22}`),
  ),
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
  it('shows employee details and requests the default first page', async () => {
    renderWithRouter(homeRoutes)

    const table = await screen.findByRole('table', { name: 'Employee list' })

    expect(screen.getByRole('heading', { level: 1, name: 'Employees' })).toBeInTheDocument()
    expect(
      within(table).getAllByRole('columnheader').map((header) => header.textContent),
    ).toEqual([
      'Name',
      'Department',
      'Designation',
      'Contract country',
      'Contract start date',
      'Status',
    ])

    const activeRow = screen.getByRole('row', { name: /Ada Lovelace/ })
    expect(
      within(activeRow).getByRole('link', { name: 'Ada Lovelace' }),
    ).toHaveAttribute('href', '/employees/1')
    expect(within(activeRow).getByText('Engineering')).toBeInTheDocument()
    expect(within(activeRow).getByText('Principal Engineer')).toBeInTheDocument()
    expect(within(activeRow).getByText('Active')).toBeInTheDocument()
    expect(within(activeRow).getByText('United States')).toBeInTheDocument()
    expect(within(activeRow).getByText('2022-07-01')).toBeInTheDocument()

    const inactiveRow = screen.getByRole('row', { name: /^Employee 2 / })
    expect(within(inactiveRow).getByText('Inactive')).toBeInTheDocument()
    expect(within(inactiveRow).getAllByText('—')).toHaveLength(2)
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
