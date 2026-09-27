import Alert from '@mui/material/Alert'
import CircularProgress from '@mui/material/CircularProgress'
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
import { useState } from 'react'
import { errorMessage } from '../api/errorMessage.js'

const FALLBACK_ERROR = 'Could not load employees'
const DEFAULT_LIMIT = 20
const LIMIT_OPTIONS = [10, DEFAULT_LIMIT, 50, 100]

/**
 * Shows the employee roster. Filters and employee details are delivered in
 * later dashboard slices.
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
