<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useAftersalesStore } from '../stores/aftersales'

const router = useRouter()
const aftersales = useAftersalesStore()

onMounted(() => {
  aftersales.fetch().catch(() => {})
})
</script>

<template>
  <div class="page">
    <UiPageHeader title="售后" />

    <main class="main" aria-live="polite">
      <UiEmptyState
        v-if="aftersales.items.length === 0"
        title="暂无售后单"
        desc="可在订单详情中发起售后"
        action-text="去订单"
        @action="router.push({ name: 'orders' })"
      />

      <div v-else class="list" aria-label="售后列表">
        <article v-for="a in aftersales.items" :key="a.id" class="card">
          <div class="row">
            <div class="id">售后号 {{ a.id }}</div>
            <div class="badge" :class="a.status">{{ a.status }}</div>
          </div>
          <div class="meta">
            <div>订单号 {{ a.orderId }}</div>
            <div>类型 {{ a.type === 'refund_only' ? '仅退款' : '退货退款' }}</div>
            <div>数量 x{{ a.qty }}</div>
            <div>{{ new Date(a.createdAt).toLocaleString() }}</div>
          </div>
          <div class="reason">{{ a.reason }}</div>
          <div class="actions">
            <UiButton size="sm" type="button" @click="router.push({ name: 'orderDetail', params: { id: a.orderId } })">
              查看订单
            </UiButton>
            <UiButton
              size="sm"
              type="button"
              :disabled="a.status === 'Cancelled' || a.status === 'Done'"
              @click="aftersales.cancel(a.id)"
            >
              取消
            </UiButton>
          </div>
        </article>
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
}

.list {
  display: grid;
  gap: 12px;
}

.card {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  background: var(--bg);
  padding: 12px;
  display: grid;
  gap: 10px;
}

.row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
}

.id {
  color: var(--text-h);
  font-weight: 900;
  font-size: var(--font-sm);
}

.badge {
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  padding: 4px 10px;
  font-size: var(--font-xs);
  font-weight: 900;
  color: var(--text-h);
}

.badge.Submitted,
.badge.Processing {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.badge.Done {
  border-color: color-mix(in srgb, var(--success) 55%, var(--border));
  background: var(--success-bg);
}

.badge.Cancelled {
  border-color: color-mix(in srgb, var(--danger) 55%, var(--border));
  background: var(--danger-bg);
}

.meta {
  display: grid;
  gap: 4px;
  color: var(--text);
  font-size: var(--font-xs);
}

.reason {
  color: var(--text-h);
  font-size: var(--font-sm);
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

@media (min-width: 920px) {
  .main {
    max-width: 1120px;
    margin: 0 auto;
    width: 100%;
  }
}
</style>
