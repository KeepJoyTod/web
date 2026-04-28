<template>
  <div class="admin-shell">
    <aside class="sidebar">
      <div class="brand">
        <strong>元气购</strong>
        <span>电商后台管理</span>
      </div>
      <nav class="nav">
        <RouterLink to="/">工作台</RouterLink>
        <RouterLink to="/products">商品</RouterLink>
        <RouterLink to="/categories">分类</RouterLink>
        <RouterLink to="/orders">订单</RouterLink>
        <RouterLink to="/aftersales">售后</RouterLink>
        <RouterLink to="/users">用户</RouterLink>
      </nav>
    </aside>

    <div class="main">
      <header class="topbar">
        <div class="topbar-title">{{ title }}</div>
        <div class="topbar-user">
          <span>{{ auth.user?.nickname || auth.user?.account }}</span>
          <button class="btn secondary" type="button" @click="logout">退出</button>
        </div>
      </header>
      <main class="content">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const title = computed(() => (typeof route.meta.title === 'string' ? route.meta.title : '后台管理'))

const logout = () => {
  auth.logout()
  router.push({ name: 'login' })
}
</script>
