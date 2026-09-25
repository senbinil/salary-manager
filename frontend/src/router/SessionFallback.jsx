import Box from '@mui/material/Box'
import CircularProgress from '@mui/material/CircularProgress'

/**
 * What the signed-in area shows while its loader is still asking the API about
 * the session. React Router renders an empty document during the initial load
 * without this, so a refresh on /dashboard flashes a blank page.
 */
export default function SessionFallback() {
  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
      }}
    >
      <CircularProgress aria-label="Checking your session" />
    </Box>
  )
}
