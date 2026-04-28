import { expect, test, type APIRequestContext, type Page } from '@playwright/test'

const apiURL = process.env.PLAYWRIGHT_API_URL ?? 'http://127.0.0.1:8080'
const checkoutPassword = process.env.PLAYWRIGHT_CHECKOUT_PASSWORD ?? '123456'

type AuthSession = {
  account: string
  token: string
  user: Record<string, unknown>
  expiresIn: number
}

type ProductFixture = {
  id: string
  title: string
  price: number
  stock: number
}

type CartItemFixture = {
  itemId: string
  productId: string
  skuId: string
  title: string
  price: number
  qty: number
  cover: string
}

const uniqueEmail = (scope: string) => {
  const suffix = `${Date.now()}_${Math.random().toString(16).slice(2, 8)}`
  return `pw_checkout_${scope}_${suffix}@example.test`
}

const authHeaders = (token: string) => ({
  Authorization: `Bearer ${token}`,
})

const createSession = async (request: APIRequestContext, scope: string): Promise<AuthSession> => {
  const account = uniqueEmail(scope)
  const nickname = account.split('@')[0]

  const registerResponse = await request.post(`${apiURL}/api/v1/auth/register`, {
    data: { account, password: checkoutPassword, nickname },
  })
  await expect(registerResponse).toBeOK()

  const loginResponse = await request.post(`${apiURL}/api/v1/auth/login`, {
    data: { account, password: checkoutPassword },
  })
  await expect(loginResponse).toBeOK()

  const body = await loginResponse.json()
  return {
    account,
    token: body.data.token,
    user: body.data.user,
    expiresIn: body.data.expiresIn,
  }
}

const getAvailableProduct = async (request: APIRequestContext): Promise<ProductFixture> => {
  const response = await request.get(`${apiURL}/api/v1/products?page=1&size=50`)
  await expect(response).toBeOK()

  const body = await response.json()
  const products = Array.isArray(body.data) ? body.data : []
  const sorted = products
    .map((item: any) => ({
      id: String(item.id),
      title: String(item.name ?? item.title ?? `Product ${item.id}`),
      price: Number(item.price ?? 0),
      stock: Number(item.stock ?? 0),
    }))
    .filter((item: ProductFixture) => item.id && item.price > 0 && item.stock > 0)
    .sort((a: ProductFixture, b: ProductFixture) => b.stock - a.stock)

  expect(sorted.length).toBeGreaterThan(0)
  return sorted[0]
}

const toCartItem = (product: ProductFixture, qty = 1): CartItemFixture => ({
  itemId: `ci_checkout_${product.id}_${Date.now()}`,
  productId: product.id,
  skuId: 'default',
  title: product.title,
  price: product.price,
  qty,
  cover: `/product_${product.id}.jpg`,
})

const seedAuthAndCart = async (page: Page, session: AuthSession, items: CartItemFixture[] = []) => {
  await page.addInitScript(
    ({ auth, cartItems }) => {
      localStorage.setItem(
        'auth:v1',
        JSON.stringify({
          v: 2,
          user: auth.user,
          token: auth.token,
          expiresAt: Date.now() + auth.expiresIn * 1000,
        }),
      )
      localStorage.setItem('cart:v1', JSON.stringify({ v: 1, items: cartItems }))
      localStorage.removeItem('orderDraft:v1')
      localStorage.removeItem('orders:v1')
    },
    { auth: session, cartItems: items },
  )
}

const readLocalStorageJson = async (page: Page, key: string) => {
  return page.evaluate((storageKey) => JSON.parse(localStorage.getItem(storageKey) || '{}'), key)
}

const addServerCartItem = async (
  request: APIRequestContext,
  session: AuthSession,
  product: ProductFixture,
  quantity = 1,
) => {
  const response = await request.post(`${apiURL}/api/v1/cart/items`, {
    headers: authHeaders(session.token),
    data: { productId: Number(product.id), skuId: 'default', quantity },
  })
  await expect(response).toBeOK()
  const body = await response.json()
  expect(body.code).toBe(200)
}

