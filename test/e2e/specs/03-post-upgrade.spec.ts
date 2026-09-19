import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { login, openDocuments, expectDocumentCount } from '../helpers/paperless'

test.describe('paperless after the upgrade', () => {
  test('sso login still works', async ({ page }, testInfo) => {
    await login(page)
    await shoot(page, testInfo, 'dashboard-after-upgrade')
  })

  test('the document seeded before the upgrade survived', async ({ page }, testInfo) => {
    await login(page)
    await openDocuments(page)
    await expectDocumentCount(page, 1)
    await shoot(page, testInfo, 'documents-after-upgrade')
  })
})
