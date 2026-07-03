<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { api } from '../lib/api'
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
const payable = computed(() => {
  if (orderDraft.orderId !== orderId.value) return 0
  return orderDraft.draft.amounts?.payable ?? 0
})
const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const channel = computed(() => {
  const raw = route.query.channel
  const v = typeof raw === 'string' ? raw : ''
  if (v === 'wechat' || v === 'alipay' || v === 'unionpay' || v === 'balance') return v
  return 'alipay'
})

const autoPay = computed(() => {
  const raw = route.query.autoPay
  return raw === '1' || raw === 'true'
})

const polling = ref(false)
const loading = ref(false)
const lastTradeId = ref<string>('')
let timer: number | null = null

const canShow = computed(() => Boolean(orderId.value))

const stop = () => {
  polling.value = false
  if (timer != null) {
    window.clearInterval(timer)
    timer = null
  }
}

const syncOrder = async () => {
  if (!orderId.value) return
  loading.value = true
  try {
    const res = await api.get(`/v1/orders/${encodeURIComponent(orderId.value)}`)
    const data = res.data?.data
    if (data) {
      orders.upsertFromBackend(data)
      orderDraft.loadFromBackend(data)
    }
  } catch (e) {
    console.error('Failed to sync order:', e)
  } finally {
    loading.value = false
  }
}

const refreshPaymentStatus = async () => {
  if (!orderId.value) return
  try {
    const res = await api.get(`/v1/payments/${encodeURIComponent(orderId.value)}/status`)
    const p = res.data?.data || {}
    const st = String(p.status ?? '')
    if (st === 'SUCCESS') {
      const paidAt = p.paidAt ? new Date(p.paidAt).toISOString() : new Date().toISOString()
      orderDraft.markPaid(paidAt)
      orders.markPaid(orderId.value, paidAt)
      cart.clear()
      toast.push({ type: 'success', message: '支付成功' })
      notifications.push({
        type: 'order_paid',
        title: '订单已支付',
        content: `订单号 ${orderId.value} 已支付成功`,
        relatedId: orderId.value,
      })
      tracker.track('payment_success', { orderId: orderId.value })
      stop()
      await syncOrder()
      return
    }
    if (st === 'FAILED') {
      orderDraft.markFailed('支付失败')
      toast.push({ type: 'error', message: '支付失败' })
      tracker.track('payment_failed', { orderId: orderId.value, reason: 'failed' })
      stop()
      await syncOrder()
      return
    }
    orderDraft.setProcessing()
  } catch (e) {
    const code = (e as any)?.response?.data?.code
    if (code === 404) {
      orderDraft.setInit()
      stop()
      return
    }
  }
}

const startPolling = () => {
  stop()
  polling.value = true
  timer = window.setInterval(() => {
    refreshPaymentStatus().catch(() => {})
  }, 1200)
}

const startPayment = async () => {
  if (!orderId.value) return
  loading.value = true
  try {
    orderDraft.setProcessing()
    tracker.track('payment_start', { orderId: orderId.value, channel: channel.value })
    const res = await api.post(`/v1/payments/${encodeURIComponent(orderId.value)}/pay`, { channel: channel.value })
    const data = res.data?.data || {}
    const tradeId = String(data.tradeId ?? '')
    lastTradeId.value = tradeId
    startPolling()
    if (tradeId) {
      await new Promise((r) => window.setTimeout(r, 800))
      await api.post('/v1/payments/webhook', { tradeId, status: 'SUCCESS' })
    }
  } catch (e) {
    const msg = (e as any)?.response?.data?.message || (e as any)?.message || '发起支付失败'
    orderDraft.markFailed(msg)
    toast.push({ type: 'error', message: msg })
    tracker.track('payment_failed', { orderId: orderId.value, reason: 'initiate_failed' })
    stop()
  } finally {
    loading.value = false
  }
}

const retry = () => {
  if (!orderId.value) return
  tracker.track('payment_retry', { orderId: orderId.value })
  startPayment().catch(() => {})
}

onMounted(async () => {
  if (!canShow.value) return
  if (orderDraft.orderId !== orderId.value) {
    await syncOrder()
  } else {
    syncOrder().catch(() => {})
  }
  if (orderDraft.paymentStatus === 'PROCESSING') startPolling()
  refreshPaymentStatus().catch(() => {})
  if (autoPay.value && orderDraft.paymentStatus === 'INIT') {
    startPayment().catch(() => {})
  }
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
        v-if="!canShow || (!loading && orderDraft.orderId !== orderId)"
        title="订单信息缺失"
        desc="请从结算页发起支付"
        action-text="去结算"
        @action="router.push({ name: 'checkout' })"
      />

      <div v-else-if="loading" class="card">
        正在获取订单信息...
      </div>

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
            <UiButton size="sm" type="button" :disabled="polling" @click="startPolling">刷新状态</UiButton>
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
            <UiButton variant="primary" type="button" :loading="loading" @click="retry">发起支付</UiButton>
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
