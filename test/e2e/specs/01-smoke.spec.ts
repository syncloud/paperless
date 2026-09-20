import { test } from '@playwright/test'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, openDocuments, expectDocumentCount, expectSuperuser } from '../helpers/paperless'

test.describe('paperless smoke', () => {
  test('log in through syncloud sso and be a superuser', async ({ page }, testInfo) => {
    await login(page)
    await shoot(page, testInfo, 'dashboard')
    await expectSuperuser(page)
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
