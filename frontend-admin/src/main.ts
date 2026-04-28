import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import { router } from './router'
import { useAuthStore } from './stores/auth'
import './style.css'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')

window.addEventListener('admin:unauthorized', () => {
  const auth = useAuthStore()
  auth.logout()
  router.push({ name: 'login', query: { redirect: router.currentRoute.value.fullPath } })
})
