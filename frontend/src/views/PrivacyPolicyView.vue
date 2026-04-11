<script setup lang="ts">
import UiPageHeader from '../components/ui/UiPageHeader.vue'
</script>

<template>
  <div class="page">
    <UiPageHeader title="隐私政策" />
    <main class="main">
      <section class="card">
        <h2 class="h">一、我们收集哪些信息</h2>
        <p>
          为提供登录、下单、消息与售后等服务，我们可能收集：账号信息（手机号/邮箱等）、设备与日志信息（用于保障安全与改进体验）、交易信息
          （订单、收货地址、售后记录）等。
        </p>

        <h2 class="h">二、我们如何使用信息</h2>
        <p>我们仅在实现产品功能与履行法定义务所必需的范围内使用信息，例如用于身份验证、订单履约、客户服务、风险控制与统计分析。</p>

        <h2 class="h">三、我们如何共享、转让与公开披露</h2>
        <p>
          我们不会出售用户个人信息。为完成交易履约，我们可能与物流、支付、客服等合作方共享必要信息，并要求其按照本政策与法律要求进行保护。
          未经用户同意或法律法规允许，我们不会对外公开披露个人信息。
        </p>

        <h2 class="h">四、信息存储与保护</h2>
        <p>
          我们采用合理的安全措施保护信息，防止未经授权的访问、使用、披露或损坏。我们仅在实现目的所需的最短期限内保留信息，法律法规另有规定的除外。
        </p>

        <h2 class="h">五、您的权利</h2>
        <p>用户可在法律允许范围内访问、更正、删除个人信息，并可撤回同意或注销账户。我们将按流程进行核验与处理。</p>

        <h2 class="h">六、未成年人保护</h2>
        <p>如您为未成年人，请在监护人同意与指导下使用本服务。我们将依法保护未成年人信息。</p>

        <h2 class="h">七、政策更新</h2>
        <p>我们可能适时更新本政策，并在页面公示。重大变更将采用更显著方式提示。</p>

        <h2 class="h">八、联系我们</h2>
        <p>如对本隐私政策有疑问，可通过页面提供的客服渠道联系我们。</p>
      </section>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100svh;
  display: flex;
  flex-direction: column;
}
.main {
  padding: 18px 16px 28px;
  display: grid;
  place-items: start center;
}
.card {
  width: min(760px, 100%);
  border: 1px solid var(--border);
  border-radius: 18px;
  background: var(--bg);
  box-shadow: var(--shadow);
  padding: 16px;
}
.h {
  margin: 12px 0 8px;
  font-size: 16px;
  color: var(--text-h);
}
p {
  margin: 0 0 10px;
  color: var(--text);
  line-height: 1.75;
}
</style>
