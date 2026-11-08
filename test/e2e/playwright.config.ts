import { defineConfig, devices } from '@playwright/test'
import { env } from './helpers/env'

export default defineConfig({
  testDir: './specs',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: 'list',
  outputDir: '/tmp/playwright-test-results',
  timeout: 600_000,
  expect: { timeout: 30_000 },
  use: {
    baseURL: `https://${env('PLAYWRIGHT_APP_DOMAIN')}`,
    ignoreHTTPSErrors: true,
    trace: 'off',
    video: 'off',
    screenshot: 'off',
  },
  projects: [
    {
      name: 'desktop',
      use: { ...devices['Desktop Chrome'], viewport: { width: 1440, height: 960 } },
    },
  ],
})
