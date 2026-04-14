<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { useCartStore } from '../stores/cart'
import { api } from '../lib/api'
import { getProductCover } from '../lib/productCovers'

type LoadState = 'loading' | 'ready' | 'empty' | 'error'
type SortKey = 'default' | 'sales' | 'price_asc' | 'price_desc'

type Product = {
  id: string
  title: string
  price: number
  cover: string
  tags: string[]
  rating: number
  sales: number
  brand: string
}

const router = useRouter()
const cart = useCartStore()

const state = ref<LoadState>('loading')
const sort = ref<SortKey>('default')
const keyword = ref('')

const filterOpen = ref(false)
const selectedBrands = ref<string[]>([])
const minPrice = ref<string>('')
const maxPrice = ref<string>('')

const added = ref<Record<string, boolean>>({})

const brands = ref<string[]>(['Apple', 'Lenovo', 'Dell', 'HP', 'ASUS', '华为'])
const all = ref<Product[]>([])

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

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

const priceRangeOk = computed(() => {
  const min = minPrice.value.trim()
  const max = maxPrice.value.trim()
  if (min === '' && max === '') return true
  const a = min === '' ? Number.NEGATIVE_INFINITY : Number(min)
  const b = max === '' ? Number.POSITIVE_INFINITY : Number(max)
  if (Number.isNaN(a) || Number.isNaN(b)) return false
  return a <= b
})

const filtered = computed(() => {
  let items = all.value.slice()

  const q = keyword.value.trim()
  if (q) {
    const lower = q.toLowerCase()
    items = items.filter((p) => p.title.toLowerCase().includes(lower) || p.brand.toLowerCase().includes(lower))
  }

  if (selectedBrands.value.length > 0) {
    const set = new Set(selectedBrands.value)
    items = items.filter((p) => set.has(p.brand))
  }

  if (priceRangeOk.value) {
    const min = minPrice.value.trim()
    const max = maxPrice.value.trim()
    const a = min === '' ? Number.NEGATIVE_INFINITY : Number(min)
    const b = max === '' ? Number.POSITIVE_INFINITY : Number(max)
    items = items.filter((p) => p.price >= a && p.price <= b)
  }

  if (sort.value === 'sales') {
    items.sort((x, y) => y.sales - x.sales)
  } else if (sort.value === 'price_asc') {
    items.sort((x, y) => x.price - y.price)
  } else if (sort.value === 'price_desc') {
    items.sort((x, y) => y.price - x.price)
  }

  return items
})

const priceSortLabel = computed(() => {
  if (sort.value === 'price_asc') return '价格↑'
  if (sort.value === 'price_desc') return '价格↓'
  return '价格'
})

const toggleBrand = (brand: string) => {
  const exists = selectedBrands.value.includes(brand)
  selectedBrands.value = exists ? selectedBrands.value.filter((x) => x !== brand) : [...selectedBrands.value, brand]
}

const resetFilters = () => {
  selectedBrands.value = []
  minPrice.value = ''
  maxPrice.value = ''
  sort.value = 'default'
  keyword.value = ''
}

const togglePriceSort = () => {
  if (sort.value === 'price_asc') {
    sort.value = 'price_desc'
  } else {
    sort.value = 'price_asc'
  }
}

const goProduct = (p: Product) => {
  router.push({ name: 'productDetail', params: { id: p.id } })
}

const addToCart = async (p: Product) => {
  cart.addItem({
    productId: p.id,
    skuId: 'default',
    title: p.title,
    price: p.price,
    qty: 1,
    cover: p.cover,
  })
  added.value = { ...added.value, [p.id]: true }
  await new Promise((r) => window.setTimeout(r, 900))
  const copy = { ...added.value }
  delete copy[p.id]
  added.value = copy
}

const retry = () => {
  state.value = 'loading'
  load().catch(() => (state.value = 'error'))
}