test.describe('checkout', () => {
  test('checkout route redirects unauthenticated users to login', async ({ page }) => {
    await page.goto('/checkout')

    await expect(page).toHaveURL(/\/login.*redirect=/)
  })

  test('authenticated empty cart shows the empty state', async ({ page, request }) => {
    const session = await createSession(request, 'empty_cart')
    await seedAuthAndCart(page, session)

    await page.goto('/checkout')

    await expect(page.locator('.title')).toBeVisible()
    await expect(page.locator('button.payBtn')).toHaveCount(0)
  })

  test('checkout page renders cart items and amount summary', async ({ page, request }) => {
    const session = await createSession(request, 'render')
    const product = await getAvailableProduct(request)
    const cartItem = toCartItem(product, 2)
    await seedAuthAndCart(page, session, [cartItem])

    await page.goto('/checkout')

    await expect(page.locator('section[aria-label]').first()).toBeVisible()
    await expect(page.locator('.addr').first()).toBeVisible()
    await expect(page.locator('.item')).toHaveCount(1)
    await expect(page.locator('.name')).toHaveText(product.title)
    await expect(page.locator('.sub')).toHaveText('x2')
    await expect(page.locator('.sumTotalVal')).toBeVisible()
    await expect(page.locator('button.payBtn')).toBeEnabled()
  })

  test('invoice title is required when invoice is selected', async ({ page, request }) => {
    const session = await createSession(request, 'invoice')
    const product = await getAvailableProduct(request)
    await seedAuthAndCart(page, session, [toCartItem(product)])

    await page.goto('/checkout')

    const submitButton = page.locator('button.payBtn')
    await expect(submitButton).toBeEnabled()

    await page.locator('input[name="inv"][value="personal"]').check()
    await expect(submitButton).toBeDisabled()

    await page.locator('.invoiceInput input').fill('个人')
    await expect(submitButton).toBeEnabled()
  })

  test('submitting checkout creates an order and opens cashier', async ({ page, request }) => {
    const session = await createSession(request, 'submit')
    const product = await getAvailableProduct(request)
    const cartItem = toCartItem(product)
    await seedAuthAndCart(page, session, [cartItem])

    await page.goto('/checkout')

    const checkoutResponsePromise = page.waitForResponse(
      (response) => response.url().includes('/api/v1/orders/checkout') && response.status() === 200,
    )
    await page.locator('button.payBtn').click()
    const checkoutResponse = await checkoutResponsePromise

    const body = await checkoutResponse.json()
    expect(body.code).toBe(200)
    expect(body.data.id).toBeTruthy()
    expect(body.data.items).toHaveLength(1)

    await expect(page).toHaveURL(/\/cashier\?orderId=/)

    const orderDraft = await readLocalStorageJson(page, 'orderDraft:v1')
    expect(String(orderDraft.orderId)).toBe(String(body.data.id))
    expect(Number(orderDraft.amounts.payable)).toBeGreaterThan(0)

    const cart = await readLocalStorageJson(page, 'cart:v1')
    expect(cart.items).toEqual([])
  })

  test('checkout API fails when server cart is empty', async ({ request }) => {
    const session = await createSession(request, 'api_empty')

    const response = await request.post(`${apiURL}/api/v1/orders/checkout`, {
      headers: authHeaders(session.token),
      data: { addressId: 0, couponCode: '' },
    })
    await expect(response).toBeOK()

    const body = await response.json()
    expect(body.code).toBe(500)
    expect(body.message).toBeTruthy()
  })

  test('checkout API creates an order from server cart', async ({ request }) => {
    const session = await createSession(request, 'api_success')
    const product = await getAvailableProduct(request)
    await addServerCartItem(request, session, product)

    const response = await request.post(`${apiURL}/api/v1/orders/checkout`, {
      headers: authHeaders(session.token),
      data: { addressId: 0, couponCode: '' },
    })
    await expect(response).toBeOK()

    const body = await response.json()
    expect(body.code).toBe(200)
    expect(body.data.id).toBeTruthy()
    expect(Number(body.data.totalAmount)).toBeGreaterThan(0)
    expect(body.data.items).toHaveLength(1)

    const cartResponse = await request.get(`${apiURL}/api/v1/cart`, {
      headers: authHeaders(session.token),
    })
    await expect(cartResponse).toBeOK()

    const cartBody = await cartResponse.json()
    expect(cartBody.data).toEqual([])
  })
})
