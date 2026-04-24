<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useCartStore } from '../stores/cart'

const router = useRouter()
const cart = useCartStore()
const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })
const isEmpty = computed(() => cart.items.length === 0)

const inc = (itemId: string, current: number) => {
  cart.updateQty(itemId, current + 1)
}

const dec = (itemId: string, current: number) => {
  cart.updateQty(itemId, Math.max(1, current - 1))
}
</script>

<template>
  <div class="page">
    <h1 class="title">购物车</h1>

    <UiEmptyState v-if="isEmpty" title="购物车空空如也" desc="去首页挑选心仪商品吧" />

    <div v-else class="list" aria-label="购物车商品">
      <article v-for="it in cart.items" :key="it.itemId" class="item">
        <img class="cover" :src="it.cover" :alt="it.title" loading="lazy" decoding="async" />
        <div class="meta">
          <div class="name">{{ it.title }}</div>
          <div class="sub">SKU：{{ it.skuId }}</div>
          <div class="row">
            <div class="price">{{ priceFmt.format(it.price) }}</div>
            <div class="qty">
              <button class="qtyBtn" type="button" aria-label="减少数量" @click="dec(it.itemId, it.qty)">-</button>
              <div class="qtyVal" aria-label="数量">{{ it.qty }}</div>
              <button class="qtyBtn" type="button" aria-label="增加数量" @click="inc(it.itemId, it.qty)">+</button>
            </div>
          </div>
          <div class="row">
            <UiButton size="sm" type="button" @click="cart.removeItem(it.itemId)">移除</UiButton>
            <div class="sum">{{ priceFmt.format(it.price * it.qty) }}</div>
          </div>
        </div>
      </article>

      <div class="footer" aria-label="结算栏">
        <div class="total">
          <div class="totalLabel">合计</div>
          <div class="totalVal">{{ priceFmt.format(cart.amount) }}</div>
        </div>
        <UiButton variant="primary" type="button" @click="router.push({ name: 'checkout' })">去结算</UiButton>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding: 18px 16px 28px;
}

.title {
  margin: 0 0 10px;
  font-size: 20px;
  color: var(--text-h);
}

.list {
  display: grid;
  gap: 12px;
}

.item {
  display: grid;
  grid-template-columns: 92px minmax(0, 1fr);
  gap: 12px;
  border: 1px solid var(--border);
  border-radius: 16px;
  background: var(--bg);
  overflow: hidden;
}

.cover {
  width: 92px;
  height: 92px;
  object-fit: cover;
  background: var(--code-bg);
}

.meta {
  padding: 12px 12px 12px 0;
  display: grid;
  gap: 8px;
}

.name {
  color: var(--text-h);
  font-weight: 800;
  font-size: 14px;
  line-height: 1.2;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.sub {
  color: var(--text);
  font-size: 12px;
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

.sum {
  color: var(--text-h);
  font-weight: 900;
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
  font-weight: 800;
}

.footer {
  position: sticky;
  bottom: 0;
  border-top: 1px solid var(--border);
  background: var(--bg);
  padding: 12px 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.total {
  display: grid;
  gap: 2px;
}

.totalLabel {
  font-size: 12px;
  color: var(--text);
}

.totalVal {
  color: var(--text-h);
  font-weight: 900;
}

</style>
