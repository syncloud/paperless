import { test } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, openDocuments, expectDocumentCount } from '../helpers/paperless'

test('seed a document on the store version', async ({ page }) => {
  await test.step('log in', async () => {
    await login(page)
    await shoot(page, 'dashboard-before-upgrade')
  })

  await test.step('upload a document', async () => {
    await uploadDocument(page, 'simple.pdf')
  })

  await test.step('see it listed', async () => {
    await openDocuments(page)
    await expectDocumentCount(page, 1)
    await shoot(page, 'documents-before-upgrade')
  })
})
