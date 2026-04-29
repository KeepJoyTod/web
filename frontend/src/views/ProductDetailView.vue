<script setup lang="ts">

import { computed, onMounted, ref } from 'vue'

import { useRoute, useRouter } from 'vue-router'



import { useCartStore } from '../stores/cart'

import { useToastStore } from '../stores/toast'

import { useAuthStore } from '../stores/auth'

import { useFavoritesStore } from '../stores/favorites'

import { useReviewsStore, type Review } from '../stores/reviews'

import { api } from '../lib/api'



import backIconUrl from '../assets/figma/product-detail/back.svg'

import cartIconUrl from '../assets/figma/product-detail/cart.svg'

import chevronRightIconUrl from '../assets/figma/product-detail/chevron-right.svg'

import minusIconUrl from '../assets/figma/product-detail/minus.svg'

import plusIconUrl from '../assets/figma/product-detail/plus.svg'

import productImgUrl from '../assets/figma/product-detail/product.png'

import starIconUrl from '../assets/figma/product-detail/star.svg'

import starsIconUrl from '../assets/figma/product-detail/stars.svg'



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

  sold: number

  activityLabel: string

  originalPrice: number

  price: number

  skus: Sku[]
}



const router = useRouter()

const route = useRoute()

const auth = useAuthStore()

const cart = useCartStore()

const favorites = useFavoritesStore()

const toast = useToastStore()

const reviewsStore = useReviewsStore()



const isFav = computed(() => favorites.isFavorite(id.value))



const toggleFavorite = async () => {

  if (!auth.user) {

    toast.push({ type: 'error', message: '请先登录' })

    router.push({ name: 'login' })

    return

  }

  

  try {

    if (isFav.value) {

      await favorites.removeByProductId(id.value)

      toast.push({ type: 'info', message: '已取消收藏' })

    } else {

      await favorites.add({ productId: id.value })

      toast.push({ type: 'success', message: '收藏成功' })

    }

  } catch (e) {

    toast.push({ type: 'error', message: '操作失败' })

  }

}



const state = ref<LoadState>('loading')

const product = ref<Product | null>(null)

const currentMediaIndex = ref(0)

const selected = ref<Record<string, string>>({})

const qty = ref(1)

const submitting = ref(false)



const id = computed(() => String(route.params.id ?? ''))



const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })



const reviewsState = ref<'idle' | 'loading' | 'ready' | 'error'>('idle')

const reviewsFilter = ref<'all' | 'positive' | 'neutral' | 'negative'>('all')

const reviewsExpanded = ref(false)



const setReviewsFilter = (next: typeof reviewsFilter.value) => {

  reviewsFilter.value = next

  reviewsExpanded.value = false

}



const productReviews = computed(() => reviewsStore.items.filter((r) => r.productId === id.value))

const reviewTotal = computed(() => productReviews.value.length)



const reviewPositive = computed(() => productReviews.value.filter((r) => r.rating >= 4).length)

const reviewNeutral = computed(() => productReviews.value.filter((r) => r.rating === 3).length)

const reviewNegative = computed(() => productReviews.value.filter((r) => r.rating <= 2).length)



const reviewAvg = computed(() => {

  if (reviewTotal.value === 0) return 0

  const sum = productReviews.value.reduce((acc, r) => acc + (Number.isFinite(r.rating) ? r.rating : 0), 0)

  return sum / reviewTotal.value

})



const reviewPositiveRate = computed(() => {

  if (reviewTotal.value === 0) return 0

  return Math.round((reviewPositive.value / reviewTotal.value) * 100)

})



const reviewStarDist = computed(() => {

  const total = reviewTotal.value

  const counts = [0, 0, 0, 0, 0, 0]

  for (const r of productReviews.value) {

    const n = Math.max(1, Math.min(5, Math.floor(Number(r.rating) || 0)))

    counts[n] += 1

  }

  return [5, 4, 3, 2, 1].map((star) => ({

    star,

    count: counts[star],

    pct: total === 0 ? 0 : Math.round((counts[star] / total) * 100),

  }))

})



const filteredReviews = computed(() => {

  const list = productReviews.value

  if (reviewsFilter.value === 'positive') return list.filter((r) => r.rating >= 4)

  if (reviewsFilter.value === 'neutral') return list.filter((r) => r.rating === 3)

  if (reviewsFilter.value === 'negative') return list.filter((r) => r.rating <= 2)

  return list

})



