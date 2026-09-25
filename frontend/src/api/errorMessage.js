/**
 * Rodauth answers a failed request with `{ error, reason, "field-error":
 * [field, message] }`, and axios rejects with that body at `error.response.data`
 * — its own `error.message` is only ever "Request failed with status code 401",
 * which no screen should show.
 *
 * Gather whatever the API sent into one line, so a screen never renders an empty
 * alert, and fall back to the caller's own wording when there was nothing worth
 * repeating (a network failure, say).
 *
 * @param {unknown} error The rejection, usually from axios.
 * @param {string} fallback Message to show when the API said nothing useful.
 */
export function errorMessage(error, fallback) {
  const data = error?.response?.data
  const messages = [data?.error, data?.['field-error']?.[1]].filter(Boolean)

  return messages.length > 0 ? messages.join(' ') : fallback
}
