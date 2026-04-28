import { expect, test, type APIRequestContext, type Page } from '@playwright/test'

const apiURL = process.env.PLAYWRIGHT_API_URL ?? 'http://127.0.0.1:8080'

const getAvailableProductId = async (request: APIRequestContext) => {
  const response = await request.get(`${apiURL}/api/v1/products?page=1&size=20`)
  await expect(response).toBeOK()

  const body = await response.json()
  const products = Array.isArray(body.data) ? body.data : []
  const product = products.find((item: any) => Number(item.stock ?? 0) > 0) ?? products[0]

  expect(product?.id).toBeTruthy()
  return String(product.id)
}

const openProductDetail = async (page: Page, productId: string) => {
  await test.step('打开商品详情页', async () => {
    const response = await page.goto(`/products/${productId}`)
    expect(response?.ok()).toBe(true)
    await expect(page.locator('.productCard')).toBeVisible()
  })
}

const selectFirstAvailableSku = async (page: Page) => {
  await test.step('选择可用规格', async () => {
    const groups = page.locator('.skuGroup')
    const groupCount = await groups.count()

    for (let i = 0; i < groupCount; i += 1) {
      const option = groups.nth(i).locator('.skuBtn:not([disabled])').first()
      await expect(option).toBeVisible()
      await option.click()
    }

    await expect(page.locator('.btnAdd')).toBeEnabled()
    await expect(page.locator('.btnBuy')).toBeEnabled()
  })
}

const readCartSnapshot = async (page: Page) => {
  return page.evaluate(() => JSON.parse(localStorage.getItem('cart:v1') || '{"items":[]}'))
}

test.describe('product detail', () => {
  test('product detail API returns detail data', async ({ request }) => {
    const productId = await getAvailableProductId(request)

    const response = await test.step('请求商品详情接口', async () => {
      return request.get(`${apiURL}/api/v1/products/${productId}`)
    })

    await test.step('校验商品详情接口响应', async () => {
      await expect(response).toBeOK()

      const body = await response.json()
      expect(body.code).toBe(200)
      expect(String(body.data.id)).toBe(productId)
      expect(body.data.name).toBeTruthy()
      expect(Number(body.data.price)).toBeGreaterThan(0)
      expect(Array.isArray(body.data.media)).toBe(true)
      expect(Array.isArray(body.data.skus)).toBe(true)
      expect(body.data.skus.length).toBeGreaterThan(0)
    })
  })

  test('product detail page renders product information', async ({ page, request }) => {
    const productId = await getAvailableProductId(request)

    await openProductDetail(page, productId)

    await test.step('校验详情页核心信息', async () => {
      await expect(page.locator('.heroImg')).toBeVisible()
      await expect(page.locator('.h1')).toBeVisible()
      await expect(page.locator('.priceMain')).toBeVisible()
      await expect(page.locator('.skuBtn').first()).toBeVisible()
      await expect(page.locator('.reviewsTitle')).toBeVisible()
      await expect(page).toHaveURL(new RegExp(`/products/${productId}$`))
    })
  })

  test('invalid product id shows an empty state', async ({ page }) => {
    await page.goto('/products/not-a-number')

    await expect(page).toHaveURL(/\/products\/not-a-number$/)
    await expect(page.locator('.panel')).toBeVisible()
    await expect(page.locator('.panelTitle')).toBeVisible()
  })

  test('sku selection enables purchase actions and quantity can increase', async ({ page, request }) => {
    const productId = await getAvailableProductId(request)

    await openProductDetail(page, productId)
    await selectFirstAvailableSku(page)

    await test.step('调整购买数量', async () => {
      const qtyValue = page.locator('.qtyValue')
      await expect(qtyValue).toHaveText('1')

      const increaseButton = page.locator('.qtyIconBtn[aria-label="增加数量"]')
      if (!(await increaseButton.isDisabled())) {
        await increaseButton.click()
        await expect(qtyValue).toHaveText('2')
      }
    })
  })

  test('adding product to cart stores the item locally', async ({ page, request }) => {
    const productId = await getAvailableProductId(request)

    await openProductDetail(page, productId)
    await selectFirstAvailableSku(page)

    await test.step('加入购物车', async () => {
      await page.locator('.btnAdd').click()
      await expect(page.locator('.item.success')).toBeVisible()
    })

    await test.step('校验本地购物车', async () => {
      const cart = await readCartSnapshot(page)
      expect(Array.isArray(cart.items)).toBe(true)
      expect(cart.items.some((item: any) => String(item.productId) === productId && Number(item.qty) >= 1)).toBe(true)
    })
  })

  test('buy now redirects unauthenticated users to login and keeps cart item', async ({ page, request }) => {
    const productId = await getAvailableProductId(request)

    await openProductDetail(page, productId)
    await selectFirstAvailableSku(page)

    await test.step('立即购买触发未登录拦截', async () => {
      await page.locator('.btnBuy').click()
      await expect(page).toHaveURL(/\/login.*redirect=/)
    })

    await test.step('校验立即购买前已写入购物车', async () => {
      const cart = await readCartSnapshot(page)
      expect(cart.items.some((item: any) => String(item.productId) === productId)).toBe(true)
    })
  })

  test('favorite action redirects unauthenticated users to login', async ({ page, request }) => {
    const productId = await getAvailableProductId(request)

    await openProductDetail(page, productId)

    await test.step('未登录点击收藏', async () => {
      await page.locator('.btnFav').click()
      await expect(page).toHaveURL(/\/login/)
    })
  })
})
