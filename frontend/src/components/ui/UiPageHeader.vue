<script setup lang="ts">
import { useRouter } from 'vue-router'

import UiButton from './UiButton.vue'

const props = withDefaults(
  defineProps<{
    title: string
    showBack?: boolean
  }>(),
  {
    showBack: true,
  },
)

const router = useRouter()
</script>

<template>
  <header class="head">
    <UiButton v-if="props.showBack" size="sm" @click="router.back()">返回</UiButton>
    <div class="title">{{ props.title }}</div>
    <div class="right">
      <slot name="right" />
    </div>
  </header>
</template>

<style scoped>
.head {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--border);
  background: var(--bg);
  position: sticky;
  top: 0;
  z-index: 100;
}

.title {
  justify-self: center;
  font-weight: 900;
  color: var(--text-h);
}

.right {
  min-width: 64px;
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}
</style>

