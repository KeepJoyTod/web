<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { api } from '../lib/api'
import { useOrdersStore } from '../stores/orders'
import { useToastStore } from '../stores/toast'
import { useTrackerStore } from '../stores/tracker'

import backIconUrl from '../assets/figma/logistics/back.svg'
import clockIconUrl from '../assets/figma/logistics/clock.svg'
import copyIconUrl from '../assets/figma/logistics/copy.svg'
import phoneIconUrl from '../assets/figma/logistics/phone.svg'
import truckIconUrl from '../assets/figma/logistics/truck.svg'

type TrackEvent = {
  title: string
  desc: string
  time: string
}

const router = useRouter()
const route = useRoute()
const orders = useOrdersStore()
const toast = useToastStore()
const tracker = useTrackerStore()

const id = computed(() => String(route.params.id ?? ''))
const order = computed(() => (id.value ? orders.getById(id.value) : null))

const company = ref('顺丰速运')
const trackingNo = ref('SF1234567890123')
const courierName = ref('张师傅')
const courierPhone = ref('13800008888')

const statusTitle = computed(() => {
  const s = order.value?.status
  if (s === 'Completed') return '已送达'
  if (s === 'Cancelled') return '已取消'
  if (s === 'Created') return '待揽收'
  if (s === 'Paid') return '待发货'
  return '运输中'
})

const statusDesc = computed(() => {
  const s = order.value?.status
  if (s === 'Created') return '订单已创建，等待支付后开始发货'
  if (s === 'Paid') return '商家正在备货，预计24小时内发货'
  if (s === 'Cancelled') return '订单已取消，如有疑问请联系平台客服'
  if (s === 'Completed') return '包裹已签收，感谢您的购买'
  return `快件已到达【北京朝阳区分拨中心】，正在派送中，快递员：${courierName.value}，电话：138****8888`
})

const etaText = computed(() => {
  const s = order.value?.status
  if (s === 'Completed') return '已送达'
  if (s === 'Cancelled') return '已取消'
  if (s === 'Created') return '待支付后可见'
  if (s === 'Paid') return '预计送达：待发货'
  return '预计送达：2026-04-15 18:00'
})

const events = computed<TrackEvent[]>(() => {
  const s = order.value?.status
  if (s === 'Created') {
    return [{ title: '待支付', desc: '订单已创建，请尽快完成支付', time: '2026-04-12 16:00' }]
  }
  if (s === 'Paid') {
    return [{ title: '待发货', desc: '支付成功，商家正在备货', time: '2026-04-12 16:05' }]
  }
  if (s === 'Cancelled') {
    return [{ title: '已取消', desc: '订单已取消', time: '2026-04-12 16:10' }]
  }
  return [
    {
      title: '派送中',
      desc: `快件已到达【北京朝阳区分拨中心】，正在派送中，快递员：${courierName.value}，电话：138****8888`,
      time: '2026-04-13 14:30',
    },
    { title: '运输中', desc: '快件已到达【北京分拨中心】', time: '2026-04-13 10:15' },
    { title: '运输中', desc: '快件已从【天津转运中心】发出，下一站【北京分拨中心】', time: '2026-04-13 06:20' },
    { title: '运输中', desc: '快件已到达【天津转运中心】', time: '2026-04-12 22:40' },
    { title: '揽收', desc: '快件已从【上海浦东区】揽收', time: '2026-04-12 18:15' },
    { title: '已下单', desc: '商家已通知快递公司揽件', time: '2026-04-12 16:00' },
  ]
})

const copyNo = async () => {
  try {
    await navigator.clipboard.writeText(trackingNo.value)
    toast.push({ type: 'success', message: '已复制运单号' })
    tracker.track('logistics_copy_tracking', { orderId: id.value })
  } catch {
    toast.push({ type: 'info', message: '复制失败，请手动复制' })
  }
}