const load = async () => {
  state.value = 'loading'
  try {
    const res = await api.get('/v1/products', { params: { category: 2, page: 1, size: 20 } })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    all.value = list.map((x: any, i: number) => {
      const name = String(x.name ?? '商品')
      const price = Number(x.price ?? 0)
      const id = String(x.id ?? '')
      const coverUrl = getProductCover(name, 'computer', id)
      return {
        id,
        title: name,
        price,
        cover: coverUrl || coverSvg(name, ['#aa3bff', '#2563eb', '#0ea5e9', '#16a34a', '#ec4899', '#f59e0b'][i % 6]),
        tags: [],
        rating: 4.6,
        sales: 0,
        brand: '',
      } as Product
    })
    state.value = all.value.length === 0 ? 'empty' : 'ready'
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
    <header class="bar" aria-label="电脑页操作栏">
      <button class="back" type="button" aria-label="返回" @click="router.back()">返回</button>
      <div class="title">电脑</div>
      <button class="filterBtn" type="button" @click="filterOpen = true">筛选</button>
    </header>

    <section class="searchRow" aria-label="搜索与排序">
      <input
        v-model="keyword"
        class="searchInput"
        type="search"
        inputmode="search"
        autocomplete="off"
        placeholder="搜索电脑/品牌"
        aria-label="搜索电脑"
      />
      <div class="sort" role="tablist" aria-label="排序">
        <button class="sortBtn" :class="{ active: sort === 'default' }" type="button" @click="sort = 'default'">
          综合
        </button>
        <button class="sortBtn" :class="{ active: sort === 'sales' }" type="button" @click="sort = 'sales'">
          销量
        </button>
        <button
          class="sortBtn"
          :class="{ active: sort === 'price_asc' || sort === 'price_desc' }"
          type="button"
          @click="togglePriceSort"
        >
          {{ priceSortLabel }}
        </button>
      </div>
    </section>

    <main class="content" aria-live="polite">
      <div v-if="state === 'loading'" class="grid" aria-label="加载中">
        <div v-for="n in 6" :key="n" class="skeleton" role="status" aria-label="加载中"></div>
      </div>

      <div v-else-if="state === 'error'" class="panel" role="alert">
        <div class="panelTitle">加载失败</div>
        <div class="panelDesc">请检查网络后重试</div>
        <button class="panelBtn" type="button" @click="retry">重试</button>
      </div>

      <div v-else-if="state === 'empty' || filtered.length === 0" class="panel">
        <div class="panelTitle">暂无商品</div>
        <div class="panelDesc">换个筛选条件试试</div>
        <button class="panelBtn" type="button" @click="filterOpen = true">去筛选</button>
      </div>

      <div v-else class="grid" aria-label="商品列表">
        <article v-for="p in filtered" :key="p.id" class="card">
          <button class="cardBtn" type="button" @click="goProduct(p)">
            <img class="cover" :src="p.cover" :alt="p.title" loading="lazy" decoding="async" @error="(e) => ((e.target as HTMLImageElement).src = coverSvg(p.title, ['#aa3bff', '#2563eb', '#0ea5e9', '#16a34a', '#ec4899', '#f59e0b'][0]))" />
            <div class="meta">
              <div class="titleText">{{ p.title }}</div>
              <div class="sub">
                <span class="brand">{{ p.brand }}</span>
                <span class="sep">·</span>
                <span class="sales">销量 {{ p.sales }}</span>
                <span class="sep">·</span>
                <span class="rating">{{ p.rating.toFixed(1) }}</span>
              </div>
              <div class="row">
                <div class="price">{{ priceFmt.format(p.price) }}</div>
                <button class="cartBtn" type="button" @click.stop="addToCart(p)">
                  <span v-if="added[p.id]">已加入</span>
                  <span v-else>加入购物车</span>
                </button>
              </div>
              <div v-if="p.tags.length" class="tags" aria-label="标签">
                <span v-for="t in p.tags" :key="t" class="tag">{{ t }}</span>
              </div>
            </div>
          </button>
        </article>
      </div>
    </main>

    <div
      v-if="filterOpen"
      class="mask"
      role="dialog"
      aria-modal="true"
      aria-label="筛选"
      @click.self="filterOpen = false"
    >
      <div class="drawer">
        <div class="drawerHead">
          <div class="drawerTitle">筛选</div>
          <button class="close" type="button" aria-label="关闭" @click="filterOpen = false">关闭</button>
        </div>

        <div class="section">
          <div class="sectionTitle">品牌</div>
          <div class="chips">
            <button
              v-for="b in brands"
              :key="b"
              class="chip"
              :class="{ on: selectedBrands.includes(b) }"
              type="button"
              @click="toggleBrand(b)"
            >
              {{ b }}
            </button>
          </div>
        </div>

        <div class="section">
          <div class="sectionTitle">价格区间</div>
          <div class="range">
            <input v-model="minPrice" class="rangeInput" inputmode="decimal" placeholder="最低价" aria-label="最低价" />
            <span class="rangeSep">-</span>
            <input v-model="maxPrice" class="rangeInput" inputmode="decimal" placeholder="最高价" aria-label="最高价" />
          </div>
          <div v-if="!priceRangeOk" class="hint" role="alert">价格区间不合法</div>
        </div>

        <div class="drawerFoot">
          <button class="ghost" type="button" @click="resetFilters">重置</button>
          <button class="primary" type="button" @click="filterOpen = false">完成</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page {
  min-height: 100%;
  display: flex;
  flex-direction: column;
}

.bar {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
  background: var(--bg);
}

.back {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.title {
  justify-self: center;
  font-weight: 900;
  color: var(--text-h);
}

.filterBtn {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.searchRow {
  padding: 12px 16px;
  display: grid;
  gap: 10px;
  border-bottom: 1px solid var(--border);
  background: var(--bg);
}

.searchInput {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 10px 12px;
  font-size: 14px;
  color: var(--text-h);
  background: color-mix(in srgb, var(--bg) 80%, var(--code-bg) 20%);
  outline: none;
}

.sort {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.sortBtn {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 9px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.sortBtn.active {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.content {
  padding: 14px 16px 28px;
}

.grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.card {
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--bg);
  overflow: hidden;
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
  font-size: 14px;
  color: var(--text-h);
  font-weight: 700;
  line-height: 1.25;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.sub {
  font-size: 12px;
  color: var(--text);
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  align-items: center;
}

.sep {
  opacity: 0.6;
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

.cartBtn {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 7px 10px;
  font-size: 12px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.tag {
  font-size: 12px;
  padding: 3px 8px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: color-mix(in srgb, var(--accent-bg) 75%, transparent);
  color: var(--text-h);
}

.skeleton {
  height: 268px;
  border-radius: 16px;
  border: 1px solid var(--border);
  background:
    linear-gradient(
      90deg,
      color-mix(in srgb, var(--code-bg) 70%, transparent),
      color-mix(in srgb, var(--bg) 90%, transparent),
      color-mix(in srgb, var(--code-bg) 70%, transparent)
    );
  background-size: 300% 100%;
  animation: shimmer 1.2s ease-in-out infinite;
}

@keyframes shimmer {
  0% {
    background-position: 0% 0%;
  }
  100% {
    background-position: 100% 0%;
  }
}

.panel {
  border: 1px dashed var(--border);
  border-radius: 16px;
  padding: 18px 16px;
  text-align: center;
  display: grid;
  gap: 8px;
}

.panelTitle {
  color: var(--text-h);
  font-weight: 900;
}

.panelDesc {
  color: var(--text);
  font-size: 13px;
}

.panelBtn {
  justify-self: center;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 14px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  display: flex;
  justify-content: flex-end;
  z-index: 50;
}

.drawer {
  width: min(420px, 92vw);
  height: 100%;
  background: var(--bg);
  border-left: 1px solid var(--border);
  display: flex;
  flex-direction: column;
}

.drawerHead {
  padding: 12px 14px;
  border-bottom: 1px solid var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.drawerTitle {
  font-weight: 900;
  color: var(--text-h);
}

.close {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.section {
  padding: 14px;
  border-bottom: 1px solid var(--border);
  display: grid;
  gap: 10px;
}

.sectionTitle {
  font-size: 13px;
  color: var(--text);
  font-weight: 700;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.chip {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.chip.on {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.range {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
  gap: 10px;
  align-items: center;
}

.rangeInput {
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 10px 10px;
  font-size: 14px;
  color: var(--text-h);
  background: var(--bg);
  box-sizing: border-box;
}

.rangeSep {
  color: var(--text);
}

.hint {
  font-size: 12px;
  color: var(--text-h);
  border: 1px solid color-mix(in srgb, var(--accent) 50%, var(--border));
  background: var(--accent-bg);
  border-radius: 12px;
  padding: 8px 10px;
}

.drawerFoot {
  margin-top: auto;
  padding: 12px 14px;
  border-top: 1px solid var(--border);
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.ghost {
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 12px 14px;
  font-size: 14px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.primary {
  border: 0;
  border-radius: 12px;
  padding: 12px 14px;
  font-size: 14px;
  font-weight: 900;
  background: var(--accent);
  color: #fff;
  cursor: pointer;
}

@media (min-width: 920px) {
  .content {
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
