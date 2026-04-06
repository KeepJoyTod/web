<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiInput from '../components/ui/UiInput.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useAuthStore } from '../stores/auth'
import { api } from '../lib/api'

type Mode = 'phone' | 'email'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const mode = ref<Mode>('phone')
const phone = ref('')
const email = ref('')
const code = ref('')
const password = ref('')
const confirmPassword = ref('')
const company = ref('')
const agree = ref(true)

const submitState = ref<'idle' | 'submitting'>('idle')
const codeState = ref<{ sending: boolean; secondsLeft: number }>({ sending: false, secondsLeft: 0 })
const errorText = ref<string | null>(null)

const redirectTo = computed(() => {
  const raw = route.query.redirect
  return typeof raw === 'string' && raw.startsWith('/') ? raw : '/'
})

const activeAccount = computed(() => {
  if (mode.value === 'phone') return phone.value.trim()
  return email.value.trim()
})

const accountOk = computed(() => {
  if (mode.value === 'phone') return /^1\d{10}$/.test(phone.value.trim())
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.value.trim())
})

const passwordOk = computed(() => password.value.length >= 6)
const confirmOk = computed(() => confirmPassword.value.length > 0 && confirmPassword.value === password.value)
const codeOk = computed(() => /^\d{4,8}$/.test(code.value.trim()))

const canSendCode = computed(() => {
  if (!accountOk.value) return false
  if (codeState.value.sending || codeState.value.secondsLeft > 0) return false
  return true
})

const canSubmit = computed(() => {
  if (submitState.value === 'submitting') return false
  if (!agree.value) return false
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
    if (!confirmOk.value) throw new Error('两次输入的密码不一致')
    if (!agree.value) throw new Error('请先同意用户协议与隐私政策')

    const account = activeAccount.value
    const nickname =
      mode.value === 'email'
        ? account.split('@')[0] || '用户'
        : account ? `用户${account.slice(-4)}` : '用户'

    await api.post('/v1/auth/register', { account, password: password.value, nickname })
    await auth.loginWithAccount(account, password.value)
    await router.replace(redirectTo.value)
  } catch (e) {
    const msg =
      (e as any)?.response?.data?.error?.message ||
      (e as any)?.message ||
      '注册失败，请重试'
    errorText.value = msg
  } finally {
    submitState.value = 'idle'
  }
}

const goLogin = () => {
  router.replace({ name: 'login', query: { redirect: redirectTo.value } })
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
    <UiPageHeader title="注册" />

    <main class="main" aria-live="polite">
      <section class="card" aria-label="注册表单">
        <div class="hero">
          <div class="heroTitle">创建企业账号</div>
          <div class="heroSub">支持手机号 / 邮箱注册，注册后可同步消息、订单与优惠</div>
        </div>

        <div class="tabs" role="tablist" aria-label="注册方式">
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
            <label class="label" for="password">设置密码</label>
            <UiInput
              id="password"
              v-model="password"
              type="password"
              autocomplete="new-password"
              placeholder="至少 6 位，建议包含数字与字母"
            />
          </div>

          <div class="field">
            <label class="label" for="confirm">确认密码</label>
            <UiInput
              id="confirm"
              v-model="confirmPassword"
              type="password"
              autocomplete="new-password"
              placeholder="再次输入密码"
            />
          </div>

          <div class="field">
            <label class="label" for="company">企业名称（可选）</label>
            <UiInput
              id="company"
              v-model="company"
              autocomplete="organization"
              placeholder="填写用于开票/归属"
            />
          </div>

          <label class="agree">
            <input v-model="agree" class="checkbox" type="checkbox" />
            <span class="agreeText">
              我已阅读并同意
              <a class="link" href="#" @click.prevent="goAgreement">用户协议</a>
              与
              <a class="link" href="#" @click.prevent="goPrivacy">隐私政策</a>
            </span>
          </label>

          <div v-if="errorText" class="error" role="alert">{{ errorText }}</div>

          <UiButton variant="primary" type="submit" :disabled="!canSubmit" :loading="submitState === 'submitting'">
            注册并登录
          </UiButton>

          <div class="footer">
            <span class="muted">已有账号？</span>
            <UiButton size="sm" type="button" @click="goLogin">去登录</UiButton>
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
  width: min(560px, 100%);
  border: 1px solid var(--border);
  border-radius: 18px;
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
  letter-spacing: 0.2px;
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

.agree {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: 12px;
  background: color-mix(in srgb, var(--code-bg) 70%, transparent);
}

.checkbox {
  margin-top: 2px;
}

.agreeText {
  font-size: 12px;
  color: var(--text);
  line-height: 1.35;
}

.link {
  color: var(--accent);
  text-decoration: none;
}

.error {
  border: 1px solid color-mix(in srgb, var(--danger) 35%, var(--border));
  background: var(--danger-bg);
  border-radius: var(--radius-sm);
  padding: 10px 12px;
  color: var(--text-h);
  font-size: var(--font-sm);
}

.footer {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: center;
  padding-top: 4px;
}

.muted {
  font-size: 12px;
  color: var(--text);
}
</style>
