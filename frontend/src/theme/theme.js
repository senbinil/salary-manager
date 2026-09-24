/**
 * App theme — colour definition only.
 *
 * The six `brandAccents` from `DESIGN.md` are mapped onto MUI's palette roles so
 * components pick them up with no extra configuration. Everything else MUI can
 * theme (typography, spacing, shape, elevation, breakpoints, component
 * overrides) is deliberately left at MUI's defaults.
 *
 * Notes on the setup:
 * - `cssVariables` turns every role into a `--mui-palette-*` CSS variable, which
 *   is why custom roles such as `tertiary` can live in the palette even though
 *   MUI has no slot for them.
 * - Component styles should read `theme.vars.palette.*`; `theme.palette.*`
 *   resolves to the raw light values only.
 * - MUI derives the tonal steps (`light` / `dark`, used for hover states) from
 *   each `main` when they are not given explicitly.
 */
import { createTheme } from '@mui/material/styles';

import { brandAccents, paletteExtras } from './tokens.js';

/**
 * Accent to role mapping:
 * - `primary`   -> `primary`
 * - `secondary` -> `secondary`
 * - `tertiary`  -> custom `tertiary` role (MUI has no slot for it)
 * - `error`     -> `error`
 * - `surface`   -> `background.default`
 * - `outline`   -> `divider`
 */
const lightPalette = {
  primary: { main: brandAccents.primary, contrastText: '#ffffff' },
  secondary: { main: brandAccents.secondary, contrastText: '#ffffff' },
  tertiary: { main: brandAccents.tertiary, contrastText: '#ffffff' },
  error: { main: brandAccents.error, contrastText: '#ffffff' },

  warning: { main: paletteExtras.warning, contrastText: '#ffffff' },
  success: { main: paletteExtras.success, contrastText: '#ffffff' },

  background: { default: brandAccents.surface },
  divider: brandAccents.outline,
};

const theme = createTheme({
  cssVariables: true,
  // DESIGN.md defines a single colour set, so there is no dark scheme yet —
  // adding one is a matter of declaring `colorSchemes.dark.palette` here.
  colorSchemes: { light: { palette: lightPalette } },
});

export default theme;
