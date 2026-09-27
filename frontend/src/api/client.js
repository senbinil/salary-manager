import axios from 'axios'

// The deployed API lives on its own host (`api.<domain>`), so browser requests need
// an absolute base URL and credentials: a cross-origin request does not carry the
// Rodauth session cookie without `withCredentials`, and the backend answers it with
// `Access-Control-Allow-Credentials` (see config/initializers/cors.rb).
//
// Vite bakes this in at build time, so changing the API origin needs a rebuild, not
// a restart. In development it is unset and requests stay relative, which keeps them
// same-origin through the Vite proxy and needs neither CORS nor credentials.
const baseUrl = import.meta.env.VITE_API_URL?.replace(/\/+$/, '')

axios.defaults.baseURL = baseUrl || undefined
axios.defaults.withCredentials = Boolean(baseUrl)
