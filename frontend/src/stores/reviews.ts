import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api } from '../lib/api'

export type Review = {
  id: string
  userId: string
  nickname: string
  orderId: string
  productId: string
  rating: number
  content: string
  images: string[]
  createdAt: string
}

export const useReviewsStore = defineStore('reviews', () => {
  const itemsRef = ref<Review[]>([])

  const items = computed(() => itemsRef.value.slice().sort((a, b) => (a.createdAt < b.createdAt ? 1 : -1)))

  const fetch = async (productId?: string, orderId?: string) => {
    const res = await api.get('/v1/reviews', { params: { productId, orderId } })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    itemsRef.value = list.map((x: any) => ({
      id: String(x.id),
      userId: String(x.userId || ''),
      nickname: String(x.nickname || '匿名用户'),
      orderId: String(x.orderId),
      productId: String(x.productId),
      rating: Number(x.rating ?? 0),
      content: String(x.content || ''),
      images: (() => {
        try {
          const arr = JSON.parse(String(x.images || '[]'))
          return Array.isArray(arr) ? arr : []
        } catch {
          return []
        }
      })(),
      createdAt: x.createTime ? String(x.createTime) : new Date().toISOString(),
    }))
  }

  const create = async (input: Omit<Review, 'id' | 'createdAt' | 'nickname' | 'userId'>) => {
    const res = await api.post('/v1/reviews', {
      orderId: input.orderId,
      productId: input.productId,
      rating: input.rating,
      content: input.content,
      images: JSON.stringify(input.images || []),
    })
    const x = res.data?.data || {}
    const r: Review = {
      id: String(x.id ?? ''),
      userId: String(x.userId || ''),
      nickname: String(x.nickname || '我'),
      orderId: String(x.orderId ?? input.orderId),
      productId: String(x.productId ?? input.productId),
      rating: Number(x.rating ?? input.rating),
      content: x.content ?? input.content,
      images: input.images || [],
      createdAt: x.createTime ? String(x.createTime) : new Date().toISOString(),
    }
    itemsRef.value = [r, ...itemsRef.value]
    return r.id
  }

  return { items, fetch, create }
})
