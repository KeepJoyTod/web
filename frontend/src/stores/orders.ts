import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'
import { api } from '../lib/api'

import type { Address } from './orderDraft'
import type { CartItem } from './cart'

export type OrderStatus = 'Created' | 'Paid' | 'Shipped' | 'Completed' | 'Cancelled'

export type OrderItem = {
  orderItemId: string
  productId: string
  skuId: string
  title: string
  price: number
  qty: number
  cover: string
}

export type Order = {
  id: string
  status: OrderStatus
  createdAt: string
  paidAt: string | null
  items: OrderItem[]
  amounts: {
    items: number
    discount: number
    shipping: number
    payable: number
    paid: number
  }
  address: Address
}

type SnapshotV1 = {
  v: 1
  orders: Order[]
}

const STORAGE_KEY = 'orders:v1'

const readSnapshot = (): SnapshotV1 => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { v: 1, orders: [] }
    const parsed = JSON.parse(raw) as SnapshotV1
    if (parsed?.v !== 1) return { v: 1, orders: [] }
    return { v: 1, orders: Array.isArray(parsed.orders) ? parsed.orders : [] }
  } catch {
    return { v: 1, orders: [] }
  }
}

const oid = () => `o_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`
const oiid = () => `oi_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

export const useOrdersStore = defineStore('orders', () => {
  const snapshot = ref<SnapshotV1>(readSnapshot())

  const orders = computed(() => snapshot.value.orders.slice().sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)))

  const getById = (id: string) => snapshot.value.orders.find((x) => x.id === id) ?? null

  const mapStatus = (s: any): OrderStatus => {
    if (s === 1 || s === 'Paid') return 'Paid'
    if (s === 2 || s === 'Shipped') return 'Shipped'
    if (s === 3 || s === 'Completed') return 'Completed'
    if (s === 4 || s === 'Cancelled') return 'Cancelled'
    return 'Created'
  }

  const toOrder = (x: any): Order => {
    const id = String(x.id ?? x.orderId ?? '')
    const status = mapStatus(x.status)
    const createdAt = x.createTime ? new Date(x.createTime).toISOString() : new Date().toISOString()
    const paidAt = x.payTime ? new Date(x.payTime).toISOString() : null
    const items: OrderItem[] = Array.isArray(x.items)
      ? x.items.map((it: any) => ({
          orderItemId: String(it.id ?? ''),
          productId: String(it.productId ?? ''),
          skuId: String(it.skuId ?? 'default'),
          title: String(it.productName ?? it.title ?? '商品'),
          price: Number(it.price ?? it.unitPrice ?? 0),
          qty: Number(it.quantity ?? it.qty ?? 1),
          cover: '',
        }))
      : []
    const itemsAmount = Number(x.totalAmount ?? 0)
    const paidAmount = Number(x.payAmount ?? 0)
    return {
      id,
      status,
      createdAt,
      paidAt,
      items,
      address: {
        receiver: '',
        phone: '',
        region: '',
        detail: '',
      },
      amounts: {
        items: itemsAmount,
        discount: 0,
        shipping: 0,
        payable: Number.isFinite(paidAmount) && paidAmount > 0 ? paidAmount : itemsAmount,
        paid: Number.isFinite(paidAmount) ? paidAmount : 0,
      },
    }
  }

  const createFromCheckout = (input: {
    orderId?: string
    cartItems: CartItem[]
    address: Address
    discount: number
    shipping: number
  }) => {
    const id = input.orderId || oid()
    const createdAt = new Date().toISOString()
    const itemsAmount = input.cartItems.reduce((sum, it) => sum + it.price * it.qty, 0)
    const payable = Math.max(0, itemsAmount - input.discount + input.shipping)

    const items: OrderItem[] = input.cartItems.map((it) => ({
      orderItemId: oiid(),
      productId: it.productId,
      skuId: it.skuId,
      title: it.title,
      price: it.price,
      qty: it.qty,
      cover: it.cover,
    }))

    const order: Order = {
      id,
      status: 'Created',
      createdAt,
      paidAt: null,
      items,
      address: input.address,
      amounts: {
        items: itemsAmount,
        discount: input.discount,
        shipping: input.shipping,
        payable,
        paid: 0,
      },
    }

    snapshot.value.orders = [order, ...snapshot.value.orders.filter((x) => x.id !== id)]
    return id
  }

  const cancel = (id: string) => {
    const t = snapshot.value.orders.find((x) => x.id === id)
    if (!t) return
    if (t.status !== 'Created') return
    t.status = 'Cancelled'
  }

  const markPaid = (id: string, paidAtIso: string) => {
    const t = snapshot.value.orders.find((x) => x.id === id)
    if (!t) return
    t.status = 'Paid'
    t.paidAt = paidAtIso
    t.amounts.paid = t.amounts.payable
  }

  const refreshFromBackend = async () => {
    const res = await api.get('/v1/orders', { params: { page: 1, size: 10 } })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    const mapped: Order[] = []
    for (const row of list) {
      const id = row?.id
      if (id != null) {
        try {
          const d = await api.get(`/v1/orders/${encodeURIComponent(id)}`)
          mapped.push(toOrder(d.data?.data ?? row))
        } catch {
          mapped.push(toOrder(row))
        }
      }
    }
    snapshot.value.orders = mapped
  }

  const upsertFromBackend = (data: any) => {
    const o = toOrder(data)
    snapshot.value.orders = [o, ...snapshot.value.orders.filter((x) => x.id !== o.id)]
    return o.id
  }

  const cancelFromBackend = async (id: string) => {
    await api.post(`/v1/orders/${encodeURIComponent(id)}/cancel`)
    const t = snapshot.value.orders.find((x) => x.id === id)
    if (t) t.status = 'Cancelled'
  }

  watch(
    snapshot,
    (v) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
    },
    { deep: true },
  )

  return { orders, getById, createFromCheckout, cancel, markPaid, refreshFromBackend, upsertFromBackend, cancelFromBackend }
})
