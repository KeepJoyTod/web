import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { api } from '../lib/api'

export type FavoriteItem = {
  favId: string
  productId: string
  title: string
  cover: string
  price: number
  oldPrice?: number
  rating: number
  sold: number
  tags: string[] | string
  promo?: string
}

export const useFavoritesStore = defineStore('favorites', () => {
  const items = ref<FavoriteItem[]>([])
  const loading = ref(false)

  const count = computed(() => items.value.length)

  const fetch = async () => {
    loading.value = true
    try {
      const res = await api.get('/v1/favorites')
      const data = res.data?.data || []
      // 处理 tags，如果是字符串则转为数组
      items.value = data.map((item: any) => ({
        ...item,
        tags: typeof item.tags === 'string' ? JSON.parse(item.tags) : item.tags
      }))
    } catch (error) {
      console.error('Failed to fetch favorites:', error)
    } finally {
      loading.value = false
    }
  }

  const add = async (input: { productId: string }) => {
    try {
      await api.post('/v1/favorites', { productId: input.productId })
      await fetch()
    } catch (error) {
      console.error('Failed to add favorite:', error)
      throw error
    }
  }

  const remove = async (favId: string) => {
    try {
      await api.delete(`/v1/favorites/${favId}`)
      items.value = items.value.filter((x) => x.favId.toString() !== favId.toString())
    } catch (error) {
      console.error('Failed to remove favorite:', error)
      throw error
    }
  }

  const removeByProductId = async (productId: string) => {
    try {
      await api.delete(`/v1/favorites/product/${productId}`)
      await fetch()
    } catch (error) {
      console.error('Failed to remove favorite by product id:', error)
      throw error
    }
  }

  const removeMany = async (favIds: string[]) => {
    try {
      await api.delete('/v1/favorites/bulk', { data: { favIds } })
      const set = new Set(favIds.map(id => id.toString()))
      items.value = items.value.filter((x) => !set.has(x.favId.toString()))
    } catch (error) {
      console.error('Failed to remove many favorites:', error)
      throw error
    }
  }

  const clear = () => {
    items.value = []
  }

  const isFavorite = (productId: string) => {
    return items.value.some(x => x.productId.toString() === productId.toString())
  }

  return { items, count, loading, fetch, add, remove, removeByProductId, removeMany, clear, isFavorite }
})
