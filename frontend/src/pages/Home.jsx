import Alert from '@mui/material/Alert'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import Chip from '@mui/material/Chip'
import CircularProgress from '@mui/material/CircularProgress'
import IconButton from '@mui/material/IconButton'
import Link from '@mui/material/Link'
import MenuItem from '@mui/material/MenuItem'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import Table from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TableHead from '@mui/material/TableHead'
import TablePagination from '@mui/material/TablePagination'
import TableRow from '@mui/material/TableRow'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import { useTheme } from '@mui/material/styles'
import { keepPreviousData, useQueries, useQuery } from '@tanstack/react-query'
import axios from 'axios'
import { Link as RouterLink } from 'react-router'
import { useCallback, useEffect, useRef, useState } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { errorMessage } from '../api/errorMessage.js'
import { paths } from '../router/paths.js'

const FALLBACK_ERROR = 'Could not load employees'
const OVERVIEW_FALLBACK_ERROR = 'Could not load the overview'
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

function formatCount(count) {
  return new Intl.NumberFormat().format(count)
}

// Aggregate figures read better without the four decimal places the API sends,
// so the overview cards round while the ledger keeps the exact contract total.
function formatWholeAmount(amount, currency) {
  const numericAmount = Number(amount)
  if (!Number.isFinite(numericAmount)) return `${amount} ${currency}`

  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(numericAmount)
  } catch {
    return `${amount} ${currency}`
  }
}

const CARD_WIDTH = 220
const CARD_GAP = 16
// One card per press, so a strip pages predictably instead of drifting.
const CARD_STEP = CARD_WIDTH + CARD_GAP

// Decorative only: the API sends no per-country colour, so neighbouring cards
// cycle through the brand accents to stay visually distinct.
const ACCENT_KEYS = ['primary', 'secondary', 'tertiary', 'success', 'warning']

function accentFor(theme, index) {
  const palette = theme.vars?.palette ?? theme.palette

  return palette[ACCENT_KEYS[index % ACCENT_KEYS.length]].main
}

/**
 * A fixed-width card in an overview strip, so the cards line up and a strip can
 * be paged by exactly one card.
 */
