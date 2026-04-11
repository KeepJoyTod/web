<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useAftersalesStore } from '../stores/aftersales'
import { useNotificationsStore } from '../stores/notifications'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useOrdersStore } from '../stores/orders'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'
import { api } from '../lib/api'

const router = useRouter()
const route = useRoute()
const orders = useOrdersStore()
const aftersales = useAftersalesStore()
const orderDraft = useOrderDraftStore()
const notifications = useNotificationsStore()
const tracker = useTrackerStore()
const toast = useToastStore()

const id = computed(() => String(route.params.id ?? ''))
const order = computed(() => (id.value ? orders.getById(id.value) : null))
const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const cancel = () => {
  if (!order.value) return
  const ok = window.confirm('确认取消订单？')
  if (!ok) return
  orders.cancelFromBackend(order.value.id).catch(() => orders.cancel(order.value!.id))
  notifications.push({
    type: 'system',
    title: '订单已取消',
    content: `订单号 ${order.value.id} 已取消`,
    relatedId: order.value.id,
  })
  tracker.track('order_cancel', { orderId: order.value.id })
  toast.push({ type: 'info', message: '已取消订单' })
}

const goAftersale = (orderItemId: string) => {
  if (!order.value) return
  router.push({ name: 'aftersaleApply', query: { orderId: order.value.id, orderItemId } })
}

const goReview = (productId: string) => {
  if (!order.value) return
  router.push({ name: 'reviewCreate', query: { orderId: order.value.id, productId } })
}

const hasAftersale = (orderItemId: string) => {
  if (!order.value) return false
  return aftersales.items.some((x) => x.orderId === order.value!.id && x.orderItemId === orderItemId)
}

const goPay = () => {
  if (!order.value) return
  orderDraft.createOrder({
    orderId: order.value.id,
    itemsAmount: order.value.amounts.items,
    discount: order.value.amounts.discount,
    shipping: order.value.amounts.shipping,
  })
  router.push({ name: 'payResult', query: { orderId: order.value.id } })
}

onMounted(async () => {
  if (!id.value || order.value) return
  try {
    const res = await api.get(`/v1/orders/${encodeURIComponent(id.value)}`)
    orders.upsertFromBackend(res.data?.data)
  } catch {}
})
</script>

<template>
  <div class="page">
    <UiPageHeader title="订单详情" />

    <main class="main" aria-live="polite">
      <UiEmptyState v-if="!order" title="订单不存在" desc="请返回订单列表" action-text="返回" @action="router.back()" />

      <div v-else class="grid">
        <section class="card" aria-label="订单信息">
          <div class="row">
            <div class="k">订单号</div>
            <div class="v">{{ order.id }}</div>
          </div>
          <div class="row">
            <div class="k">状态</div>
            <div class="v strong">
              {{ order.status === 'Created' ? '待支付' : order.status === 'Paid' ? '已支付' : '已取消' }}
            </div>
          </div>
          <div class="row">
            <div class="k">创建时间</div>
            <div class="v">{{ new Date(order.createdAt).toLocaleString() }}</div>
          </div>
          <div class="row" v-if="order.paidAt">
            <div class="k">支付时间</div>
            <div class="v">{{ new Date(order.paidAt).toLocaleString() }}</div>
          </div>
        </section>

        <section class="card" aria-label="收货信息">
          <div class="cardTitle">收货信息</div>
          <div class="addr">
            <div class="line">
              <span class="name">{{ order.address.receiver }}</span>
              <span class="phone">{{ order.address.phone }}</span>
            </div>
            <div class="line2">{{ order.address.region }} {{ order.address.detail }}</div>
          </div>
        </section>

        <section class="card" aria-label="商品列表">
          <div class="cardTitle">商品</div>
          <div class="items">
            <article v-for="it in order.items" :key="it.orderItemId" class="item">
              <img class="cover" :src="it.cover" :alt="it.title" loading="lazy" decoding="async" />
              <div class="meta">
                <div class="titleText">{{ it.title }}</div>
                <div class="sub">SKU：{{ it.skuId }} · x{{ it.qty }}</div>
                <div class="price">{{ priceFmt.format(it.price * it.qty) }}</div>
              </div>
              <div class="ops">
                <UiButton size="sm" type="button" @click="goReview(it.productId)">评价</UiButton>
                <UiButton size="sm" type="button" :disabled="hasAftersale(it.orderItemId)" @click="goAftersale(it.orderItemId)">
                  {{ hasAftersale(it.orderItemId) ? '已申请' : '售后' }}
                </UiButton>
              </div>
            </article>
          </div>
        </section>

        <section class="card" aria-label="金额明细">
          <div class="cardTitle">金额</div>
          <div class="row">
            <div class="k">商品金额</div>
            <div class="v">{{ priceFmt.format(order.amounts.items) }}</div>
          </div>
          <div class="row">
            <div class="k">优惠</div>
            <div class="v">-{{ priceFmt.format(order.amounts.discount) }}</div>
          </div>
          <div class="row">
            <div class="k">运费</div>
            <div class="v">{{ priceFmt.format(order.amounts.shipping) }}</div>
          </div>
          <div class="row">
            <div class="k strong">应付</div>
            <div class="v strong">{{ priceFmt.format(order.amounts.payable) }}</div>
          </div>
        </section>

        <section v-if="order.status === 'Created'" class="actions" aria-label="订单操作">
          <UiButton variant="primary" type="button" @click="goPay">
            去支付
          </UiButton>
          <UiButton variant="danger" type="button" @click="cancel">取消订单</UiButton>
        </section>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100%;
  display: flex;
  flex-direction: column;
}

.main {
  padding: 14px 16px 28px;
}

.grid {
  display: grid;
  gap: 12px;
}

.card {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  background: var(--bg);
  padding: 14px;
  display: grid;
  gap: 10px;
}

.cardTitle {
  color: var(--text-h);
  font-weight: 900;
}

.row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: baseline;
}

.k {
  color: var(--text);
  font-size: var(--font-sm);
}

.v {
  color: var(--text-h);
  font-size: var(--font-sm);
  text-align: right;
}

.strong {
  font-weight: 900;
  color: var(--text-h);
}

.addr {
  display: grid;
  gap: 6px;
}

.line {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.name {
  font-weight: 900;
  color: var(--text-h);
}

.phone {
  color: var(--text);
  font-size: var(--font-sm);
}

.line2 {
  color: var(--text);
  font-size: var(--font-sm);
}

.items {
  display: grid;
  gap: 10px;
}

.item {
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: color-mix(in srgb, var(--code-bg) 55%, transparent);
  padding: 10px;
  display: grid;
  grid-template-columns: 58px minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
}

.cover {
  width: 58px;
  height: 58px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  object-fit: cover;
  background: var(--code-bg);
}

.meta {
  display: grid;
  gap: 4px;
}

.titleText {
  color: var(--text-h);
  font-weight: 900;
  font-size: var(--font-sm);
  line-height: 1.2;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.sub {
  color: var(--text);
  font-size: var(--font-xs);
}

.price {
  color: var(--text-h);
  font-weight: 900;
}

.ops {
  display: grid;
  gap: 8px;
}

.actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

@media (min-width: 920px) {
  .main {
    max-width: 1120px;
    margin: 0 auto;
    width: 100%;
  }

  .ops {
    display: flex;
    gap: 10px;
  }
}
</style>
