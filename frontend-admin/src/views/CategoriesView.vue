<template>
  <section class="page-head">
    <div>
      <h1>分类管理</h1>
      <p>维护商城商品分类，支持一级和二级分类。</p>
    </div>
  </section>

  <div v-if="error" class="alert">{{ error }}</div>

  <div class="split-grid">
    <section class="panel">
      <div class="panel-title">
        <h2>分类列表</h2>
        <button class="btn secondary" type="button" @click="load">刷新</button>
      </div>
      <div class="table-wrap">
        <table class="table">
          <thead>
            <tr>
              <th>ID</th>
              <th>分类名称</th>
              <th>父级</th>
              <th>创建时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="category in categories" :key="category.id">
              <td>{{ category.id }}</td>
              <td>{{ category.name }}</td>
              <td>{{ category.parentId ? categoryName(category.parentId) : '一级分类' }}</td>
              <td>{{ formatTime(category.createTime) }}</td>
              <td>
                <div class="button-row">
                  <button class="btn ghost" type="button" @click="edit(category)">编辑</button>
                  <button class="btn danger" type="button" @click="remove(category.id)">删除</button>
                </div>
              </td>
            </tr>
            <tr v-if="!categories.length">
              <td colspan="5" class="empty">暂无分类</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="panel">
      <div class="panel-title">
        <h2>{{ editingId ? '编辑分类' : '新增分类' }}</h2>
      </div>
      <form class="form-grid" @submit.prevent="save">
        <div class="field wide">
          <label>分类名称</label>
          <input v-model.trim="form.name" class="input" required />
        </div>
        <div class="field wide">
          <label>父级分类</label>
          <select v-model="form.parentId" class="select">
            <option value="0">一级分类</option>
            <option v-for="category in rootCategories" :key="category.id" :value="category.id">{{ category.name }}</option>
          </select>
        </div>
        <div class="button-row wide">
          <button class="btn" type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存分类' }}</button>
          <button class="btn secondary" type="button" @click="reset">取消</button>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

type Category = {
  id: number
  name: string
  parentId: number
  createTime?: string
}

const categories = ref<Category[]>([])
const editingId = ref<number | null>(null)
const saving = ref(false)
const error = ref('')

const form = reactive({
  name: '',
  parentId: '0',
})

const rootCategories = computed(() => categories.value.filter((category) => Number(category.parentId || 0) === 0))

const load = async () => {
  error.value = ''
  try {
    categories.value = unwrap<Category[]>(await api.get('/v1/admin/categories'))
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载分类失败'
  }
}

const edit = (category: Category) => {
  editingId.value = category.id
  form.name = category.name
  form.parentId = String(category.parentId || 0)
}

const save = async () => {
  saving.value = true
  error.value = ''
  try {
    const body = { name: form.name, parentId: Number(form.parentId) }
    if (editingId.value) {
      await api.put(`/v1/admin/categories/${editingId.value}`, body)
    } else {
      await api.post('/v1/admin/categories', body)
    }
    reset()
    await load()
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '保存分类失败'
  } finally {
    saving.value = false
  }
}

const remove = async (id: number) => {
  if (!window.confirm('确认删除该分类？')) return
  try {
    await api.delete(`/v1/admin/categories/${id}`)
    await load()
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '删除分类失败'
  }
}

const reset = () => {
  editingId.value = null
  form.name = ''
  form.parentId = '0'
}

const categoryName = (id: number) => categories.value.find((category) => category.id === Number(id))?.name || '-'
const formatTime = (value?: string) => (value ? new Date(value).toLocaleString() : '-')

onMounted(load)
</script>
