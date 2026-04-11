<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useCartStore } from '../stores/cart'
import { useOrdersStore } from '../stores/orders'
import { useOrderDraftStore } from '../stores/orderDraft'
import { useNotificationsStore } from '../stores/notifications'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'
import { api } from '../lib/api'

const router = useRouter()
const cart = useCartStore()
const orders = useOrdersStore()
const orderDraft = useOrderDraftStore()
const notifications = useNotificationsStore()
const tracker = useTrackerStore()
const toast = useToastStore()

const receiver = ref(orderDraft.draft.address?.receiver ?? '')
const phone = ref(orderDraft.draft.address?.phone ?? '')
const region = ref(orderDraft.draft.address?.region ?? '')
const detail = ref(orderDraft.draft.address?.detail ?? '')

const invoiceTitle = ref(orderDraft.draft.invoiceTitle ?? '')
const usePoints = ref(String(orderDraft.draft.usePoints ?? 0))

const submitting = ref(false)

const isEmpty = computed(() => cart.items.length === 0)
const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const itemsAmount = computed(() => cart.amount)

const pointsDiscount = computed(() => {
  const raw = usePoints.value.trim()
  if (raw === '') return 0
  const pts = Number(raw)
  if (!Number.isFinite(pts) || pts <= 0) return 0
  const money = Math.floor(pts) / 100
  return Math.min(money, Math.max(0, itemsAmount.value))
})

const shipping = computed(() => 0)

const payable = computed(() => {
  return Math.max(0, itemsAmount.value - pointsDiscount.value + shipping.value)
})

const phoneOk = computed(() => /^1\d{10}$/.test(phone.value.trim()))

const canSubmit = computed(() => {
  if (submitting.value) return false
  if (isEmpty.value) return false
  if (!receiver.value.trim()) return false
  if (!phoneOk.value) return false
  if (!region.value.trim()) return false
  if (!detail.value.trim()) return false
  return true
})

