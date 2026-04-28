import { expect, test, type Page } from '@playwright/test'

const apiURL = process.env.PLAYWRIGHT_API_URL ?? 'http://127.0.0.1:8080'
const loginAccount = process.env.PLAYWRIGHT_LOGIN_ACCOUNT ?? 'user@example.com'
const loginPassword = process.env.PLAYWRIGHT_LOGIN_PASSWORD ?? '123456'

const fillPasswordLoginForm = async (page: Page, password: string) => {
  await test.step('填写账号和密码', async () => {
    await page.locator('#account').fill(loginAccount)
    await page.locator('#password').fill(password)
  })
}

test.describe('login', () => {
  test('login API accepts the seeded user credentials', async ({ request }) => {
    const response = await test.step('请求登录接口', async () => {
      return request.post(`${apiURL}/api/v1/auth/login`, {
        data: {
          account: loginAccount,
          password: loginPassword,
        },
      })
    })

    await test.step('校验登录接口成功响应', async () => {
      await expect(response).toBeOK()

      const body = await response.json()
      expect(body.data.token).toEqual(expect.any(String))
      expect(body.data.expiresIn).toBe(7200)
      expect(body.data.user.account).toBe(loginAccount)
      expect(body.data.user.password).toBeUndefined()
    })
  })

  test('login API rejects an incorrect password', async ({ request }) => {
    const response = await test.step('使用错误密码请求登录接口', async () => {
      return request.post(`${apiURL}/api/v1/auth/login`, {
        data: {
          account: loginAccount,
          password: 'wrong123',
        },
      })
    })

    await test.step('校验登录接口失败响应', async () => {
      expect(response.status()).toBe(400)

      const body = await response.json()
      expect(body.error.code).toBe('UNAUTHORIZED')
      expect(body.error.message).toBeTruthy()
    })
  })

  test('password login succeeds from the login page', async ({ page }) => {
    await test.step('打开登录页', async () => {
      await page.goto('/login')
    })
    await fillPasswordLoginForm(page, loginPassword)

    await test.step('提交登录表单', async () => {
      const loginResponse = page.waitForResponse(
        (response) => response.url().includes('/api/v1/auth/login') && response.status() === 200,
      )
      await page.locator('button[type="submit"]').click()
      await loginResponse
    })

    await test.step('校验登录成功状态', async () => {
      await expect(page).toHaveURL(/\/$/)

      const authSnapshot = await page.evaluate(() => JSON.parse(localStorage.getItem('auth:v1') || '{}'))
      expect(authSnapshot.token).toEqual(expect.any(String))
      expect(authSnapshot.user.account).toBe(loginAccount)
    })
  })

  test('password login shows an error for an incorrect password', async ({ page }) => {
    await test.step('打开登录页', async () => {
      await page.goto('/login')
    })
    await fillPasswordLoginForm(page, 'wrong123')

    await test.step('提交错误密码', async () => {
      const loginResponse = page.waitForResponse(
        (response) => response.url().includes('/api/v1/auth/login') && response.status() === 400,
      )
      await page.locator('button[type="submit"]').click()
      await loginResponse
    })

    await test.step('校验登录失败状态', async () => {
      await expect(page).toHaveURL(/\/login/)
      await expect(page.locator('[role="alert"]')).toBeVisible()

      const authSnapshot = await page.evaluate(() => JSON.parse(localStorage.getItem('auth:v1') || '{}'))
      expect(authSnapshot.token ?? null).toBeNull()
      expect(authSnapshot.user ?? null).toBeNull()
    })
  })

  test('login redirects back to checkout when the redirect query is present', async ({ page }) => {
    await test.step('访问受保护的结算页', async () => {
      await page.goto('/checkout')
      await expect(page).toHaveURL(/\/login.*redirect=/)
    })

    await fillPasswordLoginForm(page, loginPassword)

    await test.step('登录并等待接口成功', async () => {
      const loginResponse = page.waitForResponse(
        (response) => response.url().includes('/api/v1/auth/login') && response.status() === 200,
      )
      await page.locator('button[type="submit"]').click()
      await loginResponse
    })

    await test.step('校验回跳结算页', async () => {
      await expect(page).toHaveURL(/\/checkout$/)
    })
  })
})
