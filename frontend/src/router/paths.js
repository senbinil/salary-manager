/**
 * Route paths, so components link to URLs by name instead of repeating strings.
 */
export const paths = {
  login: '/',
  dashboard: '/dashboard',
  employeeDetails: '/employees/:employeeId',
  employeeDetailsFor: (employeeId) => `/employees/${employeeId}`,
}