const submit = async () => {
  if (!canSubmit.value) {
    toast.push({ type: 'error', message: '请完整填写收货信息' })
    return
  }

  submitting.value = true
  try {
    orderDraft.setAddress({
      receiver: receiver.value.trim(),
      phone: phone.value.trim(),
      region: region.value.trim(),
      detail: detail.value.trim(),
    })
    orderDraft.setInvoiceTitle(invoiceTitle.value.trim())
    orderDraft.setUsePoints(Number(usePoints.value.trim() || 0))

    const res = await api.post('/v1/orders/checkout', {
      addressId: 0,
    })
    const data = res.data?.data || {}
    const orderId: string = String(data.id ?? data.orderId ?? '')
    const mappedId = orders.upsertFromBackend(data)
    const backendTotal = Number(data.totalAmount ?? itemsAmount.value)
    const backendPayable = Number(data.payAmount ?? payable.value)
    const backendDiscount = Math.max(0, (Number.isFinite(backendTotal) ? backendTotal : 0) - (Number.isFinite(backendPayable) ? backendPayable : 0))

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
      shipping: 0,
      payable: backendPayable,
    })

    orderDraft.createOrder({
      orderId: mappedId,
      itemsAmount: backendTotal,
      discount: backendDiscount,
      shipping: 0,
    })
    await router.push({ name: 'payResult', query: { orderId: mappedId } })
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
    <UiPageHeader title="结算" />

    <main class="main" aria-live="polite">
      <UiEmptyState
        v-if="isEmpty"
        title="购物车空空如也"
        desc="请先添加商品再结算"
        action-text="去首页"
        @action="router.push({ name: 'home' })"
      />

      <div v-else class="grid">
        <section class="card" aria-label="收货信息">
          <div class="cardTitle">收货信息</div>
          <div class="fields">
            <div class="field">
              <div class="label">收货人</div>
              <UiInput v-model="receiver" autocomplete="name" placeholder="请输入收货人姓名" />
            </div>
            <div class="field">
              <div class="label">手机号</div>
              <UiInput v-model="phone" inputmode="tel" autocomplete="tel" placeholder="请输入手机号" />
              <div v-if="phone.trim() && !phoneOk" class="hint" role="alert">手机号格式不正确</div>
            </div>
            <div class="field">
              <div class="label">所在地区</div>
              <UiInput v-model="region" autocomplete="address-level1" placeholder="例如：北京/朝阳区" />
            </div>
            <div class="field">
              <div class="label">详细地址</div>
              <UiInput v-model="detail" autocomplete="street-address" placeholder="街道门牌号等" />
            </div>
          </div>
        </section>

        <section class="card" aria-label="发票与积分">
          <div class="cardTitle">发票与优惠</div>
          <div class="fields">
            <div class="field">
              <div class="label">发票抬头（可选）</div>
              <UiInput v-model="invoiceTitle" autocomplete="organization" placeholder="个人/企业名称" />
            </div>
            <div class="field">
              <div class="label">积分（100 积分抵 1 元）</div>
              <UiInput v-model="usePoints" inputmode="numeric" placeholder="可输入 0" />
              <div v-if="pointsDiscount > 0" class="ok">已抵扣 {{ priceFmt.format(pointsDiscount) }}</div>
            </div>
          </div>
        </section>

        <section class="card" aria-label="商品清单">
          <div class="cardTitle">商品清单</div>
          <div class="items">
            <div v-for="it in cart.items" :key="it.itemId" class="item">
              <img class="cover" :src="it.cover" :alt="it.title" loading="lazy" decoding="async" />
              <div class="meta">
                <div class="name">{{ it.title }}</div>
                <div class="sub">SKU：{{ it.skuId }} · x{{ it.qty }}</div>
              </div>
              <div class="price">{{ priceFmt.format(it.price * it.qty) }}</div>
            </div>
          </div>
        </section>
      </div>
    </main>

    <footer v-if="!isEmpty" class="footer" aria-label="提交订单">
      <div class="sum">
        <div class="sumLabel">应付</div>
        <div class="sumVal">{{ priceFmt.format(payable) }}</div>
      </div>
      <UiButton variant="primary" :loading="submitting" :disabled="!canSubmit" @click="submit">提交订单</UiButton>
    </footer>
  </div>
</template>

<style scoped>
.page {
  min-height: 100%;
  display: flex;
  flex-direction: column;
}

.main {
  padding: 14px 16px 92px;
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

.fields {
  display: grid;
  gap: 10px;
}

.field {
  display: grid;
  gap: 8px;
}

.label {
  font-size: var(--font-sm);
  color: var(--text);
}

.hint {
  font-size: var(--font-xs);
  color: var(--text);
}

.ok {
  font-size: var(--font-xs);
  color: var(--text-h);
  border: 1px solid color-mix(in srgb, var(--success) 35%, var(--border));
  background: var(--success-bg);
  border-radius: var(--radius-sm);
  padding: 8px 10px;
}

.items {
  display: grid;
  gap: 10px;
}

.item {
  display: grid;
  grid-template-columns: 58px minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  background: color-mix(in srgb, var(--code-bg) 55%, transparent);
}

.cover {
  width: 58px;
  height: 58px;
  border-radius: var(--radius-sm);
  object-fit: cover;
  border: 1px solid var(--border);
  background: var(--code-bg);
}

.meta {
  display: grid;
  gap: 4px;
}

.name {
  color: var(--text-h);
  font-weight: 900;
  font-size: var(--font-md);
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

.footer {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  border-top: 1px solid var(--border);
  background: var(--bg);
  padding: 12px 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.sum {
  display: grid;
  gap: 2px;
}

.sumLabel {
  font-size: var(--font-xs);
  color: var(--text);
}

.sumVal {
  font-weight: 900;
  color: var(--text-h);
}

@media (min-width: 920px) {
  .main {
    max-width: 1120px;
    margin: 0 auto;
    width: 100%;
  }

  .footer {
    max-width: 1120px;
    margin: 0 auto;
    left: 50%;
    transform: translateX(-50%);
    border-left: 1px solid var(--border);
    border-right: 1px solid var(--border);
  }
}
</style>
