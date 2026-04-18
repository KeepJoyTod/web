<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useAftersalesStore } from '../stores/aftersales'
import { useNotificationsStore } from '../stores/notifications'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useOrdersStore } from '../stores/orders'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'
import { api } from '../lib/api'

import backIconUrl from '../assets/figma/order-detail/back.svg'
import iconAddressUrl from '../assets/figma/order-detail/icon-address.svg'
import iconFeeUrl from '../assets/figma/order-detail/icon-fee.svg'
import iconProductUrl from '../assets/figma/order-detail/icon-product.svg'
import productAirpodsImgUrl from '../assets/figma/order-detail/product-airpods.png'

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

const statusTitle = computed(() => {
  const s = order.value?.status
  if (s === 'Paid') return '待发货'
  if (s === 'Shipped') return '已发货'
  if (s === 'Completed') return '已完成'
  if (s === 'Cancelled') return '已取消'
  return '待支付'
})

const stepIndex = computed(() => {
  const s = order.value?.status
  if (s === 'Paid') return 2
  if (s === 'Shipped') return 3
  if (s === 'Completed') return 4
  if (s === 'Cancelled') return 1
  return 1
})

const address = computed(() => {
  const a = order.value?.address
  if (a && a.receiver && a.phone && a.region && a.detail) return a
  const d = orderDraft.draft.address
  if (d && d.receiver && d.phone && d.region && d.detail) return d
  return { receiver: '张三', phone: '13800000000', region: '北京市朝阳区', detail: '朝阳区xx路xx号' }
})

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
  router.push({ name: 'payResult', query: { orderId: order.value.id, autoPay: '1' } })
}

