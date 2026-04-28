<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import UiEmptyState from '../components/ui/UiEmptyState.vue'
import { useCartStore } from '../stores/cart'
import { useOrdersStore } from '../stores/orders'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useNotificationsStore } from '../stores/notifications'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'
import { api } from '../lib/api'

import backCartIconUrl from '../assets/figma/checkout/back-cart.svg'
import iconAddressUrl from '../assets/figma/checkout/icon-address.svg'
import iconCouponUrl from '../assets/figma/checkout/icon-coupon.svg'
import iconInvoiceUrl from '../assets/figma/checkout/icon-invoice.svg'

const router = useRouter()
const cart = useCartStore()
const orders = useOrdersStore()
const orderDraft = useOrderDraftStore()
const notifications = useNotificationsStore()
const tracker = useTrackerStore()
const toast = useToastStore()

type Address = {
  id: string
  receiver: string
  phone: string
  region: string
  detail: string
  isDefault?: boolean
}

type InvoiceType = 'none' | 'personal' | 'company'

type Coupon = {
  id: string
  title: string
  code: string
  minSpend: number
  discount: number
}

const addresses = ref<Address[]>([
  {
    id: 'addr_1',
    receiver: orderDraft.draft.address?.receiver || '张三',
    phone: orderDraft.draft.address?.phone || '13800000000',
    region: orderDraft.draft.address?.region || '北京市朝阳区',
    detail: orderDraft.draft.address?.detail || '朝阳区xx路xx号',
    isDefault: true,
  },
  {
    id: 'addr_2',
    receiver: '李四',
    phone: '13900000000',
    region: '上海市浦东新区',
    detail: '浦东新区yy路yy号',
  },
])

const selectedAddressId = ref(addresses.value[0]?.id ?? '')

const addOpen = ref(false)
const addReceiver = ref('')
const addPhone = ref('')
const addRegion = ref('')
const addDetail = ref('')

const invoiceType = ref<InvoiceType>('none')
const invoiceTitle = ref(orderDraft.draft.invoiceTitle ?? '')

const coupons: Coupon[] = [
  { id: 'c_new500', title: '新客专享满5000减500', code: 'NEW500', minSpend: 5000, discount: 500 },
  { id: 'c_save300', title: '全场满3000减300', code: 'SAVE300', minSpend: 3000, discount: 300 },
  { id: 'c_spring100', title: '春季特惠满1000减100', code: 'SPRING100', minSpend: 1000, discount: 100 },
]

const selectedCouponId = ref<string>(coupons[0]?.id ?? '')

const submitting = ref(false)

const isEmpty = computed(() => cart.items.length === 0)
const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const itemsAmount = computed(() => cart.amount)

const shipping = computed(() => 0)

const selectedAddress = computed(() => addresses.value.find((x) => x.id === selectedAddressId.value) ?? null)

const couponDiscount = computed(() => {
  const c = coupons.find((x) => x.id === selectedCouponId.value) ?? null
  if (!c) return 0
  if (itemsAmount.value < c.minSpend) return 0
  return Math.min(c.discount, Math.max(0, itemsAmount.value))
})

const discountAmount = computed(() => couponDiscount.value)

const payable = computed(() => {
  return Math.max(0, itemsAmount.value - discountAmount.value + shipping.value)
})

const canSubmit = computed(() => {
  if (submitting.value) return false
  if (isEmpty.value) return false
  if (!selectedAddress.value) return false
  if (invoiceType.value !== 'none' && !invoiceTitle.value.trim()) return false
  return true
})

const openAdd = () => {
  addReceiver.value = ''
  addPhone.value = ''
  addRegion.value = ''
  addDetail.value = ''
  addOpen.value = true
}

const saveAdd = () => {
  const receiver = addReceiver.value.trim()
  const phone = addPhone.value.trim()
  const region = addRegion.value.trim()
  const detail = addDetail.value.trim()
  if (!receiver || !/^1\d{10}$/.test(phone) || !region || !detail) {
    toast.push({ type: 'error', message: '请完整填写收货信息' })
    return
  }
  const id = `addr_${Date.now()}`
  addresses.value = [{ id, receiver, phone, region, detail }, ...addresses.value.map((x) => ({ ...x, isDefault: false }))]
  selectedAddressId.value = id
  addOpen.value = false
}

