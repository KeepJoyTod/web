import { defineStore } from 'pinia'
import { computed, ref, watch } from 'vue'

export type TrackEvent = {
  id: string
  name: string
  ts: number
  params: Record<string, unknown>
}

type SnapshotV1 = {
  v: 1
  events: TrackEvent[]
}

const STORAGE_KEY = 'tracker:v1'
const MAX_EVENTS = 200

const readSnapshot = (): SnapshotV1 => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { v: 1, events: [] }
    const parsed = JSON.parse(raw) as SnapshotV1
    if (parsed?.v !== 1) return { v: 1, events: [] }
    return { v: 1, events: Array.isArray(parsed.events) ? parsed.events : [] }
  } catch {
    return { v: 1, events: [] }
  }
}

const uid = () => `e_${Math.random().toString(16).slice(2)}_${Date.now().toString(16)}`

export const useTrackerStore = defineStore('tracker', () => {
  const snapshot = ref<SnapshotV1>(readSnapshot())

  const events = computed(() => snapshot.value.events.slice().sort((a, b) => b.ts - a.ts))
  const count = computed(() => snapshot.value.events.length)

  const track = (name: string, params: Record<string, unknown> = {}) => {
    const ev: TrackEvent = { id: uid(), name, ts: Date.now(), params }
    const next = [ev, ...snapshot.value.events].slice(0, MAX_EVENTS)
    snapshot.value.events = next
    return ev.id
  }

  const clear = () => {
    snapshot.value.events = []
  }

  watch(
    snapshot,
    (v) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(v))
    },
    { deep: true },
  )

  return { events, count, track, clear }
})

