import Alert from '@mui/material/Alert'
import AppBar from '@mui/material/AppBar'
import Button from '@mui/material/Button'
import Container from '@mui/material/Container'
import Toolbar from '@mui/material/Toolbar'
import Typography from '@mui/material/Typography'
import { useMutation } from '@tanstack/react-query'
import axios from 'axios'
import { Outlet, useNavigate } from 'react-router'
import { errorMessage } from '../api/errorMessage.js'
import { paths } from '../router/paths.js'

/** Shown when the request failed without saying anything worth repeating. */
const FALLBACK_ERROR = 'Could not sign out'

/**
 * The shell every page renders inside: the product header plus the routed page.
 */
export default function RootLayout() {
  const navigate = useNavigate()

  const { mutate, isPending, error } = useMutation({
    // The empty object is required, not decoration: it is what makes axios send
    // `Content-Type: application/json`, and Rodauth answers anything else — a
    // body-less POST included — with 400 and no logout.
    mutationFn: () => axios.post('/api/v1/logout', {}),
    // Only a confirmed sign-out moves the visitor: the server, not the click,
    // decides whether the session actually ended.
    onSuccess: () => navigate(paths.login),
  })

  return (
    <>
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" noWrap>
            AMCE Payroll
          </Typography>
          <Button
            color="inherit"
            sx={{ ml: 'auto' }}
            // A click while the first request is still in flight would ask the
            // API to end a session that is already ending.
            disabled={isPending}
            onClick={() => mutate()}
          >
            Sign out
          </Button>
        </Toolbar>
      </AppBar>
      {error && (
        <Alert severity="error">
          {errorMessage(error, FALLBACK_ERROR)}
        </Alert>
      )}
      <Container component="main" sx={{ py: 4 }}>
        <Outlet />
      </Container>
    </>
  )
}
