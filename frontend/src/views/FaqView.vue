<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useToastStore } from '../stores/toast'

import backHelpIconUrl from '../assets/figma/faq/back-help.svg'
import chevronDownIconUrl from '../assets/figma/faq/chevron-down.svg'

type FaqCategory = 'all' | 'order' | 'payment' | 'shipping' | 'returns' | 'account'

type FaqItem = {
  id: string
  category: Exclude<FaqCategory, 'all'>
  question: string
  answer: string
}

const router = useRouter()
const toast = useToastStore()

const keyword = ref('')
const activeCategory = ref<FaqCategory>('all')
const openId = ref<string | null>(null)

const categories: { key: FaqCategory; label: string }[] = [
  { key: 'all', label: '全部' },
  { key: 'order', label: '订单相关' },
  { key: 'payment', label: '支付问题' },
  { key: 'shipping', label: '配送物流' },
  { key: 'returns', label: '退换货' },
  { key: 'account', label: '账号安全' },
]

const items: FaqItem[] = [
  {
    id: 'q1',
    category: 'order',
    question: '如何查看我的订单状态？',
    answer: '进入“我的”→“订单”，选择对应订单即可查看最新状态与物流信息。',
  },
  {
    id: 'q2',
    category: 'order',
    question: '下单后可以修改订单吗？',
    answer: '订单创建后部分信息可能无法修改。若需更改收货信息，请尽快联系在线客服协助处理。',
  },
  {
    id: 'q3',
    category: 'payment',
    question: '支持哪些支付方式？',
    answer: '支持在线支付、货到付款与分期付款。具体以结算页可选项为准。',
  },
  {
    id: 'q4',
    category: 'payment',
    question: '支付失败怎么办？',
    answer: '建议先确认余额/限额与网络状态，稍后重试或更换支付方式。仍失败可联系在线客服。',
  },
  {
    id: 'q5',
    category: 'shipping',
    question: '一般多久能收到货？',
    answer: '发货后通常 1–3 个工作日送达，偏远地区可能延长。具体以物流信息为准。',
  },
  {
    id: 'q6',
    category: 'shipping',
    question: '如何查询物流信息？',
    answer: '进入“我的”→“订单”→订单详情，可查看物流单号与最新轨迹。',
  },
  {
    id: 'q7',
    category: 'shipping',
    question: '可以指定配送时间吗？',
    answer: '部分地区支持配送时间预约。若结算页没有该选项，可在备注中填写或联系客服确认。',
  },
  {
    id: 'q8',
    category: 'returns',
    question: '商品可以退换货吗？',
    answer: '支持在规定时效内申请退换货。请在订单详情中发起售后，按流程提交原因与凭证。',
  },
  {
    id: 'q9',
    category: 'returns',
    question: '退货运费谁承担？',
    answer: '如因商品质量问题产生退货，运费通常由商家承担；非质量问题以售后规则为准。',
  },
  {
    id: 'q10',
    category: 'returns',
    question: '退款多久到账？',
    answer: '退款审核通过后，原路退回。到账时间与支付渠道有关，通常 1–7 个工作日。',
  },
  {
    id: 'q11',
    category: 'account',
    question: '忘记密码怎么办？',
    answer: '可在登录页通过手机号/邮箱验证重置密码。如无法验证请联系在线客服。',
  },
  {
    id: 'q12',
    category: 'account',
    question: '如何修改个人信息？',
    answer: '进入“我的”→“个人信息”即可修改头像、昵称等资料（以实际功能为准）。',
  },
  {
    id: 'q13',
    category: 'account',
    question: '账号安全如何保障？',
    answer: '建议开启安全验证、定期更换密码，避免在不可信设备登录；如发现异常请立即联系客服。',
  },
]

const filtered = computed(() => {
  const k = keyword.value.trim()
  return items.filter((x) => {
    if (activeCategory.value !== 'all' && x.category !== activeCategory.value) return false
    if (!k) return true
    return x.question.includes(k) || x.answer.includes(k)
  })
})

const toggle = (id: string) => {
  openId.value = openId.value === id ? null : id
}

const setCategory = (c: FaqCategory) => {
  activeCategory.value = c
  openId.value = null
}

const contactOnline = () => {
  toast.push({ type: 'info', message: '在线客服：功能开发中' })
}

