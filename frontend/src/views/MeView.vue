<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'

import { useAuthStore } from '../stores/auth'
import { useNotificationsStore } from '../stores/notifications'

const router = useRouter()
const auth = useAuthStore()
const notifications = useNotificationsStore()

const nickname = computed(() => auth.user?.nickname ?? '未登录')
const unread = computed(() => notifications.unreadCount)

const goLogin = () => {
  router.push({ name: 'login', query: { redirect: router.currentRoute.value.fullPath } })
}

const goRegister = () => {
  router.push({ name: 'register', query: { redirect: router.currentRoute.value.fullPath } })
}

const goAuthed = (name: string) => {
  if (!auth.isLoggedIn) {
    router.push({ name: 'login', query: { redirect: router.currentRoute.value.fullPath } })
    return
  }
  router.push({ name })
}

const logout = () => {
  const ok = window.confirm('确认退出登录？')
  if (ok) auth.logout()
}
</script>

<template>
  <div class="page">
    <h1 class="title">我的</h1>
    <div class="card">
      <div class="row">
        <div class="name">{{ nickname }}</div>
        <span class="badge" :class="{ on: auth.isLoggedIn }">{{ auth.isLoggedIn ? '已登录' : '未登录' }}</span>
      </div>

      <p class="desc">登录后可查看订单、地址与消息</p>

      <div class="actions" v-if="!auth.isLoggedIn">
        <button class="primary" type="button" @click="goLogin">去登录</button>
        <button class="ghost" type="button" @click="goRegister">去注册</button>
      </div>
      <div class="actions" v-else>
        <button class="ghost" type="button" @click="logout">退出登录</button>
      </div>
    </div>

    <div class="card">
      <div class="row">
        <div class="name">功能入口</div>
      </div>
      <div class="entries" aria-label="个人中心入口">
        <button class="entry" type="button" @click="goAuthed('orders')">
          <span>我的订单</span>
          <span class="arrow">›</span>
        </button>
        <button class="entry" type="button" @click="goAuthed('favorites')">
          <span>我的收藏</span>
          <span class="arrow">›</span>
        </button>
        <button class="entry" type="button" @click="goAuthed('messages')">
          <span>消息中心</span>
          <span class="right">
            <span v-if="unread > 0" class="unread" aria-label="未读消息数">{{ unread > 99 ? '99+' : unread }}</span>
            <span class="arrow">›</span>
          </span>
        </button>
        <button class="entry" type="button" @click="goAuthed('aftersales')">
          <span>售后</span>
          <span class="arrow">›</span>
        </button>
        <button class="entry" type="button" @click="router.push({ name: 'helpCenter' })">
          <span>帮助中心</span>
          <span class="arrow">›</span>
        </button>
      
      </div>
    </div>
  </div>
</template>

<style scoped>
.page {
  padding: 18px 16px 28px;
}

.title {
  margin: 0 0 10px;
  font-size: 20px;
  color: var(--text-h);
}

.desc {
  margin: 0;
  color: var(--text);
}

.card {
  margin-top: 12px;
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 14px;
  background: var(--bg);
  box-shadow: var(--shadow);
  display: grid;
  gap: 12px;
}

.row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.name {
  color: var(--text-h);
  font-weight: 900;
}

.badge {
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 4px 10px;
  font-size: 12px;
  color: var(--text);
  background: color-mix(in srgb, var(--code-bg) 70%, transparent);
}

.badge.on {
  color: var(--text-h);
  border-color: color-mix(in srgb, var(--accent) 50%, var(--border));
  background: var(--accent-bg);
}

.actions {
  display: flex;
  gap: 10px;
}

.entries {
  display: grid;
  gap: 10px;
}

.entry {
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 12px 12px;
  background: color-mix(in srgb, var(--code-bg) 55%, transparent);
  color: var(--text-h);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  cursor: pointer;
}

.right {
  display: inline-flex;
  align-items: center;
  gap: 10px;
}

.unread {
  min-width: 22px;
  height: 22px;
  border-radius: 999px;
  padding: 0 8px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  font-size: 12px;
  color: #fff;
  background: var(--accent);
}

.arrow {
  color: var(--text);
  font-size: 18px;
  line-height: 1;
}

.primary {
  border: 0;
  border-radius: 12px;
  padding: 12px 14px;
  font-size: 14px;
  font-weight: 900;
  color: #fff;
  background: var(--accent);
  cursor: pointer;
  flex: 1 1 auto;
}

.ghost {
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 12px 14px;
  font-size: 14px;
  background: var(--bg);
  color: var(--text-h);
  cursor: pointer;
  flex: 1 1 auto;
}
</style>
