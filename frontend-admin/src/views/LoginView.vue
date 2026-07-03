<template>
  <div class="login-shell">
    <section class="login-panel">
      <center><h1 class="login-title">元气购电商后台管理</h1></center>
      <p class="login-subtitle">默认管理员：admin@example.com / admin123</p>

      <form @submit.prevent="submit">
        <div class="field">
          <label for="account">账号</label>
          <input id="account" v-model.trim="account" class="input" autocomplete="username" />
        </div>
        <div class="field" style="margin-top: 12px">
          <label for="password">密码</label>
          <input id="password" v-model="password" class="input" type="password" autocomplete="current-password" />
        </div>

        <div v-if="error" class="alert" style="margin-top: 14px">{{ error }}</div>

        <button class="btn" type="submit" style="width: 100%; margin-top: 18px" :disabled="loading">
          {{ loading ? '登录中...' : '登录' }}
        </button>
      </form>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

const account = ref('admin@example.com')
const password = ref('admin123')
const loading = ref(false)
const error = ref('')

const submit = async () => {
  error.value = ''
  if (!account.value || !password.value) {
    error.value = '请输入账号和密码'
    return
  }

  loading.value = true
  try {
    await auth.login(account.value, password.value)
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
    router.replace(redirect)
  } catch (err: any) {
    error.value = err?.response?.data?.error?.message || err?.message || '登录失败'
  } finally {
    loading.value = false
  }
}
</script>
