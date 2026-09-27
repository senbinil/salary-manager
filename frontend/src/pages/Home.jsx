import Alert from '@mui/material/Alert'
import Chip from '@mui/material/Chip'
import CircularProgress from '@mui/material/CircularProgress'
import Link from '@mui/material/Link'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TablePagination from '@mui/material/TablePagination'
import TableRow from '@mui/material/TableRow'
import Typography from '@mui/material/Typography'
import { keepPreviousData, useQuery } from '@tanstack/react-query'
import axios from 'axios'
import { Link as RouterLink } from 'react-router'
import { useState } from 'react'
import { errorMessage } from '../api/errorMessage.js'
import { paths } from '../router/paths.js'

const FALLBACK_ERROR = 'Could not load employees'
const DEFAULT_LIMIT = 20
const LIMIT_OPTIONS = [10, DEFAULT_LIMIT, 50, 100]

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

/**
 * Shows employees' organizational roles and whether they have a current
 * active contract.
 */
export default function Home() {
  const [page, setPage] = useState(0)
  const [limit, setLimit] = useState(DEFAULT_LIMIT)

  const { data, isPending, error } = useQuery({
    queryKey: ['employees', page, limit],
    queryFn: async () => {
      const response = await axios.get('/api/v1/employees', {
        params: { page: page + 1, limit },
      })
      return response.data
    },
    placeholderData: keepPreviousData,
  })

  const employees = data?.data ?? []

  return (
    <Stack spacing={3}>
      <Typography variant="h4" component="h1">
        Employees
      </Typography>

      {isPending && (
        <Stack direction="row" spacing={1} role="status">
          <CircularProgress size={20} aria-label="Loading employees" />
          <Typography>Loading employees…</Typography>
        </Stack>
      )}

      {error && (
        <Alert severity="error">
          {errorMessage(error, FALLBACK_ERROR)}
        </Alert>
      )}

      {data && (
        <Paper variant="outlined">
          <TableContainer>
            <Table aria-label="Employee list" sx={{ minWidth: 1080 }}>
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Department</TableCell>
                  <TableCell>Designation</TableCell>
                  <TableCell>Contract country</TableCell>
                  <TableCell>Contract start date</TableCell>
                  <TableCell>Total compensation</TableCell>
                  <TableCell>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {employees.length > 0 ? (
                  employees.map((employee) => {
                    const isActive = employee.employment_status === 'active'

                    return (
                      <TableRow key={employee.id}>
                        <TableCell component="th" scope="row">
                          <Link
                            component={RouterLink}
                            to={paths.employeeDetailsFor(employee.id)}
                            underline="hover"
                          >
                            {employee.name}
                          </Link>
                        </TableCell>
                        <TableCell>{employee.department_name}</TableCell>
                        <TableCell>{employee.designation_name}</TableCell>
                        <TableCell>
                          {isActive ? employee.country_name || '—' : '—'}
                        </TableCell>
                        <TableCell>
                          {isActive ? employee.contract_start_date || '—' : '—'}
                        </TableCell>
                        <TableCell>
                          {isActive &&
                          employee.total_compensation !== null &&
                          employee.total_compensation !== undefined &&
                          employee.total_compensation_currency ? (
                            formatAmount(
                              employee.total_compensation,
                              employee.total_compensation_currency,
                            )
                          ) : (
                            '—'
                          )}
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={isActive ? 'Active' : 'Inactive'}
                            color={isActive ? 'success' : 'default'}
                            size="small"
                            variant={isActive ? 'filled' : 'outlined'}
                          />
                        </TableCell>
                      </TableRow>
                    )
                  })
                ) : (
                  <TableRow>
                    <TableCell colSpan={7}>No employees found.</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>

          <TablePagination
            component="div"
            count={data.pagination.count}
            page={page}
            onPageChange={(_event, nextPage) => setPage(nextPage)}
            rowsPerPage={limit}
            onRowsPerPageChange={(event) => {
              setLimit(Number.parseInt(event.target.value, 10))
              setPage(0)
            }}
            rowsPerPageOptions={LIMIT_OPTIONS}
            labelRowsPerPage="Rows per page:"
          />
        </Paper>
      )}
    </Stack>
  )
}