function StripCard({ children }) {
  return (
    <Paper
      variant="outlined"
      sx={{
        flex: '0 0 auto',
        width: CARD_WIDTH,
        p: 2,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {children}
    </Paper>
  )
}

/**
 * A heading with a count badge and a strip of cards that scrolls sideways. The
 * cards never wrap, so the dashboard keeps one row however many countries there
 * are; the buttons page a card at a time and go inert at each end.
 */
function CardStrip({ id, title, badge, children }) {
  const scrollerRef = useRef(null)
  const [edges, setEdges] = useState({ back: false, forward: false })

  const measure = useCallback(() => {
    const scroller = scrollerRef.current
    if (!scroller) return

    const maxScroll = scroller.scrollWidth - scroller.clientWidth
    setEdges({
      back: scroller.scrollLeft > 0,
      forward: scroller.scrollLeft < maxScroll - 1,
    })
  }, [])

  useEffect(() => {
    measure()
    window.addEventListener('resize', measure)

    return () => window.removeEventListener('resize', measure)
  }, [measure])

  function page(direction) {
    scrollerRef.current?.scrollBy({ left: direction * CARD_STEP, behavior: 'smooth' })
  }

  return (
    <Box component="section" aria-labelledby={id}>
      <Stack direction="row" spacing={1} sx={{ alignItems: 'center', mb: 1.5 }}>
        <Typography id={id} variant="h6" component="h2">
          {title}
        </Typography>
        <Chip label={badge} size="small" variant="outlined" />
        <Box sx={{ flexGrow: 1 }} />
        <IconButton
          type="button"
          size="small"
          aria-label={`Scroll back through ${title}`}
          disabled={!edges.back}
          onClick={() => page(-1)}
        >
          <ChevronLeft size={18} />
        </IconButton>
        <IconButton
          type="button"
          size="small"
          aria-label={`Scroll forward through ${title}`}
          disabled={!edges.forward}
          onClick={() => page(1)}
        >
          <ChevronRight size={18} />
        </IconButton>
      </Stack>

      <Box
        ref={scrollerRef}
        role="group"
        aria-label={`${title} cards`}
        tabIndex={0}
        onScroll={measure}
        sx={{
          display: 'flex',
          gap: `${CARD_GAP}px`,
          overflowX: 'auto',
          // The paging buttons are the affordance here; a native scrollbar
          // under each strip would be the loudest thing on the page.
          scrollbarWidth: 'none',
          '&::-webkit-scrollbar': { display: 'none' },
          p: 0.5,
        }}
      >
        {children}
      </Box>
    </Box>
  )
}

/**
 * The compensation paid in each country. Amounts stay in the country's own
 * currency, so they are labelled rather than converted to a common base.
 */
function ExpenseStrip({ totals }) {
  const theme = useTheme()

  return (
    <CardStrip
      id="expense-by-country-heading"
      title="Expense by Country"
      badge={`${formatCount(totals.length)} Countries`}
    >
      {totals.length === 0 ? (
        <StripCard>
          <Typography color="text.secondary">No active employees</Typography>
        </StripCard>
      ) : (
        totals.map((total, index) => (
          <StripCard key={total.country_code}>
            <Typography sx={{ fontWeight: 600, fontSize: 14 }}>
              {total.country_name}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {`${total.country_code.toLowerCase()} · ${total.currency}`}
            </Typography>
            <Box
              sx={{ height: 3, borderRadius: 2, bgcolor: accentFor(theme, index), my: 1.5 }}
            />
            <Typography sx={{ fontWeight: 700, fontSize: 20, lineHeight: 1.2 }}>
              {formatWholeAmount(total.total_compensation, total.currency)}
            </Typography>
          </StripCard>
        ))
      )}
    </CardStrip>
  )
}

/**
 * How many employees each country employs, with the organization-wide total on
 * the strip's badge.
 */
function HeadcountStrip({ totals, totalActive }) {
  return (
    <CardStrip
      id="employees-by-country-heading"
      title="Employees by Country"
      badge={`${formatCount(totalActive)} Total Active Personnel`}
    >
      {totals.length === 0 ? (
        <StripCard>
          <Typography color="text.secondary">No active employees</Typography>
        </StripCard>
      ) : (
        totals.map((total) => (
          <StripCard key={total.country_code}>
            <Typography sx={{ fontWeight: 600, fontSize: 14 }}>
              {total.country_name}
            </Typography>
            <Typography sx={{ fontWeight: 700, fontSize: 24, lineHeight: 1.2, mt: 1.5 }}>
              {formatCount(total.employee_count)}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Employees
            </Typography>
          </StripCard>
        ))
      )}
    </CardStrip>
  )
}

/**
 * Shows employees' organizational roles and whether they have a current
 * active contract.
 */
export default function Home() {
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
  const [departments, designations, countries] = useQueries({
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

  // The organization-wide overview is its own request, so a slow or failing
  // summary never blocks the employee list. It is not narrowed by the filters.
  const summary = useQuery({
    queryKey: ['dashboard-summary'],
    queryFn: async () => (await axios.get('/api/v1/dashboard/summary')).data,
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
    <Stack spacing={3}>
      <Typography variant="h4" component="h1">
        Dashboard
      </Typography>

      {summary.isPending && (
        <Stack direction="row" spacing={1} role="status">
          <CircularProgress size={20} aria-label="Loading overview" />
          <Typography>Loading overview…</Typography>
        </Stack>
      )}

      {summary.error && (
        <Alert severity="error">
          {errorMessage(summary.error, OVERVIEW_FALLBACK_ERROR)}
        </Alert>
      )}

      {summary.data && (
        <Stack spacing={3}>
          <ExpenseStrip totals={summary.data.country_totals} />
          <HeadcountStrip
            totals={summary.data.country_totals}
            totalActive={summary.data.total_active_employees}
          />
        </Stack>
      )}

      <Paper variant="outlined" sx={{ p: 1.5 }}>
        <Stack
          direction="row"
          spacing={1.5}
          useFlexGap
          sx={{ flexWrap: 'wrap', alignItems: 'center' }}
        >
          <TextField
            size="small"
            label="Name"
            sx={{ minWidth: 160 }}
            value={filters.name_cont ?? ''}
            onChange={(event) => updateFilter('name_cont', event.target.value)}
          />
          <TextField
            select
            size="small"
            label="Department"
            sx={{ minWidth: 160 }}
            value={filters.department_id ?? ''}
            onChange={(event) => updateFilter('department_id', event.target.value)}
          >
            <MenuItem value="">Any department</MenuItem>
            {(departments.data ?? []).map((department) => (
              <MenuItem key={department.id} value={String(department.id)}>
                {department.name}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            select
            size="small"
            label="Designation"
            sx={{ minWidth: 160 }}
            value={filters.designation_id ?? ''}
            onChange={(event) => updateFilter('designation_id', event.target.value)}
          >
            <MenuItem value="">Any designation</MenuItem>
            {(designations.data ?? []).map((designation) => (
              <MenuItem key={designation.id} value={String(designation.id)}>
                {designation.name}
              </MenuItem>
            ))}
          </TextField>
          <TextField
            select
            size="small"
            label="Status"
            sx={{ minWidth: 140 }}
            value={filters.employment_status ?? ''}
            onChange={(event) => updateFilter('employment_status', event.target.value)}
          >
            <MenuItem value="">Any status</MenuItem>
            <MenuItem value="active">Active</MenuItem>
            <MenuItem value="inactive">Inactive</MenuItem>
          </TextField>
          <TextField
            select
            size="small"
            label="Country"
            sx={{ minWidth: 160 }}
            value={filters.country_code ?? ''}
            onChange={(event) => updateFilter('country_code', event.target.value)}
          >
            <MenuItem value="">Any country</MenuItem>
            {(countries.data ?? []).map((country) => (
              <MenuItem key={country.code} value={country.code}>
                {country.name}
              </MenuItem>
            ))}
          </TextField>
          <Button
            type="button"
            size="small"
            onClick={clearFilters}
            disabled={Object.keys(appliedFilters).length === 0}
          >
            Clear filters
          </Button>
        </Stack>
      </Paper>

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
    </Stack>
  )
}
