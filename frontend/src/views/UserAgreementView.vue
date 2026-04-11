<script setup lang="ts">
import UiPageHeader from '../components/ui/UiPageHeader.vue'
</script>

<template>
  <div class="page">
    <UiPageHeader title="用户协议" />
    <main class="main">
      <section class="card">
        <h2 class="h">一、总则</h2>
        <p>本协议是用户与“元气购”之间关于使用平台服务的约定。用户在注册、登录或使用平台服务时，即视为已阅读并同意本协议全部内容。</p>

        <h2 class="h">二、账户与安全</h2>
        <p>用户应使用真实有效的联系方式进行注册，并妥善保管账户与密码。因用户自行泄露账户信息造成的损失，由用户自行承担。</p>

        <h2 class="h">三、商品与交易</h2>
        <p>平台展示的商品信息（含价格、库存、规格等）仅为要约邀请。订单提交并经平台确认后合同成立。用户应当按页面提示履行支付义务。</p>

        <h2 class="h">四、售后与评价</h2>
        <p>用户在符合法律及平台规则的前提下可享受退换货、维修等服务。用户发表的评价应真实、客观，不得包含违法或不适宜内容。</p>

        <h2 class="h">五、用户行为规范</h2>
        <p>用户不得利用平台从事违法活动，不得侵犯他人合法权益，不得对平台系统安全构成威胁。</p>

        <h2 class="h">六、责任限制</h2>
        <p>因不可抗力或第三方原因导致的服务中断或数据丢失，平台不承担相应责任，但将积极协助处理。</p>

        <h2 class="h">七、协议更新</h2>
        <p>平台可根据业务和法律变化适时更新本协议，更新后将在页面公示。继续使用即视为接受更新后的条款。</p>

        <h2 class="h">八、联系方式</h2>
        <p>如对本协议有疑问，请通过页面提供的客服渠道与我们联系。</p>
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
