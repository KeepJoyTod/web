<template>
  <section class="page-head">
    <div>
      <h1>售后管理</h1>
      <p>处理退款、退货退款等售后申请。</p>
    </div>
    <button class="btn secondary" type="button" @click="reload">刷新</button>
  </section>

  <div v-if="error" class="alert">{{ error }}</div>

  <section class="panel">
    <div class="filters">
      <div class="field">
        <label>关键词</label>
        <input v-model.trim="filters.keyword" class="input" placeholder="售后 ID、订单号、用户" @keyup.enter="reload" />
      </div>
      <div class="field">
        <label>状态</label>
        <select v-model="filters.status" class="select">
          <option value="">全部状态</option>
          <option value="SUBMITTED">已提交</option>
          <option value="PROCESSING">处理中</option>
          <option value="APPROVED">已通过</option>
          <option value="REJECTED">已拒绝</option>
          <option value="COMPLETED">已完成</option>
          <option value="CANCELLED">已取消</option>
        </select>
      </div>
      <div class="field">
        <label>审核备注</label>
        <input v-model.trim="reviewRemark" class="input" placeholder="处理说明" />
      </div>
      <div class="field">
        <label>&nbsp;</label>
        <button class="btn secondary" type="button" @click="reload">查询</button>
      </div>
    </div>

    <div class="table-wrap">
      <table class="table">
        <thead>
          <tr>
            <th>ID</th>
            <th>订单号</th>
            <th>用户</th>
            <th>类型</th>
            <th>原因</th>
            <th>状态</th>
            <th>备注</th>
            <th>创建时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in aftersales" :key="item.id">
            <td>{{ item.id }}</td>
            <td>{{ item.orderNo || item.orderId }}</td>
            <td>{{ item.userNickname || item.userAccount || '-' }}</td>
            <td>{{ typeLabel(item.type) }}</td>
            <td>{{ item.reason }}</td>
            <td><span class="tag" :class="statusClass(item.status)">{{ statusLabel(item.status) }}</span></td>
            <td>{{ item.adminRemark || '-' }}</td>
            <td>{{ formatTime(item.createTime) }}</td>
            <td>
              <div class="button-row">
                <button class="btn secondary" type="button" @click="review(item.id, 'PROCESSING')">受理</button>
                <button class="btn" type="button" @click="review(item.id, 'APPROVED')">通过</button>
                <button class="btn danger" type="button" @click="review(item.id, 'REJECTED')">拒绝</button>
                <button class="btn ghost" type="button" @click="review(item.id, 'COMPLETED')">完成</button>
              </div>
            </td>
          </tr>
          <tr v-if="!aftersales.length">
            <td colspan="9" class="empty">暂无售后申请</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="pagination">
      <button class="btn secondary" type="button" :disabled="page <= 1" @click="page-- && load()">上一页</button>
      <span class="muted">第 {{ page }} / {{ totalPages }} 页，共 {{ total }} 条</span>
      <button class="btn secondary" type="button" :disabled="page >= totalPages" @click="page++ && load()">下一页</button>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

const aftersales = ref<any[]>([])
const page = ref(1)
const total = ref(0)
const size = 10
const error = ref('')
const reviewRemark = ref('')

const filters = reactive({
  keyword: '',
  status: '',
})

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / size)))

const load = async () => {
  error.value = ''
  try {
    const data = unwrap<{ items: any[]; total: number }>(
      await api.get('/v1/admin/aftersales', {
        params: {
          keyword: filters.keyword || undefined,
          status: filters.status || undefined,
          page: page.value,
          size,
        },
      }),
    )
    aftersales.value = data.items
    total.value = data.total
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载售后失败'
  }
}

const reload = () => {
  page.value = 1
  load()
}

const review = async (id: number, status: string) => {
  try {
    await api.put(`/v1/admin/aftersales/${id}/review`, { status, adminRemark: reviewRemark.value })
    await load()
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '处理售后失败'
  }
}

const typeLabel = (type: string) => {
  const labels: Record<string, string> = { refund_only: '仅退款', return_refund: '退货退款' }
  return labels[type] || type || '-'
}

const statusLabel = (status: string) => {
  const labels: Record<string, string> = {
    SUBMITTED: '已提交',
    PROCESSING: '处理中',
    APPROVED: '已通过',
    REJECTED: '已拒绝',
    COMPLETED: '已完成',
    CANCELLED: '已取消',
  }
  return labels[status] || status
}

const statusClass = (status: string) => {
  if (status === 'APPROVED' || status === 'COMPLETED') return 'ok'
  if (status === 'REJECTED' || status === 'CANCELLED') return 'bad'
  return 'warn'
}

const formatTime = (value: unknown) => (value ? new Date(String(value)).toLocaleString() : '-')

onMounted(load)
</script>
