<script setup lang="ts">
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useToastStore } from '../stores/toast'
import { useRouter } from 'vue-router'

import helpAfterSalesIconUrl from '../assets/figma/help-center/help-aftersales.svg'
import helpFaqIconUrl from '../assets/figma/help-center/help-faq.svg'
import helpGuideIconUrl from '../assets/figma/help-center/help-guide.svg'
import helpSupportIconUrl from '../assets/figma/help-center/help-support.svg'

const router = useRouter()
const toast = useToastStore()

type HelpCard = {
  key: string
  title: string
  desc: string
  actionText: string
  iconUrl: string
}

const cards: HelpCard[] = [
  { key: 'faq', title: '常见问题', desc: '查看常见问题解答', actionText: '了解更多 →', iconUrl: helpFaqIconUrl },
  { key: 'guide', title: '购物指南', desc: '了解购物流程和注意事项', actionText: '了解更多 →', iconUrl: helpGuideIconUrl },
  { key: 'support', title: '在线客服', desc: '联系客服获取帮助', actionText: '了解更多 →', iconUrl: helpSupportIconUrl },
  { key: 'aftersales', title: '售后服务', desc: '退换货和售后服务', actionText: '了解更多 →', iconUrl: helpAfterSalesIconUrl },
]

const footerCols = [
  { title: '购物指南', items: ['购物流程', '会员介绍', '常见问题', '联系客服'] },
  { title: '配送方式', items: ['上门自提', '快递配送', '配送时效', '配送费用'] },
  { title: '支付方式', items: ['在线支付', '货到付款', '分期付款', '发票说明'] },
  { title: '售后服务', items: ['退换货政策', '退款说明', '维修服务', '投诉建议'] },
]

const openCard = (key: HelpCard['key'], title: string) => {
  if (key === 'faq') {
    router.push({ name: 'faq' })
    return
  }
  toast.push({ type: 'info', message: `${title}：功能开发中` })
}

const openFooter = (title: string) => {
  if (title === '常见问题') {
    router.push({ name: 'faq' })
    return
  }
  toast.push({ type: 'info', message: `${title}：功能开发中` })
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="帮助中心" />

    <main class="main">
      <div class="container">
        <h1 class="h1">帮助中心</h1>

        <section class="cards" aria-label="帮助入口">
          <button v-for="c in cards" :key="c.key" class="card" type="button" @click="openCard(c.key, c.title)">
            <div class="cardRow">
              <div class="iconWrap" aria-hidden="true">
                <img class="icon" :src="c.iconUrl" alt="" />
              </div>
              <div class="cardText">
                <div class="cardTitle">{{ c.title }}</div>
                <div class="cardDesc">{{ c.desc }}</div>
                <div class="cardAction">{{ c.actionText }}</div>
              </div>
            </div>
          </button>
        </section>

        <section class="contact" aria-label="联系我们">
          <h2 class="h2">联系我们</h2>
          <div class="contactList">
            <div class="contactItem">客服热线：400-888-8888</div>
            <div class="contactItem">工作时间：周一至周日 9:00-21:00</div>
            <div class="contactItem">邮箱：service@shop.com</div>
          </div>
        </section>
      </div>
    </main>

    <footer class="footer" aria-label="帮助中心页脚">
      <div class="container footerInner">
        <div class="footerCols">
          <div v-for="col in footerCols" :key="col.title" class="footerCol">
            <div class="footerTitle">{{ col.title }}</div>
            <div class="footerList">
              <button v-for="x in col.items" :key="x" class="footerLink" type="button" @click="openFooter(x)">{{ x }}</button>
            </div>
          </div>
        </div>
        <div class="footerCopyright">© 2026 优选商城 版权所有 | 企业级电商平台示例</div>
      </div>
    </footer>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  display: flex;
  flex-direction: column;
  background: #f9fafb;
}

.main {
  padding: 24px 16px;
  flex: 1 1 auto;
}

.container {
  width: min(1054px, 100%);
  margin: 0 auto;
}

.h1 {
  margin: 10px 0 18px;
  font: 600 24px/32px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.cards {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

.card {
  border: 0;
  background: #ffffff;
  border-radius: 16px;
  padding: 24px 24px 0;
  cursor: pointer;
  text-align: left;
  box-shadow: var(--shadow);
}

.cardRow {
  display: flex;
  gap: 16px;
}

.iconWrap {
  width: 48px;
  height: 48px;
  border-radius: 999px;
  background: #faf5ff;
  display: grid;
  place-items: center;
  flex: 0 0 auto;
}

.icon {
  width: 24px;
  height: 24px;
}

.cardText {
  display: grid;
  gap: 4px;
}

.cardTitle {
  font: 600 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.cardDesc {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.cardAction {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #9810fa;
  white-space: pre-line;
}

.contact {
  margin-top: 24px;
  background: #ffffff;
  border-radius: 16px;
  padding: 24px 24px 0;
  box-shadow: var(--shadow);
}

.h2 {
  margin: 0 0 16px;
  font: 600 20px/30px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.contactList {
  display: grid;
  gap: 12px;
  padding-bottom: 18px;
}

.contactItem {
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.footer {
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  background: #f9fafb;
  padding: 48px 16px 0;
}

.footerInner {
  padding-bottom: 24px;
}

.footerCols {
  display: grid;
  gap: 24px;
}

.footerCol {
  display: grid;
  gap: 16px;
}

.footerTitle {
  font: 600 18px/27px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #0a0a0a;
}

.footerList {
  display: grid;
  gap: 8px;
}

.footerLink {
  border: 0;
  background: transparent;
  padding: 0;
  text-align: left;
  cursor: pointer;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

.footerLink:hover {
  color: #9810fa;
}

.footerCopyright {
  border-top: 1px solid rgba(0, 0, 0, 0.1);
  margin-top: 48px;
  padding-top: 33px;
  text-align: center;
  font: 400 14px/20px Inter, system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
  color: #4a5565;
}

@media (min-width: 920px) {
  .cards {
    grid-template-columns: 424px 424px;
    justify-content: start;
    gap: 16px;
  }

  .footerCols {
    grid-template-columns: repeat(4, 231.5px);
    justify-content: space-between;
    gap: 32px;
  }
}
</style>
