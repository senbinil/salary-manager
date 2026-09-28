import Button from '@mui/material/Button'
import MenuItem from '@mui/material/MenuItem'
import Paper from '@mui/material/Paper'
import Stack from '@mui/material/Stack'
import TextField from '@mui/material/TextField'

/**
 * The roster's five filters. The fields hold exactly what was typed, so a space
 * can be typed mid-name; the parent trims only what it puts in the request.
 *
 * Presentational on purpose: the parent owns the filter state, because changing
 * one also returns the roster to its first page.
 */
export default function EmployeeFilters({
  filters,
  hasFilters,
  departments,
  designations,
  countries,
  onChange,
  onClear,
}) {
  return (
    <Paper variant="outlined" sx={{ p: 1.5 }}>
      <Stack
        direction="row"
        spacing={1.5}
        useFlexGap
        sx={{ flexWrap: 'wrap', alignItems: 'center' }}
      >
        <TextField
          size="small"
          label="Name"
          sx={{ minWidth: 160 }}
          value={filters.name_cont ?? ''}
          onChange={(event) => onChange('name_cont', event.target.value)}
        />
        <TextField
          select
          size="small"
          label="Department"
          sx={{ minWidth: 160 }}
          value={filters.department_id ?? ''}
          onChange={(event) => onChange('department_id', event.target.value)}
        >
          <MenuItem value="">Any department</MenuItem>
          {departments.map((department) => (
            <MenuItem key={department.id} value={String(department.id)}>
              {department.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Designation"
          sx={{ minWidth: 160 }}
          value={filters.designation_id ?? ''}
          onChange={(event) => onChange('designation_id', event.target.value)}
        >
          <MenuItem value="">Any designation</MenuItem>
          {designations.map((designation) => (
            <MenuItem key={designation.id} value={String(designation.id)}>
              {designation.name}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          select
          size="small"
          label="Status"
          sx={{ minWidth: 140 }}
          value={filters.employment_status ?? ''}
          onChange={(event) => onChange('employment_status', event.target.value)}
        >
          <MenuItem value="">Any status</MenuItem>
          <MenuItem value="active">Active</MenuItem>
          <MenuItem value="inactive">Inactive</MenuItem>
        </TextField>
        <TextField
          select
          size="small"
          label="Country"
          sx={{ minWidth: 160 }}
          value={filters.country_code ?? ''}
          onChange={(event) => onChange('country_code', event.target.value)}
        >
          <MenuItem value="">Any country</MenuItem>
          {countries.map((country) => (
            <MenuItem key={country.code} value={country.code}>
              {country.name}
            </MenuItem>
          ))}
        </TextField>
        <Button type="button" size="small" onClick={onClear} disabled={!hasFilters}>
          Clear filters
        </Button>
      </Stack>
    </Paper>
  )
}
