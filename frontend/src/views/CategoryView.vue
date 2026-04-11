<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useCartStore } from '../stores/cart'
import { useToastStore } from '../stores/toast'
import { api } from '../lib/api'
import { getProductCover, type ProductCategoryHint } from '../lib/productCovers'

type Product = {
  id: string
  title: string
  price: number
  cover: string
  tags: string[]
  sub?: string
  rating: number
  sales: number
  categoryId: string
}

type Category = {
  id: string
  name: string
  tone: string
  subs: string[]
}

const route = useRoute()
const router = useRouter()
const cart = useCartStore()
const toast = useToastStore()

const categories = ref<Category[]>([
  { id: 'c_phone', name: '手机', tone: '#aa3bff', subs: ['旗舰', '性价比', '折叠屏', '配件'] },
  { id: 'c_laptop', name: '电脑', tone: '#0ea5e9', subs: ['轻薄本', '游戏本', '显示器', '外设'] },
  { id: 'c_home', name: '家电', tone: '#16a34a', subs: ['冰洗', '清洁', '厨房', '个护'] },
  { id: 'c_digital', name: '数码配件', tone: '#f59e0b', subs: ['耳机', '充电', '存储', '智能穿戴'] },
  { id: 'c_daily', name: '生活百货', tone: '#2563eb', subs: ['收纳', '家居', '文具', '清洁耗材'] },
  { id: 'c_beauty', name: '美妆个护', tone: '#db2777', subs: ['护肤', '彩妆', '洗护', '香氛'] },
  { id: 'c_food', name: '食品饮料', tone: '#ef4444', subs: ['零食', '咖啡茶饮', '粮油', '生鲜冷冻'] },
  { id: 'c_sport', name: '运动户外', tone: '#10b981', subs: ['跑步', '露营', '健身', '骑行'] },
])

const active = ref<string>('')
const activeSub = ref<string>('全部')
const sortKey = ref<'default' | 'sales' | 'priceAsc' | 'priceDesc' | 'rating'>('default')
const tagFilter = ref<string>('全部')

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

const routeCategory = computed(() => {
  const raw = route.query.category
  return typeof raw === 'string' ? raw : ''
})

watch(
  routeCategory,
  (c) => {
    const next = categories.value.some((x) => x.id === c) ? c : categories.value[0]?.id || ''
    active.value = next
  },
  { immediate: true },
)

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const activeCategory = computed(() => categories.value.find((c) => c.id === active.value) ?? null)

watch(
  active,
  () => {
    activeSub.value = '全部'
    tagFilter.value = '全部'
    sortKey.value = 'default'
  },
  { immediate: true },
)

const subOptions = computed(() => {
  const c = activeCategory.value
  const subs = c?.subs ?? []
  return ['全部', ...subs]
})

const tagOptions = computed(() => {
  const items = all.value.filter((p) => p.categoryId === active.value)
  const tags = Array.from(new Set(items.flatMap((p) => p.tags))).filter(Boolean)
  return ['全部', ...tags]
})

const filtered = computed(() => {
  let items = all.value.filter((p) => p.categoryId === active.value)
  if (activeSub.value !== '全部') {
    const sub = activeSub.value
    items = items.filter((p) => (p.sub ? p.sub === sub : p.tags.includes(sub)))
  }
  if (tagFilter.value !== '全部') {
    const t = tagFilter.value
    items = items.filter((p) => p.tags.includes(t))
  }
  const key = sortKey.value
  if (key === 'sales') return [...items].sort((a, b) => b.sales - a.sales)
  if (key === 'priceAsc') return [...items].sort((a, b) => a.price - b.price)
  if (key === 'priceDesc') return [...items].sort((a, b) => b.price - a.price)
  if (key === 'rating') return [...items].sort((a, b) => b.rating - a.rating)
  return items
})

const setCategory = (id: string) => {
  router.replace({ name: 'category', query: { category: id } })
}

const goProduct = (p: Product) => {
  router.push({ name: 'productDetail', params: { id: p.id } })
}

const addToCart = (p: Product) => {
  cart.addItem({ productId: p.id, skuId: 'default', title: p.title, price: p.price, qty: 1, cover: p.cover })
  toast.push({ type: 'success', message: '已加入购物车' })
}

const categoryIdMap: Record<string, number> = {
  c_phone: 1,
  c_laptop: 2,
  c_home: 3,
  c_digital: 4,
  c_daily: 5,
  c_beauty: 6,
  c_food: 7,
  c_sport: 8,
}

