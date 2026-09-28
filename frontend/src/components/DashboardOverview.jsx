import Alert from '@mui/material/Alert'
import Box from '@mui/material/Box'
import Chip from '@mui/material/Chip'
import CircularProgress from '@mui/material/CircularProgress'
import IconButton from '@mui/material/IconButton'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import Typography from '@mui/material/Typography'
import { useTheme } from '@mui/material/styles'
import { useQuery } from '@tanstack/react-query'
import axios from 'axios'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useCallback, useEffect, useRef, useState } from 'react'
import { errorMessage } from '../api/errorMessage.js'
import { formatCount, formatWholeAmount } from '../lib/format.js'

const FALLBACK_ERROR = 'Could not load the overview'
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
 * The organization-wide overview of the active workforce: what each country is
 * paid, and how many employees it holds.
 *
 * It makes its own request, so a slow or failing summary never blocks the
 * employee roster, and it is not narrowed by the roster's filters.
 */
export default function DashboardOverview() {
  const summary = useQuery({
    queryKey: ['dashboard-summary'],
    queryFn: async () => (await axios.get('/api/v1/dashboard/summary')).data,
  })

  return (
    <>
      {summary.isPending && (
        <Stack direction="row" spacing={1} role="status">
          <CircularProgress size={20} aria-label="Loading overview" />
          <Typography>Loading overview…</Typography>
        </Stack>
      )}

      {summary.error && (
        <Alert severity="error">
          {errorMessage(summary.error, FALLBACK_ERROR)}
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
    </>
  )
}