const visibleReviews = computed(() => (reviewsExpanded.value ? filteredReviews.value : filteredReviews.value.slice(0, 3)))



const myReview = computed<Review | null>(() => {

  const currentUserId = auth.user?.id

  if (!currentUserId) return null

  return productReviews.value.find((r) => String(r.userId) === String(currentUserId)) ?? null

})

const otherReviewsCount = computed(() => {

  const mine = myReview.value

  if (!mine) return filteredReviews.value.length

  return filteredReviews.value.filter((r) => r.id !== mine.id).length

})



const otherVisibleReviews = computed(() => {

  const mine = myReview.value

  if (!mine) return visibleReviews.value

  return visibleReviews.value.filter((r) => r.id !== mine.id)

})



const fmtReviewDate = (iso: string) => {

  const d = new Date(iso)

  if (Number.isNaN(d.getTime())) return ''

  const y = d.getFullYear()

  const m = String(d.getMonth() + 1).padStart(2, '0')

  const day = String(d.getDate()).padStart(2, '0')

  return `${y}-${m}-${day}`

}



const fetchReviews = async (productId: string) => {

  reviewsState.value = 'loading'

  try {

    await reviewsStore.fetch(productId)

    reviewsState.value = 'ready'

  } catch {

    reviewsState.value = 'error'

  }

}



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

  return priceFmt.format(p.price)
})



const oldPriceText = computed(() => {

  const p = product.value

  if (!p) return '--'

  return priceFmt.format(p.originalPrice)

})



const ratingText = computed(() => {

  const p = product.value

  if (!p) return '--'

  return `${p.rating.toFixed(1)} 评分`

})



const soldText = computed(() => {

  const p = product.value

  if (!p) return '--'

  return `已售 ${p.sold}`

})



const stockText = computed(() => {

  const sku = selectedSku.value

  if (!sku) return '请选择规格'

  if (sku.stock <= 0) return '无货'

  return `库存 ${sku.stock}`

})



