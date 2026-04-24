import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'
import { api, setAuthToken } from '../lib/api'

type AuthSnapshotV2 =
  | {
      v: 2
      user: { id: string; nickname: string } | null
      token: string | null
      expiresAt: number | null
    }
  | { v: 1; user: { id: string; nickname: string } | null }

const STORAGE_KEY = 'auth:v1'

const readSnapshot = (): AuthSnapshotV2 => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { v: 2, user: null, token: null, expiresAt: null }
    const parsed = JSON.parse(raw) as AuthSnapshotV2
    if ((parsed as any)?.v === 1) {
      return { v: 2, user: (parsed as any).user ?? null, token: null, expiresAt: null }
    }
    if (parsed?.v === 2) {
      return {
        v: 2,
        user: parsed.user ?? null,
        token: parsed.token ?? null,
        expiresAt: parsed.expiresAt ?? null,
      }
    }
    return { v: 2, user: null, token: null, expiresAt: null }
  } catch {
    return { v: 2, user: null, token: null, expiresAt: null }
  }
}

export const useAuthStore = defineStore('auth', () => {
  const snapshot = ref<AuthSnapshotV2>(readSnapshot())
  setAuthToken(snapshot.value && (snapshot.value as any).token ? (snapshot.value as any).token : null)

  const user = computed(() => (snapshot.value as any).user)
  const token = computed(() => ((snapshot.value as any).token as string | null) || null)
  const hasToken = computed(() => Boolean(token.value))
  const isLoggedIn = computed(() => Boolean((snapshot.value as any).user) && hasToken.value)

  const loginWithAccount = async (account: string, password?: string) => {
    if (password && password.length >= 6) {
      const res = await api.post('/v1/auth/login', { account, password })
      const data = res.data?.data
      const token: string | null = data?.token ?? null
      const expiresIn: number | null = data?.expiresIn ?? null
      const u = data?.user ?? null
      const expiresAt = expiresIn ? Date.now() + expiresIn * 1000 : null
      snapshot.value = { v: 2, user: u, token, expiresAt }
      setAuthToken(token)
      return
    }
    const nickname = account.includes('@') ? account.split('@')[0] || '用户' : '用户'
    snapshot.value = { v: 2, user: { id: 'u_mock', nickname }, token: null, expiresAt: null }
    setAuthToken(null)
  }

  const loginMock = () => loginWithAccount('user@example.com')

  const logout = () => {
    snapshot.value = { v: 2, user: null, token: null, expiresAt: null }
    setAuthToken(null)
  }

  watch(
    snapshot,
    (v) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
    },
    { deep: true },
  )

  return { user, token, hasToken, isLoggedIn, loginWithAccount, loginMock, logout }
})
