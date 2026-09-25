import axios from 'axios'
import { redirect } from 'react-router'
import { paths } from './paths.js'

/**
 * Route loader for the signed-in area.
 *
 * Asks the API which account the session cookie belongs to. Anything other than
 * a straight answer counts as signed out — a 401, an expired session, an
 * unreachable API — because the alternative is showing the product chrome to
 * someone whose session we could not confirm.
 */
export async function requireAuth() {
  try {
    await axios.get('/api/v1/me')
  } catch {
    throw redirect(paths.login)
  }
}