const callCourier = () => {
  tracker.track('logistics_call_courier', { orderId: id.value })
  window.location.href = `tel:${courierPhone.value}`
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
    <main class="main" aria-live="polite">
      <UiEmptyState v-if="!order" title="订单不存在" desc="请返回订单列表" action-text="返回" @action="router.back()" />

      <div v-else class="wrap">
        <div class="top">
          <button class="back" type="button" @click="router.push({ name: 'orderDetail', params: { id } })">
            <img class="backIcon" :src="backIconUrl" alt="" aria-hidden="true" />
            <span>返回订单详情</span>
          </button>
          <h1 class="h1">物流跟踪</h1>
        </div>

        <section class="statusCard" aria-label="物流状态">
          <div class="statusBody">
            <div class="statusIconWrap">
              <img class="statusIcon" :src="truckIconUrl" alt="" aria-hidden="true" />
            </div>
            <div class="statusText">
              <div class="statusH2">{{ statusTitle }}</div>
              <div class="statusLabel">当前状态</div>
              <div class="statusDesc">{{ statusDesc }}</div>
            </div>
          </div>
          <div class="etaRow">
            <img class="etaIcon" :src="clockIconUrl" alt="" aria-hidden="true" />
            <div class="etaText">{{ etaText }}</div>
          </div>
        </section>

        <section class="panel" aria-label="物流信息">
          <div class="panelTitle">物流信息</div>
          <div class="infoRows">
            <div class="infoRow">
              <div class="k">快递公司</div>
              <div class="v">{{ company }}</div>
            </div>
            <div class="infoRow">
              <div class="k">运单号</div>
              <div class="v mono">
                <span class="monoText">{{ trackingNo }}</span>
                <button class="iconBtn" type="button" @click="copyNo">
                  <img class="icon" :src="copyIconUrl" alt="" aria-hidden="true" />
                </button>
              </div>
            </div>
            <div class="infoRow last">
              <div class="k">快递员</div>
              <div class="v">
                <span class="courier">{{ courierName }}</span>
                <button class="phoneLink" type="button" @click="callCourier">
                  <img class="phoneIcon" :src="phoneIconUrl" alt="" aria-hidden="true" />
                  <span>138****8888</span>
                </button>
              </div>
            </div>
          </div>
        </section>

        <section class="panel" aria-label="物流详情">
          <div class="panelTitle">物流详情</div>
          <div class="timeline">
            <div v-for="(e, idx) in events" :key="`${e.time}_${idx}`" class="tlRow">
              <div class="tlLeft">
                <div class="dot" :class="{ on: idx === 0 }"></div>
                <div v-if="idx !== events.length - 1" class="stem"></div>
              </div>
              <div class="tlMain">
                <div class="tlTitle" :class="{ on: idx === 0 }">{{ e.title }}</div>
                <div class="tlDesc">{{ e.desc }}</div>
              </div>
              <div class="tlTime">{{ e.time }}</div>
            </div>
          </div>
        </section>
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
  width: min(992px, 100%);
  margin: 0 auto;
  display: grid;
  gap: 16px;
}

.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.back {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.backIcon {
  width: 20px;
  height: 20px;
}

.h1 {
  margin: 0;
  font: 600 30px/36px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.statusCard {
  border-radius: 16px;
  padding: 24px 24px 0;
  background: var(--accent);
  color: #ffffff;
  display: grid;
  gap: 16px;
}

.statusBody {
  display: flex;
  gap: 16px;
}

.statusIconWrap {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.2);
  display: grid;
  place-items: center;
  flex: 0 0 auto;
}

.statusIcon {
  width: 32px;
  height: 32px;
}

.statusText {
  flex: 1;
  display: grid;
  gap: 8px;
  padding-top: 24px;
}

.statusH2 {
  font: 600 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.statusLabel {
  opacity: 0.9;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.statusDesc {
  opacity: 0.9;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.etaRow {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 16px 0 0;
  border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.etaIcon {
  width: 16px;
  height: 16px;
}

.etaText {
  opacity: 0.9;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.panel {
  border-radius: 16px;
  background: var(--bg);
  border: 1px solid var(--border);
  padding: 24px 24px 0;
  display: grid;
  gap: 16px;
}

.panelTitle {
  font: 600 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.infoRows {
  display: grid;
  gap: 0;
  padding-bottom: 24px;
}

.infoRow {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid var(--border);
}

.infoRow.last {
  border-bottom: 0;
}

.k {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.v {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.mono {
  font: 400 16px/24px Consolas, ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
}

.monoText {
  font: inherit;
}

.iconBtn {
  width: 24px;
  height: 24px;
  border-radius: 4px;
  border: 0;
  background: transparent;
  cursor: pointer;
  padding: 4px;
}

.icon {
  width: 16px;
  height: 16px;
}

.phoneLink {
  border: 0;
  background: transparent;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 0;
  color: var(--accent);
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.phoneIcon {
  width: 16px;
  height: 16px;
}

.timeline {
  padding-bottom: 24px;
  display: grid;
  gap: 24px;
}

.tlRow {
  display: grid;
  grid-template-columns: 48px minmax(0, 1fr) auto;
  gap: 16px;
  align-items: start;
}

.tlLeft {
  display: grid;
  place-items: center;
}

.dot {
  width: 24px;
  height: 24px;
  border-radius: 9999px;
  background: var(--border);
  border: 8px solid var(--bg);
  box-shadow: 0 0 0 2px var(--border);
}

.dot.on {
  background: var(--accent);
  box-shadow: 0 0 0 2px var(--accent);
}

.stem {
  width: 2px;
  height: 40px;
  background: var(--border);
  margin-top: 8px;
}

.tlMain {
  display: grid;
  gap: 4px;
}

.tlTitle {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.tlTitle.on {
  color: var(--accent);
}

.tlDesc {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.tlTime {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
  white-space: nowrap;
}
</style>

