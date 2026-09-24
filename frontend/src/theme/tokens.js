/**
 * AMCE Payroll colour tokens.
 *
 * `DESIGN.md` declares exactly six **brand accents**, transcribed verbatim below.
 * `paletteExtras` holds the semantic colours the app adds on top of them — ones
 * MUI has slots for (`warning` / `success`) but no matching defaults.
 *
 * Nothing else belongs in this file by design: typography, spacing, radii,
 * elevation and breakpoints are deliberately left at MUI's defaults.
 */

/** The six brand accents declared by DESIGN.md. */
export const brandAccents = {
  primary: '#0037b0',
  secondary: '#565d79',
  tertiary: '#004f35',
  error: '#ba1a1a',
  surface: '#f8f9ff',
  outline: '#747686',
};

/** Semantic colours the app adds beyond the six accents. */
export const paletteExtras = {
  success: '#059669',
  warning: '#d97706',
};
