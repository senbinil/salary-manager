import { StrictMode } from 'react'
import CssBaseline from '@mui/material/CssBaseline'
import { ThemeProvider } from '@mui/material/styles'
import { createRoot } from 'react-dom/client'
// Roboto weights used by the AMCE Payroll type scale (see src/theme/theme.js).
import '@fontsource/roboto/400.css'
import '@fontsource/roboto/500.css'
import '@fontsource/roboto/600.css'
import '@fontsource/roboto/700.css'
import './index.css'
import App from './App.jsx'
import { theme } from './theme'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <ThemeProvider theme={theme} defaultMode="light">
      <CssBaseline />
      <App />
    </ThemeProvider>
  </StrictMode>,
)
