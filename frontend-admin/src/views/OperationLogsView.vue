<template>
  <section class="page-head">
    <div>
      <h1>操作日志</h1>
      <p>追踪管理员访问、审核、发货和商品维护行为。</p>
    </div>
    <el-button @click="reload">刷新</el-button>
  </section>

  <el-alert v-if="error" :title="error" type="error" show-icon :closable="false" style="margin-bottom: 14px" />

  <section class="panel">
    <div class="filters">
      <div class="field">
        <label>关键词</label>
        <el-input v-model.trim="filters.keyword" placeholder="管理员、操作、路径" @keyup.enter="reload" />
      </div>
      <div class="field">
        <label>权限</label>
        <el-select v-model="filters.permissionCode" clearable placeholder="全部权限">
          <el-option label="工作台" value="DASHBOARD_VIEW" />
          <el-option label="商品管理" value="PRODUCT_MANAGE" />
          <el-option label="分类管理" value="CATEGORY_MANAGE" />
          <el-option label="订单管理" value="ORDER_MANAGE" />
          <el-option label="售后管理" value="AFTERSALE_MANAGE" />
          <el-option label="用户管理" value="USER_MANAGE" />
          <el-option label="操作日志" value="OPERATION_LOG_VIEW" />
        </el-select>
      </div>
      <div class="field">
        <label>结果</label>
        <el-select v-model="filters.status" clearable placeholder="全部结果">
          <el-option label="成功" value="SUCCESS" />
          <el-option label="失败" value="FAILED" />
        </el-select>
      </div>
      <div class="field">
        <label>&nbsp;</label>
        <el-button type="primary" @click="reload">查询</el-button>
      </div>
    </div>

    <el-table :data="logs" border style="width: 100%">
      <el-table-column prop="createTime" label="时间" min-width="170">
        <template #default="{ row }">{{ formatTime(row.createTime) }}</template>
      </el-table-column>
      <el-table-column prop="adminAccount" label="管理员" min-width="150" />
      <el-table-column prop="action" label="操作" min-width="120" />
      <el-table-column prop="permissionCode" label="权限" min-width="150" />
      <el-table-column prop="method" label="方法" width="88" />
      <el-table-column prop="path" label="路径" min-width="220" show-overflow-tooltip />
      <el-table-column prop="status" label="结果" width="92">
        <template #default="{ row }">
          <el-tag :type="row.status === 'SUCCESS' ? 'success' : 'danger'">{{ row.status }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="durationMs" label="耗时" width="96">
        <template #default="{ row }">{{ row.durationMs }}ms</template>
      </el-table-column>
      <el-table-column prop="errorMessage" label="错误" min-width="160" show-overflow-tooltip />
    </el-table>

    <div class="pagination">
      <el-pagination
        v-model:current-page="page"
        :page-size="size"
        :total="total"
        layout="prev, pager, next, total"
        @current-change="load"
      />
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

const logs = ref<any[]>([])
const page = ref(1)
const total = ref(0)
const size = 10
const error = ref('')

const filters = reactive({
  keyword: '',
  permissionCode: '',
  status: '',
})

const load = async () => {
  error.value = ''
  try {
    const data = unwrap<{ items: any[]; total: number }>(
      await api.get('/v1/admin/operation-logs', {
        params: {
          keyword: filters.keyword || undefined,
          permissionCode: filters.permissionCode || undefined,
          status: filters.status || undefined,
          page: page.value,
          size,
        },
      }),
    )
    logs.value = data.items
    total.value = data.total
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载操作日志失败'
  }
}

const reload = () => {
  page.value = 1
  load()
}

const formatTime = (value: unknown) => (value ? new Date(String(value)).toLocaleString() : '-')

onMounted(load)
</script>
