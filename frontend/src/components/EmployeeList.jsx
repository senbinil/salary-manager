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
import { keepPreviousData, useQueries, useQuery } from '@tanstack/react-query'
import axios from 'axios'
import { Link as RouterLink } from 'react-router'
import { useState } from 'react'
import { errorMessage } from '../api/errorMessage.js'
import { formatAmount } from '../lib/format.js'
import { paths } from '../router/paths.js'
import EmployeeFilters from './EmployeeFilters.jsx'

const FALLBACK_ERROR = 'Could not load employees'
const DEFAULT_LIMIT = 20
const LIMIT_OPTIONS = [10, DEFAULT_LIMIT, 50, 100]

/**
 * The paginated employee roster and the filters that narrow it. Owns the paging
 * and filter state, because changing a filter returns the roster to page one.
 */
export default function EmployeeList() {
  const [page, setPage] = useState(0)
  const [limit, setLimit] = useState(DEFAULT_LIMIT)
  const [filters, setFilters] = useState({})

  // The fields hold exactly what was typed, so a space can be typed mid-name.
  // Only the request drops padding and empty filters.
  const appliedFilters = Object.fromEntries(
    Object.entries(filters)
      .map(([key, value]) => [key, value.trim()])
      .filter(([, value]) => value !== ''),
  )

  // Each dropdown owns its cache entry, so one failing reference endpoint does
  // not blank the others.
  const [departmentQuery, designationQuery, countryQuery] = useQueries({
    queries: [
      {
        queryKey: ['departments'],
        queryFn: async () => (await axios.get('/api/v1/departments')).data,
        staleTime: Infinity,
      },
      {
        queryKey: ['designations'],
        queryFn: async () => (await axios.get('/api/v1/designations')).data,
        staleTime: Infinity,
      },
      {
        queryKey: ['countries'],
        queryFn: async () => (await axios.get('/api/v1/countries')).data,
        staleTime: Infinity,
      },
    ],
  })

  const { data, isPending, error } = useQuery({
    queryKey: ['employees', page, limit, appliedFilters],
    queryFn: async () => {
      const response = await axios.get('/api/v1/employees', {
        params: {
          page: page + 1,
          limit,
          ...(Object.keys(appliedFilters).length ? { filter: appliedFilters } : {}),
        },
      })
      return response.data
    },
    placeholderData: keepPreviousData,
  })

  const employees = data?.data ?? []

  function updateFilter(key, value) {
    setFilters((current) => ({ ...current, [key]: value }))
    setPage(0)
  }

  function clearFilters() {
    setFilters({})
    setPage(0)
  }

  return (
    <>
      <EmployeeFilters
        filters={filters}
        hasFilters={Object.keys(appliedFilters).length > 0}
        departments={departmentQuery.data ?? []}
        designations={designationQuery.data ?? []}
        countries={countryQuery.data ?? []}
        onChange={updateFilter}
        onClear={clearFilters}
      />

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
        <Paper variant="outlined" sx={{ mt: 3 }}>
          <TableContainer>
            <Table
              aria-label="Employee list"
              sx={{
                minWidth: 1080,
                '& .MuiTableRow-root:hover': { bgcolor: 'action.hover' },
              }}
            >
              <TableHead
                sx={{
                  '& .MuiTableCell-head': {
                    textTransform: 'uppercase',
                    fontSize: 12,
                    fontWeight: 700,
                    letterSpacing: '0.06em',
                    color: 'text.secondary',
                    bgcolor: 'grey.50',
                  },
                }}
              >
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
    </>
  )
}
