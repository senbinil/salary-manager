import Alert from '@mui/material/Alert'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import Chip from '@mui/material/Chip'
import CircularProgress from '@mui/material/CircularProgress'
import Divider from '@mui/material/Divider'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
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
          <Stack
            direction={{ xs: 'column', sm: 'row' }}
            spacing={2}
            sx={{
              justifyContent: 'space-between',
              alignItems: { xs: 'flex-start', sm: 'center' },
            }}
          >
            <Stack spacing={0.5}>
              <Typography variant="h4" component="h1">
                {data.employee.name}
              </Typography>
              <Typography color="text.secondary">
                {data.employee.department_name} · {data.employee.designation_name}
              </Typography>
            </Stack>
            <Chip
              label={isActive ? 'Active' : 'Inactive'}
              color={isActive ? 'success' : 'default'}
              size="small"
              variant={isActive ? 'filled' : 'outlined'}
            />
          </Stack>

          {!contract ? (
            <Alert severity="info">
              {data.employee.employment_status === 'active'
                ? 'No current active contract found.'
                : 'No ended employment contract found.'}
            </Alert>
          ) : (
            <Stack
              direction={{ xs: 'column', md: 'row' }}
              spacing={3}
            >
              <Paper
                component="section"
                aria-labelledby="contract-information-heading"
                variant="outlined"
                sx={{ p: { xs: 2, sm: 3 }, flex: { md: '1 1 0' }, minWidth: 0 }}
              >
                <Stack spacing={2.5}>
                  <Stack spacing={0.5}>
                    <Typography variant="overline" color="text.secondary">
                      Employment
                    </Typography>
                    <Typography
                      variant="h5"
                      component="h2"
                      id="contract-information-heading"
                    >
                      Contract information
                    </Typography>
                  </Stack>
                  <Divider />
                  <Box
                    sx={{
                      display: 'grid',
                      gridTemplateColumns: {
                        xs: '1fr',
                        sm: 'repeat(2, minmax(0, 1fr))',
                      },
                      gap: 2.5,
                    }}
                  >
                    <Stack spacing={0.5}>
                      <Typography variant="body2" color="text.secondary">
                        Country
                      </Typography>
                      <Typography sx={{ fontWeight: 700 }}>
                        {countryName}
                      </Typography>
                    </Stack>
                    <Stack spacing={0.5}>
                      <Typography variant="body2" color="text.secondary">
                        Start date
                      </Typography>
                      <Typography sx={{ fontWeight: 700 }}>
                        {contract.start_date}
                      </Typography>
                    </Stack>
                    <Stack spacing={0.5}>
                      <Typography variant="body2" color="text.secondary">
                        End date
                      </Typography>
                      <Typography sx={{ fontWeight: 700 }}>
                        {contract.end_date ?? 'Ongoing'}
                      </Typography>
                    </Stack>
                    <Stack spacing={0.5}>
                      <Typography variant="body2" color="text.secondary">
                        Currency
                      </Typography>
                      <Typography sx={{ fontWeight: 700 }}>
                        {contract.currency}
                      </Typography>
                    </Stack>
                  </Box>
                </Stack>
              </Paper>

              <Paper
                component="section"
                aria-labelledby="compensation-heading"
                variant="outlined"
                sx={{ p: { xs: 2, sm: 3 }, flex: { md: '1 1 0' }, minWidth: 0 }}
              >
                <Stack spacing={2.5}>
                  <Stack spacing={0.5}>
                    <Typography variant="overline" color="text.secondary">
                      Compensation plan
                    </Typography>
                    <Typography
                      variant="h5"
                      component="h2"
                      id="compensation-heading"
                    >
                      {contract.employee_compensation.compensation_plan.name}
                    </Typography>
                  </Stack>
                  <Divider />
                  {contract.employee_compensation.components.length > 0 ? (
                    <Stack divider={<Divider flexItem />} spacing={1.5}>
                      {contract.employee_compensation.components.map(
                        (component) => (
                          <Box
                            key={component.salary_component.id}
                            sx={{
                              display: 'grid',
                              gridTemplateColumns: 'minmax(0, 1fr) max-content',
                              columnGap: 2,
                              alignItems: 'start',
                            }}
                          >
                            <Stack spacing={0.25} sx={{ minWidth: 0 }}>
                              <Typography sx={{ fontWeight: 700 }}>
                                {component.salary_component.name}
                              </Typography>
                              <Chip
                                label={component.salary_component.category}
                                size="small"
                                variant="outlined"
                                sx={{
                                  alignSelf: 'flex-start',
                                  textTransform: 'capitalize',
                                }}
                              />
                            </Stack>
                            <Typography
                              fontWeight={600}
                              sx={{ textAlign: 'right', whiteSpace: 'nowrap' }}
                            >
                              {formatAmount(component.amount, contract.currency)}
                            </Typography>
                          </Box>
                        ),
                      )}
                    </Stack>
                  ) : (
                    <Typography color="text.secondary">
                      No compensation components.
                    </Typography>
                  )}
                  {isActive &&
                    data.employee.total_compensation !== null &&
                    data.employee.total_compensation !== undefined && (
                      <>
                        <Divider />
                        <Box
                          sx={{
                            display: 'flex',
                            justifyContent: 'space-between',
                            alignItems: 'center',
                            gap: 2,
                          }}
                        >
                          <Typography sx={{ fontWeight: 700 }}>
                            Total compensation
                          </Typography>
                          <Typography
                            sx={{
                              fontWeight: 700,
                              textAlign: 'right',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            {formatAmount(
                              data.employee.total_compensation,
                              contract.currency,
                            )}
                          </Typography>
                        </Box>
                      </>
                    )}
                </Stack>
              </Paper>
            </Stack>
          )}
        </>
      )}
    </Stack>
  )
}
