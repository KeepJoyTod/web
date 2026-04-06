import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'

import { router } from './router'
import { useAuthStore } from './stores/auth'
import { useToastStore } from './stores/toast'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')

window.addEventListener('app:unauthorized', () => {
  const auth = useAuthStore()
  const toast = useToastStore()
  auth.logout()
  toast.push({ type: 'info', message: '请先登录后再进行操作' })
  router.push({ name: 'login', query: { redirect: router.currentRoute.value.fullPath } })
})
