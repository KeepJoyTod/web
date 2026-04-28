<template>
  <section class="page-head">
    <div>
      <h1>商品管理</h1>
      <p>维护商品基础信息、库存、上下架、图片和 SKU。</p>
    </div>
    <button class="btn" type="button" @click="openCreate">新增商品</button>
  </section>

  <div v-if="error" class="alert">{{ error }}</div>

  <div class="split-grid">
    <section class="panel">
      <div class="filters">
        <div class="field">
          <label>关键词</label>
          <input v-model.trim="filters.keyword" class="input" placeholder="商品名称或描述" @keyup.enter="reload" />
        </div>
        <div class="field">
          <label>分类</label>
          <select v-model="filters.categoryId" class="select">
            <option value="">全部分类</option>
            <option v-for="category in categories" :key="category.id" :value="category.id">{{ category.name }}</option>
          </select>
        </div>
        <div class="field">
          <label>状态</label>
          <select v-model="filters.status" class="select">
            <option value="">全部状态</option>
            <option value="1">上架</option>
            <option value="0">下架</option>
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
              <th>商品</th>
              <th>价格</th>
              <th>库存</th>
              <th>销量</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="product in products" :key="product.id">
              <td>{{ product.id }}</td>
              <td>
                <strong>{{ product.name }}</strong>
                <div class="muted">{{ categoryName(product.categoryId) }} · {{ product.tags || '无标签' }}</div>
              </td>
              <td>￥{{ money(product.price) }}</td>
              <td>{{ product.stock }}</td>
              <td>{{ product.sold || 0 }}</td>
              <td>
                <span class="tag" :class="product.status === 1 ? 'ok' : 'bad'">
                  {{ product.status === 1 ? '上架' : '下架' }}
                </span>
              </td>
              <td>
                <div class="button-row">
                  <button class="btn ghost" type="button" @click="openEdit(product.id)">编辑</button>
                  <button class="btn secondary" type="button" @click="toggleStatus(product)">
                    {{ product.status === 1 ? '下架' : '上架' }}
                  </button>
                  <button class="btn danger" type="button" @click="remove(product.id)">删除</button>
                </div>
              </td>
            </tr>
            <tr v-if="!products.length">
              <td colspan="7" class="empty">暂无商品</td>
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
        <h2>{{ editingId ? '编辑商品' : '新增商品' }}</h2>
        <button class="btn secondary" type="button" @click="resetForm">清空</button>
      </div>

      <form class="form-grid" @submit.prevent="save">
        <div class="field wide">
          <label>商品名称</label>
          <input v-model.trim="form.name" class="input" required />
        </div>
        <div class="field">
          <label>分类</label>
          <select v-model="form.categoryId" class="select">
            <option value="">未分类</option>
            <option v-for="category in categories" :key="category.id" :value="category.id">{{ category.name }}</option>
          </select>
        </div>
        <div class="field">
          <label>状态</label>
          <select v-model="form.status" class="select">
            <option value="1">上架</option>
            <option value="0">下架</option>
          </select>
        </div>
        <div class="field">
          <label>售价</label>
          <input v-model="form.price" class="input" type="number" min="0" step="0.01" required />
        </div>
        <div class="field">
          <label>原价</label>
          <input v-model="form.originalPrice" class="input" type="number" min="0" step="0.01" />
        </div>
        <div class="field">
          <label>库存</label>
          <input v-model="form.stock" class="input" type="number" min="0" required />
        </div>
        <div class="field">
          <label>评分</label>
          <input v-model="form.rating" class="input" type="number" min="0" max="5" step="0.1" />
        </div>
        <div class="field">
          <label>标签</label>
          <input v-model.trim="form.tags" class="input" placeholder='例如 ["旗舰","热卖"]' />
        </div>
        <div class="field">
          <label>活动标签</label>
          <input v-model.trim="form.activityLabel" class="input" placeholder="限时优惠" />
        </div>
        <div class="field wide">
          <label>描述</label>
          <textarea v-model.trim="form.description" class="textarea" />
        </div>
        <div class="field wide">
          <label>图片 URL，每行一个</label>
          <textarea v-model="mediaText" class="textarea" placeholder="https://example.com/product.jpg" />
        </div>
        <div class="field wide">
          <label>SKU，每行一个 JSON</label>
          <textarea
            v-model="skuText"
            class="textarea"
            placeholder='{"attrs":{"颜色":"黑色","版本":"256G"},"price":7999,"stock":20}'
          />
        </div>
        <div class="button-row wide">
          <button class="btn" type="submit" :disabled="saving">{{ saving ? '保存中...' : '保存商品' }}</button>
          <button class="btn secondary" type="button" @click="resetForm">取消</button>
        </div>
      </form>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { api, unwrap } from '../lib/api'

