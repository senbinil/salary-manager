---
name: AMCE Payroll
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#434655'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#2151da'
  primary: '#0037b0'
  on-primary: '#ffffff'
  primary-container: '#1d4ed8'
  on-primary-container: '#cad3ff'
  inverse-primary: '#b7c4ff'
  secondary: '#565d79'
  on-secondary: '#ffffff'
  secondary-container: '#d8deff'
  on-secondary-container: '#5a627e'
  tertiary: '#004f35'
  on-tertiary: '#ffffff'
  tertiary-container: '#006948'
  on-tertiary-container: '#76eab6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b7c4ff'
  on-primary-fixed: '#001551'
  on-primary-fixed-variant: '#0039b5'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#bec5e5'
  on-secondary-fixed: '#131a33'
  on-secondary-fixed-variant: '#3e4660'
  tertiary-fixed: '#85f8c4'
  tertiary-fixed-dim: '#68dba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  label-xs:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.06em
  numeric-table:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: -0.01em
  numeric-display:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.03em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.375rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

The design system establishes a high-density, authoritative, and frictionless environment tailored for global workforce financial operations, multi-jurisdiction compliance, and enterprise payroll disbursements. The brand persona projects institutional stability, cryptographic precision, and operational clarity. It targets VP of People, Global Controllers, and Chief Financial Officers who require rapid data scanning, zero-ambiguity workflows, and effortless handling of cross-border currency regulations.

### Design Movement: Modern Precision SaaS
Drawing inspiration from contemporary financial infrastructure and institutional tools, the system combines:
- **High-Density Utility:** Prioritizing spatial economy and structured information hierarchies without visual fatigue.
- **Micro-Structured Layering:** Flat, low-contrast slate dividers and razor-thin borders paired with crisp neutral backdrops to segment massive data streams.
- **Architectural Serenity:** Quiet, understated chrome and navigational anchors allow financial values, compliance states, and cross-border currency routes to command primary focus.

## Colors

The palette balances structural depth with tactical, communicative accents. Financial figures, multi-currency routing flags, and regulatory compliance validations rely on strict chromatic roles:

- **Foundation & Navigational Anchors (`#0B132B`, `#1C2541`):** Serves as the executive backdrop for global control bars, primary vertical navigation rails, and persistent operational metrics.
- **Action & Focus Blue (`#1D4ED8`):** Applied deliberately to primary execute triggers (e.g., "Authorize Run", "Approve Batch"), interactive table states, keyboard focus perimeters, and active tab highlights.
- **Compliance & Ledger Emerald (`#059669`):** Reserved for settled ledgers, regulatory filings in good standing, approved tax tranches, and positive balance differentials.
- **Alert & Regulatory Amber (`#D97706`):** Dedicated to pending audit validations, escrow funding warnings, statutory withholding mismatch notices, and clearing deadlines.
- **Surface Geometry (`#FFFFFF`, `#F8FAFC`, `#F1F5F9`):** Pristine background planes designed to optimize contrast against micro-typefaces, tabular ledgers, and multi-layered data trees.
- **Structural Dividers (`#E2E8F0`):** Strict, subtle borders that enforce separation between dense ledger cells without introducing visual noise.

## Typography

Typography balances clean structural headers with functional, highly legible tabular body systems:

- **Display & Headings (Plus Jakarta Sans):** Introduces geometric authority and contemporary polish to top-level dashboards, entity titles, and aggregate payroll metrics.
- **Execution & Data (Inter):** Serves as the primary operational engine across data grids, forms, and analytical widgets.
- **Tabular Numeric Precision:** All monetary amounts, FX exchange calculations, statutory percentages, and employee identifier codes must enforce `font-feature-settings: "tnum" 1, "cv01" 1, "zero" 1` to ensure uniform character column widths and eliminate horizontal jitter during real-time recalculations.
- **Uppercase Currency and Region Encodings:** Currency codes (USD, EUR, GBP, JPY, SGD) and ISO country designations enforce `label-xs` or `label-sm` with strict uppercase tracking for instant identification across compact tabular cells.

## Layout & Spacing

The layout model is optimized for high-density transactional data presentation, continuous monitoring, and complex data entry.

### Grid Infrastructure
- **Desktop (>= 1280px):** Dynamic fluid workspace framed by a persistent 256px collapsed/expanded dark navigation rail (`#0B132B`). Content spans a 12-column variable fluid grid with `1.5rem` gutters and a maximum content constraint of 1600px for transactional forms and wide-viewport ledgers.
- **Tablet (768px - 1279px):** 8-column layout with `1rem` gutters. Lateral filter panels collapse into slide-over drawers; master multi-currency grids activate horizontal kinetic scroll regions.
- **Mobile (< 768px):** 4-column layout with `1rem` margins. Transaction data stacks into linear cards, and deep nested ledgers provide segmented views or bottom sheets.

### Spacing Philosophy
- Base increments utilize an absolute 4px sub-grid, optimized with concise micro-padding tokens (`space-xs` = 4px, `space-sm` = 6px, `space-md` = 12px) to maximize above-the-fold operational visibility in financial ledgers.
- Component-level spacing adheres strictly to compact internal density: table cells maintain a consistent 8px vertical padding ceiling to facilitate scanning of over 50 rows per screen without pagination.

## Elevation & Depth

