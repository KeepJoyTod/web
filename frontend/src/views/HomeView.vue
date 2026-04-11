<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { useAuthStore } from '../stores/auth'
import { api } from '../lib/api'
import { getProductCover } from '../lib/productCovers'

type LoadState = 'loading' | 'ready' | 'empty' | 'error'

type CategoryShortcut = {
  id: string
  name: string
}

type ProductCard = {
  id: string
  title: string
  price: number
  cover: string
  tags: string[]
  rating: number
}

const router = useRouter()
const auth = useAuthStore()

const state = ref<LoadState>('loading')
const keyword = ref('')

const categories = ref<CategoryShortcut[]>([
  { id: 'c_phone', name: '手机' },
  { id: 'c_laptop', name: '电脑' },
  { id: 'c_wear', name: '穿戴' },
  { id: 'c_home', name: '家电' },
  { id: 'c_food', name: '食品' },
  { id: 'c_beauty', name: '美妆' },
  { id: 'c_baby', name: '母婴' },
  { id: 'c_more', name: '更多' },
])

const banners = ref<{ id: string; title: string; subtitle: string }[]>([
  { id: 'b1', title: '春季上新', subtitle: '爆款直降，限时抢购' },
  { id: 'b2', title: '会员专享', subtitle: '精选好物，满减叠券' },
  { id: 'b3', title: '大牌补贴', subtitle: '正品保障，极速发货' },
])

const products = ref<ProductCard[]>([])

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })
const hasProducts = computed(() => products.value.length > 0)
const authText = computed(() => (auth.isLoggedIn ? '退出' : '登录'))

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

const submitSearch = () => {
  const q = keyword.value.trim()
  router.push({ name: 'search', query: q ? { q } : undefined })
}

const onAuthClick = () => {
  if (!auth.isLoggedIn) {
    router.push({ name: 'login', query: { redirect: router.currentRoute.value.fullPath } })
    return
  }

  const ok = window.confirm('确认退出登录？')
  if (ok) auth.logout()
}

const goCategory = (c: CategoryShortcut) => {
  if (c.id === 'c_phone') {
    router.push({ name: 'phone' })
    return
  }
  if (c.id === 'c_laptop') {
    router.push({ name: 'computer' })
    return
  }
  if (c.id === 'c_home') {
    router.push({ name: 'appliance' })
    return
  }
  router.push({ name: 'category', query: { category: c.id } })
}

const goProduct = (p: ProductCard) => {
  router.push({ name: 'productDetail', params: { id: p.id } })
}

const retry = () => {
  state.value = 'loading'
  load().catch(() => {
    state.value = 'error'
  })
}

