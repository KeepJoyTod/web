<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiInput from '../components/ui/UiInput.vue'
import { useCartStore } from '../stores/cart'
import { api } from '../lib/api'
import { useToastStore } from '../stores/toast'
import { getProductCover } from '../lib/productCovers'

type LoadState = 'loading' | 'ready' | 'error'
type SortKey = 'default' | 'sales' | 'price_asc' | 'price_desc'

type Product = {
  id: string
  title: string
  price: number
  cover: string
  tags: string[]
  rating: number
  sales: number
  categoryId: string
}

const route = useRoute()
const router = useRouter()
const cart = useCartStore()
const toast = useToastStore()

const state = ref<LoadState>('loading')
const sort = ref<SortKey>('default')
const keyword = ref('')

const coverSvg = (title: string, tone: string) => {
  const text = title.length > 14 ? `${title.slice(0, 14)}…` : title
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800">` +
    `<defs><linearGradient id="g" x1="0" x2="1" y1="0" y2="1">` +
    `<stop offset="0" stop-color="${tone}" stop-opacity="0.22"/>` +
    `<stop offset="1" stop-color="${tone}" stop-opacity="0.08"/>` +
    `</linearGradient></defs>` +
    `<rect width="1200" height="800" fill="#f4f3ec"/>` +
    `<rect width="1200" height="800" fill="url(#g)"/>` +
    `<text x="60" y="420" font-size="64" font-family="system-ui, Segoe UI, Roboto, sans-serif" fill="#08060d" font-weight="800">${text}</text>` +
    `<text x="60" y="498" font-size="30" font-family="system-ui, Segoe UI, Roboto, sans-serif" fill="#6b6375">元气购</text>` +
    `</svg>`
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
}

const all = ref<Product[]>([])

const qFromRoute = computed(() => {
  const raw = route.query.q
  return typeof raw === 'string' ? raw : ''
})

watch(
  qFromRoute,
  (q) => {
    keyword.value = q
  },
  { immediate: true },
)

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const filtered = computed(() => {
  let items = all.value.slice()
  const q = keyword.value.trim()
  if (q) {
    const lower = q.toLowerCase()
    items = items.filter((p) => p.title.toLowerCase().includes(lower))
  }

  if (sort.value === 'sales') items.sort((a, b) => b.sales - a.sales)
  else if (sort.value === 'price_asc') items.sort((a, b) => a.price - b.price)
  else if (sort.value === 'price_desc') items.sort((a, b) => b.price - a.price)

  return items
})

const priceSortLabel = computed(() => {
  if (sort.value === 'price_asc') return '价格↑'
  if (sort.value === 'price_desc') return '价格↓'
  return '价格'
})

const togglePriceSort = () => {
  sort.value = sort.value === 'price_asc' ? 'price_desc' : 'price_asc'
}

const submitSearch = () => {
  router.replace({ name: 'search', query: keyword.value.trim() ? { q: keyword.value.trim() } : undefined })
}

const goProduct = (p: Product) => {
  router.push({ name: 'productDetail', params: { id: p.id } })
}

const addToCart = (p: Product) => {
  cart.addItem({ productId: p.id, skuId: 'default', title: p.title, price: p.price, qty: 1, cover: p.cover })
  toast.push({ type: 'success', message: '已加入购物车' })
}

const load = async () => {
  state.value = 'loading'
  try {
    const res = await api.get('/v1/products', { params: { keyword: keyword.value || undefined } })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    all.value = list.map((x: any) => {
      const name = String(x.name ?? x.title ?? '商品')
      const price = Number(x.price ?? 0)
      const id = String(x.id ?? '')
      const coverUrl = getProductCover(name)
      return {
        id,
        title: name,
        price,
        cover: coverUrl || coverSvg(name, '#0ea5e9'),
        tags: [],
        rating: 4.5,
        sales: 0,
        categoryId: String(x.categoryId ?? ''),
      } as Product
    })
    state.value = 'ready'
  } catch {
    state.value = 'error'
  }
}