Visual hierarchy uses flat, high-definition structural planes, surface color shifts, and precise outlines rather than heavy theatrical drop shadows.

### Elevation Tiers
- **Surface Level 0 (Base Canvas - `#F8FAFC`):** Application viewport canvas housing background grid structures.
- **Surface Level 1 (Card & Module Shells - `#FFFFFF`):** High-contrast primary work surfaces, bordered by 1px solid `#E2E8F0`. Shadows are omitted entirely or restricted to an ambient micro-depth (`0 1px 2px 0 rgba(11, 19, 43, 0.04)`).
- **Surface Level 2 (Flyout Menus, Currency Selectors, Date Pickers):** Elevated interface units built with crisp boundaries (`1px solid #CBD5E1`) and a low-opacity, wide-dispersion ambient drop: `0 4px 12px -2px rgba(11, 19, 43, 0.08), 0 2px 4px -1px rgba(11, 19, 43, 0.04)`.
- **Surface Level 3 (Global Transaction Modals, Critical Approval Shields):** Deep overlay backdrops tinted with 40% `#0B132B` accompanied by a distinct floating card boundary: `0 12px 32px -4px rgba(11, 19, 43, 0.16)`.

### Border Strategy
Visual containment relies on single-pixel architectural delineations. Never blur bounds between conflicting ledgers. Hairline borders (`#E2E8F0` on white; `#1E293B` on dark foundations) guarantee structural clarity across varying display resolutions.

## Shapes

The geometric language is engineered for enterprise efficiency and authoritative financial precision:

- **Core Elements (`rounded` = 0.25rem / 4px):** Form fields, table rows, button surfaces, inline status indicators, and modal boundaries enforce a disciplined, tight radius. This preserves rectilinear grid alignment and supports compact density.
- **Pill Containers (Custom 9999px):** Applied exclusively to atomic metadata elements, such as currency badges (e.g., `USD`, `SGD`), employee employment status indicators (`Contractor`, `Full-time`), and country flags. This creates immediate semantic contrast against rectilinear inputs and structured data tables.
- **Segmented Selectors:** Built with a uniform 4px outer frame housing 3px internal active segment pills, ensuring tight internal alignment.

## Components

### Buttons & Action Triggers
- **Primary Execution:** Solid `#1D4ED8` background, `#FFFFFF` text, 4px border radius, 0 1px 2px rgba(29, 78, 216, 0.2) resting shadow. Hover: `#1E40AF`. Active: `#172554`. Height: 32px (Compact Ledger) or 38px (Standard).
- **Secondary / Functional:** Solid `#FFFFFF`, 1px solid `#CBD5E1`, text `#1E293B`. Hover: `#F8FAFC`, border `#94A3B8`.
- **Destructive / Rollback:** Solid `#FEF2F2`, border 1px solid `#FCA5A5`, text `#B91C1C`. Hover: `#FEE2E2`.

### Status Badges & Chips
- **Pill Architecture:** Height 20px, internal padding 2px 8px, font token `label-sm`.
- **Success / Compliant:** Background `#ECFDF5`, text `#047857`, dot indicator `#059669`.
- **Warning / Review Required:** Background `#FFFBEB`, text `#B45309`, dot indicator `#D97706`.
- **Pending / In Settlement:** Background `#EFF6FF`, text `#1D4ED8`, dot indicator `#3B82F6`.
- **Neutral / Draft:** Background `#F1F5F9`, text `#475569`, dot indicator `#64748B`.

### Tables & Data Grids
- **Header Row:** Height 32px, background `#F8FAFC`, bottom border 1px solid `#CBD5E1`, typography `label-sm` uppercase, text `#64748B`.
- **Data Rows:** Height 44px (Compact) or 52px (Standard), alternating hover state `#F8FAFC`, bottom border 1px solid `#E2E8F0`. Selected row state: `#EFF6FF` with `#1D4ED8` 2px inset vertical border on the leading cell.
- **Numeric Alignment:** Strictly right-aligned with `tnum` font styling. Secondary conversion units (e.g., base currency equivalents) are rendered directly underneath in `body-sm` `#64748B`.

### Segmented Controls & Global Breadcrumbs
- **Breadcrumbs:** Persistent path tracking (e.g., `Entities > EMEA Operations > United Kingdom > May 2024 Cycle`) using `body-sm` `#64748B` with chevron dividers (`#94A3B8`), ending on the active entity in font weight 600 `#0B132B`.
- **Segmented Filter Bars:** Enclosed `#F1F5F9` background container with 2px padding. Inactive options display `#64748B`; active selected options display `#FFFFFF` fill, 1px solid `#CBD5E1`, and `#0B132B` text.

### Form Inputs & Currency Selectors
- **Input Fields:** Height 36px, background `#FFFFFF`, border 1px solid `#CBD5E1`, inner padding 8px 12px, font `body-md`. Focus-visible ring: 2px `#1D4ED8` with 0px offset.
- **Composite FX Input Groups:** Inline selector affix with a country flag, ISO currency code dropdown (pill-styled `#F1F5F9`), and hairline vertical divider separating the currency indicator from the numeric field.

### Selection Controls
- **Checkboxes & Radios:** 16px × 16px geometry with a 3px radius (checkbox) or circular boundary (radio). Checked state: `#1D4ED8` background with an optical white glyph. Indeterminate state (used for partial batch approvals): horizontal line glyph in a `#1D4ED8` frame.