const load = async () => {
  state.value = 'loading'
  try {
    const res = await api.get('/v1/products', { params: { page: 1, size: 6 } })
    const list = Array.isArray(res.data?.data) ? res.data.data : []
    products.value = list.slice(0, 6).map((x: any, i: number) => {
      const name = String(x.name ?? '商品')
      const price = Number(x.price ?? 0)
      const coverUrl = getProductCover(name)
      return {
        id: String(x.id ?? ''),
        title: name,
        price,
        cover: coverUrl || coverSvg(name, ['#aa3bff', '#2563eb', '#0ea5e9', '#16a34a', '#ec4899', '#f59e0b'][i % 6]),
        tags: [],
        rating: 4.6,
      } as ProductCard
    })
    state.value = products.value.length === 0 ? 'empty' : 'ready'
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
    <header class="topbar">
      <form class="search" role="search" @submit.prevent="submitSearch">
        <input
          v-model="keyword"
          class="searchInput"
          type="search"
          inputmode="search"
          autocomplete="off"
          placeholder="搜索商品、品牌、类目"
          aria-label="搜索"
        />
        <button class="searchBtn" type="submit">搜索</button>
      </form>
      <div class="right">
        <button class="msgBtn" type="button" aria-label="消息中心" @click="router.push({ name: 'me' })">
          消息
        </button>
        <button
          class="authBtn"
          type="button"
          :aria-label="auth.isLoggedIn ? '退出登录' : '登录'"
          @click="onAuthClick"
        >
          {{ authText }}
        </button>
      </div>
    </header>

    <main class="content" aria-live="polite">
      <section class="banner" aria-label="活动横幅">
        <div class="bannerTrack">
          <article v-for="b in banners" :key="b.id" class="bannerCard">
            <div class="bannerTitle">{{ b.title }}</div>
            <div class="bannerSub">{{ b.subtitle }}</div>
            <div class="bannerCta" aria-hidden="true">立即查看</div>
          </article>
        </div>
      </section>

      <section class="cats" aria-label="快捷类目">
        <button
          v-for="c in categories"
          :key="c.id"
          class="cat"
          type="button"
          @click="goCategory(c)"
        >
          <span class="catIcon" aria-hidden="true"></span>
          <span class="catName">{{ c.name }}</span>
        </button>
      </section>

      <section class="section">
        <div class="sectionHead">
          <h2 class="sectionTitle">为你推荐</h2>
          <button class="sectionMore" type="button" @click="router.push({ name: 'search' })">
            查看更多
          </button>
        </div>

        <div v-if="state === 'loading'" class="grid" aria-label="加载中">
          <div v-for="n in 6" :key="n" class="skeletonCard" role="status" aria-label="加载中"></div>
        </div>

        <div v-else-if="state === 'error'" class="panel" role="alert">
          <div class="panelTitle">网络开小差了</div>
          <div class="panelDesc">请检查网络连接后重试</div>
          <button class="panelBtn" type="button" @click="retry">重试</button>
        </div>

        <div v-else-if="state === 'empty'" class="panel">
          <div class="panelTitle">暂无推荐商品</div>
          <div class="panelDesc">稍后再来看看</div>
          <button class="panelBtn" type="button" @click="retry">刷新</button>
        </div>

        <div v-else class="grid" aria-label="商品列表">
          <article v-for="p in products" :key="p.id" class="card">
          <button class="cardBtn" type="button" @click="goProduct(p)">
            <img class="cover" :src="p.cover" :alt="p.title" loading="lazy" decoding="async" @error="(e) => ((e.target as HTMLImageElement).src = coverSvg(p.title, ['#aa3bff', '#2563eb', '#0ea5e9', '#16a34a', '#ec4899', '#f59e0b'][0]))" />
              <div class="meta">
                <div class="title">{{ p.title }}</div>
                <div class="row">
                  <div class="price">{{ priceFmt.format(p.price) }}</div>
                  <div class="rating">{{ p.rating.toFixed(1) }}</div>
                </div>
                <div v-if="p.tags.length" class="tags" aria-label="标签">
                  <span v-for="t in p.tags" :key="t" class="tag">{{ t }}</span>
                </div>
              </div>
            </button>
          </article>
        </div>

        <div v-if="state === 'ready' && !hasProducts" class="panel">
          <div class="panelTitle">暂无推荐商品</div>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  display: flex;
  flex-direction: column;
}

.topbar {
  background: var(--bg);
  border-bottom: 1px solid var(--border);
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
}

.right {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  align-items: center;
}

.search {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 4px;
  background: color-mix(in srgb, var(--bg) 80%, var(--code-bg) 20%);
}

.searchInput {
  border: 0;
  outline: none;
  background: transparent;
  padding: 8px 12px;
  font-size: 14px;
  color: var(--text-h);
  min-width: 0;
}

.searchBtn {
  border: 0;
  border-radius: 999px;
  padding: 8px 12px;
  font-size: 13px;
  color: #fff;
  background: var(--accent);
  cursor: pointer;
}

.msgBtn {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.authBtn {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.content {
  padding: 14px 16px 24px;
  display: grid;
  gap: 16px;
}

.banner {
  overflow: hidden;
}

.bannerTrack {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: minmax(260px, 1fr);
  gap: 12px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  padding-bottom: 4px;
}

.bannerTrack::-webkit-scrollbar {
  height: 8px;
}

.bannerCard {
  scroll-snap-align: start;
  border-radius: 16px;
  padding: 18px 16px;
  border: 1px solid var(--border);
  background:
    radial-gradient(1200px 300px at 20% 10%, color-mix(in srgb, var(--accent) 25%, transparent), transparent),
    linear-gradient(180deg, color-mix(in srgb, var(--code-bg) 65%, transparent), transparent);
  min-height: 120px;
  display: grid;
  align-content: start;
  gap: 8px;
}

.bannerTitle {
  font-size: 18px;
  font-weight: 700;
  color: var(--text-h);
}

.bannerSub {
  font-size: 14px;
  color: var(--text);
}

.bannerCta {
  margin-top: 6px;
  font-size: 13px;
  color: var(--accent);
}

.cats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.cat {
  border: 1px solid var(--border);
  background: var(--bg);
  border-radius: 14px;
  padding: 12px 10px;
  display: grid;
  place-items: center;
  gap: 8px;
  cursor: pointer;
}

.catIcon {
  width: 34px;
  height: 34px;
  border-radius: 12px;
  background: color-mix(in srgb, var(--accent) 20%, transparent);
  border: 1px solid color-mix(in srgb, var(--accent) 35%, transparent);
}

.catName {
  font-size: 13px;
  color: var(--text-h);
}

.section {
  display: grid;
  gap: 12px;
}

.sectionHead {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
}

.sectionTitle {
  font-size: 16px;
  margin: 0;
  color: var(--text-h);
  font-weight: 700;
}

.sectionMore {
  border: 0;
  background: transparent;
  color: var(--accent);
  cursor: pointer;
  font-size: 13px;
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

.title {
  font-size: 14px;
  color: var(--text-h);
  font-weight: 650;
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
  font-weight: 800;
}

.rating {
  font-size: 12px;
  color: var(--text);
  background: color-mix(in srgb, var(--code-bg) 80%, transparent);
  border: 1px solid var(--border);
  padding: 4px 8px;
  border-radius: 999px;
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
  font-weight: 700;
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

.skeletonCard {
  height: 232px;
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

@media (min-width: 920px) {
  .content {
    padding: 20px 24px 28px;
    max-width: 1120px;
    margin: 0 auto;
    width: 100%;
  }

  .cats {
    grid-template-columns: repeat(8, minmax(0, 1fr));
  }

  .grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .cover {
    height: 170px;
  }
}
</style>
