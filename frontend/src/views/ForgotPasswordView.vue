<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'

type Mode = 'phone' | 'email'

const router = useRouter()
const route = useRoute()

const mode = ref<Mode>('phone')
const phone = ref('')
const email = ref('')
const code = ref('')
const password = ref('')
const confirmPassword = ref('')

const submitState = ref<'idle' | 'submitting'>('idle')
const codeState = ref<{ sending: boolean; secondsLeft: number }>({ sending: false, secondsLeft: 0 })
const errorText = ref<string | null>(null)

const redirectTo = computed(() => {
  const raw = route.query.redirect
  return typeof raw === 'string' && raw.startsWith('/') ? raw : '/'
})

const accountOk = computed(() => {
  if (mode.value === 'phone') return /^1\d{10}$/.test(phone.value.trim())
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim())
})

const codeOk = computed(() => /^\d{4,8}$/.test(code.value.trim()))
const passwordOk = computed(() => password.value.length >= 6)
const confirmOk = computed(() => confirmPassword.value.length > 0 && confirmPassword.value === password.value)

const canSendCode = computed(() => {
  if (!accountOk.value) return false
  if (codeState.value.sending || codeState.value.secondsLeft > 0) return false
  return true
})

const canSubmit = computed(() => {
  if (submitState.value === 'submitting') return false
  return accountOk.value && codeOk.value && passwordOk.value && confirmOk.value
})

const setMode = (next: Mode) => {
  if (mode.value === next) return
  mode.value = next
  errorText.value = null
  code.value = ''
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
  if (!canSubmit.value) return
  errorText.value = null
  submitState.value = 'submitting'

  try {
    await new Promise((r) => window.setTimeout(r, 550))

    if (!confirmOk.value) throw new Error('两次输入的密码不一致')

    window.alert('密码已重置，请使用新密码登录')
    await router.replace({ name: 'login', query: { redirect: redirectTo.value } })
  } catch (e) {
    errorText.value = e instanceof Error ? e.message : '重置失败，请重试'
  } finally {
    submitState.value = 'idle'
  }
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="忘记密码" />

    <main class="main" aria-live="polite">
      <section class="card" aria-label="重置密码表单">
        <div class="hero">
          <div class="heroTitle">找回账号</div>
          <div class="heroSub">通过验证码验证身份后设置新密码</div>
        </div>

        <div class="tabs" role="tablist" aria-label="找回方式">
          <button
            class="tab"
            :class="{ active: mode === 'phone' }"
            type="button"
            role="tab"
            :aria-selected="mode === 'phone'"
            @click="setMode('phone')"
          >
            手机号
          </button>
          <button
            class="tab"
            :class="{ active: mode === 'email' }"
            type="button"
            role="tab"
            :aria-selected="mode === 'email'"
            @click="setMode('email')"
          >
            邮箱
          </button>
        </div>

        <form class="form" @submit.prevent="submit">
          <div v-if="mode === 'phone'" class="field">
            <label class="label" for="phone">手机号</label>
            <UiInput
              id="phone"
              v-model="phone"
              inputmode="tel"
              autocomplete="tel"
              placeholder="请输入手机号"
            />
          </div>
          <div v-else class="field">
            <label class="label" for="email">邮箱</label>
            <UiInput
              id="email"
              v-model="email"
              inputmode="email"
              autocomplete="email"
              placeholder="请输入邮箱"
            />
          </div>

          <div class="field">
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

          <div class="field">
            <label class="label" for="password">新密码</label>
            <UiInput
              id="password"
              v-model="password"
              type="password"
              autocomplete="new-password"
              placeholder="至少 6 位"
            />
          </div>

          <div class="field">
            <label class="label" for="confirm">确认新密码</label>
            <UiInput
              id="confirm"
              v-model="confirmPassword"
              type="password"
              autocomplete="new-password"
              placeholder="再次输入新密码"
            />
          </div>

          <div v-if="errorText" class="error" role="alert">{{ errorText }}</div>

          <UiButton variant="primary" type="submit" :disabled="!canSubmit" :loading="submitState === 'submitting'">
            重置密码
          </UiButton>
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
  width: min(560px, 100%);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--bg);
  overflow: hidden;
  box-shadow: var(--shadow);
}

.hero {
  padding: 18px 16px 14px;
  background:
    radial-gradient(1200px 380px at 0% 0%, color-mix(in srgb, var(--accent) 20%, transparent), transparent),
    linear-gradient(180deg, color-mix(in srgb, var(--code-bg) 60%, transparent), transparent);
  border-bottom: 1px solid var(--border);
}

.heroTitle {
  font-weight: 900;
  color: var(--text-h);
}

.heroSub {
  margin-top: 6px;
  font-size: 13px;
  color: var(--text);
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
</style>
