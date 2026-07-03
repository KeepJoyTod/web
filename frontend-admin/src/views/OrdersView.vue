<template>
  <section class="page-head">
    <div>
      <h1>订单管理</h1>
      <p>查看订单明细，处理发货和订单状态流转。</p>
    </div>
    <button class="btn secondary" type="button" @click="reload">刷新</button>
  </section>

  <div v-if="error" class="alert">{{ error }}</div>

  <div class="split-grid">
    <section class="panel">
      <div class="filters">
        <div class="field">
          <label>关键词</label>
          <input v-model.trim="filters.keyword" class="input" placeholder="订单号、用户" @keyup.enter="reload" />
        </div>
        <div class="field">
          <label>状态</label>
          <select v-model="filters.status" class="select">
            <option value="">全部状态</option>
            <option value="0">待支付</option>
            <option value="1">已支付</option>
            <option value="2">已发货</option>
            <option value="3">已完成</option>
            <option value="4">已取消</option>
          </select>
        </div>
        <div class="field">
          <label>开始日期</label>
          <input v-model="filters.dateFrom" class="input" type="date" />
        </div>
        <div class="field">
          <label>结束日期</label>
          <input v-model="filters.dateTo" class="input" type="date" />
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
              <th>订单号</th>
              <th>用户</th>
              <th>金额</th>
              <th>状态</th>
              <th>物流</th>
              <th>创建时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="order in orders" :key="order.id">
              <td>{{ order.orderNo }}</td>
              <td>{{ order.userNickname || order.userAccount || '-' }}</td>
              <td>￥{{ money(order.payAmount) }}</td>
              <td><span class="tag" :class="statusClass(order.status)">{{ orderStatus(order.status) }}</span></td>
              <td>{{ order.logisticsNo || '-' }}</td>
              <td>{{ formatTime(order.createTime) }}</td>
              <td><button class="btn ghost" type="button" @click="openDetail(order.id)">详情</button></td>
            </tr>
            <tr v-if="!orders.length">
              <td colspan="7" class="empty">暂无订单</td>
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

    <section class="panel">
      <div class="panel-title">
        <h2>订单详情</h2>
      </div>

      <div v-if="!selectedOrder" class="empty">选择左侧订单查看详情</div>
      <div v-else>
        <p><strong>{{ selectedOrder.orderNo }}</strong></p>
        <p class="muted">
          {{ selectedOrder.userNickname || selectedOrder.userAccount }} · ￥{{ money(selectedOrder.payAmount) }} ·
          {{ formatTime(selectedOrder.createTime) }}
        </p>
        <p>
          <span class="tag" :class="statusClass(selectedOrder.status)">{{ orderStatus(selectedOrder.status) }}</span>
        </p>

        <div class="panel-title" style="margin-top: 18px">
          <h2>发货</h2>
        </div>
        <div class="form-grid">
          <div class="field">
            <label>物流公司</label>
            <input v-model.trim="shipForm.logisticsCompany" class="input" />
          </div>
          <div class="field">
            <label>物流单号</label>
            <input v-model.trim="shipForm.logisticsNo" class="input" />
          </div>
          <div class="button-row wide">
            <button class="btn" type="button" @click="ship">确认发货</button>
            <button class="btn secondary" type="button" @click="setStatus(3)">标记完成</button>
            <button class="btn danger" type="button" @click="setStatus(4)">取消订单</button>
          </div>
        </div>

        <div class="panel-title" style="margin-top: 18px">
          <h2>收货信息</h2>
        </div>
        <p v-if="selectedOrder.address">
          {{ selectedOrder.address.receiver }}，{{ selectedOrder.address.phone }}<br />
          {{ selectedOrder.address.region }} {{ selectedOrder.address.detail }}
        </p>
        <p v-else class="muted">无收货地址</p>

        <div class="panel-title" style="margin-top: 18px">
          <h2>商品明细</h2>
        </div>
        <div class="table-wrap">
          <table class="table" style="min-width: 520px">
            <thead>
              <tr>
                <th>商品</th>
                <th>单价</th>
                <th>数量</th>
                <th>小计</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in selectedOrder.items" :key="item.id">
                <td>{{ item.productName }}</td>
                <td>￥{{ money(item.price) }}</td>
                <td>{{ item.quantity }}</td>
                <td>￥{{ money(item.totalAmount) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

const orders = ref<any[]>([])
const selectedOrder = ref<any | null>(null)
const error = ref('')
const page = ref(1)
const total = ref(0)
const size = 10

const filters = reactive({
  keyword: '',
  status: '',
  dateFrom: '',
  dateTo: '',
})

const shipForm = reactive({
  logisticsCompany: '',
  logisticsNo: '',
})

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / size)))

const load = async () => {
  error.value = ''
  try {
    const data = unwrap<{ items: any[]; total: number }>(
      await api.get('/v1/admin/orders', {
        params: {
          keyword: filters.keyword || undefined,
          status: filters.status === '' ? undefined : filters.status,
          dateFrom: filters.dateFrom || undefined,
          dateTo: filters.dateTo || undefined,
          page: page.value,
          size,
        },
      }),
    )
    orders.value = data.items
    total.value = data.total
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载订单失败'
  }
}

const reload = () => {
  page.value = 1
  load()
}

const openDetail = async (id: number) => {
  error.value = ''
  try {
    selectedOrder.value = unwrap<any>(await api.get(`/v1/admin/orders/${id}`))
    shipForm.logisticsCompany = selectedOrder.value.logisticsCompany || ''
    shipForm.logisticsNo = selectedOrder.value.logisticsNo || ''
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载订单详情失败'
  }
}

const ship = async () => {
  if (!selectedOrder.value) return
  try {
    await api.post(`/v1/admin/orders/${selectedOrder.value.id}/ship`, shipForm)
    await openDetail(selectedOrder.value.id)
    await load()
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '发货失败'
  }
}

const setStatus = async (status: number) => {
  if (!selectedOrder.value) return
  await api.put(`/v1/admin/orders/${selectedOrder.value.id}/status`, { status })
  await openDetail(selectedOrder.value.id)
  await load()
}

const orderStatus = (status: number) => {
  const labels: Record<number, string> = { 0: '待支付', 1: '已支付', 2: '已发货', 3: '已完成', 4: '已取消' }
  return labels[Number(status)] || '未知'
}

const statusClass = (status: number) => {
  if (Number(status) === 1 || Number(status) === 2) return 'warn'
  if (Number(status) === 3) return 'ok'
  if (Number(status) === 4) return 'bad'
  return ''
}

const money = (value: unknown) => Number(value || 0).toFixed(2)
const formatTime = (value: unknown) => (value ? new Date(String(value)).toLocaleString() : '-')

onMounted(load)
</script>
