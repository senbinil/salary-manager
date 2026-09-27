import Alert from '@mui/material/Alert'
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
import { errorMessage } from '../api/errorMessage.js'

const FALLBACK_ERROR = 'Could not load employees'

/**
 * Shows the employee roster. Filters, employee details, and table pagination
 * are delivered in later dashboard slices.
 */
export default function Home() {
  const { data, isPending, error } = useQuery({
    queryKey: ['employees'],
    queryFn: async () => {
      const response = await axios.get('/api/v1/employees')
      return response.data
    },
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
        <TableContainer component={Paper} variant="outlined">
          <Table aria-label="Employee list">
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {employees.length > 0 ? (
                employees.map((employee) => (
                  <TableRow key={employee.id}>
                    <TableCell component="th" scope="row">
                      {employee.name}
                    </TableCell>
                  </TableRow>
                ))
              ) : (
                <TableRow>
                  <TableCell>No employees found.</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Stack>
  )
}
