<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    modelValue: string
    type?: string
    placeholder?: string
    autocomplete?: string
    inputmode?: 'text' | 'search' | 'none' | 'tel' | 'url' | 'email' | 'numeric' | 'decimal'
    disabled?: boolean
    ariaLabel?: string
  }>(),
  {
    type: 'text',
    placeholder: '',
    autocomplete: 'off',
    inputmode: undefined,
    disabled: false,
    ariaLabel: undefined,
  },
)

const emit = defineEmits<{
  (e: 'update:modelValue', v: string): void
  (e: 'blur'): void
  (e: 'focus'): void
  (e: 'keydown', ev: KeyboardEvent): void
}>()

const aria = computed(() => props.ariaLabel ?? props.placeholder ?? undefined)
</script>

<template>
  <input
    class="input"
    :value="modelValue"
    :type="type"
    :placeholder="placeholder"
    :autocomplete="autocomplete"
    :inputmode="inputmode"
    :disabled="disabled"
    :aria-label="aria"
    @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    @blur="emit('blur')"
    @focus="emit('focus')"
    @keydown="emit('keydown', $event)"
  />
</template>

<style scoped>
.input {
  width: 100%;
  border: 1px solid var(--border);
  border-radius: var(--radius-sm);
  padding: 12px 12px;
  font-size: var(--font-md);
  color: var(--text-h);
  background: var(--bg);
}

.input:disabled {
  cursor: not-allowed;
  opacity: 0.7;
}
</style>
