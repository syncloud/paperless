import { test } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, openDocuments, expectDocumentCount, expectSuperuser } from '../helpers/paperless'

test('sso login, upload and list documents', async ({ page }) => {
  await test.step('log in through syncloud sso as a superuser', async () => {
    await login(page)
    await shoot(page, 'dashboard')
    await expectSuperuser(page)
  })

  await test.step('upload a pdf and a jpg', async () => {
    await uploadDocument(page, 'simple.pdf')
    await uploadDocument(page, 'simple.jpg')
    await shoot(page, 'uploaded')
  })

  await test.step('see them listed', async () => {
    await openDocuments(page)
    await expectDocumentCount(page, 2)
    await shoot(page, 'documents')
  })
})
