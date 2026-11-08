import { test } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { login, expectDocumentCount } from '../helpers/paperless'

test('sso login works and the seeded document survived the upgrade', async ({ page }) => {
  await test.step('log in through syncloud sso', async () => {
    await login(page)
    await shoot(page, 'dashboard-after-upgrade')
  })

  await test.step('the document seeded before the upgrade is listed', async () => {
    await expectDocumentCount(page, 1)
    await shoot(page, 'documents-after-upgrade')
  })
})
