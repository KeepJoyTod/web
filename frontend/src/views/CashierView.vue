<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { api } from '../lib/api'

import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useOrdersStore } from '../stores/orders'
import { useTrackerStore } from '../stores/tracker'

import shieldIconUrl from '../assets/figma/cashier/icon-shield.svg'
import payAlipayIconUrl from '../assets/figma/cashier/pay-alipay.svg'
import payBalanceIconUrl from '../assets/figma/cashier/pay-balance.svg'
import payUnionpayIconUrl from '../assets/figma/cashier/pay-unionpay.svg'
import payWechatIconUrl from '../assets/figma/cashier/pay-wechat.svg'
import radioCheckedUrl from '../assets/figma/cashier/radio-checked.svg'

type PayChannel = 'wechat' | 'alipay' | 'unionpay' | 'balance'

const router = useRouter()
const route = useRoute()
const orderDraft = useOrderDraftStore()
const orders = useOrdersStore()
const tracker = useTrackerStore()

const loading = ref(false)

const orderId = computed(() => {
  const raw = route.query.orderId
  return typeof raw === 'string' ? raw : ''
})

const canShow = computed(() => Boolean(orderId.value))

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })
const payable = computed(() => {
  if (orderDraft.orderId !== orderId.value) return 0
  return orderDraft.draft.amounts?.payable ?? 0
})

const selectedChannel = ref<PayChannel>('wechat')

const secondsLeft = ref(293)
let timer: number | null = null

const timeText = computed(() => {
  const s = Math.max(0, secondsLeft.value)
  const mm = String(Math.floor(s / 60)).padStart(2, '0')
  const ss = String(s % 60).padStart(2, '0')
  return `${mm}:${ss}`
})

const stopTimer = () => {
  if (timer != null) {
    window.clearInterval(timer)
    timer = null
  }
}

const startTimer = () => {
  stopTimer()
  timer = window.setInterval(() => {
    secondsLeft.value = Math.max(0, secondsLeft.value - 1)
  }, 1000)
}

const setChannel = (c: PayChannel) => {
  selectedChannel.value = c
  tracker.track('cashier_channel_select', { orderId: orderId.value, channel: c })
}

const confirmPay = async () => {
  if (!canShow.value) return
  tracker.track('cashier_confirm', { orderId: orderId.value, channel: selectedChannel.value, payable: payable.value })
  await router.push({ name: 'payResult', query: { orderId: orderId.value, channel: selectedChannel.value, autoPay: '1' } })
}

const cancelPay = async () => {
  tracker.track('cashier_cancel', { orderId: orderId.value })
  await router.push({ name: 'orders' })
}

const fetchOrder = async () => {
  if (!orderId.value) return
  loading.value = true
  try {
    const res = await api.get(`/v1/orders/${encodeURIComponent(orderId.value)}`)
    const data = res.data?.data
    if (data) {
      orderDraft.loadFromBackend(data)
      orders.upsertFromBackend(data)
    }
  } catch (e) {
    console.error('Failed to fetch order:', e)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  if (!canShow.value) return
  if (orderDraft.orderId !== orderId.value) {
    await fetchOrder()
  }
  startTimer()
})

onBeforeUnmount(() => {
  stopTimer()
})
</script>