const stockTextFor = (key: string, value: string) => {

  const p = product.value

  if (!p) return ''

  const keys = attrKeys.value

  const draft: Record<string, string> = { ...selected.value, [key]: value }

  const sku =

    p.skus.find((s) => keys.every((k) => (draft[k] ? s.attrs[k] === draft[k] : true))) ??

    p.skus.find((s) => s.attrs[key] === value) ??

    null

  if (!sku) return '—'

  if (sku.stock <= 0) return '无货'

  return `库存 ${sku.stock}`

}



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

  // 如果点击已选中的，则取消选择

  if (selected.value[key] === value) {

    const next = { ...selected.value }

    delete next[key]

    selected.value = next

  } else {

    selected.value = { ...selected.value, [key]: value }

  }

  qty.value = 1

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

      cover: p.media[0] ?? productImgUrl,

    })



    toast.push({ type: 'success', message: '已加入购物车' })



    if (goCheckout) {

      await router.push({ name: 'checkout' })

    }

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

    const originalPrice = Number.isFinite(Number(x.originalPrice)) ? Number(x.originalPrice) : price

    const cover = `/product_${String(x.id ?? id.value)}.jpg`

    const media =

      Array.isArray(x.media) && x.media.length > 0

        ? x.media.map((m: any) => String(m)).filter((m: string) => m.trim())

        : [cover]



    const p: Product = {

      id: String(x.id ?? id.value),

      title: name,

      desc: String(x.description ?? ''),

      media: media.length > 0 ? media : [productImgUrl],

      rating: Number.isFinite(Number(x.rating)) ? Number(x.rating) : 4.5,

      sold: Number.isFinite(Number(x.sold)) ? Number(x.sold) : 0,

      activityLabel: typeof x.activityLabel === 'string' && x.activityLabel.trim() ? x.activityLabel : '',

      originalPrice,

      price,

      // 如果后端有 SKUs 则使用，否则使用基础价格和库存作为默认 SKU

      skus: x.skus && x.skus.length > 0 

        ? x.skus.map((s: any) => ({

            id: String(s.id),

            attrs: s.attrs || {},

            price: Number(s.price),

            stock: Number(s.stock)

          }))

        : [{ id: 'default', attrs: { '规格': '默认' }, price, stock: Number(x.stock ?? 0) }],

    }



    product.value = p

    currentMediaIndex.value = 0

    // 取消默认全部选择，改为默认不选，让用户手动选择

    selected.value = {}

    qty.value = 1

    state.value = 'ready'

    await fetchReviews(id.value)

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

    <header class="headerSticky">

      <div class="headerContent">

        <button class="backBtn" type="button" aria-label="返回" @click="router.back()">

          <img class="backIcon" :src="backIconUrl" alt="" aria-hidden="true" />

          <span class="backText">返回</span>

        </button>



        <nav v-if="product" class="crumbs" aria-label="面包屑">

          <button class="crumbLink" type="button" @click="router.push({ name: 'home' })">首页</button>

          <span class="crumbSep" aria-hidden="true">/</span>

          <button class="crumbLink" type="button" @click="router.push({ name: 'category' })">商品</button>

          <span class="crumbSep" aria-hidden="true">/</span>

          <span class="crumbCurrent">{{ product.title }}</span>

        </nav>

      </div>

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



      <div v-else class="wrap">

        <section class="productCard" aria-label="商品详情">

          <div class="cols">

            <div class="left">

              <div class="hero" aria-label="商品图片">

                <img class="heroImg" :src="product.media[currentMediaIndex]" :alt="product.title" />

              </div>



              <div class="thumbs" aria-label="图片选择">

                <button

                  v-for="(m, i) in product.media"

                  :key="i"

                  class="thumbBtn"

                  :class="{ on: currentMediaIndex === i }"

                  type="button"

                  :aria-label="`图片 ${i + 1}`"

                  @click="currentMediaIndex = i"

                >

                  <img class="thumbImg" :src="m" :alt="product.title" />

                </button>

              </div>

            </div>



            <div class="right">

              <div class="promo">{{ product.activityLabel }}</div>

              <h1 class="h1">{{ product.title }}</h1>

              <div class="sub">{{ product.desc }}</div>



              <div class="stats">

                <div class="rating">

                  <img class="statIcon" :src="starIconUrl" alt="" aria-hidden="true" />

                  <span class="statText strong">{{ ratingText }}</span>

                </div>

                <span class="statSep" aria-hidden="true">|</span>

                <span class="statText">{{ soldText }}</span>

              </div>



              <div class="priceCard" aria-label="价格">

                <div class="priceLine">

                  <div class="priceLabel">价格</div>

                  <div class="priceMain">{{ priceText }}</div>

                </div>

                <div class="priceOld">原价: {{ oldPriceText }}</div>

              </div>



              <div class="skuBlock" aria-label="规格选择">

                <div class="blockTitle">选择规格</div>

                <div v-for="k in attrKeys" :key="k" class="skuGroup">

                  <div class="skuGrid">

                    <button

                      v-for="v in optionsFor(k)"

                      :key="v"

                      class="skuBtn"

                      :class="{ on: selected[k] === v, off: isOptionDisabled(k, v) }"

                      type="button"

                      :disabled="isOptionDisabled(k, v)"

                      @click="selectOption(k, v)"

                    >

                      <div class="skuName">{{ v }}</div>

                      <div class="skuStock">{{ stockTextFor(k, v) }}</div>

                    </button>

                  </div>

                </div>

              </div>



              <div class="qtyBlock" aria-label="数量选择">

                <div class="blockTitle">数量</div>

                <div class="qtyRow">

                  <div class="qtyControl" role="group" aria-label="数量控制">

                    <button class="qtyIconBtn" type="button" aria-label="减少数量" :disabled="qty <= 1" @click="setQty(qty - 1)">

                      <img class="qtyIcon" :src="minusIconUrl" alt="" aria-hidden="true" />

                    </button>

                    <div class="qtyValue" aria-label="数量">{{ qty }}</div>

                    <button

                      class="qtyIconBtn"

                      type="button"

                      aria-label="增加数量"

                      :disabled="qty >= maxQty"

                      @click="setQty(qty + 1)"

                    >

                      <img class="qtyIcon" :src="plusIconUrl" alt="" aria-hidden="true" />

                    </button>

                  </div>

                  <div class="qtyStock">{{ stockText }}</div>

                </div>

              </div>



              <div class="actions" aria-label="购买操作">

                <button class="btnAdd" type="button" :disabled="!canSubmit" @click="addToCart(false)">

                  <img class="btnIcon" :src="cartIconUrl" alt="" aria-hidden="true" />

                  加入购物车

                </button>

                <button class="btnBuy" type="button" :disabled="!canSubmit" @click="addToCart(true)">立即购买</button>

                <button class="btnFav" :class="{ on: isFav }" type="button" aria-label="收藏" @click="toggleFavorite">

                  <img class="favIcon" :src="starIconUrl" alt="" aria-hidden="true" />

                </button>

              </div>

            </div>

          </div>

        </section>



        <section class="reviewsSection" aria-label="商品评价">

          <header class="reviewsHead">

            <h2 class="reviewsTitle">商品评价</h2>

            <button class="reviewsMore" type="button" @click="reviewsExpanded = !reviewsExpanded">

              <span>查看全部</span>

              <img class="reviewsMoreIcon" :src="chevronRightIconUrl" alt="" aria-hidden="true" />

            </button>

          </header>



          <div v-if="reviewsState === 'error'" class="reviewsPanel" role="alert">

            <div class="reviewsPanelTitle">评价加载失败</div>

            <button class="reviewsRetry" type="button" @click="fetchReviews(id)">重试</button>

          </div>



          <div v-else class="reviewsBody">

            <div class="reviewsSummary" aria-label="评价概览">

              <div class="summaryLeft">

                <div class="summaryScore">{{ reviewAvg ? reviewAvg.toFixed(1) : '0.0' }}</div>

                <img class="summaryStars" :src="starsIconUrl" alt="" aria-hidden="true" />

                <div class="summaryCount">{{ reviewTotal }} 条评价</div>

              </div>



              <div class="summaryRight">

                <div v-for="row in reviewStarDist" :key="row.star" class="distRow">

                  <div class="distStar">{{ row.star }}星</div>

                  <div class="distBar" aria-hidden="true">

                    <div class="distFill" :style="{ width: row.pct + '%' }"></div>

                  </div>

                  <div class="distCount">{{ row.count }}</div>

                </div>

                <div class="distRate">好评率: {{ reviewPositiveRate }}%</div>

              </div>

            </div>



            <div class="reviewsTabs" role="tablist" aria-label="评价筛选">

              <button

                class="tabBtn"

                :class="{ on: reviewsFilter === 'all' }"

                type="button"

                role="tab"

                :aria-selected="reviewsFilter === 'all'"

                @click="setReviewsFilter('all')"

              >

                全部 ({{ reviewTotal }})

              </button>

              <button

                class="tabBtn"

                :class="{ on: reviewsFilter === 'positive' }"

                type="button"

                role="tab"

                :aria-selected="reviewsFilter === 'positive'"

                @click="setReviewsFilter('positive')"

              >

                好评 ({{ reviewPositive }})

              </button>

              <button

                class="tabBtn"

                :class="{ on: reviewsFilter === 'neutral' }"

                type="button"

                role="tab"

                :aria-selected="reviewsFilter === 'neutral'"

                @click="setReviewsFilter('neutral')"

              >

                中评 ({{ reviewNeutral }})

              </button>

              <button

                class="tabBtn"

                :class="{ on: reviewsFilter === 'negative' }"

                type="button"

                role="tab"

                :aria-selected="reviewsFilter === 'negative'"

                @click="setReviewsFilter('negative')"

              >

                差评 ({{ reviewNegative }})

              </button>

            </div>



            <div class="reviewBlock">

              <div class="reviewBlockTitle">我的评价</div>

              <div class="myReviewCard">

                <div v-if="myReview" class="reviewRow">

                  <div class="avatar avatarMe">我</div>

                  <div class="reviewMain">

                    <div class="reviewMeta">

                      <div class="reviewName">我</div>

                      <div class="reviewStars">{{ '★★★★★'.slice(0, Math.max(0, Math.min(5, Math.floor(myReview.rating)))) }}</div>

                      <div class="reviewDate">{{ fmtReviewDate(myReview.createdAt) }}</div>

                    </div>

                    <div class="reviewText">{{ myReview.content }}</div>

                  </div>

                </div>

                <div v-else class="myReviewEmpty">

                  <div class="myEmptyText">暂无评价，需从订单详情进入发布评价</div>

                  <button class="myEmptyBtn" type="button" @click="router.push({ name: 'orders' })">去订单</button>

                </div>

              </div>

            </div>



            <div class="reviewBlock">

              <div class="reviewBlockTitle">其他用户评价 ({{ otherReviewsCount }})</div>



              <div v-if="reviewsState === 'loading'" class="reviewsLoading">加载中…</div>

              <div v-else-if="otherVisibleReviews.length === 0" class="reviewsEmpty">暂无评价</div>



              <div v-else class="otherList" role="list">

                <div v-for="r in otherVisibleReviews" :key="r.id" class="otherItem" role="listitem">

                  <div class="avatar">{{ r.nickname[0] }}</div>

                  <div class="reviewMain">

                    <div class="reviewMeta">

                      <div class="reviewName">{{ r.nickname }}</div>

                      <div class="reviewStars">{{ '★★★★★'.slice(0, Math.max(0, Math.min(5, Math.floor(r.rating)))) }}</div>

                      <div class="reviewDate">{{ fmtReviewDate(r.createdAt) }}</div>

                    </div>

                    <div class="reviewText">{{ r.content }}</div>

                    <div v-if="r.images && r.images.length > 0" class="reviewImgs">

                      <img v-for="(img, idx) in r.images" :key="idx" :src="img" class="reviewImg" alt="评价图片" />

                    </div>

                  </div>

                </div>

              </div>

            </div>

          </div>

        </section>

      </div>

    </main>

  </div>

