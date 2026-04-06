<script setup lang="ts">
import UiButton from './UiButton.vue'

withDefaults(
  defineProps<{
    title?: string
    desc?: string
    actionText?: string
  }>(),
  {
    title: '暂无数据',
    desc: '',
    actionText: '',
  },
)

const emit = defineEmits<{
  (e: 'action'): void
}>()
</script>

<template>
  <div class="wrap">
    <div class="title">{{ title }}</div>
    <div v-if="desc" class="desc">{{ desc }}</div>
    <UiButton v-if="actionText" class="btn" size="sm" @click="emit('action')">{{ actionText }}</UiButton>
    <slot />
  </div>
</template>

<style scoped>
.wrap {
  border: 1px dashed var(--border);
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

