import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import { api } from '../lib/api'

export type NotificationType = 'order_paid' | 'order_created' | 'system'

export type NotificationItem = {
  id: string
  type: NotificationType
  title: string
  content: string
  ts: number
  read: boolean
  relatedId?: string
}

export const useNotificationsStore = defineStore('notifications', () => {
  const itemsRef = ref<NotificationItem[]>([])

  const items = computed(() => itemsRef.value.slice().sort((a, b) => b.ts - a.ts))
  const unreadCount = computed(() => itemsRef.value.filter((x) => !x.read).length)
  const newId = () => `n_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

  const fetch = async () => {
    try {
      const res = await api.get('/v1/notifications')
      const list = Array.isArray(res.data?.data) ? res.data.data : []
      itemsRef.value = list.map((x: any) => ({
        id: String(x.id),
        type: (x.type || 'system') as NotificationType,
        title: String(x.title || ''),
        content: String(x.content || ''),
        relatedId: x.relatedId ? String(x.relatedId) : undefined,
        ts: x.createTime ? new Date(x.createTime).getTime() : Date.now(),
        read: !!(x.isRead ?? x.read),
      }))
    } catch {}
  }

  const push = async (input: Omit<NotificationItem, 'id' | 'ts' | 'read'>) => {
    let item: NotificationItem
    try {
      const res = await api.post('/v1/notifications', {
        type: input.type,
        title: input.title,
        content: input.content,
        relatedId: input.relatedId || '',
      })
      const x = res.data?.data
      item = {
        id: String(x?.id ?? newId()),
        type: (x?.type || input.type) as NotificationType,
        title: x?.title || input.title,
        content: x?.content || input.content,
        relatedId: x?.relatedId || input.relatedId,
        ts: x?.createTime ? new Date(x.createTime).getTime() : Date.now(),
        read: !!(x?.isRead ?? false),
      }
    } catch {
      item = {
        id: newId(),
        type: input.type,
        title: input.title,
        content: input.content,
        relatedId: input.relatedId,
        ts: Date.now(),
        read: false,
      }
    }
    itemsRef.value = [item, ...itemsRef.value]
    return item.id
  }

  const markRead = async (id: string) => {
    try {
      await api.post(`/v1/notifications/${encodeURIComponent(id)}/read`)
    } catch {}
    const t = itemsRef.value.find((x) => x.id === id)
    if (t) t.read = true
  }

  const markAllRead = async () => {
    try {
      await api.post('/v1/notifications/markAllRead')
    } catch {}
    itemsRef.value = itemsRef.value.map((x) => ({ ...x, read: true }))
  }

  const clear = async () => {
    try {
      await api.delete('/v1/notifications')
    } catch {}
    itemsRef.value = []
  }

  return { items, unreadCount, fetch, push, markRead, markAllRead, clear }
})