const callHotline = () => {
  toast.push({ type: 'info', message: '客服热线：400-888-8888' })
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="常见问题" />

    <main class="main">
      <div class="wrap">
        <button class="backLink" type="button" @click="router.push({ name: 'helpCenter' })">
          <img class="backIcon" :src="backHelpIconUrl" alt="" aria-hidden="true" />
          <span>返回帮助中心</span>
        </button>

        <h1 class="title">常见问题</h1>
        <div class="sub">快速找到您想要的答案</div>

        <div class="search">
          <span class="searchIcon" aria-hidden="true"></span>
          <input v-model="keyword" class="searchInput" type="text" placeholder="搜索问题关键词..." />
        </div>

        <div class="tabs" role="tablist" aria-label="分类">
          <button
            v-for="c in categories"
            :key="c.key"
            class="tab"
            :class="{ on: activeCategory === c.key }"
            type="button"
            role="tab"
            :aria-selected="activeCategory === c.key"
            @click="setCategory(c.key)"
          >
            {{ c.label }}
          </button>
        </div>

        <div class="list" aria-label="问题列表">
          <div v-if="filtered.length === 0" class="empty">暂无匹配的问题</div>

          <div v-for="x in filtered" :key="x.id" class="item">
            <button class="itemBtn" type="button" :aria-expanded="openId === x.id" @click="toggle(x.id)">
              <div class="q">{{ x.question }}</div>
              <img class="chev" :class="{ up: openId === x.id }" :src="chevronDownIconUrl" alt="" aria-hidden="true" />
            </button>
            <div v-if="openId === x.id" class="answer">{{ x.answer }}</div>
          </div>
        </div>

        <section class="cta" aria-label="联系客服">
          <div class="ctaTitle">没有找到答案？</div>
          <div class="ctaSub">我们的客服团队随时为您服务</div>
          <div class="ctaBtns">
            <button class="ctaPrimary" type="button" @click="contactOnline">联系在线客服</button>
            <button class="ctaGhost" type="button" @click="callHotline">拨打客服热线</button>
          </div>
        </section>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  background: #f9fafb;
  display: flex;
  flex-direction: column;
}

.main {
  padding: 24px 16px 64px;
  flex: 1 1 auto;
}

.wrap {
  width: min(864px, 100%);
  margin: 0 auto;
}

.backLink {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: 0;
  background: transparent;
  padding: 0;
  cursor: pointer;
  color: #4a5565;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.backIcon {
  width: 20px;
  height: 20px;
}

.title {
  margin: 12px 0 8px;
  font: 600 30px/36px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.sub {
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
  margin-bottom: 18px;
}

.search {
  position: relative;
  width: 100%;
  height: 50px;
  border-radius: 16px;
  border: 1px solid #d1d5dc;
  background: #ffffff;
  display: flex;
  align-items: center;
  padding: 12px 16px 12px 48px;
}

.searchIcon {
  position: absolute;
  left: 16px;
  width: 20px;
  height: 20px;
  border-radius: 999px;
  box-sizing: border-box;
  border: 2px solid rgba(10, 10, 10, 0.5);
}

.searchIcon::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 2px;
  background: rgba(10, 10, 10, 0.5);
  right: -7px;
  bottom: -4px;
  transform: rotate(45deg);
  border-radius: 2px;
}

.searchInput {
  width: 100%;
  border: 0;
  outline: none;
  background: transparent;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.tabs {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin: 20px 0 18px;
}

.tab {
  height: 36px;
  padding: 0 16px;
  border-radius: 999px;
  border: 0;
  background: #ffffff;
  cursor: pointer;
  color: #364153;
  font: 500 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.tab.on {
  background: #9810fa;
  color: #ffffff;
}

.list {
  display: grid;
  gap: 12px;
}

.item {
  background: #ffffff;
  border-radius: 16px;
  overflow: hidden;
}

.itemBtn {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  border: 0;
  background: transparent;
  cursor: pointer;
  text-align: left;
}

.q {
  font: 500 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #101828;
  padding-right: 16px;
}

.chev {
  width: 20px;
  height: 20px;
  flex: 0 0 auto;
  transition: transform 0.16s ease;
}

.chev.up {
  transform: rotate(180deg);
}

.answer {
  padding: 0 24px 18px;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.empty {
  padding: 18px 16px;
  border-radius: 16px;
  background: #ffffff;
  color: #4a5565;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.cta {
  margin-top: 22px;
  background: #ffffff;
  border-radius: 16px;
  padding: 24px;
}

.ctaTitle {
  color: #0a0a0a;
  font: 600 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.ctaSub {
  margin-top: 4px;
  color: #4a5565;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.ctaBtns {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  margin-top: 16px;
}

.ctaPrimary,
.ctaGhost {
  height: 40px;
  padding: 0 16px;
  border-radius: 10px;
  cursor: pointer;
  font: 400 16px/24px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
}

.ctaPrimary {
  border: 0;
  background: #9810fa;
  color: #ffffff;
}

.ctaGhost {
  border: 1px solid #d1d5dc;
  background: #ffffff;
  color: #9810fa;
}
</style>
