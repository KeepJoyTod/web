---
name: "figma-links"
description: "从本仓库登记文件读取 Figma 链接，并触发 figma-to-vue3 进行 Vue 3 1:1 界面还原流程。用户说“读取figma链接/解析 figma 链接/用 Vue3 还原 Figma”时调用。"
---

# 读取 Figma 链接（入口）

## 目的

提供一个统一入口：用户只要说“读取figma链接”，就从仓库文件读取 Figma URL，并进入 **figma-to-vue3** 流程，要求用 Vue 3 对界面进行 1:1 还原（像素级布局、字号、颜色、间距、圆角、阴影等）。

## 何时调用

当用户：

- 发送“读取figma链接 / 读取 Figma 链接 / 解析 figma 链接”
- 或明确表示 Figma 链接已写在仓库里，希望直接读取并开始解析
- 或要求“用 Vue3 按 Figma 1:1 还原界面”，但未显式提供 URL（暗示仓库已登记）

## 数据来源

默认从以下文件读取：

- `skills/figma/FIGMA_LINKS.md`

## 执行步骤

1) 读取 `skills/figma/FIGMA_LINKS.md`，提取其中的 `url:` 字段或任意 Figma URL。
2) 如果找到多个链接：
   - 按“当前默认链接”优先；
   - 若仍不明确，列出候选链接并让用户选择要解析哪一个（只需要用户选序号或粘贴 URL）。
3) 解析目标：
   - 同时读取 `page/frame/node:` 与“解析要求”段落作为约束（如断点、样式方案、交互要求）。
4) 立刻切换到 **figma-to-vue3**：
   - 把选定的 Figma URL 与解析约束交给 figma-to-vue3；
   - 明确传递“Vue 3 1:1 还原界面”的硬性目标；
   - 按 figma-to-vue3 的规则先输出“页面结构/布局/样式蓝图”并等待用户确认；
   - 用户确认后再生成 Vue 3 代码。

## 输出要求

- 如果文件为空或没有 URL：提示用户把链接填入 `skills/figma/FIGMA_LINKS.md` 的“当前默认链接”。
- 如果 URL 不是 Figma 链接：提示用户修正为有效 Figma URL（file/page/node 任意一种都可以）。