onMounted(() => {
  load()
})
</script>

<template>
  <div class="page">
    <section class="searchRow" aria-label="搜索与排序">
      <form class="search" role="search" @submit.prevent="submitSearch">
        <UiInput v-model="keyword" type="search" inputmode="search" placeholder="搜索商品、品牌、类目" />
        <UiButton variant="primary" size="sm" type="submit">搜索</UiButton>
      </form>
      <div class="sort" role="tablist" aria-label="排序">
        <UiButton size="sm" :variant="sort === 'default' ? 'primary' : 'ghost'" @click="sort = 'default'">
          综合
        </UiButton>
        <UiButton size="sm" :variant="sort === 'sales' ? 'primary' : 'ghost'" @click="sort = 'sales'">销量</UiButton>
        <UiButton
          size="sm"
          :variant="sort === 'price_asc' || sort === 'price_desc' ? 'primary' : 'ghost'"
          @click="togglePriceSort"
        >
          {{ priceSortLabel }}
        </UiButton>
      </div>
    </section>

    <main class="content" aria-live="polite">
      <UiEmptyState v-if="state === 'ready' && filtered.length === 0" title="没有找到相关商品" desc="换个关键词试试" />

      <div v-else class="grid" aria-label="搜索结果">
        <article v-for="p in filtered" :key="p.id" class="card">
          <button class="cardBtn" type="button" @click="goProduct(p)">
            <img class="cover" :src="p.cover" :alt="p.title" loading="lazy" decoding="async" @error="(e) => ((e.target as HTMLImageElement).src = coverSvg(p.title, '#0ea5e9'))" />
            <div class="meta">
              <div class="titleText">{{ p.title }}</div>
              <div class="row">
                <div class="price">{{ priceFmt.format(p.price) }}</div>
                <div class="rating">{{ p.rating.toFixed(1) }}</div>
              </div>
              <div v-if="p.tags.length" class="tags" aria-label="标签">
                <span v-for="t in p.tags" :key="t" class="tag">{{ t }}</span>
              </div>
            </div>
          </button>
          <div class="actions">
            <UiButton size="sm" type="button" @click="addToCart(p)">加购</UiButton>
            <UiButton size="sm" type="button" @click="router.push({ name: 'productDetail', params: { id: p.id } })">
              查看
            </UiButton>
          </div>
        </article>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  padding: 14px 16px 28px;
  display: grid;
  gap: 12px;
}

.searchRow {
  display: grid;
  gap: 10px;
}

.search {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
}

.sort {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.content {
  display: grid;
}

.grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.card {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  background: var(--bg);
  overflow: hidden;
  display: grid;
}

.cardBtn {
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  text-align: left;
  width: 100%;
}

.cover {
  width: 100%;
  height: 140px;
  object-fit: cover;
  display: block;
  background: var(--code-bg);
}

.meta {
  padding: 12px;
  display: grid;
  gap: 8px;
}

.titleText {
  font-size: var(--font-md);
  color: var(--text-h);
  font-weight: 900;
  line-height: 1.25;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.price {
  color: var(--text-h);
  font-weight: 900;
}

.rating {
  font-size: var(--font-xs);
  color: var(--text);
  background: color-mix(in srgb, var(--code-bg) 80%, transparent);
  border: 1px solid var(--border);
  padding: 4px 8px;
  border-radius: var(--radius-pill);
}

.tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.tag {
  font-size: var(--font-xs);
  padding: 3px 8px;
  border-radius: var(--radius-pill);
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--accent-bg) 75%, transparent);
  color: var(--text-h);
}

.actions {
  padding: 10px 12px 12px;
  border-top: 1px solid var(--border);
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

@media (min-width: 920px) {
  .page {
    max-width: 1120px;
    margin: 0 auto;
  }

  .grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .cover {
    height: 170px;
  }
}
</style>
