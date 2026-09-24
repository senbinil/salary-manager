import Button from '@mui/material/Button'
import CssBaseline from '@mui/material/CssBaseline'
import { ThemeProvider } from '@mui/material/styles'
import { render, screen } from '@testing-library/react'
import { theme } from './index.js'
import { brandAccents } from './tokens.js'

describe('theme', () => {
  it('keeps the six brand accents DESIGN.md declares', () => {
    expect(brandAccents).toEqual({
      primary: '#0037b0',
      secondary: '#565d79',
      tertiary: '#004f35',
      error: '#ba1a1a',
      surface: '#f8f9ff',
      outline: '#747686',
    })
  })

  it('maps every accent onto a palette role', () => {
    const { palette } = theme.colorSchemes.light

    expect(palette.primary.main).toBe(brandAccents.primary)
    expect(palette.secondary.main).toBe(brandAccents.secondary)
    expect(palette.tertiary.main).toBe(brandAccents.tertiary)
    expect(palette.error.main).toBe(brandAccents.error)
    expect(palette.background.default).toBe(brandAccents.surface)
    expect(palette.divider).toBe(brandAccents.outline)
  })

  it('exposes the palette as CSS variables', () => {
    expect(theme.vars.palette.primary.main).toBe(
      'var(--mui-palette-primary-main, #0037b0)',
    )
    expect(theme.vars.palette.tertiary.main).toBe(
      'var(--mui-palette-tertiary-main, #004f35)',
    )
  })

  it('leaves everything that is not colour at MUI defaults', () => {
    expect(theme.spacing(2)).toBe('calc(2 * var(--mui-spacing, 8px))')
    expect(theme.shape.borderRadius).toBe(4)
    expect(theme.breakpoints.values.sm).toBe(600)
    expect(theme.typography.h1.fontSize).toBe('6rem')
  })

  it('renders MUI components under the provider', () => {
    render(
      <ThemeProvider theme={theme} defaultMode="light">
        <CssBaseline />
        <Button>Save</Button>
      </ThemeProvider>,
    )

    expect(screen.getByRole('button', { name: 'Save' })).toBeInTheDocument()
  })
})
