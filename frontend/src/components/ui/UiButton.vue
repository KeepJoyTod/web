<script setup lang="ts">
import { computed } from 'vue'

type Variant = 'primary' | 'ghost' | 'danger'
type Size = 'sm' | 'md'

const props = withDefaults(
  defineProps<{
    variant?: Variant
    size?: Size
    loading?: boolean
    disabled?: boolean
    type?: 'button' | 'submit' | 'reset'
  }>(),
  {
    variant: 'ghost',
    size: 'md',
    loading: false,
    disabled: false,
    type: 'button',
  },
)

const isDisabled = computed(() => props.disabled || props.loading)
</script>

<template>
  <button class="btn" :class="[variant, size]" :type="type" :disabled="isDisabled">
    <span v-if="loading" class="spinner" aria-hidden="true"></span>
    <span class="content"><slot /></span>
  </button>
</template>

<style scoped>
.btn {
  border-radius: var(--radius-sm);
  padding: 12px 14px;
  font-size: var(--font-md);
  font-weight: 900;
  cursor: pointer;
  border: 1px solid var(--border);
  background: var(--bg);
  color: var(--text-h);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  line-height: 1;
}

.btn.sm {
  padding: 9px 12px;
  font-size: var(--font-sm);
  border-radius: var(--radius-pill);
  font-weight: 800;
}

.btn.primary {
  border: 0;
  background: var(--accent);
  color: #fff;
}

.btn.ghost {
  background: var(--bg);
}

.btn.danger {
  border: 0;
  background: var(--danger);
  color: #fff;
}

.btn:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid color-mix(in srgb, #fff 40%, transparent);
  border-top-color: #fff;
  animation: spin 0.75s linear infinite;
}

.ghost .spinner {
  border: 2px solid color-mix(in srgb, var(--text-h) 25%, transparent);
  border-top-color: var(--text-h);
}

.danger .spinner {
  border: 2px solid color-mix(in srgb, #fff 40%, transparent);
  border-top-color: #fff;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}
</style>

