import { expect, test } from '@playwright/test'

const apiURL = process.env.PLAYWRIGHT_API_URL ?? 'http://127.0.0.1:8080'

test.describe('smoke', () => {
  test('backend API is available', async ({ request }) => {
    const health = await request.get(`${apiURL}/api/`)
    await expect(health).toBeOK()

    const healthBody = await health.json()
    expect(healthBody.status).toBe('UP')
    expect(healthBody.message).toContain('Backend is running')

    const products = await request.get(`${apiURL}/api/v1/products?page=1&size=1`)
    await expect(products).toBeOK()

    const productsBody = await products.json()
    expect(productsBody.code).toBe(200)
    expect(Array.isArray(productsBody.data)).toBe(true)
  })

  test('home page loads product cards through the frontend proxy', async ({ page }) => {
    const pageErrors: string[] = []
    page.on('pageerror', (error) => pageErrors.push(error.message))

    const productsResponse = page.waitForResponse(
      (response) => response.url().includes('/api/v1/products') && response.status() === 200,
    )

    const response = await page.goto('/')
    expect(response?.ok()).toBe(true)

    await productsResponse
    await expect(page.locator('article.card').first()).toBeVisible()

    const productCards = await page.locator('article.card').count()
    expect(productCards).toBeGreaterThan(0)
    expect(pageErrors).toEqual([])
  })

  test('login page shows the password login form', async ({ page }) => {
    await page.goto('/login')

    await expect(page.locator('#account')).toBeVisible()
    await expect(page.locator('#password')).toBeVisible()
    await expect(page.locator('button[type="submit"]')).toBeVisible()
  })

  test('checkout redirects unauthenticated users to login', async ({ page }) => {
    await page.goto('/checkout')

    await expect(page).toHaveURL(/\/login.*redirect=/)
  })
})
