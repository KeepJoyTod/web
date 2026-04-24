<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useCartStore } from '../stores/cart'
import { useFavoritesStore } from '../stores/favorites'
import { useToastStore } from '../stores/toast'

import backIconUrl from '../assets/figma/favorites/back.svg'
import cartIconUrl from '../assets/figma/favorites/cart.svg'
import favIconUrl from '../assets/figma/favorites/icon-favorites.svg'
import removeIconUrl from '../assets/figma/favorites/remove.svg'
import starIconUrl from '../assets/figma/favorites/star.svg'

const router = useRouter()
const favorites = useFavoritesStore()
const cart = useCartStore()
const toast = useToastStore()

onMounted(() => {
  favorites.fetch()
})

const selected = ref<Set<string>>(new Set())

const selectedCount = computed(() => selected.value.size)
const allSelected = computed(() => favorites.items.length > 0 && selected.value.size === favorites.items.length)

const toggleAll = () => {
  if (allSelected.value) {
    selected.value = new Set()
    return
  }
  selected.value = new Set(favorites.items.map((x) => x.favId))
}

const toggleOne = (favId: string) => {
  const next = new Set(selected.value)
  if (next.has(favId)) next.delete(favId)
  else next.add(favId)
  selected.value = next
}

const goBrowse = () => {
  router.push({ name: 'home' })
}

const goProduct = (productId: string) => {
  router.push({ name: 'productDetail', params: { id: productId } })
}

const addToCart = (favId: string) => {
  const it = favorites.items.find((x) => x.favId === favId)
  if (!it) return
  cart.addItem({
    productId: it.productId,
    skuId: 'default',
    title: it.title,
    cover: it.cover,
    price: it.price,
    qty: 1,
  })
  toast.push({ type: 'success', message: '已加入购物车' })
}

const bulkAdd = () => {
  if (selected.value.size === 0) return
  for (const favId of selected.value) {
    addToCart(favId)
  }
  toast.push({ type: 'success', message: `已加购 ${selected.value.size} 件` })
}

const removeOne = (favId: string) => {
  favorites.remove(favId)
  const next = new Set(selected.value)
  next.delete(favId)
  selected.value = next
  toast.push({ type: 'info', message: '已移除收藏' })
}

const bulkRemove = () => {
  if (selected.value.size === 0) return
  favorites.removeMany([...selected.value])
  selected.value = new Set()
  toast.push({ type: 'info', message: '已移除' })
}
</script>

<template>
  <div class="page">
    <main class="main" aria-live="polite">
      <button class="back" type="button" @click="router.back()">
        <img class="backIcon" :src="backIconUrl" alt="" aria-hidden="true" />
        <span>返回</span>
      </button>

      <div class="top">
        <div class="titleBlock">
          <div class="h1Row">
            <img class="h1Icon" :src="favIconUrl" alt="" aria-hidden="true" />
            <h1 class="h1">我的收藏</h1>
          </div>
          <div class="sub">共 {{ favorites.count }} 件商品</div>
        </div>
        <button class="browseBtn" type="button" @click="goBrowse">继续浏览</button>
      </div>

      <UiEmptyState
        v-if="favorites.items.length === 0"
        title="暂无收藏"
        desc="收藏喜欢的商品，方便随时查看"
        action-text="去逛逛"
        @action="goBrowse"
      />

      <div v-else class="bulkBar" aria-label="操作">
        <button class="selectAll" type="button" @click="toggleAll">
          <span class="checkbox" :class="{ on: allSelected }" aria-hidden="true"></span>
          <span>全选</span>
        </button>
        <div class="bulkActions">
          <button class="bulkAdd" type="button" :disabled="selectedCount === 0" @click="bulkAdd">
            加购 ({{ selectedCount }})
          </button>
          <button class="bulkRemove" type="button" :disabled="selectedCount === 0" @click="bulkRemove">
            移除 ({{ selectedCount }})
          </button>
        </div>
      </div>

      <section v-if="favorites.items.length > 0" class="grid" aria-label="收藏列表">
        <article v-for="it in favorites.items" :key="it.favId" class="card">
          <div class="media">
            <button class="mediaBtn" type="button" @click="goProduct(it.productId)" aria-label="查看商品">
              <img class="img" :src="it.cover" :alt="it.title" loading="lazy" decoding="async" />
            </button>
            <button class="cardSelect" type="button" @click="toggleOne(it.favId)" aria-label="选择收藏">
              <span class="checkbox" :class="{ on: selected.has(it.favId) }" aria-hidden="true"></span>
            </button>
          </div>

          <div class="body">
            <div class="tags" aria-label="标签">
              <span v-for="t in it.tags.slice(0, 2)" :key="t" class="tag">{{ t }}</span>
            </div>

            <button class="nameBtn" type="button" @click="goProduct(it.productId)">{{ it.title }}</button>

            <div class="meta">
              <div class="rating">
                <img class="star" :src="starIconUrl" alt="" aria-hidden="true" />
                <span class="ratingVal">{{ it.rating.toFixed(1) }}</span>
              </div>
              <span class="sep">|</span>
              <span class="sold">已售 {{ it.sold }}</span>
            </div>

            <div class="prices">
              <div class="price">¥{{ Math.round(it.price) }}</div>
              <div v-if="it.oldPrice" class="old">¥{{ Math.round(it.oldPrice) }}</div>
            </div>

            <div v-if="it.promo" class="promo">{{ it.promo }}</div>

            <div class="actions">
              <button class="addBtn" type="button" @click="addToCart(it.favId)">
                <img class="cartIcon" :src="cartIconUrl" alt="" aria-hidden="true" />
                <span>加购</span>
              </button>
              <button class="removeBtn" type="button" @click="removeOne(it.favId)" aria-label="移除收藏">
                <img class="removeIcon" :src="removeIconUrl" alt="" aria-hidden="true" />
              </button>
            </div>
          </div>
        </article>
      </section>

      <section class="tips" aria-label="小贴士">
        <div class="tipsTitle">💡 小贴士</div>
        <ul class="tipsList">
          <li class="tip">收藏的商品会在这里保存，方便随时查看</li>
          <li class="tip">商品价格变动时，我们会及时通知您</li>
          <li class="tip">点击"加购"可快速将商品加入购物车</li>
        </ul>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  background: var(--bg);
}

