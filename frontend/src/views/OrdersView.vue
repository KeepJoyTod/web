<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useOrdersStore } from '../stores/orders'

type Tab = 'all' | 'Created' | 'Paid' | 'Cancelled'

const router = useRouter()
const ordersStore = useOrdersStore()

const tab = ref<Tab>('all')

const priceFmt = new Intl.NumberFormat('zh-CN', { style: 'currency', currency: 'CNY' })

const list = computed(() => {
  if (tab.value === 'all') return ordersStore.orders
  return ordersStore.orders.filter((o) => o.status === tab.value)
})

const goDetail = (id: string) => {
  router.push({ name: 'orderDetail', params: { id } })
}

onMounted(() => {
  ordersStore.refreshFromBackend().catch(() => {})
})
</script>

<template>
  <div class="page">
    <UiPageHeader title="我的订单" />

    <main class="main" aria-live="polite">
      <section class="tabs" aria-label="订单筛选">
        <UiButton size="sm" :variant="tab === 'all' ? 'primary' : 'ghost'" @click="tab = 'all'">全部</UiButton>
        <UiButton size="sm" :variant="tab === 'Created' ? 'primary' : 'ghost'" @click="tab = 'Created'">
          待支付
        </UiButton>
        <UiButton size="sm" :variant="tab === 'Paid' ? 'primary' : 'ghost'" @click="tab = 'Paid'">已支付</UiButton>
        <UiButton
          size="sm"
          :variant="tab === 'Cancelled' ? 'primary' : 'ghost'"
          @click="tab = 'Cancelled'"
        >
          已取消
        </UiButton>
      </section>

      <UiEmptyState v-if="list.length === 0" title="暂无订单" desc="去首页看看有什么好物" action-text="去首页" @action="router.push({ name: 'home' })" />

      <div v-else class="list" aria-label="订单列表">
        <article v-for="o in list" :key="o.id" class="card" @click="goDetail(o.id)">
          <div class="row">
            <div class="id">订单号 {{ o.id }}</div>
            <div class="badge" :class="o.status">{{ o.status === 'Created' ? '待支付' : o.status === 'Paid' ? '已支付' : '已取消' }}</div>
          </div>
          <div class="row">
            <div class="meta">{{ new Date(o.createdAt).toLocaleString() }}</div>
            <div class="price">{{ priceFmt.format(o.amounts.payable) }}</div>
          </div>
          <div class="items">
            <div v-for="it in o.items.slice(0, 2)" :key="it.orderItemId" class="item">
              <img class="cover" :src="it.cover" :alt="it.title" loading="lazy" decoding="async" />
              <div class="name">{{ it.title }}</div>
              <div class="qty">x{{ it.qty }}</div>
            </div>
            <div v-if="o.items.length > 2" class="more">+{{ o.items.length - 2 }}</div>
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
  display: grid;
  gap: 12px;
}

.tabs {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
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
  cursor: pointer;
}

.row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: baseline;
}

.id {
  color: var(--text-h);
  font-weight: 900;
  font-size: var(--font-sm);
}

.meta {
  color: var(--text);
  font-size: var(--font-xs);
}

.price {
  color: var(--text-h);
  font-weight: 900;
}

.badge {
  border: 1px solid var(--border);
  border-radius: var(--radius-pill);
  padding: 4px 10px;
  font-size: var(--font-xs);
  font-weight: 900;
  color: var(--text-h);
}

.badge.Created {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.badge.Paid {
  border-color: color-mix(in srgb, var(--success) 55%, var(--border));
  background: var(--success-bg);
}

.badge.Cancelled {
  border-color: color-mix(in srgb, var(--danger) 55%, var(--border));
  background: var(--danger-bg);
}

.items {
  display: grid;
  gap: 8px;
}

.item {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
}

.cover {
  width: 44px;
  height: 44px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  object-fit: cover;
  background: var(--code-bg);
}

.name {
  color: var(--text-h);
  font-size: var(--font-sm);
  font-weight: 800;
  line-height: 1.2;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.qty {
  color: var(--text);
  font-size: var(--font-xs);
}

.more {
  color: var(--text);
  font-size: var(--font-xs);
}

@media (min-width: 920px) {
  .main {
    max-width: 1120px;
    margin: 0 auto;
    width: 100%;
  }
}
</style>
