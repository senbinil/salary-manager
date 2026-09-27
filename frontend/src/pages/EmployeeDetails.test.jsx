import axios from 'axios'
import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { renderWithRouter } from '../test/render.jsx'
import { routes } from '../router/routes.js'

vi.mock('axios', () => ({
  default: { get: vi.fn() },
}))

const dateOffset = (days) => {
  const date = new Date()
  date.setUTCHours(0, 0, 0, 0)
  date.setUTCDate(date.getUTCDate() + days)
  return date.toISOString().slice(0, 10)
}

const makeEmployee = (id, name, employmentStatus, totalCompensation = null) => ({
  id,
  name,
  department_id: 1,
  department_name: 'Engineering',
  designation_id: 1,
  designation_name: 'Software Engineer',
  user_id: null,
  employment_status: employmentStatus,
  country_name: null,
  contract_start_date: null,
  total_compensation: totalCompensation,
})

const makeContract = ({
  id,
  startOffset,
  endOffset,
  countryCode = 'IN',
  currency = 'INR',
  planName,
  componentName,
}) => ({
  id,
  employee_id: 7,
  country_code: countryCode,
  currency,
  compensation_plan_id: id,
  start_date: dateOffset(startOffset),
  end_date: endOffset === null ? null : dateOffset(endOffset),
  employee_compensation: {
    id,
    compensation_plan: { id, name: planName },
    components: [
      {
        amount: '1250.7500',
        salary_component: { id, name: componentName, category: 'earning' },
      },
    ],
  },
})

const countryList = [{ code: 'IN', name: 'India', currency: 'INR' }]

function mockEmployeeApi(employee, contracts, employees = [employee]) {
  axios.get.mockReset()
  axios.get.mockImplementation((url, { params } = {}) => {
    if (url === '/api/v1/me') {
      return Promise.resolve({ data: { id: 1, email: 'person@example.com' } })
    }

    if (url === '/api/v1/employees') {
      return Promise.resolve({
        data: {
          data: employees,
          pagination: {
            page: params?.page ?? 1,
            limit: params?.limit ?? 20,
            count: employees.length,
            pages: 1,
            from: employees.length > 0 ? 1 : null,
            to: employees.length,
          },
        },
      })
    }

    if (url === `/api/v1/employees/${employee.id}`) {
      return Promise.resolve({ data: employee })
    }

    if (url === `/api/v1/employees/${employee.id}/employment_contracts`) {
      return Promise.resolve({ data: contracts })
    }

    if (url === '/api/v1/countries') {
      return Promise.resolve({ data: countryList })
    }

    throw new Error(`Unexpected request: ${url}`)
  })
}

