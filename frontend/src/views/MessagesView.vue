<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'

import UiButton from '../components/ui/UiButton.vue'
import UiEmptyState from '../components/ui/UiEmptyState.vue'
import UiPageHeader from '../components/ui/UiPageHeader.vue'
import { useNotificationsStore } from '../stores/notifications'

const router = useRouter()
const notifications = useNotificationsStore()

onMounted(() => {
  notifications.fetch().catch(() => {})
})

const onOpen = (id: string, relatedId?: string) => {
  notifications.markRead(id)
  if (relatedId) {
    router.push({ name: 'orderDetail', params: { id: relatedId } })
  }
}
</script>

<template>
  <div class="page">
    <UiPageHeader title="消息中心">
      <template #right>
        <UiButton size="sm" type="button" :disabled="notifications.items.length === 0" @click="notifications.markAllRead()">
          全部已读
        </UiButton>
      </template>
    </UiPageHeader>

    <main class="main" aria-live="polite">
      <UiEmptyState v-if="notifications.items.length === 0" title="暂无消息" desc="有新消息会在这里展示" />

      <div v-else class="list" aria-label="消息列表">
        <article
          v-for="n in notifications.items"
          :key="n.id"
          class="card"
          :class="{ unread: !n.read }"
          @click="onOpen(n.id, n.relatedId)"
        >
          <div class="row">
            <div class="title">{{ n.title }}</div>
            <div class="time">{{ new Date(n.ts).toLocaleString() }}</div>
          </div>
          <div class="content">{{ n.content }}</div>
          <div class="meta">
            <span class="type">{{ n.type }}</span>
            <span v-if="!n.read" class="dot" aria-label="未读"></span>
          </div>
        </article>
      </div>
    </main>
  </div>
</template>

<style scoped>
.page {
  min-height: 100%;
  display: flex;
  flex-direction: column;
}

.main {
  padding: 14px 16px 28px;
}

.list {
  display: grid;
  gap: 12px;
}

.card {
  border: 1px solid var(--border);
  border-radius: var(--radius-md);
  background: var(--bg);
  padding: 12px;
  display: grid;
  gap: 8px;
  cursor: pointer;
}

.card.unread {
  border-color: color-mix(in srgb, var(--accent) 35%, var(--border));
  background: color-mix(in srgb, var(--accent-bg) 40%, transparent);
}

.row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: baseline;
}

.title {
  color: var(--text-h);
  font-weight: 900;
  font-size: var(--font-sm);
}

.time {
  color: var(--text);
  font-size: var(--font-xs);
}

.content {
  color: var(--text);
  font-size: var(--font-sm);
  line-height: 1.4;
}

.meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.type {
  color: var(--text);
  font-size: var(--font-xs);
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--accent);
}

@media (min-width: 920px) {
  .main {
    max-width: 1120px;
    margin: 0 auto;
    width: 100%;
  }
}
</style>
