import { Page } from '@playwright/test'
import * as path from 'node:path'
import { expect } from '../fixtures'
import { env } from './env'

function appFrame(page: Page) {
  return page.locator('a[href="/documents"]').or(page.locator('pngx-app-frame'))
}

export async function login(page: Page) {
  await page.goto('/')

  const autheliaUser = page.locator('#username-textfield')
  await expect(autheliaUser.or(appFrame(page)).first()).toBeVisible({ timeout: 120_000 })

  if (await autheliaUser.isVisible()) {
    await autheliaUser.fill(env('PLAYWRIGHT_DEVICE_USER'))
    await page.locator('#password-textfield').fill(env('PLAYWRIGHT_DEVICE_PASSWORD'))
    await page.locator('#sign-in-button').click()
  }

  const signUp = page.getByRole('button', { name: 'Sign up' })
  await expect(signUp.or(appFrame(page)).first()).toBeVisible({ timeout: 120_000 })
  if (await signUp.isVisible()) {
    await signUp.click()
  }

  await expect(appFrame(page).first()).toBeVisible({ timeout: 120_000 })
}

export async function expectSuperuser(page: Page) {
  const res = await page.request.get('/api/ui_settings/')
  expect(res.ok()).toBeTruthy()
  const body = await res.json()
  expect(body.user?.is_superuser, JSON.stringify(body.user)).toBe(true)
}

export async function uploadDocument(page: Page, file: string) {
  await page.locator('input[type="file"]').first().setInputFiles(path.join(env('PLAYWRIGHT_SAMPLES'), file))
}

export async function openDocuments(page: Page) {
  await page.locator('a[href="/documents"]').first().click()
  await expect(page.locator('pngx-document-list')).toBeVisible()
}

export async function expectDocumentCount(page: Page, atLeast: number) {
  const cards = page.locator('pngx-document-card-small, pngx-document-card-large')
  await expect(async () => {
    await openDocuments(page)
    await expect(cards.nth(atLeast - 1)).toBeVisible({ timeout: 10_000 })
  }).toPass({ timeout: 300_000, intervals: [5_000] })
}
