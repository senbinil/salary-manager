import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // The API is a separate Rails server on :3000. Routing it through the dev
  // server keeps every request same-origin, so the browser sends the Rodauth
  // `_backend_session` cookie with no CORS headers and no `withCredentials`.
  // No `rewrite` — the backend serves auth under the same `/api/v1` prefix.
  // `preview.proxy` defaults to this, so `npm run preview` inherits it too.
  server: {
    proxy: {
      '/api': { target: 'http://localhost:3000', changeOrigin: true },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.js',
    coverage: {
      provider: 'v8',
      // Vitest silently sets `skipFull: true` on the `text` reporter when it
      // detects an AI agent, which drops every 100%-covered file and leaves the
      // table empty. Pin it off so the table always lists files. `html` writes
      // the browsable report to coverage/.
      reporter: [['text', { skipFull: false }], 'html'],
      // Only JS/JSX source counts. Without this, imported assets (css, png,
      // svg) show up as 0%-covered files.
      include: ['src/**/*.{js,jsx}'],
      // main.jsx mounts the app into the real DOM and is never imported by a
      // spec, and the harness itself should not count towards coverage.
      exclude: ['src/main.jsx', 'src/test/**', 'src/**/*.test.{js,jsx}'],
    },
  },
})