const viewShipping = () => {
  if (!order.value) return
  tracker.track('order_shipping_view', { orderId: order.value.id })
  router.push({ name: 'orderLogistics', params: { id: order.value.id } })
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
        <button class="back" type="button" @click="router.push({ name: 'orders' })">
          <img class="backIcon" :src="backIconUrl" alt="" aria-hidden="true" />
          <span>返回订单列表</span>
        </button>

        <nav class="crumbs" aria-label="面包屑">
          <button class="crumbLink" type="button" @click="router.push({ name: 'home' })">首页</button>
          <span class="crumbSep" aria-hidden="true">/</span>
          <button class="crumbLink" type="button" @click="router.push({ name: 'orders' })">我的订单</button>
          <span class="crumbSep" aria-hidden="true">/</span>
          <span class="crumbCur">订单详情</span>
        </nav>

        <section class="panel statusPanel" aria-label="订单状态">
          <div class="statusLeft">
            <div class="statusH1">{{ statusTitle }}</div>
            <div class="statusNo">订单号: {{ order.id }}</div>
          </div>
          <button class="shipBtn" type="button" @click="viewShipping">查看物流</button>
        </section>

        <section class="panel stepPanel" aria-label="订单进度">
          <div class="stepWrap">
            <div class="stepLine" aria-hidden="true"></div>
            <div v-for="n in 4" :key="n" class="step">
              <div class="stepCircle" :class="{ on: n <= stepIndex }">
                <span class="stepNum" :class="{ on: n <= stepIndex }">{{ n }}</span>
              </div>
              <div class="stepText">
                {{ n === 1 ? '待支付' : n === 2 ? '待发货' : n === 3 ? '已发货' : '已完成' }}
              </div>
            </div>
          </div>
        </section>

        <section class="panel infoPanel" aria-label="收货信息">
          <div class="panelHead">
            <img class="panelIcon" :src="iconAddressUrl" alt="" aria-hidden="true" />
            <div class="panelTitle">收货信息</div>
          </div>
          <div class="kvList">
            <div class="kvRow">
              <div class="kvK">收货人:</div>
              <div class="kvV">{{ address.receiver }}</div>
            </div>
            <div class="kvRow">
              <div class="kvK">联系电话:</div>
              <div class="kvV">{{ address.phone }}</div>
            </div>
            <div class="kvRow">
              <div class="kvK">收货地址:</div>
              <div class="kvV">{{ address.region }} {{ address.detail }}</div>
            </div>
          </div>
        </section>

        <section class="panel prodPanel" aria-label="商品信息">
          <div class="panelHead">
            <img class="panelIcon" :src="iconProductUrl" alt="" aria-hidden="true" />
            <div class="panelTitle">商品信息</div>
          </div>
          <div class="prodList">
            <div v-for="it in order.items" :key="it.orderItemId" class="prodRow">
              <img class="prodImg" :src="it.cover || productAirpodsImgUrl" :alt="it.title" loading="lazy" decoding="async" />
              <div class="prodMid">
                <div class="prodTitle">{{ it.title }}</div>
                <div class="prodQty">数量: x{{ it.qty }}</div>
              </div>
              <div class="prodRight">
                <div class="prodPrice">¥{{ Math.round(it.price) }}</div>
              </div>
            </div>
          </div>
        </section>

        <section class="panel feePanel" aria-label="费用明细">
          <div class="panelHead">
            <img class="panelIcon" :src="iconFeeUrl" alt="" aria-hidden="true" />
            <div class="panelTitle">费用明细</div>
          </div>
          <div class="feeList">
            <div class="feeRow">
              <div class="feeK">商品金额</div>
              <div class="feeV">{{ priceFmt.format(order.amounts.items) }}</div>
            </div>
            <div class="feeRow">
              <div class="feeK">运费</div>
              <div class="feeV">{{ order.amounts.shipping > 0 ? priceFmt.format(order.amounts.shipping) : '免运费' }}</div>
            </div>
            <div class="feeTotal">
              <div class="feeTotalK">实付款</div>
              <div class="feeTotalV">{{ priceFmt.format(order.amounts.payable) }}</div>
            </div>
          </div>
        </section>

        <section v-if="order.status === 'Created'" class="bottomActions" aria-label="订单操作">
          <button class="primaryBtn" type="button" @click="goPay">去支付</button>
          <button class="ghostBtn" type="button" @click="cancel">取消订单</button>
        </section>

        <section v-if="order.status !== 'Created'" class="bottomActions" aria-label="售后与评价">
          <button v-if="order.items[0]" class="ghostBtn" type="button" @click="goReview(order.items[0].productId)">评价</button>
          <button
            v-if="order.items[0]"
            class="ghostBtn"
            type="button"
            :disabled="hasAftersale(order.items[0].orderItemId)"
            @click="goAftersale(order.items[0].orderItemId)"
          >
            {{ hasAftersale(order.items[0].orderItemId) ? '已申请售后' : '申请售后' }}
          </button>
        </section>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  background: #f9fafb;
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

.back {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.backIcon {
  width: 20px;
  height: 20px;
}

.crumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 20px;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.crumbLink {
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  color: #4a5565;
  font: inherit;
}

.crumbSep {
  color: #4a5565;
}

.crumbCur {
  color: #4a5565;
}

.panel {
  border-radius: 16px;
  background: #ffffff;
  padding: 24px 24px 0;
  display: grid;
  gap: 16px;
}

.panelHead {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.panelIcon {
  width: 20px;
  height: 20px;
}

.panelTitle {
  font: 500 20px/28px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.statusPanel {
  height: 112px;
}

.statusPanel {
  grid-template-columns: 1fr auto;
  align-items: center;
}

.statusLeft {
  display: grid;
  gap: 8px;
}

.statusH1 {
  font: 500 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.statusNo {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.shipBtn {
  width: 112px;
  height: 40px;
  border-radius: 10px;
  border: 0;
  cursor: pointer;
  background: #9810fa;
  color: #ffffff;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.stepPanel {
  height: 116px;
}

.stepWrap {
  position: relative;
  height: 68px;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  align-items: start;
}

.stepLine {
  position: absolute;
  left: 0;
  right: 0;
  top: 20px;
  height: 2px;
  background: #e5e7eb;
}

.step {
  display: grid;
  place-items: center;
  gap: 8px;
}

.stepCircle {
  width: 40px;
  height: 40px;
  border-radius: 9999px;
  background: #e5e7eb;
  display: grid;
  place-items: center;
  z-index: 1;
}

.stepCircle.on {
  background: #9810fa;
}

.stepNum {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #99a1af;
}

.stepNum.on {
  color: #ffffff;
}

.stepText {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
  text-align: center;
}

.kvList {
  display: grid;
  gap: 8px;
  padding-bottom: 24px;
}

.kvRow {
  display: flex;
  gap: 16px;
  align-items: center;
  flex-wrap: wrap;
}

.kvK {
  width: 80px;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.kvV {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.prodList {
  padding-bottom: 16px;
  display: grid;
  gap: 12px;
}

.prodRow {
  display: flex;
  align-items: center;
  gap: 16px;
}

.prodImg {
  width: 80px;
  height: 80px;
  border-radius: 10px;
  object-fit: cover;
  background: #f3f4f6;
}

.prodMid {
  flex: 1;
  min-width: 0;
  display: grid;
  gap: 4px;
}

.prodTitle {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.prodQty {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.prodRight {
  width: 56px;
  text-align: right;
}

.prodPrice {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.feeList {
  display: grid;
  gap: 12px;
  padding-bottom: 24px;
}

.feeRow {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.feeK {
  color: #4a5565;
}

.feeV {
  color: #0a0a0a;
}

.feeTotal {
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  padding-top: 12px;
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
}

.feeTotalK {
  font: 400 20px/28px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.feeTotalV {
  font: 400 30px/36px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #e7000b;
}

.bottomActions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}

.primaryBtn,
.ghostBtn {
  height: 56px;
  border-radius: 14px;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  cursor: pointer;
}

.primaryBtn {
  border: 0;
  background: #9810fa;
  color: #ffffff;
}

.ghostBtn {
  border: 1px solid #d1d5dc;
  background: #ffffff;
  color: #364153;
}

.ghostBtn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
