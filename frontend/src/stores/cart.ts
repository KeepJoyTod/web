import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'
import { api } from '../lib/api'

export type CartItem = {
  itemId: string
  productId: string
  skuId: string
  title: string
  price: number
  qty: number
  cover: string
}

type CartSnapshotV1 = {
  v: 1
  items: CartItem[]
}

const STORAGE_KEY = 'cart:v1'

const readSnapshot = (): CartSnapshotV1 => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { v: 1, items: [] }
    const parsed = JSON.parse(raw) as CartSnapshotV1
    if (parsed?.v !== 1) return { v: 1, items: [] }
    return { v: 1, items: Array.isArray(parsed.items) ? parsed.items : [] }
  } catch {
    return { v: 1, items: [] }
  }
}

const uid = () => `ci_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

export const useCartStore = defineStore('cart', () => {
  const snapshot = ref<CartSnapshotV1>(readSnapshot())

  const items = computed(() => snapshot.value.items)
  const count = computed(() => snapshot.value.items.reduce((sum, it) => sum + it.qty, 0))
  const amount = computed(() => snapshot.value.items.reduce((sum, it) => sum + it.qty * it.price, 0))

  const addItem = (input: Omit<CartItem, 'itemId'>) => {
    const existed = snapshot.value.items.find((it) => it.productId === input.productId && it.skuId === input.skuId)
    if (existed) {
      existed.qty += input.qty
      try {
        const pid = Number(input.productId)
        if (Number.isFinite(pid)) {
          api.post('/v1/cart/items', { productId: pid, quantity: input.qty }).catch(() => {})
        }
      } catch {}
      return
    }
    snapshot.value.items.push({ ...input, itemId: uid() })
    try {
      const pid = Number(input.productId)
      if (Number.isFinite(pid)) {
        api.post('/v1/cart/items', { productId: pid, quantity: input.qty }).catch(() => {})
      }
    } catch {}
  }

  const updateQty = (itemId: string, qty: number) => {
    const target = snapshot.value.items.find((it) => it.itemId === itemId)
    if (!target) return
    target.qty = Math.max(1, Math.floor(qty))
    const pid = Number(target.productId)
    if (!Number.isFinite(pid)) return
    api
      .get('/v1/cart')
      .then((res) => {
        const list = Array.isArray(res.data?.data) ? res.data.data : []
        const found = list.find((x: any) => Number(x.productId) === pid)
        if (found && found.id != null) {
          return api.put(`/v1/cart/items/${encodeURIComponent(found.id)}`, { quantity: target.qty })
        }
      })
      .catch(() => {})
  }

  const removeItem = (itemId: string) => {
    const target = snapshot.value.items.find((it) => it.itemId === itemId)
    snapshot.value.items = snapshot.value.items.filter((it) => it.itemId !== itemId)
    if (!target) return
    const pid = Number(target.productId)
    if (!Number.isFinite(pid)) return
    api
      .get('/v1/cart')
      .then((res) => {
        const list = Array.isArray(res.data?.data) ? res.data.data : []
        const found = list.find((x: any) => Number(x.productId) === pid)
        if (found && found.id != null) {
          return api.delete(`/v1/cart/items/${encodeURIComponent(found.id)}`)
        }
      })
      .catch(() => {})
  }

  const clear = () => {
    snapshot.value.items = []
  }

  watch(
    snapshot,
    (v) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
    },
    { deep: true },
  )

  return { items, count, amount, addItem, updateQty, removeItem, clear }
})
