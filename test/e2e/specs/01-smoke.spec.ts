import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, openDocuments, expectDocumentCount } from '../helpers/paperless'

test.describe('paperless smoke', () => {
  test('log in through syncloud sso', async ({ page }, testInfo) => {
    await login(page)
    await shoot(page, testInfo, 'dashboard')
  })

  test('upload a pdf and a jpg and see them listed', async ({ page }, testInfo) => {
    await login(page)
    await uploadDocument(page, 'simple.pdf')
    await uploadDocument(page, 'simple.jpg')
    await shoot(page, testInfo, 'uploaded')
    await openDocuments(page)
    await expectDocumentCount(page, 2)
    await shoot(page, testInfo, 'documents')
  })
})
