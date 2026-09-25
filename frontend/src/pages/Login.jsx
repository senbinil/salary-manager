import { useState } from 'react'
import Alert from '@mui/material/Alert'
import Box from '@mui/material/Box'
import Button from '@mui/material/Button'
import IconButton from '@mui/material/IconButton'
import InputAdornment from '@mui/material/InputAdornment'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'
import Typography from '@mui/material/Typography'
import { useMutation } from '@tanstack/react-query'
import axios from 'axios'
import { Eye, EyeOff } from 'lucide-react'
import { useNavigate } from 'react-router'
import { errorMessage } from '../api/errorMessage.js'
import { paths } from '../router/paths.js'

/** Shown when the request failed without saying anything worth repeating. */
const FALLBACK_ERROR = 'Invalid credentials'

const EMPTY_CREDENTIALS = { email: '', password: '' }

/**
 * Radius values are multiples of `theme.shape.borderRadius` (4px), so 4 is 16px
 * and 2 is 8px. Rounding the controls to match the card keeps the page from
 * looking like a square card with square fields in it.
 */
const CARD_RADIUS = 4
const CONTROL_RADIUS = 2

/** Outlined inputs draw their border on the wrapper, not the `<input>`. */
const fieldSx = { '& .MuiOutlinedInput-root': { borderRadius: CONTROL_RADIUS } }

/**
 * The toggle names the action its next click performs, so it reads as "Show
 * password" while the field is masked and "Hide password" once it is not. This
 * is the button's accessible name, which is also what the tests query.
 */
const TOGGLE_LABELS = ['Show password', 'Hide password']

/** What the form refuses to send without, keyed by field name. */
function requiredErrors({ email, password }) {
  const errors = {}

  if (!email.trim()) errors.email = 'Email is required'
  if (!password) errors.password = 'Password is required'

  return errors
}

/**
 * Sign-in page, served at the app root.
 *
 * It sits outside `RootLayout` on purpose — the product chrome belongs to
 * signed-in screens, so this page centres a single card on its own.
 */
export default function Login() {
  const navigate = useNavigate()
  const [credentials, setCredentials] = useState(EMPTY_CREDENTIALS)
  const [fieldErrors, setFieldErrors] = useState({})
  // Masked on load: revealing a password is opt-in, per field, every time.
  const [showPassword, setShowPassword] = useState(false)

  const { mutate, isPending, error } = useMutation({
    mutationFn: (values) => axios.post('/api/v1/login', values),
    onSuccess: () => navigate(paths.dashboard),
  })

  function handleChange(event) {
    const { name, value } = event.target
    setCredentials((current) => ({ ...current, [name]: value }))
  }

  function handleSubmit(event) {
    event.preventDefault()

    const errors = requiredErrors(credentials)
    setFieldErrors(errors)
    if (Object.keys(errors).length > 0) return

    mutate(credentials)
  }

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'background.default',
        p: 2,
      }}
    >
      <Paper
        elevation={3}
        sx={{ p: 4, width: '100%', maxWidth: 400, borderRadius: CARD_RADIUS }}
      >
        <Box
          component="form"
          // The checks above are the only validation, so the browser must not
          // also block submission with its own required-field rules.
          noValidate
          onSubmit={handleSubmit}
        >
          <Stack spacing={3}>
            <Typography variant="h4" component="h1">
              Sign in
            </Typography>

            {error && (
              <Alert severity="error">
                {errorMessage(error, FALLBACK_ERROR)}
              </Alert>
            )}

            <TextField
              name="email"
              value={credentials.email}
              onChange={handleChange}
              label="Email"
              type="email"
              autoComplete="email"
              autoFocus
              required
              error={Boolean(fieldErrors.email)}
              helperText={fieldErrors.email}
              sx={fieldSx}
            />

            <TextField
              name="password"
              value={credentials.password}
              onChange={handleChange}
              label="Password"
              type={showPassword ? 'text' : 'password'}
              autoComplete="current-password"
              required
              error={Boolean(fieldErrors.password)}
              helperText={fieldErrors.password}
              sx={fieldSx}
              slotProps={{
                input: {
                  endAdornment: (
                    <InputAdornment position="end">
                      <IconButton
                        edge="end"
                        onClick={() => setShowPassword((visible) => !visible)}
                        aria-label={TOGGLE_LABELS[Number(showPassword)]}
                      >
                        {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
                      </IconButton>
                    </InputAdornment>
                  ),
                },
              }}
            />

            <Button
              type="submit"
              variant="contained"
              size="large"
              disabled={isPending}
              sx={{ borderRadius: CONTROL_RADIUS }}
            >
              Sign in
            </Button>
          </Stack>
        </Box>
      </Paper>
    </Box>
  )
}
