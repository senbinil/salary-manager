/**
 * Number and currency formatting for the dashboard and the employee detail view.
 *
 * Amounts reach the client as decimal strings, and a currency code can be one
 * the browser does not recognise, so every helper falls back to a plain
 * "amount currency" rendering rather than throwing.
 */

/** The exact amount, in the number of decimal places the currency uses. */
export function formatAmount(amount, currency) {
  const numericAmount = Number(amount)
  if (!Number.isFinite(numericAmount)) return `${amount} ${currency}`

  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
    }).format(numericAmount)
  } catch {
    return `${amount} ${currency}`
  }
}

/**
 * The same amount rounded to whole units. Aggregate figures read better without
 * the four decimal places the API sends.
 */
export function formatWholeAmount(amount, currency) {
  const numericAmount = Number(amount)
  if (!Number.isFinite(numericAmount)) return `${amount} ${currency}`

  try {
    return new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency,
      maximumFractionDigits: 0,
    }).format(numericAmount)
  } catch {
    return `${amount} ${currency}`
  }
}

/** A plain count with the browser's grouping, so 8100 reads as "8,100". */
export function formatCount(count) {
  return new Intl.NumberFormat().format(count)
}