describe('Employee contract drill-down', () => {
  beforeEach(() => {
    axios.get.mockReset()
  })

  it('opens the active contract from the dashboard and ignores past and future contracts', async () => {
    const employee = makeEmployee(7, 'Ada Lovelace', 'active', '1250.7500')
    const contracts = [
      makeContract({
        id: 1,
        startOffset: -100,
        endOffset: -10,
        planName: 'Old plan',
        componentName: 'Old salary',
      }),
      makeContract({
        id: 2,
        startOffset: -30,
        endOffset: 0,
        planName: 'Current plan',
        componentName: 'Current salary',
      }),
      makeContract({
        id: 3,
        startOffset: 30,
        endOffset: null,
        planName: 'Future plan',
        componentName: 'Future salary',
      }),
    ]
    mockEmployeeApi(employee, contracts)

    const user = userEvent.setup()
    renderWithRouter(routes, { route: '/dashboard' })

    await user.click(await screen.findByRole('link', { name: 'Ada Lovelace' }))

    expect(
      await screen.findByRole('heading', { level: 1, name: 'Ada Lovelace' }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', { name: /Current plan/ }),
    ).toBeInTheDocument()
    expect(screen.getByText('Current salary')).toBeInTheDocument()
    expect(screen.getByText('Current salary')).toHaveStyle({ fontWeight: '700' })
    expect(screen.getByText(dateOffset(-30))).toBeInTheDocument()
    expect(screen.getByText(dateOffset(0))).toBeInTheDocument()
    expect(screen.getByText('earning')).toBeInTheDocument()
    expect(screen.getByText('India')).toBeInTheDocument()
    expect(screen.getByText('India')).toHaveStyle({ fontWeight: '700' })
    const formattedAmounts = screen.getAllByText(/1,250\.75/)
    expect(formattedAmounts).toHaveLength(2)
    expect(formattedAmounts[0]).toHaveStyle({ textAlign: 'right' })
    expect(screen.getByText('Total compensation')).toBeInTheDocument()
    expect(screen.getByText('Total compensation').parentElement).toHaveTextContent(
      '₹1,250.75',
    )
    expect(screen.getByText('Active')).toBeInTheDocument()
    expect(screen.queryByText('Old salary')).not.toBeInTheDocument()
    expect(screen.queryByText('Future salary')).not.toBeInTheDocument()
  })

  it('shows the most recently ended contract for an inactive employee', async () => {
    const employee = makeEmployee(7, 'Ada Lovelace', 'inactive')
    const contracts = [
      makeContract({
        id: 1,
        startOffset: -180,
        endOffset: -60,
        planName: 'Earlier plan',
        componentName: 'Earlier salary',
      }),
      makeContract({
        id: 2,
        startOffset: -30,
        endOffset: -2,
        planName: 'Latest ended plan',
        componentName: 'Latest ended salary',
      }),
      makeContract({
        id: 3,
        startOffset: 30,
        endOffset: null,
        planName: 'Future plan',
        componentName: 'Future salary',
      }),
    ]
    mockEmployeeApi(employee, contracts)

    renderWithRouter(routes, { route: '/employees/7' })

    expect(
      await screen.findByRole('heading', { level: 1, name: 'Ada Lovelace' }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole('heading', { name: /Latest ended plan/ }),
    ).toBeInTheDocument()
    expect(screen.getByText('Latest ended salary')).toBeInTheDocument()
    expect(screen.getByText('Inactive')).toBeInTheDocument()
    expect(screen.queryByText('Total compensation')).not.toBeInTheDocument()
    expect(screen.queryByText('Earlier salary')).not.toBeInTheDocument()
    expect(screen.queryByText('Future salary')).not.toBeInTheDocument()
  })

  it('shows an empty state when an inactive employee has no ended contract', async () => {
    const employee = makeEmployee(7, 'Ada Lovelace', 'inactive')
    const futureContract = makeContract({
      id: 3,
      startOffset: 30,
      endOffset: null,
      planName: 'Future plan',
      componentName: 'Future salary',
    })
    mockEmployeeApi(employee, [futureContract])

    renderWithRouter(routes, { route: '/employees/7' })

    expect(
      await screen.findByText('No ended employment contract found.'),
    ).toBeInTheDocument()
    expect(screen.queryByText('Future salary')).not.toBeInTheDocument()
    expect(
      screen.getByRole('link', { name: 'Back to employees' }),
    ).toHaveAttribute('href', '/dashboard')
  })

  it('shows a loading state while employee details are being fetched', async () => {
    axios.get.mockImplementation((url) => {
      if (url === '/api/v1/me') {
        return Promise.resolve({ data: { id: 1, email: 'person@example.com' } })
      }

      return new Promise(() => {})
    })

    renderWithRouter(routes, { route: '/employees/7' })

    expect(await screen.findByRole('status')).toHaveTextContent(
      'Loading employee details…',
    )
  })

  it('shows the API error when the employee does not exist', async () => {
    axios.get.mockImplementation((url) => {
      if (url === '/api/v1/me') {
        return Promise.resolve({ data: { id: 1, email: 'person@example.com' } })
      }

      if (url === '/api/v1/employees/404') {
        return Promise.reject({
          response: { status: 404, data: { error: 'Employee not found' } },
        })
      }

      if (url === '/api/v1/employees/404/employment_contracts') {
        return Promise.resolve({ data: [] })
      }

      if (url === '/api/v1/countries') {
        return Promise.resolve({ data: countryList })
      }

      throw new Error(`Unexpected request: ${url}`)
    })

    renderWithRouter(routes, { route: '/employees/404' })

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Employee not found',
    )
    expect(
      screen.getByRole('link', { name: 'Back to employees' }),
    ).toHaveAttribute('href', '/dashboard')
  })
})
