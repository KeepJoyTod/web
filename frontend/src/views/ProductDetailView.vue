<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import { useCartStore } from '../stores/cart'
import { useToastStore } from '../stores/toast'
import { api } from '../lib/api'
import { getProductCover } from '../lib/productCovers'

type LoadState = 'loading' | 'ready' | 'empty' | 'error'

type Sku = {
  id: string
  attrs: Record<string, string>
  price: number
  stock: number
}

type Product = {
  id: string
  title: string
  desc: string
  media: string[]
  rating: number
  tags: string[]
  activity: { type: 'limited_time' | 'none'; label: string } | null
  skus: Sku[]
}

const router = useRouter()
const route = useRoute()
const cart = useCartStore()
const toast = useToastStore()

const state = ref<LoadState>('loading')
const product = ref<Product | null>(null)
const selected = ref<Record<string, string>>({})
const qty = ref(1)

const sheetOpen = ref(false)
const submitting = ref(false)

const id = computed(() => String(route.params.id ?? ''))

const coverSvg = (title: string, tone: string) => {
  const text = title.length > 18 ? `${title.slice(0, 18)}…` : title
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800">` +
    `<defs><linearGradient id="g" x1="0" x2="1" y1="0" y2="1">` +
    `<stop offset="0" stop-color="${tone}" stop-opacity="0.22"/>` +
    `<stop offset="1" stop-color="${tone}" stop-opacity="0.08"/>` +
    `</linearGradient></defs>` +
    `<rect width="1200" height="800" fill="#f4f3ec"/>` +
    `<rect width="1200" height="800" fill="url(#g)"/>` +
    `<text x="60" y="420" font-size="64" font-family="system-ui, Segoe UI, Roboto, sans-serif" fill="#08060d" font-weight="900">${text}</text>` +
    `<text x="60" y="498" font-size="30" font-family="system-ui, Segoe UI, Roboto, sans-serif" fill="#6b6375">元气购</text>` +
    `</svg>`
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
}

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const attrKeys = computed(() => {
  const p = product.value
  if (!p || p.skus.length === 0) return []
  return Object.keys(p.skus[0].attrs)
})

const selectedSku = computed(() => {
  const p = product.value
  if (!p) return null
  const keys = attrKeys.value
  if (keys.length === 0) return p.skus[0] ?? null
  return (
    p.skus.find((sku) => keys.every((k) => selected.value[k] && sku.attrs[k] === selected.value[k])) ?? null
  )
})

const priceText = computed(() => {
  const p = product.value
  if (!p) return '--'
  const sku = selectedSku.value
  if (sku) return priceFmt.format(sku.price)
  const min = Math.min(...p.skus.map((s) => s.price))
  const max = Math.max(...p.skus.map((s) => s.price))
  if (min === max) return priceFmt.format(min)
  return `${priceFmt.format(min)} - ${priceFmt.format(max)}`
})

const stockText = computed(() => {
  const sku = selectedSku.value
  if (!sku) return '请选择规格'
  if (sku.stock <= 0) return '无货'
  return `库存 ${sku.stock}`
})

const maxQty = computed(() => {
  const sku = selectedSku.value
  if (!sku) return 1
  return Math.max(1, sku.stock)
})

const canSubmit = computed(() => {
  if (submitting.value) return false
  const sku = selectedSku.value
  if (!sku) return false
  if (sku.stock <= 0) return false
  if (qty.value < 1) return false
  if (qty.value > sku.stock) return false
  return true
})

const optionsFor = (key: string) => {
  const p = product.value
  if (!p) return []
  return Array.from(new Set(p.skus.map((s) => s.attrs[key])))
}

const isOptionDisabled = (key: string, value: string) => {
  const p = product.value
  if (!p) return true
  const keys = attrKeys.value
  const draft: Record<string, string> = { ...selected.value, [key]: value }
  return (
    p.skus.find((sku) => keys.every((k) => (draft[k] ? sku.attrs[k] === draft[k] : true)) && sku.stock > 0) == null
  )
}

