import { test } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { login, openDocuments, expectDocumentCount } from '../helpers/paperless'

test('sso login and seeded document survive the upgrade', async ({ page }) => {
  await test.step('log in', async () => {
    await login(page)
    await shoot(page, 'dashboard-after-upgrade')
  })

  await test.step('the seeded document is still listed', async () => {
    await openDocuments(page)
    await expectDocumentCount(page, 1)
    await shoot(page, 'documents-after-upgrade')
  })
})
