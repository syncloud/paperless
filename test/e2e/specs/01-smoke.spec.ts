import { test } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { login, uploadDocument, expectDocumentCount, expectSuperuser } from '../helpers/paperless'

test('sso login, upload a pdf and a jpg and see them listed', async ({ page }) => {
  await test.step('log in through syncloud sso', async () => {
    await login(page)
    await shoot(page, 'dashboard')
  })

  await test.step('the sso user is a superuser', async () => {
    await expectSuperuser(page)
  })

  await test.step('upload documents', async () => {
    await uploadDocument(page, 'simple.pdf')
    await uploadDocument(page, 'simple.jpg')
  })

  await test.step('documents are listed', async () => {
    await expectDocumentCount(page, 2)
    await shoot(page, 'documents')
  })
})
