import Button from '@mui/material/Button'
import Stack from '@mui/material/Stack'
import Typography from '@mui/material/Typography'
import { Link } from 'react-router'
import { paths } from '../router/paths.js'

/**
 * Catch-all page for URLs that match no route.
 */
export default function NotFound() {
  return (
    <Stack spacing={2} sx={{ alignItems: 'flex-start' }}>
      <Typography variant="h4" component="h1">
        Page not found
      </Typography>
      <Typography>
        The page you are looking for does not exist or has moved.
      </Typography>
      <Button component={Link} to={paths.dashboard} variant="contained">
        Back to dashboard
      </Button>
    </Stack>
  )
}
