import { expect, test, type APIRequestContext, type Page } from '@playwright/test'

const apiURL = process.env.PLAYWRIGHT_API_URL ?? 'http://127.0.0.1:8080'
const registerPassword = process.env.PLAYWRIGHT_REGISTER_PASSWORD ?? '123456'

const uniqueEmail = (scope: string) => {
  const suffix = `${Date.now()}_${Math.random().toString(16).slice(2, 8)}`
  return `pw_${scope}_${suffix}@example.test`
}

const registerAccount = async (request: APIRequestContext, account: string, password = registerPassword) => {
  return request.post(`${apiURL}/api/v1/auth/register`, {
    data: {
      account,
      password,
      nickname: account.split('@')[0],
    },
  })
}

const openEmailRegister = async (page: Page, path = '/register') => {
  await page.goto(path)
  await page.locator('[role="tab"]').nth(1).click()
  await expect(page.locator('#email')).toBeVisible()
}

const fillEmailRegisterForm = async (page: Page, account: string, password = registerPassword) => {
  await page.locator('#email').fill(account)
  await page.locator('#code').fill('123456')
  await page.locator('#password').fill(password)
  await page.locator('#confirm').fill(password)
}

const readAuthSnapshot = async (page: Page) => {
  return page.evaluate(() => JSON.parse(localStorage.getItem('auth:v1') || '{}'))
}

test.describe('register', () => {
  test('register API accepts a new account', async ({ request }) => {
    const account = uniqueEmail('api_success')

    const response = await test.step('request register API', async () => {
      return registerAccount(request, account)
    })

    await test.step('verify successful register response', async () => {
      await expect(response).toBeOK()

      const body = await response.json()
      expect(body.data.account).toBe(account)
      expect(body.data.nickname).toBe(account.split('@')[0])
      expect(body.data.password).toBeUndefined()
      expect(body.meta.requestId).toEqual(expect.any(String))
    })
  })

  test('register API rejects a duplicated account', async ({ request }) => {
    const account = uniqueEmail('api_duplicate')

    const firstResponse = await registerAccount(request, account)
    await expect(firstResponse).toBeOK()

    const duplicateResponse = await test.step('request register API with the same account again', async () => {
      return registerAccount(request, account)
    })

    await test.step('verify duplicated account error', async () => {
      expect(duplicateResponse.status()).toBe(400)

      const body = await duplicateResponse.json()
      expect(body.error.code).toBe('VALIDATION_FAILED')
      expect(body.error.message).toBeTruthy()
    })
  })

  test('register page keeps submit disabled until required fields are valid', async ({ page }) => {
    await openEmailRegister(page)

    const submitButton = page.locator('button[type="submit"]')
    const agreement = page.locator('input[type="checkbox"]')

    await test.step('invalid email and password mismatch cannot submit', async () => {
      await page.locator('#email').fill('invalid-email')
      await page.locator('#code').fill('123456')
      await page.locator('#password').fill('12345')
      await page.locator('#confirm').fill('123456')

      await expect(submitButton).toBeDisabled()
    })

    await test.step('valid fields still require agreement', async () => {
      await page.locator('#email').fill(uniqueEmail('form_valid'))
      await page.locator('#password').fill(registerPassword)
      await page.locator('#confirm').fill(registerPassword)
      await agreement.uncheck()

      await expect(submitButton).toBeDisabled()
    })
  })

  test('email registration succeeds from the register page and follows redirect', async ({ page }) => {
    const account = uniqueEmail('page_success')

    await openEmailRegister(page, '/register?redirect=/checkout')
    await fillEmailRegisterForm(page, account)

    await test.step('submit register form', async () => {
      const registerResponse = page.waitForResponse(
        (response) => response.url().includes('/api/v1/auth/register') && response.status() === 200,
      )
      const loginResponse = page.waitForResponse(
        (response) => response.url().includes('/api/v1/auth/login') && response.status() === 200,
      )

      await page.locator('button[type="submit"]').click()
      await registerResponse
      await loginResponse
    })

    await test.step('verify auto login and redirect', async () => {
      await expect(page).toHaveURL(/\/checkout$/)

      const authSnapshot = await readAuthSnapshot(page)
      expect(authSnapshot.token).toEqual(expect.any(String))
      expect(authSnapshot.user.account).toBe(account)
    })
  })

  test('register page shows an error for duplicated account', async ({ page, request }) => {
    const account = uniqueEmail('page_duplicate')
    const firstResponse = await registerAccount(request, account)
    await expect(firstResponse).toBeOK()

    await openEmailRegister(page)
    await fillEmailRegisterForm(page, account)

    await test.step('submit duplicated account', async () => {
      const registerResponse = page.waitForResponse(
        (response) => response.url().includes('/api/v1/auth/register') && response.status() === 400,
      )
      await page.locator('button[type="submit"]').click()
      await registerResponse
    })

    await test.step('verify failure state', async () => {
      await expect(page).toHaveURL(/\/register/)
      await expect(page.locator('[role="alert"]')).toBeVisible()

      const authSnapshot = await readAuthSnapshot(page)
      expect(authSnapshot.token ?? null).toBeNull()
      expect(authSnapshot.user ?? null).toBeNull()
    })
  })

  test('register page keeps redirect when navigating to login', async ({ page }) => {
    await page.goto('/register?redirect=/checkout')
    await page.locator('.footer button').click()

    await expect(page).toHaveURL(/\/login.*redirect=%2Fcheckout|\/login.*redirect=\/checkout/)
  })
})
