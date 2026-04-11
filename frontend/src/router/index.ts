import { createRouter, createWebHistory } from 'vue-router'
import type { RouteLocationNormalized } from 'vue-router'

import { useTrackerStore } from '../stores/tracker'
import { useAuthStore } from '../stores/auth'
import { useToastStore } from '../stores/toast'

export const router = createRouter({
  history: createWebHistory(),
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.path === from.path) return
    return { top: 0, left: 0 }
  },
  routes: [
    {
      path: '/',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
      meta: { title: '首页', description: '元气购首页：精选推荐、分类入口与热销商品。' },
    },
    {
      path: '/category',
      name: 'category',
      component: () => import('../views/CategoryView.vue'),
      meta: { title: '类目', description: '元气购类目：按品类快速浏览商品。' },
    },
    {
      path: '/search',
      name: 'search',
      component: () => import('../views/SearchView.vue'),
      meta: { title: '搜索', description: '搜索元气购商品：支持关键词、排序与快速加购。' },
    },
    { path: '/cart', name: 'cart', component: () => import('../views/CartView.vue'), meta: { title: '购物车' } },
    { path: '/me', name: 'me', component: () => import('../views/MeView.vue'), meta: { title: '我的' } },

    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { title: '登录', hideNav: true, description: '登录元气购，查看订单、消息与优惠。' },
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
      meta: { title: '注册', hideNav: true, description: '注册元气购账号，开启购物体验。' },
    },
    {
      path: '/forgot-password',
      name: 'forgotPassword',
      component: () => import('../views/ForgotPasswordView.vue'),
      meta: { title: '忘记密码', hideNav: true },
    },
    {
      path: '/user-agreement',
      name: 'userAgreement',
      component: () => import('../views/UserAgreementView.vue'),
      meta: { title: '用户协议', hideNav: true },
    },
    {
      path: '/privacy-policy',
      name: 'privacyPolicy',
      component: () => import('../views/PrivacyPolicyView.vue'),
      meta: { title: '隐私政策', hideNav: true },
    },

    { path: '/phone', name: 'phone', component: () => import('../views/PhoneView.vue'), meta: { title: '手机' } },
    { path: '/computer', name: 'computer', component: () => import('../views/ComputerView.vue'), meta: { title: '电脑' } },
    { path: '/appliance', name: 'appliance', component: () => import('../views/ApplianceView.vue'), meta: { title: '家电' } },

    {
      path: '/products/:id',
      name: 'productDetail',
      component: () => import('../views/ProductDetailView.vue'),
      meta: { title: '商品详情', hideNav: true },
    },
    {
      path: '/checkout',
      name: 'checkout',
      component: () => import('../views/CheckoutView.vue'),
      meta: { title: '结算', hideNav: true, requiresAuth: true },
    },
    { path: '/pay-result', name: 'payResult', component: () => import('../views/PayResultView.vue'), meta: { title: '支付结果', hideNav: true } },

    {
      path: '/orders',
      name: 'orders',
      component: () => import('../views/OrdersView.vue'),
      meta: { title: '我的订单', hideNav: true },
    },
    {
      path: '/orders/:id',
      name: 'orderDetail',
      component: () => import('../views/OrderDetailView.vue'),
      meta: { title: '订单详情', hideNav: true },
    },
    {
      path: '/messages',
      name: 'messages',
      component: () => import('../views/MessagesView.vue'),
      meta: { title: '消息中心', hideNav: true, requiresAuth: true },
    },
    {
      path: '/aftersales',
      name: 'aftersales',
      component: () => import('../views/AftersalesView.vue'),
      meta: { title: '售后', hideNav: true, requiresAuth: true },
    },
    {
      path: '/aftersales/apply',
      name: 'aftersaleApply',
      component: () => import('../views/AftersaleApplyView.vue'),
      meta: { title: '申请售后', hideNav: true, requiresAuth: true },
    },
    {
      path: '/reviews/create',
      name: 'reviewCreate',
      component: () => import('../views/ReviewCreateView.vue'),
      meta: { title: '发布评价', hideNav: true },
    },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
})

const ensureMeta = (name: string) => {
  let el = document.querySelector(`meta[name="${name}"]`) as HTMLMetaElement | null
  if (!el) {
    el = document.createElement('meta')
    el.setAttribute('name', name)
    document.head.appendChild(el)
  }
  return el
}

const buildTitle = (to: RouteLocationNormalized) => {
  const t = typeof to.meta?.title === 'string' ? to.meta.title : ''
  if (!t) return '元气购'
  return `${t} - 元气购`
}

router.beforeEach((to) => {
  const auth = useAuthStore()
  if (to.meta?.requiresAuth && !auth.hasToken) {
    const toast = useToastStore()
    toast.push({ type: 'info', message: '请先登录后再进行操作' })
    return { name: 'login', query: { redirect: to.fullPath } }
  }
})

router.afterEach((to) => {
  document.title = buildTitle(to)

  const desc = typeof to.meta?.description === 'string' ? to.meta.description : '元气购：精选好物，安心服务。'
  ensureMeta('description').setAttribute('content', desc)

  const tracker = useTrackerStore()
  tracker.track('page_view', { name: String(to.name ?? ''), path: to.fullPath })
})