</template>



<style scoped>

.page {

  min-height: 100%;

}



.content {

  padding: 40px 16px;

}



.wrap {

  max-width: 1022px;

  margin: 0 auto;

  display: grid;

  gap: 24px;

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

  max-width: 560px;

  margin: 0 auto;

}



.panelTitle {

  color: var(--text-h);

  font-weight: 900;

}



.panelDesc {

  color: var(--text);

  font-size: 13px;

}



.headerSticky {

  position: sticky;

  top: 0;

  background: var(--bg);

  z-index: 100;

  border-bottom: 1px solid var(--border);

}



.headerContent {

  max-width: 1022px;

  margin: 0 auto;

  padding: 16px;

  display: flex;

  align-items: center;

  gap: 24px;

}



.backBtn {

  display: inline-flex;

  align-items: center;

  gap: 8px;

  border: 0;

  background: transparent;

  padding: 0;

  cursor: pointer;

  color: var(--text);

  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.backIcon {

  width: 20px;

  height: 20px;

}



.crumbs {

  display: flex;

  align-items: center;

  gap: 8px;

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  color: var(--text);

  min-width: 0;

}



.crumbLink {

  border: 0;

  background: transparent;

  padding: 0;

  cursor: pointer;

  color: var(--text);

  font: inherit;

}



.crumbSep {

  color: var(--text);

}



.crumbCurrent {

  color: var(--text);

  overflow: hidden;

  text-overflow: ellipsis;

  white-space: nowrap;

}



.productCard {

  background: var(--bg);

  border-radius: 10px;

  border: 1px solid var(--border);

  padding: 32px 32px 0;

}



.cols {

  display: grid;

  gap: 24px;

}



.left {

  display: grid;

  gap: 16px;

}



.hero {

  background: var(--code-bg);

  border-radius: 10px;

  overflow: hidden;

}



.heroImg {

  width: 100%;

  height: 463px;

  object-fit: cover;

  display: block;

}



.thumbs {

  display: flex;

  gap: 8px;

}



.thumbBtn {

  width: 80px;

  height: 80px;

  padding: 2px;

  border-radius: 10px;

  border: 2px solid rgba(0, 0, 0, 0);

  background: transparent;

  display: grid;

  place-items: center;

}



.thumbBtn.on {

  border-color: var(--accent);

}



.thumbBtn:disabled {

  opacity: 0.6;

}



.thumbImg {

  width: 100%;

  height: 76px;

  object-fit: cover;

  border-radius: 8px;

  display: block;

}



.right {

  display: grid;

  gap: 12px;

}



.promo {

  display: inline-flex;

  align-items: center;

  height: 28px;

  padding: 0 12px;

  border-radius: 999px;

  background: var(--danger-bg);

  color: var(--danger);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  width: fit-content;

}



.h1 {

  margin: 0;

  color: var(--text-h);

  font: 500 30px/36px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.sub {

  color: var(--text);

  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.stats {

  display: flex;

  align-items: center;

  gap: 16px;

  height: 24px;

}



.rating {

  display: inline-flex;

  align-items: center;

  gap: 8px;

}



.statIcon {

  width: 20px;

  height: 20px;

}



.statText {

  color: var(--text);

  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.statText.strong {

  color: var(--text-h);

}



.statSep {

  color: var(--border);

  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.priceCard {

  background: var(--code-bg);

  border-radius: 10px;

  padding: 24px 24px 0;

  display: grid;

  gap: 8px;

}



.priceLine {

  display: flex;

  align-items: baseline;

  flex-wrap: wrap;

  gap: 8px;

  min-height: 40px;

}



.priceLabel {

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  flex-shrink: 0;

}



.priceMain {

  color: var(--danger);

  font: 400 clamp(20px, 5vw, 36px)/1.1 Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  word-break: break-all;

}



.priceOld {

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.blockTitle {

  color: var(--text-h);

  font: 500 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.skuGrid {

  display: grid;

  grid-template-columns: 1fr;

  gap: 12px;

}



.skuBtn {

  border-radius: 10px;

  border: 2px solid var(--border);

  background: var(--bg);

  padding: 14px 14px 2px;

  display: grid;

  gap: 4px;

  text-align: center;

  cursor: pointer;

}



.skuBtn.on {

  background: var(--accent-bg);

  border-color: var(--accent);

}



.skuBtn.off {

  cursor: not-allowed;

  opacity: 0.5;

}



.skuName {

  color: var(--text-h);

  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.skuStock {

  color: var(--text);

  font: 500 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.qtyRow {

  display: flex;

  justify-content: space-between;

  align-items: center;

  gap: 12px;

}



.qtyControl {

  width: 130px;

  height: 42px;

  border-radius: 10px;

  border: 1px solid var(--border);

  display: grid;

  grid-template-columns: 32px 1fr 32px;

  align-items: center;

  overflow: hidden;

}



.qtyIconBtn {

  width: 32px;

  height: 32px;

  border: 0;

  background: transparent;

  padding: 0;

  display: grid;

  place-items: center;

  cursor: pointer;

}



.qtyIconBtn:disabled {

  cursor: not-allowed;

  opacity: 0.4;

}



.qtyIcon {

  width: 20px;

  height: 20px;

}



.qtyValue {

  height: 40px;

  display: grid;

  place-items: center;

  border-left: 1px solid var(--border);

  border-right: 1px solid var(--border);

  color: var(--text-h);

  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.qtyStock {

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.actions {

  display: grid;

  grid-template-columns: 1fr 1fr 50px;

  gap: 16px;

  padding-bottom: 32px;

}



.btnAdd,

.btnBuy {

  height: 50px;

  border-radius: 10px;

  border: 0;

  color: #ffffff;

  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  cursor: pointer;

  display: inline-flex;

  align-items: center;

  justify-content: center;

  gap: 8px;

}



.btnAdd {

  background: var(--accent);

}



.btnBuy {

  background: var(--danger);

}



.btnAdd:disabled,

.btnBuy:disabled {

  cursor: not-allowed;

  opacity: 0.5;

}



.btnFav {

  width: 56px;

  height: 56px;

  border-radius: 12px;

  border: 1px solid var(--border);

  background: var(--bg);

  cursor: pointer;

  display: flex;

  align-items: center;

  justify-content: center;

  transition: all 0.2s ease;

}



.btnFav.on {

  border-color: #fadb14;

  background: #fffbe6;

}



.favIcon {

  width: 24px;

  height: 24px;

  filter: grayscale(1);

  transition: all 0.2s ease;

}



.btnFav.on .favIcon {

  filter: none;

}



.btnIcon {

  width: 20px;

  height: 20px;

}



.btnMore {

  width: 50px;

  height: 50px;

  border-radius: 10px;

  border: 1px solid var(--border);

  background: transparent;

  padding: 0;

  display: grid;

  place-items: center;

  cursor: pointer;

}



.moreIcon {

  width: 20px;

  height: 20px;

}



.reviewsSection {

  background: var(--bg);

  border-radius: 16px;

  border: 1px solid var(--border);

  padding: 32px;

  display: grid;

  gap: 24px;

}



.reviewsHead {

  display: flex;

  justify-content: space-between;

  align-items: center;

  gap: 16px;

}



.reviewsTitle {

  margin: 0;

  color: var(--text-h);

  font: 600 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewsMore {

  border: 0;

  background: transparent;

  padding: 0;

  cursor: pointer;

  display: inline-flex;

  align-items: center;

  gap: 4px;

  color: var(--accent);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewsMoreIcon {

  width: 16px;

  height: 16px;

}



.reviewsPanel {

  border: 1px solid var(--border);

  border-radius: 16px;

  padding: 18px 16px;

  display: flex;

  justify-content: space-between;

  align-items: center;

  gap: 12px;

}



.reviewsPanelTitle {

  color: var(--text);

  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewsRetry {

  height: 36px;

  border-radius: 999px;

  border: 0;

  background: var(--accent);

  color: #ffffff;

  padding: 0 14px;

  cursor: pointer;

  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewsBody {

  display: grid;

  gap: 24px;

}



.reviewsSummary {

  border-radius: 16px;

  padding: 24px 24px 0;

  background: var(--code-bg);

  display: grid;

  gap: 24px;

}



.summaryLeft {

  display: grid;

  justify-items: center;

  gap: 8px;

}



.summaryScore {

  color: var(--accent);

  font: 600 48px/48px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.summaryStars {

  width: 96px;

  height: 16px;

}



.summaryCount {

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.summaryRight {

  display: grid;

  gap: 8px;

  align-content: start;

}



.distRow {

  display: flex;

  align-items: center;

  gap: 12px;

}



.distStar {

  width: 48px;

  color: var(--text-h);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.distBar {

  flex: 1;

  height: 8px;

  border-radius: 999px;

  background: var(--border);

  overflow: hidden;

}



.distFill {

  height: 100%;

  background: var(--accent);

  border-radius: 999px;

}



.distCount {

  width: 24px;

  text-align: right;

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.distRate {

  margin-top: 8px;

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewsTabs {

  display: flex;

  align-items: center;

  gap: 12px;

  flex-wrap: wrap;

}



.tabBtn {

  height: 36px;

  padding: 0 15px;

  border-radius: 999px;

  border: 0;

  background: var(--code-bg);

  color: var(--text);

  cursor: pointer;

  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.tabBtn.on {

  background: var(--accent);

  color: #ffffff;

}



.reviewBlock {

  display: grid;

  gap: 16px;

}



.reviewBlockTitle {

  color: var(--text-h);

  font: 600 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.myReviewCard {

  border-radius: 16px;

  border: 2px solid var(--accent-border);

  background: var(--accent-bg);

  padding: 26px 26px 2px;

}



.reviewRow {

  display: flex;

  gap: 16px;

}



.avatar {

  width: 48px;

  height: 48px;

  border-radius: 999px;

  background: var(--border);

  color: var(--text);

  display: grid;

  place-items: center;

  font: 600 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  flex: 0 0 auto;

}



.avatarMe {

  background: var(--accent);

  color: #ffffff;

}



.reviewMain {

  flex: 1;

  display: grid;

  gap: 12px;

  min-width: 0;

}



.reviewMeta {

  display: flex;

  align-items: center;

  gap: 12px;

  flex-wrap: wrap;

}



.reviewName {

  color: var(--text-h);

  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewStars {

  color: var(--accent);

  letter-spacing: 1px;

  font: 400 14px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewDate {

  color: var(--text);

  font: 500 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.reviewText {

  color: var(--text);

  font: 400 16px/26px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  word-break: break-word;

}



.reviewImgs {

  display: flex;

  flex-wrap: wrap;

  gap: 8px;

  margin-top: 8px;

}



.reviewImg {

  width: 80px;

  height: 80px;

  object-fit: cover;

  border-radius: 4px;

  border: 1px solid var(--border);

}



.myReviewEmpty {

  display: flex;

  justify-content: space-between;

  align-items: center;

  gap: 12px;

}



.myEmptyText {

  color: var(--text);

  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.myEmptyBtn {

  height: 36px;

  border-radius: 999px;

  border: 0;

  background: var(--accent);

  color: #ffffff;

  padding: 0 14px;

  cursor: pointer;

  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

  flex: 0 0 auto;

}



.reviewsLoading,

.reviewsEmpty {

  color: var(--text);

  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;

}



.otherList {

  display: grid;

  gap: 24px;

}



.otherItem {

  display: flex;

  gap: 16px;

  padding-bottom: 24px;

  border-bottom: 1px solid var(--border);

}



.otherItem:last-child {

  border-bottom: 0;

  padding-bottom: 0;

}



@media (min-width: 1024px) {

  .cols {

    grid-template-columns: 463px 463px;

    gap: 32px;

    align-items: start;

  }



  .reviewsSummary {

    grid-template-columns: 287.33px 1fr;

  }



  .skuGrid {

    grid-template-columns: 225.5px 225.5px;

    column-gap: 12px;

    row-gap: 12px;

  }

}



@media (max-width: 540px) {

  .heroImg {

    height: 320px;

  }

}

</style>