.main {
  padding: 24px 16px 64px;
  width: min(1022px, 100%);
  margin: 0 auto;
  display: grid;
  gap: 16px;
}

.back {
  height: 24px;
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.backIcon {
  width: 20px;
  height: 20px;
}

.top {
  height: 68px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.titleBlock {
  display: grid;
  gap: 8px;
}

.h1Row {
  display: inline-flex;
  align-items: center;
  gap: 12px;
}

.h1Icon {
  width: 32px;
  height: 32px;
}

.h1 {
  margin: 0;
  font: 700 30px/36px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.sub {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.browseBtn {
  width: 112px;
  height: 40px;
  border: 0;
  border-radius: 10px;
  cursor: pointer;
  background: var(--accent);
  color: #ffffff;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.bulkBar {
  height: 70px;
  border-radius: 14px;
  background: var(--bg);
  border: 1px solid var(--border);
  padding: 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.selectAll {
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.checkbox {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  border: 2px solid var(--border);
  background: var(--bg);
  position: relative;
  flex: 0 0 auto;
}

.checkbox.on {
  border-color: var(--accent);
  background: var(--accent);
}

.checkbox.on::after {
  content: '';
  position: absolute;
  left: 4px;
  top: 1px;
  width: 5px;
  height: 9px;
  border: 2px solid #ffffff;
  border-top: 0;
  border-left: 0;
  transform: rotate(45deg);
}

.bulkActions {
  display: inline-flex;
  align-items: center;
  gap: 12px;
}

.bulkAdd,
.bulkRemove {
  height: 38px;
  border-radius: 10px;
  cursor: pointer;
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  padding: 0 16px;
}

.bulkAdd {
  border: 0;
  background: var(--accent);
  color: #ffffff;
}

.bulkRemove {
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text);
}

.bulkAdd:disabled,
.bulkRemove:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.grid {
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(auto-fill, minmax(324px, 1fr));
}

.card {
  border-radius: 14px;
  background: var(--bg);
  border: 1px solid var(--border);
  padding: 2px;
  overflow: hidden;
  display: grid;
}

.media {
  position: relative;
  height: 320px;
}

.mediaBtn {
  border: 0;
  padding: 0;
  background: transparent;
  cursor: pointer;
  width: 100%;
  height: 100%;
  display: block;
}

.img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.cardSelect {
  position: absolute;
  top: 12px;
  right: 12px;
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: color-mix(in srgb, var(--bg) 90%, transparent);
  border: 1px solid var(--border);
  display: grid;
  place-items: center;
  cursor: pointer;
}

.body {
  padding: 16px;
  display: grid;
  gap: 12px;
}

.tags {
  display: flex;
  gap: 8px;
}

.tag {
  width: 40px;
  height: 24px;
  border-radius: 9999px;
  background: var(--accent);
  color: #ffffff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font: 400 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.nameBtn {
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  text-align: left;
  font: 500 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.meta {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  height: 20px;
}

.rating {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}

.star {
  width: 16px;
  height: 16px;
}

.ratingVal {
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.sep {
  font: 400 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--border);
}

.sold {
  font: 400 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.prices {
  display: inline-flex;
  align-items: baseline;
  gap: 12px;
  height: 32px;
}

.price {
  font: 700 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--danger);
}

.old {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
  text-decoration: line-through;
}

.promo {
  padding: 4px 8px;
  border-radius: 4px;
  background: var(--danger-bg);
  color: var(--danger);
  font: 400 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  width: fit-content;
}

.actions {
  display: flex;
  gap: 8px;
  height: 36px;
}

.addBtn {
  flex: 1;
  border: 0;
  border-radius: 10px;
  cursor: pointer;
  background: var(--accent);
  color: #ffffff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.cartIcon {
  width: 16px;
  height: 16px;
}

.removeBtn {
  width: 42px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--bg);
  cursor: pointer;
  padding: 10px 13px;
}

.removeIcon {
  width: 16px;
  height: 16px;
  display: block;
}

.tips {
  border-radius: 16px;
  background: var(--accent-bg);
  padding: 24px 24px 0;
  display: grid;
  gap: 8px;
}

.tipsTitle {
  height: 27px;
  font: 500 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--accent);
}

.tipsList {
  margin: 0;
  padding: 0 0 24px 0;
  list-style: none;
  display: grid;
  gap: 4px;
}

.tip {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}
</style>

