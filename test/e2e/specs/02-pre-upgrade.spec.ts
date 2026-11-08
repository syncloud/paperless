import { test } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, expectDocumentCount } from '../helpers/paperless'

test('seed a document on the store version', async ({ page }) => {
  await test.step('log in through syncloud sso', async () => {
    await login(page)
  })

  await test.step('upload a document', async () => {
    await uploadDocument(page, 'simple.pdf')
  })

  await test.step('the document is listed', async () => {
    await expectDocumentCount(page, 1)
    await shoot(page, 'documents-before-upgrade')
  })
})
