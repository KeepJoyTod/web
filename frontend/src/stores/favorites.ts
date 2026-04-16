import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'

import iphoneCoverUrl from '../assets/figma/favorites/product-iphone.png'

export type FavoriteItem = {
  favId: string
  productId: string
  title: string
  cover: string
  price: number
  oldPrice?: number
  rating: number
  sold: number
  tags: string[]
  promo?: string
}

type FavoritesSnapshotV1 = {
  v: 1
  items: FavoriteItem[]
}

const STORAGE_KEY = 'favorites:v1'

const readSnapshot = (): FavoritesSnapshotV1 => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw)
      return {
        v: 1,
        items: [
          {
            favId: `fav_${Date.now().toString(16)}`,
            productId: 'p_iphone_15_pro_max',
            title: 'iPhone 15 Pro Max',
            cover: iphoneCoverUrl,
            price: 9999,
            oldPrice: 10499,
            rating: 4.9,
            sold: 6595,
            tags: ['热卖', '新品'],
            promo: '限时直降500',
          },
        ],
      }
    const parsed = JSON.parse(raw) as FavoritesSnapshotV1
    if (parsed?.v !== 1) return { v: 1, items: [] }
    return { v: 1, items: Array.isArray(parsed.items) ? parsed.items : [] }
  } catch {
    return { v: 1, items: [] }
  }
}

const uid = () => `fav_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

export const useFavoritesStore = defineStore('favorites', () => {
  const snapshot = ref<FavoritesSnapshotV1>(readSnapshot())

  const items = computed(() => snapshot.value.items)
  const count = computed(() => snapshot.value.items.length)

  const add = (input: Omit<FavoriteItem, 'favId'>) => {
    const existed = snapshot.value.items.find((x) => x.productId === input.productId)
    if (existed) return
    snapshot.value.items = [{ ...input, favId: uid() }, ...snapshot.value.items]
  }

  const remove = (favId: string) => {
    snapshot.value.items = snapshot.value.items.filter((x) => x.favId !== favId)
  }

  const removeMany = (favIds: string[]) => {
    const set = new Set(favIds)
    snapshot.value.items = snapshot.value.items.filter((x) => !set.has(x.favId))
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

  return { items, count, add, remove, removeMany, clear }
})

