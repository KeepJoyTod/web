<template>
  <section class="page-head">
    <div>
      <h1>用户管理</h1>
      <p>查看用户资料，启用或禁用账号。</p>
    </div>
    <button class="btn secondary" type="button" @click="reload">刷新</button>
  </section>

  <div v-if="error" class="alert">{{ error }}</div>

  <div class="split-grid">
    <section class="panel">
      <div class="filters">
        <div class="field">
          <label>关键词</label>
          <input v-model.trim="filters.keyword" class="input" placeholder="账号、昵称" @keyup.enter="reload" />
        </div>
        <div class="field">
          <label>角色</label>
          <select v-model="filters.role" class="select">
            <option value="">全部角色</option>
            <option value="ADMIN">管理员</option>
            <option value="USER">普通用户</option>
          </select>
        </div>
        <div class="field">
          <label>状态</label>
          <select v-model="filters.status" class="select">
            <option value="">全部状态</option>
            <option value="1">启用</option>
            <option value="0">禁用</option>
          </select>
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
              <th>账号</th>
              <th>昵称</th>
              <th>角色</th>
              <th>状态</th>
              <th>注册时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in users" :key="user.id">
              <td>{{ user.id }}</td>
              <td>{{ user.account }}</td>
              <td>{{ user.nickname || '-' }}</td>
              <td>{{ user.role === 'ADMIN' ? '管理员' : '普通用户' }}</td>
              <td><span class="tag" :class="user.status === 1 ? 'ok' : 'bad'">{{ user.status === 1 ? '启用' : '禁用' }}</span></td>
              <td>{{ formatTime(user.createTime) }}</td>
              <td>
                <div class="button-row">
                  <button class="btn ghost" type="button" @click="openDetail(user.id)">详情</button>
                  <button class="btn secondary" type="button" @click="toggleStatus(user)">
                    {{ user.status === 1 ? '禁用' : '启用' }}
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="!users.length">
              <td colspan="7" class="empty">暂无用户</td>
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
        <h2>用户详情</h2>
      </div>
      <div v-if="!selectedUser" class="empty">选择左侧用户查看详情</div>
      <div v-else>
        <p><strong>{{ selectedUser.nickname || selectedUser.account }}</strong></p>
        <p class="muted">{{ selectedUser.account }} · {{ selectedUser.role }}</p>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-label">订单数</div>
            <div class="stat-value">{{ selectedUser.orderCount || 0 }}</div>
          </div>
          <div class="stat-card">
            <div class="stat-label">累计消费</div>
            <div class="stat-value">￥{{ money(selectedUser.totalSpent) }}</div>
          </div>
          <div class="stat-card">
            <div class="stat-label">售后数</div>
            <div class="stat-value">{{ selectedUser.aftersaleCount || 0 }}</div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

const users = ref<any[]>([])
const selectedUser = ref<any | null>(null)
const page = ref(1)
const total = ref(0)
const size = 10
const error = ref('')

const filters = reactive({
  keyword: '',
  role: '',
  status: '',
})

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / size)))

const load = async () => {
  error.value = ''
  try {
    const data = unwrap<{ items: any[]; total: number }>(
      await api.get('/v1/admin/users', {
        params: {
          keyword: filters.keyword || undefined,
          role: filters.role || undefined,
          status: filters.status === '' ? undefined : filters.status,
          page: page.value,
          size,
        },
      }),
    )
    users.value = data.items
    total.value = data.total
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载用户失败'
  }
}

const reload = () => {
  page.value = 1
  load()
}

const openDetail = async (id: number) => {
  try {
    selectedUser.value = unwrap<any>(await api.get(`/v1/admin/users/${id}`))
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载用户详情失败'
  }
}

const toggleStatus = async (user: any) => {
  try {
    await api.put(`/v1/admin/users/${user.id}/status`, { status: user.status === 1 ? 0 : 1 })
    await load()
    if (selectedUser.value?.id === user.id) {
      await openDetail(user.id)
    }
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '更新用户状态失败'
  }
}

const money = (value: unknown) => Number(value || 0).toFixed(2)
const formatTime = (value: unknown) => (value ? new Date(String(value)).toLocaleString() : '-')

onMounted(load)
</script>