const selectOption = (key: string, value: string) => {
  if (isOptionDisabled(key, value)) return
  selected.value = { ...selected.value, [key]: value }
  qty.value = 1
}

const openSheet = () => {
  sheetOpen.value = true
}

const closeSheet = () => {
  sheetOpen.value = false
}

const setQty = (next: number) => {
  const n = Math.floor(next)
  qty.value = Math.max(1, Math.min(maxQty.value, n))
}

const addToCart = async (goCheckout: boolean) => {
  if (!canSubmit.value) return
  submitting.value = true

  try {
    const p = product.value
    const sku = selectedSku.value
    if (!p || !sku) return

    cart.addItem({
      productId: p.id,
      skuId: sku.id,
      title: p.title,
      price: sku.price,
      qty: qty.value,
      cover: p.media[0] ?? coverSvg(p.title, '#aa3bff'),
    })
    const pid = Number(p.id)
    if (Number.isFinite(pid)) {
      api.post('/v1/cart/items', { productId: pid, quantity: qty.value }).catch(() => {})
    }

    toast.push({ type: 'success', message: '已加入购物车' })

    if (goCheckout) {
      await router.push({ name: 'checkout' })
      return
    }
    closeSheet()
  } finally {
    submitting.value = false
  }
}

const load = async () => {
  state.value = 'loading'
  try {
    if (!/^\d+$/.test(id.value)) {
      state.value = 'empty'
      return
    }
    const res = await api.get(`/v1/products/${encodeURIComponent(id.value)}`)
    const x = res.data?.data || null
    if (!x) {
      state.value = 'empty'
      return
    }
    const name = String(x.name ?? '商品')
    const price = Number(x.price ?? 0)
    const stock = Number(x.stock ?? 0)
    const coverUrl = getProductCover(name)
    const p: Product = {
      id: String(x.id ?? id.value),
      title: name,
      desc: String(x.description ?? ''),
      media: [coverUrl || coverSvg(name, '#aa3bff')],
      rating: 4.6,
      tags: [],
      activity: null,
      skus: [{ id: 'default', attrs: {}, price, stock }],
    }
    product.value = p
    const first = p.skus.find((s) => s.stock > 0) ?? p.skus[0]
    selected.value = { ...first.attrs }
    qty.value = 1
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
    <header class="bar" aria-label="商品详情页顶部栏">
      <button class="back" type="button" aria-label="返回" @click="router.back()">返回</button>
      <div class="title">商品详情</div>
      <button class="toCart" type="button" aria-label="购物车" @click="router.push({ name: 'cart' })">
        购物车
      </button>
    </header>

    <main class="content" aria-live="polite">
      <div v-if="state === 'loading'" class="skeletonHero" role="status" aria-label="加载中"></div>

      <div v-else-if="state === 'error'" class="panel" role="alert">
        <div class="panelTitle">加载失败</div>
        <div class="panelDesc">请稍后重试</div>
      </div>

      <div v-else-if="state === 'empty' || !product" class="panel">
        <div class="panelTitle">商品不存在</div>
        <div class="panelDesc">请返回重新选择</div>
      </div>

      <div v-else class="body">
        <section class="media" aria-label="商品图片">
          <div class="track">
            <img
              v-for="(m, i) in product.media"
              :key="i"
              class="img"
              :src="m"
              :alt="product.title"
              @error="(e) => ((e.target as HTMLImageElement).src = coverSvg(product!.title, '#aa3bff'))"
            />
          </div>
        </section>

        <section class="card" aria-label="商品信息">
          <div class="priceRow">
            <div class="price">{{ priceText }}</div>
            <div class="stock">{{ stockText }}</div>
          </div>
          <div class="name">{{ product.title }}</div>
          <div class="metaRow">
            <span class="rating">评分 {{ product.rating.toFixed(1) }}</span>
            <span class="dot">·</span>
            <span class="tagsText">{{ product.tags.join(' / ') }}</span>
          </div>
          <div v-if="product.activity" class="activity">{{ product.activity.label }}</div>
        </section>

        <section class="card" aria-label="规格选择">
          <div class="cardTitle">选择规格</div>
          <div v-for="k in attrKeys" :key="k" class="attr">
            <div class="attrKey">{{ k }}</div>
            <div class="opts">
              <button
                v-for="v in optionsFor(k)"
                :key="v"
                class="opt"
                :class="{ on: selected[k] === v, off: isOptionDisabled(k, v) }"
                type="button"
                :disabled="isOptionDisabled(k, v)"
                @click="selectOption(k, v)"
              >
                {{ v }}
              </button>
            </div>
          </div>

          <div class="qtyRow">
            <div class="qtyLabel">数量</div>
            <div class="qty">
              <button class="qtyBtn" type="button" aria-label="减少数量" @click="setQty(qty - 1)">-</button>
              <div class="qtyVal" aria-label="数量">{{ qty }}</div>
              <button class="qtyBtn" type="button" aria-label="增加数量" @click="setQty(qty + 1)">+</button>
            </div>
          </div>
        </section>

        <section class="card" aria-label="商品说明">
          <div class="cardTitle">详情</div>
          <div class="desc">{{ product.desc }}</div>
        </section>
      </div>
    </main>

    <footer class="action" aria-label="购买操作栏">
      <div class="actionPrice">
        <div class="actionLabel">到手价</div>
        <div class="actionVal">{{ priceText }}</div>
      </div>
      <button class="ghost" type="button" @click="openSheet">加入购物车</button>
      <button class="primary" type="button" @click="openSheet">立即购买</button>
    </footer>

    <div v-if="sheetOpen" class="mask" role="dialog" aria-modal="true" aria-label="购买" @click.self="closeSheet">
      <div class="sheet">
        <div class="sheetHead">
          <div class="sheetTitle">确认规格</div>
          <button class="close" type="button" aria-label="关闭" @click="closeSheet">关闭</button>
        </div>
        <div v-if="product" class="sheetBody">
          <div class="sheetSummary">
            <img class="sheetCover" :src="product.media[0]" :alt="product.title" />
            <div class="sheetInfo">
              <div class="sheetName">{{ product.title }}</div>
              <div class="sheetPrice">{{ priceText }}</div>
              <div class="sheetStock">{{ stockText }}</div>
            </div>
          </div>

          <div class="sheetAttrs">
            <div v-for="k in attrKeys" :key="k" class="attr">
              <div class="attrKey">{{ k }}</div>
              <div class="opts">
                <button
                  v-for="v in optionsFor(k)"
                  :key="v"
                  class="opt"
                  :class="{ on: selected[k] === v, off: isOptionDisabled(k, v) }"
                  type="button"
                  :disabled="isOptionDisabled(k, v)"
                  @click="selectOption(k, v)"
                >
                  {{ v }}
                </button>
              </div>
            </div>

            <div class="qtyRow">
              <div class="qtyLabel">数量</div>
              <div class="qty">
                <button class="qtyBtn" type="button" aria-label="减少数量" @click="setQty(qty - 1)">-</button>
                <div class="qtyVal" aria-label="数量">{{ qty }}</div>
                <button class="qtyBtn" type="button" aria-label="增加数量" @click="setQty(qty + 1)">+</button>
              </div>
            </div>
          </div>
        </div>

        <div class="sheetFoot">
          <button class="ghost" type="button" :disabled="!canSubmit" @click="addToCart(false)">加入购物车</button>
          <button class="primary" type="button" :disabled="!canSubmit" @click="addToCart(true)">去结算</button>
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

.back,
.toCart {
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

.content {
  padding: 14px 16px 100px;
}

.skeletonHero {
  height: 360px;
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

.body {
  display: grid;
  gap: 12px;
}

.media {
  overflow: hidden;
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--bg);
}

.track {
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: 85%;
  gap: 10px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  padding: 10px;
}

.img {
  width: 100%;
  height: 220px;
  object-fit: contain;
  object-position: center center;
  border-radius: 12px;
  scroll-snap-align: start;
  background: var(--code-bg);
}

.card {
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--bg);
  padding: 14px;
  display: grid;
  gap: 10px;
}

.priceRow {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
}

.price {
  color: var(--text-h);
  font-weight: 900;
  font-size: 20px;
}

.stock {
  color: var(--text);
  font-size: 12px;
}

.name {
  color: var(--text-h);
  font-weight: 900;
  font-size: 16px;
  line-height: 1.25;
}

.metaRow {
  color: var(--text);
  font-size: 12px;
  display: flex;
  gap: 8px;
  align-items: center;
}

.dot {
  opacity: 0.6;
}

.activity {
  border: 1px solid color-mix(in srgb, var(--accent) 50%, var(--border));
  background: var(--accent-bg);
  border-radius: 12px;
  padding: 10px 12px;
  color: var(--text-h);
  font-size: 13px;
}

.cardTitle {
  color: var(--text-h);
  font-weight: 900;
}

.attr {
  display: grid;
  gap: 8px;
}

.attrKey {
  color: var(--text);
  font-size: 13px;
}

.opts {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.opt {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 8px 10px;
  font-size: 13px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
}

.opt.on {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.opt.off {
  cursor: not-allowed;
  opacity: 0.45;
}

.qtyRow {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding-top: 6px;
}

.qtyLabel {
  color: var(--text-h);
  font-weight: 800;
}

.qty {
  display: grid;
  grid-template-columns: 30px 40px 30px;
  border: 1px solid var(--border);
  border-radius: 12px;
  overflow: hidden;
}

.qtyBtn {
  border: 0;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
  font-size: 16px;
}

.qtyVal {
  display: grid;
  place-items: center;
  background: color-mix(in srgb, var(--code-bg) 65%, transparent);
  color: var(--text-h);
  font-weight: 900;
}

.desc {
  color: var(--text);
  font-size: 13px;
  line-height: 1.55;
}

.action {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  border-top: 1px solid var(--border);
  background: var(--bg);
  padding: 12px 14px;
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 10px;
  align-items: center;
}

.actionPrice {
  display: grid;
  gap: 2px;
}

.actionLabel {
  font-size: 12px;
  color: var(--text);
}

.actionVal {
  font-weight: 900;
  color: var(--text-h);
}

.ghost,
.primary {
  border-radius: 12px;
  padding: 12px 14px;
  font-size: 14px;
  font-weight: 900;
  cursor: pointer;
}

.ghost {
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text-h);
}

.primary {
  border: 0;
  background: var(--accent);
  color: #fff;
}

.mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  display: grid;
  align-items: end;
  z-index: 50;
}

.sheet {
  background: var(--bg);
  border-top-left-radius: 18px;
  border-top-right-radius: 18px;
  border: 1px solid var(--border);
  border-bottom: 0;
  max-height: 86vh;
  overflow: auto;
}

.sheetHead {
  padding: 12px 14px;
  border-bottom: 1px solid var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 10px;
}

.sheetTitle {
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

.sheetBody {
  padding: 14px;
  display: grid;
  gap: 12px;
}

.sheetSummary {
  display: grid;
  grid-template-columns: 92px minmax(0, 1fr);
  gap: 12px;
  align-items: center;
}

.sheetCover {
  width: 92px;
  height: 92px;
  object-fit: cover;
  border-radius: 14px;
  border: 1px solid var(--border);
  background: var(--code-bg);
}

.sheetInfo {
  display: grid;
  gap: 6px;
}

.sheetName {
  color: var(--text-h);
  font-weight: 900;
  line-height: 1.2;
}

.sheetPrice {
  color: var(--text-h);
  font-weight: 900;
}

.sheetStock {
  font-size: 12px;
  color: var(--text);
}

.sheetAttrs {
  display: grid;
  gap: 12px;
}

.sheetFoot {
  padding: 12px 14px;
  border-top: 1px solid var(--border);
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.sheetFoot .ghost:disabled,
.sheetFoot .primary:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

@media (min-width: 920px) {
  .content {
    max-width: 1120px;
    margin: 0 auto;
  }

  .img { height: 320px; }

  .action {
    max-width: 1120px;
    margin: 0 auto;
    left: 50%;
    transform: translateX(-50%);
    border-left: 1px solid var(--border);
    border-right: 1px solid var(--border);
  }
}
</style>
