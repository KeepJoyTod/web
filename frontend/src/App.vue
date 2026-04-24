<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import { computed, onMounted, watch } from 'vue'
import { useAuthStore } from './stores/auth'
import { useFavoritesStore } from './stores/favorites'

import BottomNav from './components/BottomNav.vue'
import UiToastHost from './components/ui/UiToastHost.vue'

const route = useRoute()
const auth = useAuthStore()
const favorites = useFavoritesStore()

const showNav = computed(() => route.meta?.hideNav !== true)

onMounted(() => {
  if (auth.isLoggedIn) {
    favorites.fetch()
  }
})

watch(() => auth.isLoggedIn, (loggedIn) => {
  if (loggedIn) {
    favorites.fetch()
  } else {
    favorites.clear()
  }
})
</script>

<template>
  <div class="app">
    <header class="brandbar" aria-label="平台名称">
      <div class="brand">元气购</div>
    </header>
    <BottomNav v-if="showNav" />
    <RouterView class="view" />
    <UiToastHost />
  </div>
</template>

<style scoped>
.app {
  min-height: 100svh;
  display: flex;
  flex-direction: column;
  --app-brandbar-h: 52px;
}

.brandbar {
  position: sticky;
  top: 0;
  z-index: var(--z-brandbar);
  height: var(--app-brandbar-h);
  display: flex;
  align-items: center;
  padding: 0 16px;
  border-bottom: 1px solid var(--border);
  background: var(--bg);
  backdrop-filter: saturate(180%) blur(10px);
}

.brand {
  font-weight: 900;
  letter-spacing: 0.2px;
  color: var(--text-h);
  font-size: 16px;
}

.view {
  flex: 1 1 auto;
  min-height: 0;
}
</style>
