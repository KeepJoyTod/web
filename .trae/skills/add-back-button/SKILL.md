---
name: "add-back-button"
description: "在 Vue 页面中添加固定的返回按钮及吸顶标题栏。当页面缺少导航入口或需要优化滚动体验时调用。"
---

# 添加返回按钮

该技能用于在 Vue 视图组件中添加一个固定在页面顶部的返回按钮标题栏。

## 适用场景
- 页面缺少返回入口。
- 返回按钮随页面滚动而消失，需要固定。
- 需要统一页面的导航栏风格。

## 实现规范

### 1. 使用通用组件 (推荐)
如果项目中有 `UiPageHeader.vue`，优先使用它。该组件已配置为 `sticky`。

```vue
<UiPageHeader title="页面标题" />
```

### 2. 自定义吸顶标题栏
如果需要更复杂的布局（如面包屑或自定义按钮），请参考以下实现：

#### 模板结构
```vue
<template>
  <div class="page">
    <header class="headerSticky">
      <div class="headerContent">
        <button class="backBtn" type="button" @click="router.back()">
          <img class="backIcon" :src="backIconUrl" alt="返回" />
          <span class="backText">返回</span>
        </button>
        <!-- 可选：面包屑 -->
        <nav v-if="product" class="crumbs">...</nav>
        <h1 class="h1">标题</h1>
      </div>
    </header>
    
    <main class="main">
      <!-- 页面内容 -->
    </main>
  </div>
</template>
```

#### 样式规范
```css
.headerSticky {
  position: sticky;
  top: 0;
  background: var(--bg); /* 必须设置背景色 */
  z-index: 100;          /* 确保在顶层 */
  border-bottom: 1px solid var(--border);
}

.headerContent {
  width: min(864px, 100%); /* 保持与主内容区宽度一致 */
  margin: 0 auto;
  padding: 16px;
  display: flex;
  align-items: center;
  gap: 24px;
}
```

## 注意事项
- **Z-Index**: 建议设为 100 或以上。
- **背景覆盖**: 必须明确设置 `background`，否则滚动时下方文字会透过标题栏显示。
- **Sticky 失效**: 确保父容器没有 `overflow: hidden` 或 `overflow: auto`，否则 `sticky` 属性会失效。
