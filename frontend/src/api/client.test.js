import { afterEach, describe, expect, it, vi } from 'vitest'
import axios from 'axios'

// The module configures axios as a side effect of being imported, so every case
// re-imports it after stubbing the build-time variable.
async function importClient() {
  vi.resetModules()
  await import('./client.js')
}

describe('api client configuration', () => {
  afterEach(() => {
    vi.unstubAllEnvs()
    axios.defaults.baseURL = undefined
    axios.defaults.withCredentials = false
  })

  it('keeps requests relative when VITE_API_URL is not set', async () => {
    vi.stubEnv('VITE_API_URL', '')

    await importClient()

    expect(axios.defaults.baseURL).toBeUndefined()
    expect(axios.defaults.withCredentials).toBeFalsy()
  })

  it('targets the deployed API and sends credentials when VITE_API_URL is set', async () => {
    vi.stubEnv('VITE_API_URL', 'https://api.diciq.site')

    await importClient()

    expect(axios.defaults.baseURL).toBe('https://api.diciq.site')
    expect(axios.defaults.withCredentials).toBe(true)
  })

  it('trims trailing slashes so request paths do not double up', async () => {
    vi.stubEnv('VITE_API_URL', 'https://api.diciq.site/')

    await importClient()

    expect(axios.defaults.baseURL).toBe('https://api.diciq.site')
  })
})
