<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useNotificationsStore } from '../stores/notifications'
import { useReviewsStore } from '../stores/reviews'
import { useTrackerStore } from '../stores/tracker'
import { useToastStore } from '../stores/toast'

const router = useRouter()
const route = useRoute()
const reviews = useReviewsStore()
const notifications = useNotificationsStore()
const tracker = useTrackerStore()
const toast = useToastStore()

const orderId = computed(() => (typeof route.query.orderId === 'string' ? route.query.orderId : ''))
const productId = computed(() => (typeof route.query.productId === 'string' ? route.query.productId : ''))

const rating = ref(5)
const content = ref('')
const submitting = ref(false)

const canSubmit = computed(() => {
  if (submitting.value) return false
  if (!orderId.value || !productId.value) return false
  if (rating.value < 1 || rating.value > 5) return false
  if (!content.value.trim()) return false
  return true
})

const submit = async () => {
  if (!canSubmit.value) {
    toast.push({ type: 'error', message: '请填写评分与内容' })
    return
  }
  submitting.value = true
  try {
    await new Promise((r) => window.setTimeout(r, 450))
    const id = await reviews.create({
      orderId: orderId.value,
      productId: productId.value,
      rating: rating.value,
      content: content.value.trim(),
      images: [],
    })
    notifications.push({
      type: 'system',
      title: '评价已提交',
      content: `评价号 ${id} 已提交，感谢你的反馈`,
      relatedId: id,
    })
    tracker.track('review_submit', { reviewId: id, orderId: orderId.value, productId: productId.value, rating: rating.value })
    toast.push({ type: 'success', message: '评价已提交' })
    router.replace({ name: 'orderDetail', params: { id: orderId.value } })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="发布评价" />

    <main class="main" aria-live="polite">
      <UiEmptyState v-if="!orderId || !productId" title="无法发布评价" desc="请从订单详情进入" action-text="去订单" @action="router.push({ name: 'orders' })" />

      <div v-else class="card">
        <div class="row">
          <div class="k">订单号</div>
          <div class="v">{{ orderId }}</div>
        </div>
        <div class="row">
          <div class="k">商品</div>
          <div class="v">{{ productId }}</div>
        </div>

        <div class="field">
          <div class="k">评分</div>
          <div class="stars" role="radiogroup" aria-label="评分">
            <button v-for="n in 5" :key="n" class="star" type="button" :class="{ on: n <= rating }" @click="rating = n">
              {{ n <= rating ? '★' : '☆' }}
            </button>
          </div>
        </div>

        <div class="field">
          <div class="k">内容</div>
          <UiInput v-model="content" placeholder="说说你的使用感受（必填）" />
        </div>

        <UiButton variant="primary" :disabled="!canSubmit" :loading="submitting" @click="submit">提交评价</UiButton>
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

.field {
  display: grid;
  gap: 8px;
}

.stars {
  display: flex;
  gap: 6px;
}

.star {
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  padding: 8px 10px;
  background: var(--bg);
  cursor: pointer;
  font-size: 16px;
  color: var(--text);
}

.star.on {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
  color: var(--text-h);
}
</style>
