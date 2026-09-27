import Alert from '@mui/material/Alert'
import Button from '@mui/material/Button'
import Chip from '@mui/material/Chip'
import CircularProgress from '@mui/material/CircularProgress'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TableRow from '@mui/material/TableRow'
import Typography from '@mui/material/Typography'
import { useQuery } from '@tanstack/react-query'
import axios from 'axios'
import { Link, useParams } from 'react-router'
import { errorMessage } from '../api/errorMessage.js'
import { paths } from '../router/paths.js'

const FALLBACK_ERROR = 'Could not load employee details'

function currentDate() {
  // Rails uses UTC by default; compare ISO dates without local-time conversion.
  return new Date().toISOString().slice(0, 10)
}

function selectContract(contracts, employeeStatus, asOfDate) {
  const activeContracts = contracts
    .filter(
      (contract) =>
        contract.start_date <= asOfDate &&
        (contract.end_date === null || contract.end_date >= asOfDate),
    )
    .sort((left, right) => right.start_date.localeCompare(left.start_date))

  if (activeContracts.length > 0) return activeContracts[0]
  if (employeeStatus === 'active') return null

  return (
    contracts
      .filter((contract) => contract.end_date && contract.end_date < asOfDate)
      .sort(
        (left, right) =>
          right.end_date.localeCompare(left.end_date) ||
          right.start_date.localeCompare(left.start_date),
      )[0] ?? null
  )
}

function formatAmount(amount, currency) {
  const numericAmount = Number(amount)
  if (!Number.isFinite(numericAmount)) return `${amount} ${currency}`

  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
    }).format(numericAmount)
  } catch {
    return `${amount} ${currency}`
  }
}

export default function EmployeeDetails() {
  const { employeeId } = useParams()

  const { data, isPending, error } = useQuery({
    queryKey: ['employee-contract-details', employeeId],
    queryFn: async () => {
      const [employeeResponse, contractsResponse, countriesResponse] =
        await Promise.all([
          axios.get(`/api/v1/employees/${employeeId}`),
          axios.get(`/api/v1/employees/${employeeId}/employment_contracts`),
          axios.get('/api/v1/countries'),
        ])

      const asOfDate = currentDate()
      const employee = employeeResponse.data

      return {
        employee,
        contract: selectContract(
          contractsResponse.data,
          employee.employment_status,
          asOfDate,
        ),
        countries: countriesResponse.data,
        asOfDate,
      }
    },
  })

  const contract = data?.contract
  const isActive =
    contract
      ? contract.start_date <= data.asOfDate &&
        (!contract.end_date || contract.end_date >= data.asOfDate)
      : data?.employee.employment_status === 'active'
  const countryName = contract
    ? data.countries.find((country) => country.code === contract.country_code)
        ?.name ?? contract.country_code
    : null

  return (
    <Stack spacing={3}>
      <Button
        component={Link}
        to={paths.dashboard}
        sx={{ alignSelf: 'flex-start' }}
        variant="text"
      >
        Back to employees
      </Button>

      {isPending && (
        <Stack direction="row" spacing={1} role="status">
          <CircularProgress size={20} aria-label="Loading employee details" />
          <Typography>Loading employee details…</Typography>
        </Stack>
      )}

      {error && <Alert severity="error">{errorMessage(error, FALLBACK_ERROR)}</Alert>}

      {data && (
        <>
          <Stack spacing={1}>
            <Typography variant="h4" component="h1">
              {data.employee.name}
            </Typography>
            <Typography color="text.secondary">
              {data.employee.department_name} · {data.employee.designation_name}
            </Typography>
            <Chip
              label={isActive ? 'Active' : 'Inactive'}
              color={isActive ? 'success' : 'default'}
              size="small"
              variant={isActive ? 'filled' : 'outlined'}
              sx={{ alignSelf: 'flex-start' }}
            />
          </Stack>

          {!contract ? (
            <Alert severity="info">
              {data.employee.employment_status === 'active'
                ? 'No current active contract found.'
                : 'No ended employment contract found.'}
            </Alert>
          ) : (
            <>
              <Paper variant="outlined" sx={{ p: 3 }}>
                <Stack spacing={2}>
                  <Typography variant="h5" component="h2">
                    Employment contract
                  </Typography>
                  <Typography>
                    <strong>Country:</strong> {countryName}
                  </Typography>
                  <Typography>
                    <strong>Start date:</strong> {contract.start_date}
                  </Typography>
                  <Typography>
                    <strong>End date:</strong> {contract.end_date ?? 'Ongoing'}
                  </Typography>
                  <Typography>
                    <strong>Currency:</strong> {contract.currency}
                  </Typography>
                </Stack>
              </Paper>

              <Paper variant="outlined" sx={{ p: 3 }}>
                <Stack spacing={2}>
                  <Typography variant="h5" component="h2">
                    Compensation · {contract.employee_compensation.compensation_plan.name}
                  </Typography>
                  <TableContainer>
                    <Table aria-label="Compensation components">
                      <TableHead>
                        <TableRow>
                          <TableCell>Component</TableCell>
                          <TableCell>Category</TableCell>
                          <TableCell align="right">Amount</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {contract.employee_compensation.components.length > 0 ? (
                          contract.employee_compensation.components.map(
                            (component) => (
                              <TableRow key={component.salary_component.id}>
                                <TableCell component="th" scope="row">
                                  {component.salary_component.name}
                                </TableCell>
                                <TableCell>
                                  {component.salary_component.category}
                                </TableCell>
                                <TableCell align="right">
                                  {formatAmount(component.amount, contract.currency)}
                                </TableCell>
                              </TableRow>
                            ),
                          )
                        ) : (
                          <TableRow>
                            <TableCell colSpan={3}>
                              No compensation components.
                            </TableCell>
                          </TableRow>
                        )}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </Stack>
              </Paper>
            </>
          )}
        </>
      )}
    </Stack>
  )
}
