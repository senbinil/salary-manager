import axios from 'axios'
import { fireEvent, screen, waitFor, within } from '@testing-library/react'
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
  total_compensation: null,
  total_compensation_currency: null,
  ...details,
})

const employees = [
  employee(1, 'Ada Lovelace', {
    designation_name: 'Principal Engineer',
    employment_status: 'active',
    country_name: 'United States',
    contract_start_date: '2022-07-01',
    total_compensation: '10250.3750',
    total_compensation_currency: 'USD',
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

const filterOptions = {
  departments: [
    { id: 1, name: 'Engineering' },
    { id: 2, name: 'Research' },
  ],
  designations: [
    { id: 1, name: 'Software Engineer' },
    { id: 2, name: 'Computer Scientist' },
  ],
  countries: [
    { code: 'US', name: 'United States', currency: 'USD' },
    { code: 'IN', name: 'India', currency: 'INR' },
  ],
}

// The overview is its own request, so an example can point it at a different
// payload (or a failure) without disturbing the employee list.
const dashboardSummary = {
  total_active_employees: 12,
  country_totals: [
    {
      country_code: 'CA',
      country_name: 'Canada',
      currency: 'CAD',
      employee_count: 5,
      total_compensation: '250000.0000',
    },
    {
      country_code: 'US',
      country_name: 'United States',
      currency: 'USD',
      employee_count: 7,
      total_compensation: '10250.3750',
    },
  ],
}

let summaryData
let summaryError

beforeEach(() => {
  summaryData = dashboardSummary
  summaryError = null
  axios.get.mockReset()
  axios.get.mockImplementation((url, { params = { page: 1, limit: 20 } } = {}) => {
    if (url === '/api/v1/departments') {
      return Promise.resolve({ data: filterOptions.departments })
    }
    if (url === '/api/v1/designations') {
      return Promise.resolve({ data: filterOptions.designations })
    }
    if (url === '/api/v1/countries') {
      return Promise.resolve({ data: filterOptions.countries })
    }
    if (url === '/api/v1/dashboard/summary') {
      return summaryError
        ? Promise.reject(summaryError)
        : Promise.resolve({ data: summaryData })
    }
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

    expect(screen.getByRole('heading', { level: 1, name: 'Dashboard' })).toBeInTheDocument()
    expect(
      within(table).getAllByRole('columnheader').map((header) => header.textContent),
    ).toEqual([
      'Name',
      'Department',
      'Designation',
      'Contract country',
      'Contract start date',
      'Total compensation',
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
    expect(
      within(activeRow).getByText(
        new Intl.NumberFormat(undefined, {
          style: 'currency',
          currency: 'USD',
        }).format(Number('10250.3750')),
      ),
    ).toBeInTheDocument()

    const inactiveRow = screen.getByRole('row', { name: /^Employee 2 / })
    expect(within(inactiveRow).getByText('Inactive')).toBeInTheDocument()
    expect(within(inactiveRow).getAllByText('—')).toHaveLength(3)
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

  it('filters by employment status and requests the first page', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.click(screen.getByRole('combobox', { name: 'Status' }))
    await user.click(screen.getByRole('option', { name: 'Inactive' }))

    await waitFor(() => {
      expect(axios.get).toHaveBeenLastCalledWith('/api/v1/employees', {
        params: { page: 1, limit: 20, filter: { employment_status: 'inactive' } },
      })
    })
  })

  it('sends the name and dropdown filters and returns to the first page', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.type(screen.getByLabelText('Name'), 'ada')
    await user.click(screen.getByRole('combobox', { name: 'Department' }))
    await user.click(screen.getByRole('option', { name: 'Research' }))
    await user.click(screen.getByRole('combobox', { name: 'Designation' }))
    await user.click(screen.getByRole('option', { name: 'Computer Scientist' }))
    await user.click(screen.getByRole('combobox', { name: 'Country' }))
    await user.click(screen.getByRole('option', { name: 'India' }))

    await waitFor(() => {
      expect(axios.get).toHaveBeenLastCalledWith('/api/v1/employees', {
        params: {
          page: 1,
          limit: 20,
          filter: {
            name_cont: 'ada',
            department_id: '2',
            designation_id: '2',
            country_code: 'IN',
          },
        },
      })
    })
  })

  it('keeps spaces in the name field and trims them from the request', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.type(screen.getByLabelText('Name'), 'ada lovelace')

    expect(screen.getByLabelText('Name')).toHaveValue('ada lovelace')

    await user.type(screen.getByLabelText('Name'), ' ')

    expect(screen.getByLabelText('Name')).toHaveValue('ada lovelace ')
    await waitFor(() => {
      expect(axios.get).toHaveBeenLastCalledWith('/api/v1/employees', {
        params: { page: 1, limit: 20, filter: { name_cont: 'ada lovelace' } },
      })
    })
  })

  it('clears the filters and requests the unfiltered first page', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.type(screen.getByLabelText('Name'), 'ada')

    await waitFor(() => {
      expect(axios.get).toHaveBeenLastCalledWith('/api/v1/employees', {
        params: { page: 1, limit: 20, filter: { name_cont: 'ada' } },
      })
    })

    await user.click(screen.getByRole('button', { name: 'Clear filters' }))

    await waitFor(() => {
      expect(axios.get).toHaveBeenLastCalledWith('/api/v1/employees', {
        params: { page: 1, limit: 20 },
      })
    })
    expect(screen.getByLabelText('Name')).toHaveValue('')
  })

  it('sends a selected page size and returns to the first page', async () => {
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    await screen.findByRole('row', { name: /Ada Lovelace/ })
    await user.click(screen.getByRole('button', { name: 'Go to next page' }))
    await screen.findByRole('row', { name: /Grace Hopper/ })

    await user.click(screen.getByRole('combobox', { name: /rows per page/i }))
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

describe('Home dashboard overview', () => {
  const formatCount = (count) => new Intl.NumberFormat().format(count)
  const formatWholeCurrency = (amount, currency) =>
    new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(Number(amount))

  // jsdom does no layout, so a strip reports no width and every button starts
  // inert. Give it a scrollable width so the paging buttons become usable.
  function makeScrollable(strip) {
    Object.defineProperty(strip, 'scrollWidth', { configurable: true, value: 1000 })
    Object.defineProperty(strip, 'clientWidth', { configurable: true, value: 400 })
  }

  it('badges each strip with its own count', async () => {
    renderWithRouter(homeRoutes)

    expect(
      await screen.findByText(`${formatCount(12)} Total Active Personnel`),
    ).toBeInTheDocument()
    expect(screen.getByText(`${formatCount(2)} Countries`)).toBeInTheDocument()
  })

  it('shows one card per country with its native compensation total', async () => {
    renderWithRouter(homeRoutes)

    const strip = await screen.findByRole('group', {
      name: 'Expense by Country cards',
    })

    expect(within(strip).getByText('Canada')).toBeInTheDocument()
    expect(within(strip).getByText('ca · CAD')).toBeInTheDocument()
    expect(
      within(strip).getByText(formatWholeCurrency('250000.0000', 'CAD')),
    ).toBeInTheDocument()
    expect(within(strip).getByText('United States')).toBeInTheDocument()
    expect(within(strip).getByText('us · USD')).toBeInTheDocument()
    expect(
      within(strip).getByText(formatWholeCurrency('10250.3750', 'USD')),
    ).toBeInTheDocument()
  })

  it('shows one card per country with its employee count', async () => {
    renderWithRouter(homeRoutes)

    const strip = await screen.findByRole('group', {
      name: 'Employees by Country cards',
    })

    expect(within(strip).getAllByText('Employees')).toHaveLength(2)
    expect(within(strip).getByText(formatCount(5))).toBeInTheDocument()
    expect(within(strip).getByText(formatCount(7))).toBeInTheDocument()
  })

  it('keeps the strip buttons inert until there is something to scroll', async () => {
    renderWithRouter(homeRoutes)

    expect(
      await screen.findByRole('button', {
        name: 'Scroll forward through Expense by Country',
      }),
    ).toBeDisabled()
    expect(
      screen.getByRole('button', { name: 'Scroll back through Expense by Country' }),
    ).toBeDisabled()
  })

  it('pages one card per press once the strip overflows', async () => {
    const scrollBy = vi.fn()
    Element.prototype.scrollBy = scrollBy
    const user = userEvent.setup()
    renderWithRouter(homeRoutes)

    const strip = await screen.findByRole('group', {
      name: 'Expense by Country cards',
    })
    makeScrollable(strip)
    fireEvent.scroll(strip)

    const forward = screen.getByRole('button', {
      name: 'Scroll forward through Expense by Country',
    })
    expect(forward).toBeEnabled()
    await user.click(forward)

    // One card plus the gap between cards.
    expect(scrollBy).toHaveBeenCalledWith({ left: 236, behavior: 'smooth' })
  })

  it('reports an overview failure without hiding the employee list', async () => {
    summaryError = Object.assign(new Error('Request failed'), {
      response: { data: { error: 'Overview unavailable' } },
    })
    renderWithRouter(homeRoutes)

    expect(await screen.findByText('Overview unavailable')).toBeInTheDocument()
    expect(screen.getByRole('table', { name: 'Employee list' })).toBeInTheDocument()
    expect(screen.getByText('Ada Lovelace')).toBeInTheDocument()
  })

  it('shows an empty overview when no employee is active', async () => {
    summaryData = { total_active_employees: 0, country_totals: [] }
    renderWithRouter(homeRoutes)

    expect(
      await screen.findByText(`${formatCount(0)} Total Active Personnel`),
    ).toBeInTheDocument()
    expect(screen.getByText(`${formatCount(0)} Countries`)).toBeInTheDocument()
    const expense = screen.getByRole('group', { name: 'Expense by Country cards' })
    const headcount = screen.getByRole('group', {
      name: 'Employees by Country cards',
    })
    expect(within(expense).getByText('No active employees')).toBeInTheDocument()
    expect(within(headcount).getByText('No active employees')).toBeInTheDocument()
  })
})
