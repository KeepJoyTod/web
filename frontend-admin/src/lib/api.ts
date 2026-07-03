import axios from 'axios'

const baseURL = import.meta.env.VITE_API_BASE || '/api'

export const api = axios.create({
  baseURL,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

export const setAuthToken = (token: string | null) => {
  if (token) {
    api.defaults.headers.common.Authorization = `Bearer ${token}`
  } else {
    delete api.defaults.headers.common.Authorization
  }
}

api.interceptors.response.use(
  (response) => {
    const code = response.data?.code
    if (typeof code === 'number' && code !== 200) {
      const error = new Error(response.data?.message || '请求失败') as Error & { response?: unknown; code?: number }
      error.response = response
      error.code = code
      return Promise.reject(error)
    }
    return response
  },
  (error) => {
    const code = error?.response?.data?.error?.code
    if (code === 'UNAUTHORIZED' || code === 'FORBIDDEN') {
      window.dispatchEvent(new CustomEvent('admin:unauthorized'))
    }
    return Promise.reject(error)
  },
)

export const unwrap = <T = any>(response: { data: { data: T } }) => response.data.data
