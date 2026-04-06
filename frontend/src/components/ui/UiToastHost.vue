<script setup lang="ts">
import { useToastStore } from '../../stores/toast'

const toast = useToastStore()
</script>

<template>
  <div class="host" aria-live="polite" aria-relevant="additions removals">
    <TransitionGroup name="toast" tag="div" class="stack">
      <div
        v-for="t in toast.items"
        :key="t.id"
        class="item"
        :class="t.type"
        role="status"
        @click="toast.remove(t.id)"
      >
        <div class="msg">{{ t.message }}</div>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.host {
  position: fixed;
  top: calc(var(--app-brandbar-h, 0px) + 10px);
  left: 0;
  right: 0;
  z-index: var(--z-toast);
  pointer-events: none;
  padding: 0 12px;
  display: grid;
  justify-items: center;
}

.stack {
  width: min(520px, 100%);
  display: grid;
  gap: 10px;
}

.item {
  pointer-events: auto;
  border: 1px solid var(--border);
  background: var(--bg);
  border-radius: var(--radius-pill);
  padding: 10px 14px;
  box-shadow: var(--shadow);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.item.success {
  border-color: color-mix(in srgb, var(--success) 55%, var(--border));
  background: var(--success-bg);
}

.item.error {
  border-color: color-mix(in srgb, var(--danger) 55%, var(--border));
  background: var(--danger-bg);
}

.item.info {
  border-color: color-mix(in srgb, var(--accent) 55%, var(--border));
  background: var(--accent-bg);
}

.msg {
  color: var(--text-h);
  font-weight: 800;
  font-size: var(--font-sm);
}

.toast-enter-active,
.toast-leave-active {
  transition: transform 0.18s ease, opacity 0.18s ease;
}

.toast-enter-from,
.toast-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>

