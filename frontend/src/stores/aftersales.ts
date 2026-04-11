import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api } from '../lib/api'

export type AftersaleType = 'refund_only' | 'return_refund'
export type AftersaleStatus = 'Submitted' | 'Processing' | 'Done' | 'Cancelled'

export type AftersaleItem = {
  id: string
  orderId: string
  orderItemId: string
  type: AftersaleType
  reason: string
  evidence: string[]
  qty: number
  status: AftersaleStatus
  createdAt: string
}

export const useAftersalesStore = defineStore('aftersales', () => {
  const itemsRef = ref<AftersaleItem[]>([])

  const items = computed(() => itemsRef.value.slice().sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)))

  const fetch = async () => {
    const res = await api.get('/v1/aftersales')
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    itemsRef.value = list.map((x: any) => ({
      id: String(x.id),
      orderId: String(x.orderId),
      orderItemId: String(x.orderItemId ?? ''),
      type: (x.type || 'refund_only') as AftersaleType,
      reason: String(x.reason || ''),
      evidence: (() => {
        try {
          if (!x.evidence) return []
          const arr = JSON.parse(String(x.evidence))
          return Array.isArray(arr) ? arr : []
        } catch {
          return []
        }
      })(),
      qty: Number(x.qty ?? 1),
      status: ((): AftersaleStatus => {
        const s = String(x.status || '').toUpperCase()
        return s === 'PROCESSING' ? 'Processing' : s === 'COMPLETED' ? 'Done' : s === 'CANCELLED' ? 'Cancelled' : 'Submitted'
      })(),
      createdAt: x.createTime ? String(x.createTime) : new Date().toISOString(),
    }))
  }

  const apply = async (input: Omit<AftersaleItem, 'id' | 'createdAt' | 'status'>) => {
    const res = await api.post('/v1/aftersales/apply', {
      orderId: input.orderId,
      orderItemId: input.orderItemId,
      type: input.type,
      reason: input.reason,
      evidence: JSON.stringify(input.evidence || []),
      qty: input.qty,
    })
    const x = res.data?.data || {}
    const it: AftersaleItem = {
      id: String(x.id ?? ''),
      orderId: String(x.orderId ?? input.orderId),
      orderItemId: String(x.orderItemId ?? input.orderItemId ?? ''),
      type: (x.type || input.type) as AftersaleType,
      reason: x.reason || input.reason,
      evidence: input.evidence || [],
      qty: Number(x.qty ?? input.qty ?? 1),
      status: 'Submitted',
      createdAt: x.createTime ? String(x.createTime) : new Date().toISOString(),
    }
    itemsRef.value = [it, ...itemsRef.value]
    return it.id
  }

  const cancel = async (id: string) => {
    await api.post(`/v1/aftersales/${encodeURIComponent(id)}/cancel`)
    const t = itemsRef.value.find((x) => x.id === id)
    if (t && (t.status === 'Submitted' || t.status === 'Processing')) t.status = 'Cancelled'
  }

  return { items, fetch, apply, cancel }
})