const submit = async () => {
  if (!canSubmit.value) return

  submitting.value = true
  try {
    if (selectedAddress.value) {
      orderDraft.setAddress({
        receiver: selectedAddress.value.receiver,
        phone: selectedAddress.value.phone,
        region: selectedAddress.value.region,
        detail: selectedAddress.value.detail,
      })
    }
    orderDraft.setInvoiceTitle(invoiceTitle.value.trim())
    orderDraft.setCouponCode(coupons.find((x) => x.id === selectedCouponId.value)?.code ?? '')

    const sync = (cart as any)?.syncToServer
    if (typeof sync === 'function') {
      await sync()
    } else {
      toast.push({ type: 'info', message: '页面已更新，请刷新后重试' })
      return
    }

    const res = await api.post('/v1/orders/checkout', {
      addressId: 0,
      couponCode: orderDraft.draft.couponCode,
    })
    const data = res.data?.data || {}
    const orderId: string = String(data.id ?? data.orderId ?? '')
    const mappedId = orders.upsertFromBackend(data)
    const backendTotal = Number(data.totalAmount ?? itemsAmount.value)
    const backendPayable = Number(data.payAmount ?? payable.value)
    const backendShipping = Number(data.shippingAmount ?? shipping.value)
    const backendDiscount = Math.max(0, (Number.isFinite(backendTotal) ? backendTotal : 0) + (Number.isFinite(backendShipping) ? backendShipping : 0) - (Number.isFinite(backendPayable) ? backendPayable : 0))

    notifications.push({
      type: 'order_created',
      title: '订单已创建',
      content: `订单号 ${orderId}，待支付金额 ${priceFmt.format(backendPayable)}`,
      relatedId: orderId,
    })

    tracker.track('checkout_submit', {
      orderId: mappedId,
      itemsCount: cart.count,
      itemsAmount: backendTotal,
      discount: backendDiscount,
      shipping: backendShipping,
      payable: backendPayable,
    })

    orderDraft.createOrder({
      orderId: mappedId,
      itemsAmount: backendTotal,
      discount: backendDiscount,
      shipping: backendShipping,
      payable: backendPayable,
    })
    cart.clear()
    await router.push({ name: 'cashier', query: { orderId: mappedId } })
  } catch (e) {
    const msg =
      (e as any)?.response?.data?.error?.message ||
      (e as any)?.message ||
      '提交订单失败，请稍后重试'
    toast.push({ type: 'error', message: msg })
    return
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <main class="main" aria-live="polite">
      <UiEmptyState
        v-if="isEmpty"
        title="购物车空空如也"
        desc="请先添加商品再结算"
        action-text="去首页"
        @action="router.push({ name: 'home' })"
      />

      <div v-else class="wrap">
        <div class="top">
          <button class="back" type="button" @click="router.push({ name: 'cart' })">
            <img class="backIcon" :src="backCartIconUrl" alt="" aria-hidden="true" />
            <span>返回购物车</span>
          </button>
          <h1 class="h1">确认订单</h1>
        </div>

        <section class="panel" aria-label="收货地址">
          <div class="panelHead">
            <img class="panelIcon" :src="iconAddressUrl" alt="" aria-hidden="true" />
            <div class="panelTitle">收货地址</div>
          </div>

          <div class="addrList">
            <label
              v-for="a in addresses"
              :key="a.id"
              class="addr"
              :class="{ on: selectedAddressId === a.id }"
            >
              <input v-model="selectedAddressId" class="radio" type="radio" name="addr" :value="a.id" />
              <div class="addrBody">
                <div class="addrTop">
                  <div class="addrName">{{ a.receiver }}</div>
                  <div class="addrPhone">{{ a.phone }}</div>
                  <div v-if="a.isDefault" class="badge">默认</div>
                </div>
                <div class="addrLine">{{ a.region }} {{ a.detail }}</div>
              </div>
            </label>

            <button class="addLink" type="button" @click="openAdd">+ 添加新地址</button>

            <div v-if="addOpen" class="addForm" aria-label="添加新地址">
              <div class="formGrid">
                <input v-model="addReceiver" class="input" type="text" placeholder="收货人" />
                <input v-model="addPhone" class="input" type="tel" placeholder="手机号" />
                <input v-model="addRegion" class="input" type="text" placeholder="所在地区" />
                <input v-model="addDetail" class="input" type="text" placeholder="详细地址" />
              </div>
              <div class="formBtns">
                <button class="btnGhost" type="button" @click="addOpen = false">取消</button>
                <button class="btnPrimary" type="button" @click="saveAdd">保存</button>
              </div>
            </div>
          </div>
        </section>

        <section class="panel" aria-label="配送方式">
          <div class="panelTitle">配送方式</div>
          <label class="shipRow">
            <input checked class="radio" type="radio" name="ship" />
            <div class="shipBody">
              <div class="shipName">快递配送</div>
              <div class="shipDesc">预计2-3天送达</div>
            </div>
            <div class="shipFee">免运费</div>
          </label>
        </section>

        <section class="panel" aria-label="发票信息">
          <div class="panelHead">
            <img class="panelIcon" :src="iconInvoiceUrl" alt="" aria-hidden="true" />
            <div class="panelTitle">发票信息</div>
          </div>
          <div class="invoiceRow">
            <label class="inlineOpt">
              <input v-model="invoiceType" class="radio" type="radio" name="inv" value="none" />
              <span>不需要发票</span>
            </label>
            <label class="inlineOpt">
              <input v-model="invoiceType" class="radio" type="radio" name="inv" value="personal" />
              <span>个人发票</span>
            </label>
            <label class="inlineOpt">
              <input v-model="invoiceType" class="radio" type="radio" name="inv" value="company" />
              <span>企业发票</span>
            </label>
          </div>
          <div v-if="invoiceType !== 'none'" class="invoiceInput">
            <input v-model="invoiceTitle" class="input" type="text" placeholder="发票抬头" />
          </div>
        </section>

        <section class="panel" aria-label="优惠券">
          <div class="panelHead">
            <img class="panelIcon" :src="iconCouponUrl" alt="" aria-hidden="true" />
            <div class="panelTitle">优惠券</div>
          </div>
          <div class="couponList">
            <label v-for="c in coupons" :key="c.id" class="coupon" :class="{ on: selectedCouponId === c.id }">
              <input v-model="selectedCouponId" class="radio" type="radio" name="coupon" :value="c.id" />
              <div class="couponBody">
                <div class="couponTitle">{{ c.title }}</div>
                <div class="couponCode">优惠码: {{ c.code }}</div>
              </div>
              <div class="couponVal">-¥{{ c.discount }}</div>
            </label>
          </div>
        </section>

        <section class="panel" aria-label="商品清单">
          <div class="panelTitle">商品清单</div>
          <div class="items">
            <div v-for="it in cart.items" :key="it.itemId" class="item">
              <img class="cover" :src="it.cover" :alt="it.title" loading="lazy" decoding="async" />
              <div class="meta">
                <div class="name">{{ it.title }}</div>
                <div class="sub">x{{ it.qty }}</div>
              </div>
              <div class="price">{{ priceFmt.format(it.price * it.qty) }}</div>
            </div>
          </div>
        </section>

        <section class="panel sumPanel" aria-label="金额汇总">
          <div class="sumList">
            <div class="sumRow">
              <div class="sumLabel">商品金额</div>
              <div class="sumValue">{{ priceFmt.format(itemsAmount) }}</div>
            </div>
            <div class="sumRow">
              <div class="sumLabel">优惠金额</div>
              <div class="sumValue discount">-{{ priceFmt.format(discountAmount) }}</div>
            </div>
            <div class="sumRow">
              <div class="sumLabel">运费</div>
              <div class="sumValue">免运费</div>
            </div>
            <div class="sumDivider"></div>
            <div class="sumRow total">
              <div class="sumTotalLabel">应付金额</div>
              <div class="sumTotalVal">{{ priceFmt.format(payable) }}</div>
            </div>
          </div>
          <button class="payBtn" type="button" :disabled="!canSubmit" @click="submit">提交订单并支付</button>
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
  width: min(944px, 100%);
  margin: 0 auto;
  display: grid;
  gap: 16px;
}

.top {
  width: min(864px, 100%);
  margin: 0 auto;
  display: grid;
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
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
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

.panel {
  width: min(864px, 100%);
  margin: 0 auto;
  background: var(--bg);
  border-radius: 10px;
  border: 1px solid var(--border);
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
  color: var(--text-h);
}

.addrList {
  display: grid;
  gap: 8px;
  padding-bottom: 24px;
}

.addr {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  border-radius: 10px;
  border: 2px solid var(--border);
  background: var(--bg);
  padding: 16px 24px;
  cursor: pointer;
}

.addr.on {
  border-color: var(--accent);
  background: var(--accent-bg);
}

.radio {
  margin-top: 4px;
  width: 13px;
  height: 13px;
}

.addrBody {
  display: grid;
  gap: 4px;
  flex: 1;
}

.addrTop {
  display: flex;
  align-items: center;
  gap: 8px;
}

.addrName,
.addrPhone {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.addrPhone {
  color: var(--text);
}

.badge {
  height: 20px;
  padding: 0 8px;
  border-radius: 4px;
  background: var(--accent-bg);
  color: var(--accent);
  font: 500 12px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.addrLine {
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.addLink {
  border: 0;
  background: transparent;
  padding: 0;
  text-align: left;
  cursor: pointer;
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--accent);
}

.addForm {
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--bg);
  padding: 12px;
  display: grid;
  gap: 12px;
}

.formGrid {
  display: grid;
  gap: 8px;
}

.input {
  height: 44px;
  border-radius: 10px;
  border: 1px solid var(--border);
  padding: 0 12px;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.formBtns {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.btnGhost,
.btnPrimary {
  height: 36px;
  padding: 0 14px;
  border-radius: 10px;
  cursor: pointer;
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.btnGhost {
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text);
}

.btnPrimary {
  border: 0;
  background: var(--accent);
  color: #ffffff;
}

.shipRow {
  display: flex;
  align-items: center;
  gap: 12px;
  padding-bottom: 24px;
  cursor: pointer;
}

.shipBody {
  display: grid;
  gap: 2px;
  flex: 1;
}

.shipName {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.shipDesc {
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.shipFee {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--success);
}

.invoiceRow {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;
}

.inlineOpt {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  cursor: pointer;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.invoiceInput {
  padding-bottom: 24px;
}

.couponList {
  display: grid;
  gap: 8px;
  padding-bottom: 24px;
}

.coupon {
  display: flex;
  align-items: center;
  gap: 12px;
  border-radius: 10px;
  border: 1px solid var(--border);
  padding: 12px;
  cursor: pointer;
  background: var(--bg);
}

.coupon.on {
  border-color: var(--accent);
  background: var(--accent-bg);
}

.couponBody {
  flex: 1;
  display: grid;
}

.couponTitle {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.couponCode {
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.couponVal {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--danger);
}

.items {
  display: grid;
  gap: 12px;
  padding-bottom: 24px;
}

.item {
  display: grid;
  grid-template-columns: 64px minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
}

.cover {
  width: 64px;
  height: 64px;
  border-radius: 10px;
  object-fit: cover;
  background: var(--code-bg);
}

.meta {
  display: grid;
  gap: 4px;
}

.name {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sub {
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.price {
  font: 500 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.sumPanel {
  padding-bottom: 24px;
}

.sumList {
  display: grid;
  gap: 12px;
}

.sumRow {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.sumLabel {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text);
}

.sumValue {
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.sumValue.discount {
  color: var(--danger);
}

.sumDivider {
  height: 1px;
  background: var(--border);
}

.sumTotalLabel {
  font: 500 20px/28px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--text-h);
}

.sumTotalVal {
  font: 400 30px/36px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: var(--danger);
}

.payBtn {
  margin-top: 16px;
  width: 100%;
  height: 56px;
  border-radius: 14px;
  border: 0;
  background: var(--accent);
  color: #ffffff;
  cursor: pointer;
  font: 500 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.payBtn:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}
</style>
