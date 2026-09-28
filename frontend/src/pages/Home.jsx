import Stack from '@mui/material/Stack'
import Typography from '@mui/material/Typography'
import DashboardOverview from '../components/DashboardOverview.jsx'
import EmployeeList from '../components/EmployeeList.jsx'

/**
 * The dashboard: the organization-wide overview of the active workforce above
 * the employee roster, whose rows link into the contract drill-down.
 *
 * Deliberately thin. Each section owns its own request and state, so a slow or
 * failing overview cannot affect the roster, and the roster's filters do not
 * narrow the overview.
 */
export default function Home() {
  return (
    <Stack spacing={3}>
      <Typography variant="h4" component="h1">
        Dashboard
      </Typography>

      <DashboardOverview />
      <EmployeeList />
    </Stack>
  )
}
