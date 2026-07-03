import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { title: '登录' },
    },
    {
      path: '/',
      component: () => import('../layouts/AdminLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        { path: '', name: 'dashboard', component: () => import('../views/DashboardView.vue'), meta: { title: '工作台' } },
        { path: 'products', name: 'products', component: () => import('../views/ProductsView.vue'), meta: { title: '商品管理' } },
        { path: 'categories', name: 'categories', component: () => import('../views/CategoriesView.vue'), meta: { title: '分类管理' } },
        { path: 'orders', name: 'orders', component: () => import('../views/OrdersView.vue'), meta: { title: '订单管理' } },
        { path: 'aftersales', name: 'aftersales', component: () => import('../views/AftersalesView.vue'), meta: { title: '售后管理' } },
        { path: 'users', name: 'users', component: () => import('../views/UsersView.vue'), meta: { title: '用户管理' } },
      ],
    },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.name === 'login' && auth.isLoggedIn) {
    return { name: 'dashboard' }
  }
})

router.afterEach((to) => {
  const title = typeof to.meta.title === 'string' ? to.meta.title : '后台管理'
  document.title = `${title} - ProjectKu 后台管理`
})
