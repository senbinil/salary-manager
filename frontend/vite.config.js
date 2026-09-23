import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
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
