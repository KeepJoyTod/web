<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useAftersalesStore } from '../stores/aftersales'
import { useOrdersStore } from '../stores/orders'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'

const router = useRouter()
const route = useRoute()
const orders = useOrdersStore()
const aftersales = useAftersalesStore()
const tracker = useTrackerStore()
const toast = useToastStore()

const orderId = computed(() => (typeof route.query.orderId === 'string' ? route.query.orderId : ''))
const orderItemId = computed(() => (typeof route.query.orderItemId === 'string' ? route.query.orderItemId : ''))

const order = computed(() => (orderId.value ? orders.getById(orderId.value) : null))
const item = computed(() => order.value?.items.find((x) => x.orderItemId === orderItemId.value) ?? null)

const type = ref<'refund_only' | 'return_refund'>('refund_only')
const reason = ref('')
const qty = ref(1)
const submitting = ref(false)

const maxQty = computed(() => item.value?.qty ?? 1)
const canSubmit = computed(() => {
  if (submitting.value) return false
  if (!order.value || !item.value) return false
  if (!reason.value.trim()) return false
  if (qty.value < 1 || qty.value > maxQty.value) return false
  return true
})

const submit = async () => {
  if (!canSubmit.value) {
    toast.push({ type: 'error', message: '请完善售后信息' })
    return
  }
  submitting.value = true
  try {
    await new Promise((r) => window.setTimeout(r, 450))
    const id = await aftersales.apply({
      orderId: orderId.value,
      orderItemId: orderItemId.value,
      type: type.value,
      reason: reason.value.trim(),
      evidence: [],
      qty: qty.value,
    })
    tracker.track('aftersale_apply', { aftersaleId: id, orderId: orderId.value, orderItemId: orderItemId.value, type: type.value })
    toast.push({ type: 'success', message: '已提交售后申请' })
    router.replace({ name: 'aftersales' })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="申请售后" />

    <main class="main" aria-live="polite">
      <UiEmptyState v-if="!order || !item" title="无法发起售后" desc="请从订单详情进入" action-text="去订单" @action="router.push({ name: 'orders' })" />

      <div v-else class="grid">
        <section class="card" aria-label="商品信息">
          <div class="item">
            <img class="cover" :src="item.cover" :alt="item.title" loading="lazy" decoding="async" />
            <div class="meta">
              <div class="name">{{ item.title }}</div>
              <div class="sub">SKU：{{ item.skuId }} · x{{ item.qty }}</div>
            </div>
          </div>
        </section>

        <section class="card" aria-label="售后信息">
          <div class="cardTitle">售后类型</div>
          <div class="tabs">
            <UiButton size="sm" :variant="type === 'refund_only' ? 'primary' : 'ghost'" @click="type = 'refund_only'">仅退款</UiButton>
            <UiButton size="sm" :variant="type === 'return_refund' ? 'primary' : 'ghost'" @click="type = 'return_refund'">退货退款</UiButton>
          </div>

          <div class="field">
            <div class="label">数量</div>
            <div class="qty">
              <UiButton size="sm" type="button" :disabled="qty <= 1" @click="qty = Math.max(1, qty - 1)">-</UiButton>
              <div class="qtyVal">{{ qty }}</div>
              <UiButton size="sm" type="button" :disabled="qty >= maxQty" @click="qty = Math.min(maxQty, qty + 1)">+</UiButton>
            </div>
          </div>

          <div class="field">
            <div class="label">原因</div>
            <UiInput v-model="reason" placeholder="请描述问题（必填）" />
          </div>
        </section>
      </div>
    </main>

    <footer v-if="order && item" class="footer" aria-label="提交售后">
      <UiButton variant="primary" :disabled="!canSubmit" :loading="submitting" @click="submit">提交申请</UiButton>
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

.item {
  display: grid;
  grid-template-columns: 58px minmax(0, 1fr);
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

.name {
  color: var(--text-h);
  font-weight: 900;
  font-size: var(--font-sm);
  line-height: 1.2;
}

.sub {
  color: var(--text);
  font-size: var(--font-xs);
}

.tabs {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.field {
  display: grid;
  gap: 8px;
}

.label {
  color: var(--text);
  font-size: var(--font-sm);
}

.qty {
  display: flex;
  gap: 10px;
  align-items: center;
}

.qtyVal {
  min-width: 36px;
  text-align: center;
  font-weight: 900;
  color: var(--text-h);
}

.footer {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  border-top: 1px solid var(--border);
  background: var(--bg);
  padding: 12px 14px;
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

