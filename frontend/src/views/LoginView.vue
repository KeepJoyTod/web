<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useAuthStore } from '../stores/auth'

type Mode = 'code' | 'password'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const mode = ref<Mode>('password')
const account = ref('')
const code = ref('')
const password = ref('')
const agree = ref(true)
const accountTouched = ref(false)

const submitState = ref<'idle' | 'submitting'>('idle')
const codeState = ref<{ sending: boolean; secondsLeft: number }>({ sending: false, secondsLeft: 0 })
const errorText = ref<string | null>(null)

const redirectTo = computed(() => {
  const raw = route.query.redirect
  return typeof raw === 'string' && raw.startsWith('/') ? raw : '/'
})

const activeAccount = computed(() => account.value.trim())

const accountOk = computed(() => {
  const v = account.value.trim()
  if (/^1\d{10}$/.test(v)) return true
  if (/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v)) return true
  return false
})

const accountWarn = computed(() => {
  const v = activeAccount.value
  if (!v) return null
  if (accountOk.value) return null
  if (!accountTouched.value) return null
  return '只能填写手机号或邮箱'
})

const canSendCode = computed(() => {
  if (codeState.value.sending || codeState.value.secondsLeft > 0) return false
  if (mode.value !== 'code') return false
  return accountOk.value
})

const canSubmit = computed(() => {
  if (submitState.value === 'submitting') return false
  if (!agree.value) return false
  if (!accountOk.value) return false
  if (mode.value === 'code') return /^\d{4,8}$/.test(code.value.trim())
  return password.value.length >= 6
})

const setMode = (next: Mode) => {
  if (mode.value === next) return
  mode.value = next
  errorText.value = null
  code.value = ''
  password.value = ''
}

const tick = () => {
  if (codeState.value.secondsLeft <= 0) return
  codeState.value = { ...codeState.value, secondsLeft: codeState.value.secondsLeft - 1 }
  if (codeState.value.secondsLeft - 1 > 0) {
    window.setTimeout(tick, 1000)
  }
}

const sendCode = async () => {
  if (!canSendCode.value) return
  errorText.value = null
  codeState.value = { sending: true, secondsLeft: 0 }
  await new Promise((r) => window.setTimeout(r, 450))
  codeState.value = { sending: false, secondsLeft: 60 }
  window.setTimeout(tick, 1000)
}

const submit = async () => {
  accountTouched.value = true
  if (!accountOk.value) {
    errorText.value = '只能填写手机号或邮箱'
    return
  }
  if (!canSubmit.value) return
  errorText.value = null
  submitState.value = 'submitting'

  try {
    await new Promise((r) => window.setTimeout(r, 500))

    if (mode.value === 'password' && password.value.length < 6) {
      throw new Error('密码至少 6 位')
    }
    if (!agree.value) {
      throw new Error('请先同意用户协议与隐私政策')
    }

    if (mode.value === 'password') {
      await auth.loginWithAccount(activeAccount.value || 'user@example.com', password.value)
    } else {
      await auth.loginWithAccount(activeAccount.value || 'user@example.com')
    }
    await router.replace(redirectTo.value)
  } catch (e) {
    const msg =
      (e as any)?.response?.data?.error?.message ||
      (e as any)?.message ||
      '登录失败，请重试'
    errorText.value = msg
  } finally {
    submitState.value = 'idle'
  }
}

const goRegister = () => {
  router.replace({ name: 'register', query: { redirect: redirectTo.value } })
}

const goForgot = () => {
  router.replace({ name: 'forgotPassword', query: { redirect: redirectTo.value } })
}

const goAgreement = () => {
  router.push({ name: 'userAgreement', query: { redirect: redirectTo.value } })
}

