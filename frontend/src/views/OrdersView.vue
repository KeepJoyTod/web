<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useOrdersStore } from '../stores/orders'
import { useToastStore } from '../stores/toast'

import backIconUrl from '../assets/figma/product-detail/back.svg'
import macbookImgUrl from '../assets/figma/orders/product-macbook.png'
import statusCancelIconUrl from '../assets/figma/orders/icon-status-cancel.svg'
import statusPayIconUrl from '../assets/figma/orders/icon-status-pay.svg'
import statusShipIconUrl from '../assets/figma/orders/icon-status-ship.svg'

const router = useRouter()
const ordersStore = useOrdersStore()
const orderDraft = useOrderDraftStore()
const toast = useToastStore()

const list = computed(() => {
  return ordersStore.orders
})

const fmtDate = (iso: string) => {
  const d = new Date(iso)
  const y = d.getFullYear()
  const m = d.getMonth() + 1
  const day = d.getDate()
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  const ss = String(d.getSeconds()).padStart(2, '0')
  return `${y}/${m}/${day} ${hh}:${mm}:${ss}`
}

const statusText = (s: string) => {
  if (s === 'Paid') return '待发货'
  if (s === 'Shipped') return '已发货'
  if (s === 'Completed') return '已完成'
  if (s === 'Cancelled') return '已取消'
  return '待支付'
}

const statusIcon = (s: string) => {
  if (s === 'Paid') return statusShipIconUrl
  if (s === 'Shipped') return statusShipIconUrl
  if (s === 'Completed') return statusShipIconUrl
  if (s === 'Cancelled') return statusCancelIconUrl
  return statusPayIconUrl
}

const goDetail = (id: string) => router.push({ name: 'orderDetail', params: { id } })

const goPay = (o: any) => {
  orderDraft.createOrder({
    orderId: o.id,
    itemsAmount: o.amounts.items,
    discount: o.amounts.discount,
    shipping: o.amounts.shipping,
  })
  router.push({ name: 'payResult', query: { orderId: o.id, autoPay: '1' } })
}

const cancel = async (o: any) => {
  if (o.status !== 'Created') {
    toast.push({ type: 'info', message: '当前订单暂不支持取消' })
    return
  }
  const ok = window.confirm('确认取消订单？')
  if (!ok) return
  try {
    await ordersStore.cancelFromBackend(o.id)
  } catch {
    ordersStore.cancel(o.id)
  }
  toast.push({ type: 'info', message: '已取消订单' })
}

onMounted(() => {
  ordersStore.refreshFromBackend().catch(() => {})
})
</script>

<template>
  <div class="page">
    <header class="headerSticky">
      <div class="headerContent">
        <button class="backBtn" type="button" aria-label="返回" @click="router.push({ name: 'me' })">
          <img class="backIcon" :src="backIconUrl" alt="" aria-hidden="true" />
          <span class="backText">返回</span>
        </button>
        <h1 class="h1">我的订单</h1>
      </div>
    </header>

    <main class="main" aria-live="polite">
      <UiEmptyState v-if="list.length === 0" title="暂无订单" desc="去首页看看有什么好物" action-text="去首页" @action="router.push({ name: 'home' })" />

      <div v-else class="list" aria-label="订单列表">
        <article v-for="o in list" :key="o.id" class="card">
          <div class="cardHead">
            <div class="headLeft">
              <div class="orderNo">订单号: {{ o.id }}</div>
              <div class="time">{{ fmtDate(o.createdAt) }}</div>
            </div>
            <div class="status">
              <img class="statusIcon" :src="statusIcon(o.status)" alt="" aria-hidden="true" />
              <div class="statusText">{{ statusText(o.status) }}</div>
            </div>
          </div>

          <div class="cardBody">
            <div v-for="it in o.items.slice(0, 1)" :key="it.orderItemId" class="prod">
              <img class="prodImg" :src="it.cover || macbookImgUrl" :alt="it.title" loading="lazy" decoding="async" />
              <div class="prodMid">
                <div class="prodTitle">{{ it.title }}</div>
                <div class="prodQty">x{{ it.qty }}</div>
              </div>
              <div class="prodRight">
                <div class="prodPrice">¥{{ Math.round(it.price) }}</div>
              </div>
            </div>

            <div class="cardFoot">
              <div class="actions">
                <button
                  class="link"
                  type="button"
                  @click="o.status === 'Created' ? goPay(o) : goDetail(o.id)"
                >
                  {{ o.status === 'Created' ? '查看详情立即支付' : '查看详情' }}
                </button>
                <button class="linkGray" type="button" @click="cancel(o)">取消订单</button>
              </div>

              <div class="amounts">
                <div class="amountLabel">实付款</div>
                <div class="amountVal">¥{{ Math.round(o.amounts.payable) }}</div>
              </div>
            </div>
          </div>
        </article>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  background: var(--bg);
}

.main {
  padding: 0 16px 64px; /* 移除顶部 padding */
  width: min(864px, 100%);
  margin: 0 auto;
  display: grid;
  gap: 16px;
}

.headerSticky {
  position: sticky;
  top: 0;
  background: var(--bg);
  z-index: 100;
  border-bottom: 1px solid var(--border);
  transition: border-color 0.2s;
}

/* 当页面滚动时，可以通过 JS 或简单 CSS 给它加阴影或边框，但这里先保持简洁 */

.headerContent {
  width: min(864px, 100%);
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

.h1 {
  margin: 0;
  font: 600 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.list {
  display: grid;
  gap: 16px;
}

.card {
  border-radius: 16px;
  background: var(--bg);
  border: 1px solid var(--border);
  box-shadow: var(--shadow);
  display: grid;
  overflow: hidden;
}

.cardHead {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 12px 24px;
  background: var(--accent-bg);
  border-bottom: 1px solid var(--accent-border);
}

.headLeft {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;
}

.orderNo,
.time {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.status {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.statusIcon {
  width: 20px;
  height: 20px;
}

.statusText {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.cardBody {
  padding: 24px 24px 0;
  display: grid;
  gap: 16px;
}

.prod {
  display: flex;
  align-items: center;
  gap: 16px;
}

.prodImg {
  width: 80px;
  height: 80px;
  border-radius: 10px;
  object-fit: cover;
  background: var(--code-bg);
}

.prodMid {
  flex: 1;
  min-width: 0;
  display: grid;
  gap: 4px;
}

.prodTitle {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.prodQty {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.prodRight {
  width: 56px;
  text-align: right;
}

.prodPrice {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.cardFoot {
  padding: 16px 0 0;
  border-top: 1px solid var(--border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.actions {
  display: inline-flex;
  align-items: center;
  gap: 24px;
}

.link,
.linkGray {
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.link {
  color: var(--accent);
}

.linkGray {
  font-weight: 500;
  color: var(--text);
}

.amounts {
  display: grid;
  gap: 4px;
  text-align: right;
}

.amountLabel {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.amountVal {
  font: 400 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--danger);
}
</style>
