---
name: "figma-links"
description: "读取本仓库的 Figma 链接登记文件并发起解析流程。用户说“读取figma链接/读取 Figma 链接/解析 figma 链接”时调用。"
---

# 读取 Figma 链接（入口）

## 目的

提供一个统一入口：用户只要说“读取figma链接”，就从仓库文件读取 Figma URL，并进入 **figma-to-vue3** 的两步工作流（先蓝图后代码）。

## 何时调用

当用户：

- 发送“读取figma链接 / 读取 Figma 链接 / 解析 figma 链接”
- 或明确表示 Figma 链接已写在仓库里，希望直接读取并开始解析

## 数据来源

默认从以下文件读取：

- `.trae/figma/FIGMA_LINKS.md`

## 执行步骤

1) 读取 `.trae/figma/FIGMA_LINKS.md`，提取其中的 `url:` 字段或任意 Figma URL。
2) 如果找到多个链接：
   - 按“当前默认链接”优先；
   - 若仍不明确，列出候选链接并让用户选择要解析哪一个（只需要用户选序号或粘贴 URL）。
3) 解析目标：
   - 同时读取 `page/frame/node:` 与“解析要求”段落作为约束（如断点、样式方案、交互要求）。
4) 立刻切换到 **figma-to-vue3**：
   - 把选定的 Figma URL 与解析约束交给 figma-to-vue3；
   - 按 figma-to-vue3 的规则先输出“页面结构/布局/样式蓝图”并等待用户确认；
   - 用户确认后再生成 Vue3 代码。

## 输出要求

- 如果文件为空或没有 URL：提示用户把链接填入 `.trae/figma/FIGMA_LINKS.md` 的“当前默认链接”。
- 如果 URL 不是 Figma 链接：提示用户修正为有效 Figma URL（file/page/node 任意一种都可以）。

