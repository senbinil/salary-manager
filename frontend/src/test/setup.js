import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

// Unmount anything rendered by React Testing Library between tests so that
// queries in one test cannot see the DOM of another.
afterEach(() => {
  cleanup()
})
