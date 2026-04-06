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

  const fetch = async () => {
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
  }

  const push = async (input: Omit<NotificationItem, 'id' | 'ts' | 'read'>) => {
    const res = await api.post('/v1/notifications', {
      type: input.type,
      title: input.title,
      content: input.content,
      relatedId: input.relatedId || '',
    })
    const x = res.data?.data
    const item: NotificationItem = {
      id: String(x?.id ?? ''),
      type: (x?.type || input.type) as NotificationType,
      title: x?.title || input.title,
      content: x?.content || input.content,
      relatedId: x?.relatedId || input.relatedId,
      ts: x?.createTime ? new Date(x.createTime).getTime() : Date.now(),
      read: !!(x?.isRead ?? false),
    }
    itemsRef.value = [item, ...itemsRef.value]
    return item.id
  }

  const markRead = async (id: string) => {
    await api.post(`/v1/notifications/${encodeURIComponent(id)}/read`)
    const t = itemsRef.value.find((x) => x.id === id)
    if (t) t.read = true
  }

  const markAllRead = async () => {
    await api.post('/v1/notifications/markAllRead')
    itemsRef.value = itemsRef.value.map((x) => ({ ...x, read: true }))
  }

  const clear = async () => {
    await api.delete('/v1/notifications')
    itemsRef.value = []
  }

  return { items, unreadCount, fetch, push, markRead, markAllRead, clear }
})
