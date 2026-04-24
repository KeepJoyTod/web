<script setup lang="ts">
import { onBeforeUnmount, onMounted } from 'vue'

const props = withDefaults(
  defineProps<{
    open: boolean
    closeOnMask?: boolean
    closeOnEsc?: boolean
  }>(),
  {
    closeOnMask: true,
    closeOnEsc: true,
  },
)

const emit = defineEmits<{
  (e: 'update:open', v: boolean): void
}>()

const close = () => emit('update:open', false)

const onKey = (e: KeyboardEvent) => {
  if (!props.open) return
  if (!props.closeOnEsc) return
  if (e.key === 'Escape') close()
}

onMounted(() => {
  window.addEventListener('keydown', onKey)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
})
</script>

<template>
  <Teleport to="body">
    <div v-if="open" class="mask" role="dialog" aria-modal="true" @click="closeOnMask ? close() : undefined">
      <div class="panel" @click.stop>
        <slot />
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.mask {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.35);
  display: grid;
  place-items: center;
  z-index: var(--z-modal);
  padding: 16px;
}

.panel {
  width: min(560px, 100%);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  background: var(--bg);
  box-shadow: var(--shadow);
  overflow: hidden;
}
</style>

