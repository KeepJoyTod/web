<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useCartStore } from '../stores/cart'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useOrdersStore } from '../stores/orders'
import { useNotificationsStore } from '../stores/notifications'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'

const router = useRouter()
const route = useRoute()
const cart = useCartStore()
const orderDraft = useOrderDraftStore()
const orders = useOrdersStore()
const notifications = useNotificationsStore()
const tracker = useTrackerStore()
const toast = useToastStore()

const orderId = computed(() => {
  const raw = route.query.orderId
  return typeof raw === 'string' ? raw : ''
})

const status = computed(() => orderDraft.paymentStatus)
const payable = computed(() => orderDraft.draft.amounts?.payable ?? 0)
const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const polling = ref(false)
const ticks = ref(0)
let timer: number | null = null

const canShow = computed(() => Boolean(orderId.value) && orderDraft.orderId === orderId.value)

const stop = () => {
  polling.value = false
  ticks.value = 0
  if (timer != null) {
    window.clearInterval(timer)
    timer = null
  }
}

const start = () => {
  stop()
  polling.value = true
  ticks.value = 0
  timer = window.setInterval(() => {
    ticks.value += 1

    if (orderDraft.paymentStatus === 'SUCCESS' || orderDraft.paymentStatus === 'FAILED') {
      stop()
      return
    }

    if (ticks.value < 2) return

    const r = Math.random()
    if (r < 0.75) {
      const paidAt = new Date().toISOString()
      orderDraft.markPaid(paidAt)
      if (orderId.value) orders.markPaid(orderId.value, paidAt)
      cart.clear()
      toast.push({ type: 'success', message: '支付成功' })
      if (orderId.value) {
        notifications.push({
          type: 'order_paid',
          title: '订单已支付',
          content: `订单号 ${orderId.value} 已支付成功`,
          relatedId: orderId.value,
        })
        tracker.track('payment_success', { orderId: orderId.value })
      }
      stop()
      return
    }
    if (ticks.value >= 5) {
      orderDraft.markFailed('支付处理中超时，请重试')
      toast.push({ type: 'error', message: '支付失败' })
      if (orderId.value) tracker.track('payment_failed', { orderId: orderId.value, reason: 'timeout' })
      stop()
    }
  }, 1000)
}

const retry = () => {
  orderDraft.setProcessing()
  if (orderId.value) tracker.track('payment_retry', { orderId: orderId.value })
  start()
}

onMounted(() => {
  if (orderDraft.paymentStatus === 'PROCESSING') start()
})

onBeforeUnmount(() => {
  stop()
})
</script>

<template>
  <div class="page">
    <UiPageHeader title="支付结果" :show-back="false">
      <template #right>
        <UiButton size="sm" type="button" @click="router.push({ name: 'home' })">回首页</UiButton>
      </template>
    </UiPageHeader>

    <main class="main" aria-live="polite">
      <UiEmptyState
        v-if="!canShow"
        title="订单信息缺失"
        desc="请从结算页发起支付"
        action-text="去结算"
        @action="router.push({ name: 'checkout' })"
      />

      <div v-else class="card">
        <div class="row">
          <div class="k">订单号</div>
          <div class="v">{{ orderId }}</div>
        </div>
        <div class="row">
          <div class="k">应付金额</div>
          <div class="v strong">{{ priceFmt.format(payable) }}</div>
        </div>

        <div v-if="status === 'PROCESSING'" class="status">
          <div class="badge info">处理中</div>
          <div class="desc">正在同步支付状态，请稍候</div>
          <div class="actions">
            <UiButton size="sm" type="button" :disabled="polling" @click="start">刷新状态</UiButton>
            <UiButton size="sm" type="button" @click="router.push({ name: 'cart' })">返回购物车</UiButton>
          </div>
        </div>

        <div v-else-if="status === 'SUCCESS'" class="status">
          <div class="badge success">支付成功</div>
          <div class="desc">订单状态已同步</div>
          <div class="actions">
            <UiButton variant="primary" type="button" @click="router.push({ name: 'home' })">继续逛逛</UiButton>
            <UiButton type="button" @click="router.push({ name: 'me' })">去我的</UiButton>
          </div>
        </div>

        <div v-else-if="status === 'FAILED'" class="status">
          <div class="badge danger">支付失败</div>
          <div class="desc">{{ orderDraft.draft.payment.failureReason || '请重试或更换支付方式' }}</div>
          <div class="actions">
            <UiButton variant="primary" type="button" @click="retry">重试支付</UiButton>
            <UiButton type="button" @click="router.push({ name: 'cart' })">返回购物车</UiButton>
          </div>
        </div>

        <div v-else class="status">
          <div class="badge info">待支付</div>
          <div class="actions">
            <UiButton variant="primary" type="button" @click="retry">发起支付</UiButton>
          </div>
        </div>
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
  display: grid;
  place-items: start center;
}

.card {
  width: min(560px, 100%);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--bg);
  box-shadow: var(--shadow);
  padding: 14px;
  display: grid;
  gap: 12px;
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
  font-size: var(--font-lg);
}

.status {
  margin-top: 4px;
  border-top: 1px solid var(--border);
  padding-top: 12px;
  display: grid;
  gap: 10px;
}

.badge {
  justify-self: start;
  border-radius: var(--radius-pill);
  padding: 6px 10px;
  font-size: var(--font-sm);
  font-weight: 900;
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text-h);
}

.badge.info {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.badge.success {
  border-color: color-mix(in srgb, var(--success) 55%, var(--border));
  background: var(--success-bg);
}

.badge.danger {
  border-color: color-mix(in srgb, var(--danger) 55%, var(--border));
  background: var(--danger-bg);
}

.desc {
  color: var(--text);
  font-size: var(--font-sm);
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}
</style>
