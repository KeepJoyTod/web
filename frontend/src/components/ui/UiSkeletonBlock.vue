<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    height?: string
    radius?: string
  }>(),
  {
    height: '16px',
    radius: 'var(--radius-sm)',
  },
)
</script>

<template>
  <div class="sk" role="status" aria-label="加载中" :style="{ height: props.height, borderRadius: props.radius }"></div>
</template>

<style scoped>
.sk {
  width: 100%;
  border: 1px solid var(--border);
  background:
    linear-gradient(
      90deg,
      color-mix(in srgb, var(--code-bg) 70%, transparent),
      color-mix(in srgb, var(--bg) 90%, transparent),
      color-mix(in srgb, var(--code-bg) 70%, transparent)
    );
  background-size: 300% 100%;
  animation: shimmer 1.2s ease-in-out infinite;
}

@keyframes shimmer {
  0% {
    background-position: 0% 0%;
  }
  100% {
    background-position: 100% 0%;
  }
}
</style>

