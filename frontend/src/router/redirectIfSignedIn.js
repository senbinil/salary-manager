import axios from 'axios'
import { redirect } from 'react-router'
import { paths } from './paths.js'

/**
 * Route loader for the screens that only exist for visitors without a session.
 *
 * A session that answers means there is nothing to do here, so the visitor goes
 * to the dashboard. A failed check is not an error: it means the sign-in form
 * is exactly where they belong — including when the API is unreachable, since
 * signing in is then the only way forward anyway.
 */
export async function redirectIfSignedIn() {
  try {
    await axios.get('/api/v1/me')
  } catch {
    return
  }

  throw redirect(paths.dashboard)
}
