import { computed, ref, watch } from 'vue'
import { defineStore } from 'pinia'
import { api, setAuthToken, unwrap } from '../lib/api'

type AdminUser = {
  id: number
  account: string
  nickname?: string
  role: string
}

type Snapshot = {
  user: AdminUser | null
  token: string | null
  expiresAt: number | null
}

const STORAGE_KEY = 'projectku-admin-auth:v1'

const readSnapshot = (): Snapshot => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { user: null, token: null, expiresAt: null }
    const parsed = JSON.parse(raw) as Snapshot
    if (parsed.expiresAt && parsed.expiresAt < Date.now()) {
      return { user: null, token: null, expiresAt: null }
    }
    return {
      user: parsed.user ?? null,
      token: parsed.token ?? null,
      expiresAt: parsed.expiresAt ?? null,
    }
  } catch {
    return { user: null, token: null, expiresAt: null }
  }
}

export const useAuthStore = defineStore('admin-auth', () => {
  const snapshot = ref<Snapshot>(readSnapshot())
  setAuthToken(snapshot.value.token)

  const user = computed(() => snapshot.value.user)
  const token = computed(() => snapshot.value.token)
  const isLoggedIn = computed(() => Boolean(snapshot.value.user && snapshot.value.token))

  const login = async (account: string, password: string) => {
    const data = unwrap<{ token: string; expiresIn: number; user: AdminUser }>(
      await api.post('/v1/admin/auth/login', { account, password }),
    )
    snapshot.value = {
      user: data.user,
      token: data.token,
      expiresAt: Date.now() + data.expiresIn * 1000,
    }
    setAuthToken(data.token)
  }

  const logout = () => {
    snapshot.value = { user: null, token: null, expiresAt: null }
    setAuthToken(null)
  }

  watch(
    snapshot,
    (value) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(value))
    },
    { deep: true },
  )

  return { user, token, isLoggedIn, login, logout }
})