const load = async () => {
  const catId = categoryIdMap[active.value]
  if (!catId) {
    // 无对应后端类目时清空
    all.value = []
    return
  }
  const res = await api.get('/v1/products', { params: { category: catId, page: 1, size: 50 } })
  const list = Array.isArray(res.data?.data) ? res.data.data : []
  const tone = activeCategory.value?.tone ?? '#0ea5e9'
  const hintMap: Record<number, ProductCategoryHint> = {
    1: 'phone',
    2: 'computer',
    3: 'appliance',
    4: 'digital',
    5: 'daily',
    6: 'beauty',
    7: 'food',
    8: 'sport',
  }
  const hint = hintMap[catId]
  const items: Product[] = list.map((x: any) => {
    const name = String(x.name ?? '商品')
    const coverUrl = getProductCover(name, hint)
    return {
      id: String(x.id ?? ''),
      title: name,
      price: Number(x.price ?? 0),
      cover: coverUrl || coverSvg(name, tone),
    tags: (() => {
      const tSet = new Set<string>()
      const pushTag = (v: any) => {
        const s = String(v ?? '').trim()
        if (s) tSet.add(s)
      }
      try {
        const raw = x.tags
        if (Array.isArray(raw)) {
          raw.forEach(pushTag)
        } else if (typeof raw === 'string') {
          let parsed: any
          try {
            parsed = JSON.parse(raw)
            if (Array.isArray(parsed)) parsed.forEach(pushTag)
            else if (parsed && typeof parsed === 'object') Object.values(parsed).forEach(pushTag)
            else if (typeof parsed === 'string') pushTag(parsed)
          } catch {
            raw
              .split(/[;,|]/)
              .map((s) => s.trim())
              .forEach(pushTag)
          }
        }
      } catch {}
      const sub = String(x.subCategory ?? x.sub ?? '').trim()
      if (sub) tSet.add(sub)
      return Array.from(tSet)
    })(),
    sub: (() => {
      const s = String(x.subCategory ?? x.sub ?? '').trim()
      return s || undefined
    })(),
      rating: 4.6,
      sales: 0,
      categoryId: active.value,
    } as Product
  })
  // 将新类目结果合并到 all 中（保留其它类目已有数据）
  all.value = [...items, ...all.value.filter((p) => p.categoryId !== active.value)]
}

const onImgErr = (e: Event, title: string) => {
  const el = e.target as HTMLImageElement
  el.src = coverSvg(title, activeCategory.value?.tone ?? '#0ea5e9')
}
watch(active, () => {
  load().catch(() => {
    // 出错则仅清空该类目数据
    all.value = all.value.filter((p) => p.categoryId !== active.value)
  })
}, { immediate: true })
</script>

<template>
  <div class="page">
    <section class="head" aria-label="类目选择">
      <div class="title">类目</div>
      <div class="tabs">
        <UiButton
          v-for="c in categories"
          :key="c.id"
          size="sm"
          type="button"
          :disabled="active === c.id"
          @click="setCategory(c.id)"
        >
          {{ c.name }}
        </UiButton>
      </div>
      <div class="toolbar" aria-label="筛选与排序">
        <div class="chipRow" aria-label="子类目">
          <button
            v-for="s in subOptions"
            :key="s"
            class="chip"
            :class="{ on: activeSub === s }"
            type="button"
            @click="activeSub = s"
          >
            {{ s }}
          </button>
        </div>
        <div class="chipRow" aria-label="标签筛选">
          <button
            v-for="t in tagOptions"
            :key="t"
            class="chip"
            :class="{ on: tagFilter === t }"
            type="button"
            @click="tagFilter = t"
          >
            {{ t }}
          </button>
        </div>
        <div class="sortRow" aria-label="排序">
          <span class="sortLabel">排序</span>
          <button class="sortBtn" :class="{ on: sortKey === 'default' }" type="button" @click="sortKey = 'default'">
            综合
          </button>
          <button class="sortBtn" :class="{ on: sortKey === 'sales' }" type="button" @click="sortKey = 'sales'">
            销量
          </button>
          <button class="sortBtn" :class="{ on: sortKey === 'rating' }" type="button" @click="sortKey = 'rating'">
            评分
          </button>
          <button class="sortBtn" :class="{ on: sortKey === 'priceAsc' }" type="button" @click="sortKey = 'priceAsc'">
            价格↑
          </button>
          <button
            class="sortBtn"
            :class="{ on: sortKey === 'priceDesc' }"
            type="button"
            @click="sortKey = 'priceDesc'"
          >
            价格↓
          </button>
        </div>
      </div>
    </section>

    <main class="content" aria-live="polite">
      <UiEmptyState v-if="filtered.length === 0" title="暂无商品" desc="请选择其他类目看看" />

      <div v-else class="grid" aria-label="商品列表">
        <article v-for="p in filtered" :key="p.id" class="card">
          <button class="cardBtn" type="button" @click="goProduct(p)">
            <img class="cover" :src="p.cover" :alt="p.title" loading="lazy" decoding="async" @error="onImgErr($event, p.title)" />
            <div class="meta">
              <div class="name">{{ p.title }}</div>
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
            <UiButton size="sm" type="button" @click="goProduct(p)">查看</UiButton>
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

.title {
  margin: 0;
  font-size: var(--font-xl);
  color: var(--text-h);
  font-weight: 900;
}

.head {
  display: grid;
  gap: 10px;
}

.tabs {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.toolbar {
  display: grid;
  gap: 10px;
  padding: 12px 12px;
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  background: color-mix(in srgb, var(--code-bg) 70%, transparent);
}

.chipRow {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.chip {
  border: 1px solid var(--border);
  background: var(--bg);
  border-radius: var(--radius-pill);
  padding: 6px 10px;
  font-size: 12px;
  cursor: pointer;
  color: var(--text);
}

.chip.on {
  border-color: color-mix(in srgb, var(--accent) 50%, var(--border));
  background: var(--accent-bg);
  color: var(--text-h);
  font-weight: 800;
}

.sortRow {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.sortLabel {
  font-size: 12px;
  color: var(--text);
  font-weight: 800;
  margin-right: 2px;
}

.sortBtn {
  border: 1px solid var(--border);
  background: var(--bg);
  border-radius: var(--radius-pill);
  padding: 6px 10px;
  font-size: 12px;
  cursor: pointer;
  color: var(--text);
}

.sortBtn.on {
  border-color: color-mix(in srgb, var(--accent) 50%, var(--border));
  background: var(--accent-bg);
  color: var(--text-h);
  font-weight: 800;
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

.name {
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