type Product = {
  id: number
  categoryId?: number
  name: string
  description?: string
  tags?: string
  rating?: number
  sold?: number
  activityLabel?: string
  originalPrice?: number
  price: number
  stock: number
  status: number
}

type Category = { id: number; name: string; parentId?: number }

const products = ref<Product[]>([])
const categories = ref<Category[]>([])
const loading = ref(false)
const saving = ref(false)
const error = ref('')
const page = ref(1)
const total = ref(0)
const size = 10
const editingId = ref<number | null>(null)
const mediaText = ref('')
const skuText = ref('')

const filters = reactive({
  keyword: '',
  categoryId: '',
  status: '',
})

const blankForm = () => ({
  name: '',
  categoryId: '',
  description: '',
  tags: '',
  rating: '4.5',
  sold: '0',
  activityLabel: '',
  originalPrice: '',
  price: '',
  stock: '0',
  status: '1',
})

const form = reactive(blankForm())

const totalPages = computed(() => Math.max(1, Math.ceil(total.value / size)))

const loadCategories = async () => {
  categories.value = unwrap<Category[]>(await api.get('/v1/admin/categories'))
}

const load = async () => {
  loading.value = true
  error.value = ''
  try {
    const data = unwrap<{ items: Product[]; total: number }>(
      await api.get('/v1/admin/products', {
        params: {
          keyword: filters.keyword || undefined,
          categoryId: filters.categoryId || undefined,
          status: filters.status === '' ? undefined : filters.status,
          page: page.value,
          size,
        },
      }),
    )
    products.value = data.items
    total.value = data.total
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载商品失败'
  } finally {
    loading.value = false
  }
}

const reload = () => {
  page.value = 1
  load()
}

const openCreate = () => {
  resetForm()
}

const openEdit = async (id: number) => {
  error.value = ''
  try {
    const data = unwrap<any>(await api.get(`/v1/admin/products/${id}`))
    editingId.value = data.id
    Object.assign(form, {
      name: data.name || '',
      categoryId: data.categoryId ? String(data.categoryId) : '',
      description: data.description || '',
      tags: data.tags || '',
      rating: data.rating == null ? '' : String(data.rating),
      sold: data.sold == null ? '0' : String(data.sold),
      activityLabel: data.activityLabel || '',
      originalPrice: data.originalPrice == null ? '' : String(data.originalPrice),
      price: data.price == null ? '' : String(data.price),
      stock: data.stock == null ? '0' : String(data.stock),
      status: data.status == null ? '1' : String(data.status),
    })
    mediaText.value = Array.isArray(data.media) ? data.media.join('\n') : ''
    skuText.value = Array.isArray(data.skus)
      ? data.skus
          .map((sku: any) => JSON.stringify({ attrs: sku.attrs || {}, price: sku.price, stock: sku.stock }))
          .join('\n')
      : ''
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '加载商品详情失败'
  }
}

const resetForm = () => {
  editingId.value = null
  Object.assign(form, blankForm())
  mediaText.value = ''
  skuText.value = ''
  error.value = ''
}

const save = async () => {
  error.value = ''
  saving.value = true
  try {
    const body = buildBody()
    if (editingId.value) {
      await api.put(`/v1/admin/products/${editingId.value}`, body)
    } else {
      await api.post('/v1/admin/products', body)
    }
    resetForm()
    await load()
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '保存商品失败'
  } finally {
    saving.value = false
  }
}

const buildBody = () => {
  return {
    name: form.name,
    categoryId: form.categoryId ? Number(form.categoryId) : null,
    description: form.description,
    tags: form.tags,
    rating: form.rating === '' ? null : Number(form.rating),
    sold: form.sold === '' ? null : Number(form.sold),
    activityLabel: form.activityLabel,
    originalPrice: form.originalPrice === '' ? null : Number(form.originalPrice),
    price: Number(form.price),
    stock: Number(form.stock),
    status: Number(form.status),
    media: mediaText.value
      .split('\n')
      .map((line) => line.trim())
      .filter(Boolean),
    skus: parseSkus(),
  }
}

const parseSkus = () => {
  return skuText.value
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => JSON.parse(line))
}

const toggleStatus = async (product: Product) => {
  await api.put(`/v1/admin/products/${product.id}/status`, { status: product.status === 1 ? 0 : 1 })
  await load()
}

const remove = async (id: number) => {
  if (!window.confirm('确认删除该商品？')) return
  await api.delete(`/v1/admin/products/${id}`)
  await load()
}

const categoryName = (id?: number) => categories.value.find((item) => item.id === id)?.name || '未分类'
const money = (value: unknown) => Number(value || 0).toFixed(2)

onMounted(async () => {
  await loadCategories()
  await load()
})
</script>
