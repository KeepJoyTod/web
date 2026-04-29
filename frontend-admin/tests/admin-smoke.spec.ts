import { expect, test } from '@playwright/test'

test('admin login page renders with default credentials', async ({ page }) => {
  await page.goto('/login')
  await expect(page.getByRole('heading', { name: '后台管理登录' })).toBeVisible()
  await expect(page.locator('input').nth(0)).toHaveValue('admin@example.com')
  await expect(page.locator('input').nth(1)).toHaveValue('admin123')
})
