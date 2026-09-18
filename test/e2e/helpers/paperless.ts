import { Page, expect } from '@playwright/test'
import * as path from 'node:path'

const user = process.env.PLAYWRIGHT_DEVICE_USER ?? 'user'
const password = process.env.PLAYWRIGHT_DEVICE_PASSWORD ?? 'Password1'
const samples = process.env.PLAYWRIGHT_SAMPLES ?? 'build/samples'

export async function dump(page: Page, label: string) {
  console.log(`[${label}] url=${page.url()}`)
  console.log(`[${label}] title=${await page.title().catch(() => '?')}`)
  const html = await page.content().catch(() => '')
  console.log(`[${label}] html=\n${html.slice(0, 4000)}`)
}

function appFrame(page: Page) {
  return page.locator('a[href="/documents"]').or(page.locator('pngx-app-frame'))
}

export async function login(page: Page) {
  await page.goto('/')

  const autheliaUser = page.locator('#username-textfield')

  try {
    await expect(autheliaUser.or(appFrame(page)).first()).toBeVisible({ timeout: 120_000 })
  } catch (e) {
    await dump(page, 'no-login-form-and-no-app')
    throw e
  }

  if (await autheliaUser.isVisible().catch(() => false)) {
    await autheliaUser.fill(user)
    await page.locator('#password-textfield').fill(password)
    await page.locator('#sign-in-button').click()
  }

  const signUp = page.getByRole('button', { name: 'Sign up' })
  try {
    await signUp.waitFor({ state: 'visible', timeout: 15_000 })
    await signUp.click()
  } catch {
    // allauth only asks to confirm the social account on the very first login
  }

  await expectLoggedIn(page)
}

export async function expectLoggedIn(page: Page) {
  try {
    await expect(appFrame(page).first()).toBeVisible({ timeout: 120_000 })
  } catch (e) {
    await dump(page, 'app-frame-missing')
    throw e
  }
}

export async function uploadDocument(page: Page, file: string) {
  await page.locator('input[type="file"]').first().setInputFiles(path.join(samples, file))

  const done = page.getByText('Dismiss completed', { exact: false })
    .or(page.getByText('Upload complete', { exact: false }))
  try {
    await expect(done.first()).toBeVisible({ timeout: 180_000 })
  } catch (e) {
    await dump(page, `upload-not-confirmed-${file}`)
    throw e
  }
}

export async function openDocuments(page: Page) {
  await page.locator('a[href="/documents"]').first().click()
}

export async function expectDocumentCount(page: Page, atLeast: number) {
  const cards = page.locator('pngx-document-card-small, pngx-document-card-large')
  try {
    await expect(async () => {
      expect(await cards.count()).toBeGreaterThanOrEqual(atLeast)
    }).toPass({ timeout: 180_000 })
  } catch (e) {
    await dump(page, 'document-list')
    throw e
  }
}
