<template>
  <section class="page-head">
    <div>
      <h1>工作台</h1>
      <p>查看平台核心经营指标和待处理事项。</p>
    </div>
    <button class="btn secondary" type="button" @click="load" :disabled="loading">刷新</button>
  </section>

  <div v-if="error" class="alert">{{ error }}</div>

  <section class="stats-grid">
    <div v-for="item in statsCards" :key="item.label" class="stat-card">
      <div class="stat-label">{{ item.label }}</div>
      <div class="stat-value">{{ item.value }}</div>
    </div>
  </section>

  <section class="panel">
    <div class="panel-title">
      <h2>最近订单</h2>
    </div>
    <div class="table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>订单号</th>
            <th>用户</th>
            <th>金额</th>
            <th>状态</th>
            <th>创建时间</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in stats.recentOrders" :key="order.id">
            <td>{{ order.orderNo }}</td>
            <td>{{ order.userNickname || order.userAccount || '-' }}</td>
            <td>￥{{ money(order.payAmount) }}</td>
            <td><span class="tag" :class="statusClass(order.status)">{{ orderStatus(order.status) }}</span></td>
            <td>{{ formatTime(order.createTime) }}</td>
          </tr>
          <tr v-if="!stats.recentOrders?.length">
            <td colspan="5" class="empty">暂无订单</td>
          </tr>
        </tbody>
      </table>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

type DashboardStats = {
  users: number
  products: number
  orders: number
  todaySales: number | string
  pendingShipment: number
  pendingAftersales: number
  lowStockProducts: number
  recentOrders: any[]
}

const loading = ref(false)
const error = ref('')
const stats = reactive<DashboardStats>({
  users: 0,
  products: 0,
  orders: 0,
  todaySales: 0,
  pendingShipment: 0,
  pendingAftersales: 0,
  lowStockProducts: 0,
  recentOrders: [],
})

const statsCards = computed(() => [
  { label: '用户总数', value: stats.users },
  { label: '商品总数', value: stats.products },
  { label: '订单总数', value: stats.orders },
  { label: '今日销售额', value: `￥${money(stats.todaySales)}` },
  { label: '待发货订单', value: stats.pendingShipment },
  { label: '待处理售后', value: stats.pendingAftersales },
  { label: '低库存商品', value: stats.lowStockProducts },
])

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const data = unwrap<DashboardStats>(await api.get('/v1/admin/dashboard/stats'))
    Object.assign(stats, data)
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载工作台失败'
  } finally {
    loading.value = false
  }
}

const orderStatus = (status: number) => {
  const labels: Record<number, string> = { 0: '待支付', 1: '已支付', 2: '已发货', 3: '已完成', 4: '已取消' }
  return labels[status] || '未知'
}

const statusClass = (status: number) => {
  if (status === 1 || status === 2) return 'warn'
  if (status === 3) return 'ok'
  if (status === 4) return 'bad'
  return ''
}

const money = (value: unknown) => Number(value || 0).toFixed(2)
const formatTime = (value: unknown) => (value ? new Date(String(value)).toLocaleString() : '-')

onMounted(load)
</script>