const goPrivacy = () => {
  router.push({ name: 'privacyPolicy', query: { redirect: redirectTo.value } })
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="登录" />

    <main class="main" aria-live="polite">
      <section class="card" aria-label="登录表单">
        <div class="tabs" role="tablist" aria-label="登录方式">
          <button
            class="tab"
            :class="{ active: mode === 'password' }"
            type="button"
            role="tab"
            :aria-selected="mode === 'password'"
            @click="setMode('password')"
          >
            密码登录
          </button>
          <button
            class="tab"
            :class="{ active: mode === 'code' }"
            type="button"
            role="tab"
            :aria-selected="mode === 'code'"
            @click="setMode('code')"
          >
            验证码登录
          </button>
        </div>

        <form class="form" @submit.prevent="submit">
          <div class="field">
            <label class="label" for="account">手机号/邮箱</label>
            <UiInput
              id="account"
              v-model="account"
              inputmode="email"
              autocomplete="username"
              placeholder="请输入手机号或邮箱"
              @blur="accountTouched = true"
            />
            <div v-if="accountWarn" class="fieldError" role="alert">{{ accountWarn }}</div>
          </div>

          <div v-if="mode === 'password'" class="field">
            <label class="label" for="password">密码</label>
            <UiInput
              id="password"
              v-model="password"
              type="password"
              autocomplete="current-password"
              placeholder="请输入密码（至少 6 位）"
            />
            <div class="helper">
              <button class="linkBtn" type="button" @click="goForgot">忘记密码</button>
            </div>
          </div>

          <div v-else class="field">
            <label class="label" for="code">验证码</label>
            <div class="row">
              <UiInput
                id="code"
                v-model="code"
                inputmode="numeric"
                autocomplete="one-time-code"
                placeholder="请输入验证码"
              />
              <UiButton size="sm" type="button" :disabled="!canSendCode" @click="sendCode">
                <span v-if="codeState.sending">发送中</span>
                <span v-else-if="codeState.secondsLeft > 0">{{ codeState.secondsLeft }}s</span>
                <span v-else>获取验证码</span>
              </UiButton>
            </div>
          </div>

          <div v-if="errorText" class="error" role="alert">{{ errorText }}</div>

          <UiButton variant="primary" type="submit" :disabled="!canSubmit" :loading="submitState === 'submitting'">
            登录
          </UiButton>

          <label class="agree">
            <input v-model="agree" class="checkbox" type="checkbox" />
            <span class="agreeText">
              我已阅读并同意
              <a class="link" href="#" @click.prevent="goAgreement">用户协议</a>
              与
              <a class="link" href="#" @click.prevent="goPrivacy">隐私政策</a>
            </span>
          </label>

          <div class="footer">
            <span class="muted">没有账号？</span>
            <UiButton size="sm" type="button" @click="goRegister">去注册</UiButton>
          </div>
        </form>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  display: flex;
  flex-direction: column;
}

.main {
  padding: 18px 16px 28px;
  display: grid;
  place-items: start center;
}

.card {
  width: min(520px, 100%);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--bg);
  overflow: hidden;
}

.tabs {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  border-bottom: 1px solid var(--border);
}

.tab {
  border: 0;
  background: transparent;
  padding: 14px 12px;
  cursor: pointer;
  color: var(--text);
  font-weight: 650;
}

.tab.active {
  color: var(--text-h);
  background: color-mix(in srgb, var(--code-bg) 70%, transparent);
}

.form {
  padding: 16px;
  display: grid;
  gap: 12px;
}

.field {
  display: grid;
  gap: 8px;
}

.label {
  font-size: var(--font-sm);
  color: var(--text);
}

.row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 10px;
  align-items: center;
}

.error {
  border: 1px solid color-mix(in srgb, var(--danger) 35%, var(--border));
  background: var(--danger-bg);
  border-radius: var(--radius-sm);
  padding: 10px 12px;
  color: var(--text-h);
  font-size: var(--font-sm);
}

.fieldError {
  color: color-mix(in srgb, var(--danger) 80%, var(--text));
  font-size: 12px;
}

.muted {
  color: var(--text);
}

.link {
  color: var(--accent);
  text-decoration: none;
}

.agree {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: color-mix(in srgb, var(--code-bg) 70%, transparent);
  justify-content: center;
}

.checkbox {
  margin-top: 2px;
}

.agreeText {
  font-size: 12px;
  color: var(--text);
  line-height: 1.35;
}

.helper {
  display: flex;
  justify-content: flex-end;
}

.linkBtn {
  border: 0;
  background: transparent;
  padding: 4px 0;
  color: var(--accent);
  cursor: pointer;
  font-size: 13px;
}

.footer {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: center;
  padding-top: 2px;
}
</style>
