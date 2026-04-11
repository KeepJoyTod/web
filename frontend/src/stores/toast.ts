import { defineStore } from 'pinia'
import { ref } from 'vue'

export type ToastType = 'success' | 'error' | 'info'

export type ToastItem = {
  id: string
  type: ToastType
  message: string
}

const uid = () => `t_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

export const useToastStore = defineStore('toast', () => {
  const items = ref<ToastItem[]>([])

  const push = (input: { type?: ToastType; message: string; durationMs?: number }) => {
    const id = uid()
    const type: ToastType = input.type ?? 'info'
    const durationMs = input.durationMs ?? 2000
    items.value = [...items.value, { id, type, message: input.message }]

    window.setTimeout(() => {
      items.value = items.value.filter((x) => x.id !== id)
    }, durationMs)

    return id
  }

  const remove = (id: string) => {
    items.value = items.value.filter((x) => x.id !== id)
  }

  const clear = () => {
    items.value = []
  }

  return { items, push, remove, clear }
})

