<script setup lang="ts">
import UiButton from './UiButton.vue'

withDefaults(
  defineProps<{
    title?: string
    desc?: string
    actionText?: string
  }>(),
  {
    title: '加载失败',
    desc: '请检查网络后重试',
    actionText: '重试',
  },
)

const emit = defineEmits<{
  (e: 'action'): void
}>()
</script>

<template>
  <div class="wrap" role="alert">
    <div class="title">{{ title }}</div>
    <div class="desc">{{ desc }}</div>
    <UiButton class="btn" size="sm" @click="emit('action')">{{ actionText }}</UiButton>
    <slot />
  </div>
</template>

<style scoped>
.wrap {
  border: 1px solid color-mix(in srgb, var(--danger) 35%, var(--border));
  background: var(--danger-bg);
  border-radius: var(--radius-md);
  padding: 18px 16px;
  text-align: center;
  display: grid;
  gap: 8px;
}

.title {
  color: var(--text-h);
  font-weight: 900;
}

.desc {
  color: var(--text);
  font-size: var(--font-sm);
}

.btn {
  justify-self: center;
}
</style>

