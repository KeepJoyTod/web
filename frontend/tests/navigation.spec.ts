import { expect, test, type Page } from '@playwright/test'

const apiURL = process.env.PLAYWRIGHT_API_URL ?? 'http://127.0.0.1:8080'

const expectPageHasContent = async (page: Page) => {
  await expect(page.locator('#app')).toBeVisible()
  await expect
    .poll(async () => page.locator('body').evaluate((body) => body.innerText.trim().length))
    .toBeGreaterThan(0)
}

test.describe('core page navigation', () => {
  test('backend is available before navigation tests', async ({ request }) => {
    const response = await request.get(`${apiURL}/api/`)
    await expect(response).toBeOK()
  })

  test('public core routes render content', async ({ page }) => {
    const routes = ['/', '/category', '/search', '/cart', '/me', '/phone', '/computer', '/appliance']

    for (const route of routes) {
      await test.step(`open ${route}`, async () => {
        const response = await page.goto(route)
        expect(response?.ok()).toBe(true)
        await expect(page).toHaveURL(new RegExp(`${route === '/' ? '/$' : `${route}$`}`))
        await expectPageHasContent(page)
      })
    }
  })

  test('bottom navigation links switch between main tabs', async ({ page }) => {
    await page.goto('/')

    const links = [
      { href: '/category', expected: /\/category$/ },
      { href: '/search', expected: /\/search$/ },
      { href: '/cart', expected: /\/cart$/ },
      { href: '/me', expected: /\/me$/ },
      { href: '/', expected: /\/$/ },
    ]

    for (const link of links) {
      await test.step(`click bottom nav ${link.href}`, async () => {
        await page.locator(`nav a[href="${link.href}"]`).click()
        await expect(page).toHaveURL(link.expected)
        await expectPageHasContent(page)
      })
    }
  })

  test('home shortcut buttons navigate to core category pages', async ({ page }) => {
    const shortcuts = [
      { index: 0, expected: /\/phone$/ },
      { index: 1, expected: /\/computer$/ },
      { index: 3, expected: /\/appliance$/ },
      { index: 7, expected: /\/category$/ },
    ]

    for (const shortcut of shortcuts) {
      await test.step(`click home shortcut ${shortcut.index}`, async () => {
        await page.goto('/')
        await page.locator('button.cat').nth(shortcut.index).click()
        await expect(page).toHaveURL(shortcut.expected)
        await expectPageHasContent(page)
      })
    }
  })

  test('home search form navigates to search results with query', async ({ page }) => {
    await page.goto('/')

    await page.locator('form[role="search"] input[type="search"]').fill('phone')
    await page.locator('form[role="search"]').evaluate((form) => {
      form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    })

    await expect(page).toHaveURL(/\/search\?q=phone$/)
    await expectPageHasContent(page)
  })

  test('clicking a product card opens product detail page', async ({ page }) => {
    await page.goto('/')

    await expect(page.locator('article.card .cardBtn').first()).toBeVisible()
    await page.locator('article.card .cardBtn').first().click()

    await expect(page).toHaveURL(/\/products\/\d+$/)
    await expectPageHasContent(page)
  })

  test('protected routes redirect unauthenticated users to login', async ({ page }) => {
    const protectedRoutes = ['/checkout', '/favorites', '/messages', '/aftersales']

    for (const route of protectedRoutes) {
      await test.step(`open protected route ${route}`, async () => {
        await page.goto(route)
        await expect(page).toHaveURL(/\/login.*redirect=/)
      })
    }
  })
})
