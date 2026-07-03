import { expect, test, type Page } from '@playwright/test'

type CartItemFixture = {
  itemId: string
  productId: string
  skuId: string
  title: string
  price: number
  qty: number
  cover: string
}

const itemA: CartItemFixture = {
  itemId: 'ci_test_1',
  productId: '170',
  skuId: '508',
  title: 'Cart Test Product',
  price: 99.5,
  qty: 2,
  cover: '/product_170.jpg',
}

const itemB: CartItemFixture = {
  itemId: 'ci_test_2',
  productId: '171',
  skuId: 'default',
  title: 'Second Cart Product',
  price: 50,
  qty: 1,
  cover: '/product_171.jpg',
}

const seedCart = async (page: Page, items: CartItemFixture[]) => {
  await page.addInitScript((seedItems) => {
    localStorage.setItem('cart:v1', JSON.stringify({ v: 1, items: seedItems }))
  }, items)
}

const readCart = async (page: Page) => {
  return page.evaluate(() => JSON.parse(localStorage.getItem('cart:v1') || '{"items":[]}'))
}

test.describe('cart', () => {
  test('empty cart shows the empty state', async ({ page }) => {
    await page.goto('/cart')

    await expect(page.locator('article.item')).toHaveCount(0)
    await expect(page.locator('.wrap')).toBeVisible()
  })

  test('seeded cart renders item list and total area', async ({ page }) => {
    await seedCart(page, [itemA, itemB])
    await page.goto('/cart')

    await expect(page.locator('article.item')).toHaveCount(2)
    await expect(page.locator('.name').first()).toHaveText(itemA.title)
    await expect(page.locator('.qtyVal').first()).toHaveText(String(itemA.qty))
    await expect(page.locator('.footer')).toBeVisible()
    await expect(page.locator('.totalVal')).toBeVisible()
  })

  test('quantity buttons update the cart item quantity', async ({ page }) => {
    await seedCart(page, [{ ...itemA, qty: 1 }])
    await page.goto('/cart')

    await test.step('increase quantity', async () => {
      await page.locator('article.item').first().locator('.qtyBtn').last().click()
      await expect(page.locator('.qtyVal').first()).toHaveText('2')

      const cart = await readCart(page)
      expect(cart.items[0].qty).toBe(2)
    })

    await test.step('decrease quantity', async () => {
      await page.locator('article.item').first().locator('.qtyBtn').first().click()
      await expect(page.locator('.qtyVal').first()).toHaveText('1')

      const cart = await readCart(page)
      expect(cart.items[0].qty).toBe(1)
    })

    await test.step('quantity does not go below one', async () => {
      await page.locator('article.item').first().locator('.qtyBtn').first().click()
      await expect(page.locator('.qtyVal').first()).toHaveText('1')

      const cart = await readCart(page)
      expect(cart.items[0].qty).toBe(1)
    })
  })

  test('remove button deletes an item and shows empty state when cart becomes empty', async ({ page }) => {
    await seedCart(page, [itemA])
    await page.goto('/cart')

    await expect(page.locator('article.item')).toHaveCount(1)
    await page.locator('article.item').first().locator('.row').last().locator('button').first().click()

    await expect(page.locator('article.item')).toHaveCount(0)
    await expect(page.locator('.wrap')).toBeVisible()

    const cart = await readCart(page)
    expect(cart.items).toEqual([])
  })

  test('checkout redirects unauthenticated users to login and keeps cart data', async ({ page }) => {
    await seedCart(page, [itemA])
    await page.goto('/cart')

    await page.locator('.footer button').click()

    await expect(page).toHaveURL(/\/login.*redirect=/)

    const cart = await readCart(page)
    expect(cart.items).toHaveLength(1)
    expect(cart.items[0].itemId).toBe(itemA.itemId)
  })
})
