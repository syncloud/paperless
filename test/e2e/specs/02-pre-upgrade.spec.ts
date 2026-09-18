import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, openDocuments, expectDocumentCount } from '../helpers/paperless'

test.describe('paperless before the upgrade', () => {
  test('seed a document on the store version', async ({ page }, testInfo) => {
    await login(page)
    await uploadDocument(page, 'simple.pdf')
    await openDocuments(page)
    await expectDocumentCount(page, 1)
    await shoot(page, testInfo, 'seeded')
  })
})