<template>
  <div class="page">
    <main class="main" aria-live="polite">
      <UiEmptyState
        v-if="!canShow || (!loading && orderDraft.orderId !== orderId)"
        title="订单信息缺失"
        desc="请从结算页提交订单后再支付"
        action-text="去结算"
        @action="router.push({ name: 'checkout' })"
      />

      <div v-else-if="loading" class="loading">
        正在获取订单信息...
      </div>

      <div v-else class="wrap">
        <div class="top">
          <div class="h1">收银台</div>
          <div class="orderNo">订单号：{{ orderId }}</div>
        </div>

        <section class="amountCard" aria-label="应付金额">
          <div class="amountLabel">应付金额</div>
          <div class="amountVal">{{ priceFmt.format(payable) }}</div>
          <div class="countdown">
            <span>剩余支付时间：</span>
            <span class="time">{{ timeText }}</span>
          </div>
        </section>

        <section class="payPanel" aria-label="选择支付方式">
          <div class="panelTitle">选择支付方式</div>

          <div class="payList">
            <button class="payBtn" :class="{ on: selectedChannel === 'wechat' }" type="button" @click="setChannel('wechat')">
              <div class="payLeft">
                <img class="payIcon" :src="payWechatIconUrl" alt="" aria-hidden="true" />
                <div class="payText">
                  <div class="payName">微信支付</div>
                  <div class="payDesc">推荐使用</div>
                </div>
              </div>
              <img v-if="selectedChannel === 'wechat'" class="radioOn" :src="radioCheckedUrl" alt="" aria-hidden="true" />
              <div v-else class="radioOff" aria-hidden="true"></div>
            </button>

            <button class="payBtn" :class="{ on: selectedChannel === 'alipay' }" type="button" @click="setChannel('alipay')">
              <div class="payLeft">
                <img class="payIcon" :src="payAlipayIconUrl" alt="" aria-hidden="true" />
                <div class="payText">
                  <div class="payName">支付宝</div>
                  <div class="payDesc">安全快捷</div>
                </div>
              </div>
              <img v-if="selectedChannel === 'alipay'" class="radioOn" :src="radioCheckedUrl" alt="" aria-hidden="true" />
              <div v-else class="radioOff" aria-hidden="true"></div>
            </button>

            <button class="payBtn" :class="{ on: selectedChannel === 'unionpay' }" type="button" @click="setChannel('unionpay')">
              <div class="payLeft">
                <img class="payIcon" :src="payUnionpayIconUrl" alt="" aria-hidden="true" />
                <div class="payText">
                  <div class="payName">银联支付</div>
                  <div class="payDesc">银行卡支付</div>
                </div>
              </div>
              <img v-if="selectedChannel === 'unionpay'" class="radioOn" :src="radioCheckedUrl" alt="" aria-hidden="true" />
              <div v-else class="radioOff" aria-hidden="true"></div>
            </button>

            <button class="payBtn" :class="{ on: selectedChannel === 'balance' }" type="button" @click="setChannel('balance')">
              <div class="payLeft">
                <img class="payIcon" :src="payBalanceIconUrl" alt="" aria-hidden="true" />
                <div class="payText">
                  <div class="payName">余额支付</div>
                  <div class="payDesc">账户余额</div>
                </div>
              </div>
              <img v-if="selectedChannel === 'balance'" class="radioOn" :src="radioCheckedUrl" alt="" aria-hidden="true" />
              <div v-else class="radioOff" aria-hidden="true"></div>
            </button>
          </div>
        </section>

        <section class="safePanel" aria-label="安全保障">
          <div class="safeTitleRow">
            <img class="safeIcon" :src="shieldIconUrl" alt="" aria-hidden="true" />
            <div class="safeTitle">安全保障</div>
          </div>
          <div class="safeList">
            <div class="safeItem">
              <div class="dot">•</div>
              <div class="safeText">256位SSL加密传输，保护您的支付信息安全</div>
            </div>
            <div class="safeItem">
              <div class="dot">•</div>
              <div class="safeText">支持各大银行和第三方支付平台</div>
            </div>
            <div class="safeItem">
              <div class="dot">•</div>
              <div class="safeText">未收到货可申请退款，7天无理由退货</div>
            </div>
          </div>
        </section>

        <div class="actions" aria-label="支付操作">
          <button class="primary" type="button" @click="confirmPay">确认支付 {{ priceFmt.format(payable) }}</button>
          <button class="ghost" type="button" @click="cancelPay">取消支付</button>
        </div>
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
  padding: 24px 16px 64px;
}

.wrap {
  width: min(640px, 100%);
  margin: 0 auto;
  display: grid;
  gap: 16px;
}

.top {
  display: grid;
  gap: 8px;
  text-align: center;
}

.h1 {
  font: 600 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.orderNo {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.amountCard {
  border-radius: 16px;
  padding: 32px;
  background: var(--accent);
  color: #ffffff;
  display: grid;
  place-items: center;
  gap: 8px;
}

.amountLabel {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  opacity: 0.9;
}

.amountVal {
  font: 700 48px/48px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.countdown {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  opacity: 0.9;
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.time {
  font: 700 14px/20px Consolas, ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
}

.payPanel {
  border-radius: 16px;
  background: var(--bg);
  border: 1px solid var(--border);
  padding: 24px 24px 24px;
  display: grid;
  gap: 16px;
}

.panelTitle {
  font: 600 20px/30px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.payList {
  display: grid;
  gap: 12px;
}

.payBtn {
  width: 100%;
  height: 84px;
  border-radius: 14px;
  border: 2px solid var(--border);
  background: var(--bg);
  padding: 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  cursor: pointer;
}

.payBtn.on {
  border-color: var(--accent);
  background: var(--accent-bg);
}

.payLeft {
  display: flex;
  align-items: center;
  gap: 16px;
  min-width: 0;
}

.payIcon {
  width: 48px;
  height: 48px;
}

.payText {
  display: grid;
  gap: 4px;
  text-align: left;
  min-width: 0;
}

.payName {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.payDesc {
  font: 500 12px/16px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.radioOff {
  width: 20px;
  height: 20px;
  border-radius: 9999px;
  border: 2px solid var(--border);
  flex: 0 0 auto;
}

.radioOn {
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
}

.safePanel {
  border-radius: 16px;
  background: var(--accent-bg);
  padding: 24px 24px 24px;
  display: grid;
  gap: 12px;
}

.safeTitleRow {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.safeIcon {
  width: 20px;
  height: 20px;
}

.safeTitle {
  font: 500 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--accent);
}

.safeList {
  display: grid;
  gap: 8px;
}

.safeItem {
  display: grid;
  grid-template-columns: 8px minmax(0, 1fr);
  gap: 8px;
  align-items: start;
}

.dot {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--accent);
}

.safeText {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.actions {
  display: grid;
  gap: 12px;
}

.primary,
.ghost {
  width: 100%;
  height: 58px;
  border-radius: 14px;
  cursor: pointer;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.primary {
  border: 0;
  background: var(--accent);
  color: #ffffff;
}

.ghost {
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text);
}
</style>

