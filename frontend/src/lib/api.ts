import axios from 'axios'

const base = (import.meta as any).env?.VITE_API_BASE || '/api'

export const api = axios.create({
  baseURL: base,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

export const setAuthToken = (token: string | null) => {
  if (token) {
    api.defaults.headers.common['Authorization'] = `Bearer ${token}`
  } else {
    delete api.defaults.headers.common['Authorization']
  }
}

export const withIdempotency = () => {
  const key = crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}_${Math.random().toString(16).slice(2)}`
  return { 'Idempotency-Key': key }
}

api.interceptors.response.use(
  (resp) => {
    const code = resp?.data?.code
    if (typeof code === 'number' && code !== 200) {
      if (code === 401) {
        window.dispatchEvent(new CustomEvent('app:unauthorized'))
      }
      const msg = resp?.data?.message || resp?.data?.error?.message || '请求失败'
      const err = new Error(msg) as any
      err.response = resp
      err.code = code
      return Promise.reject(err)
    }
    return resp
  },
  (err) => {
    const status = err?.response?.status
    const ecode = err?.response?.data?.error?.code
    if (status === 401 || ecode === 'UNAUTHORIZED') {
      window.dispatchEvent(new CustomEvent('app:unauthorized'))
    }
    return Promise.reject(err)
  },
)
