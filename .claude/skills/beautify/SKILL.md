---
name: beautify
description: 美化排版阶段。套用 Obsidian Markdown 规范，添加双链、标签、Callout 块、Mermaid 图表、YAML frontmatter 等 Obsidian 特性，优化段落长度和术语一致性。触发时机：用户审核通过 write 产出后，Phase 4。
---

# Skill: beautify（美化排版）

## 触发时机
用户审核通过 write 产出后。

## 输入
`{SYSTEM_ROOT}/2-drafts/{topic}/{topic}-笔记.md`

## 执行步骤

### Step 1: 检查 Markdown 规范
- 标题层级正确（不越级，最多 4 级）
- 统一格式（粗体、斜体、代码块）

### Step 2: 添加 Obsidian 特性

#### 双链 `[[]]`
- 为笔记中出现的概念添加双链
- 格式：`[[概念名]]` 或 `[[路径|显示名]]`

#### 标签 `#tag`
根据内容分析打标签：
- 主题标签：#react #hooks #frontend
- 类型标签：#concept #tutorial #cheatsheet
- 难度标签：#beginner #intermediate #advanced

#### Callout 块
- `> [!note]` 补充说明
- `> [!warning]` 坑点/注意事项
- `> [!tip]` 最佳实践/技巧
- `> [!example]` 代码示例
- `> [!info]` 背景知识
- `> [!danger]` 严重警告

#### Mermaid 图表
- 流程 → `flowchart TD`
- 序列 → `sequenceDiagram`
- 类关系 → `classDiagram`

#### YAML Frontmatter
```yaml
---
topic: ""
type: concept | practice | compare | cheat-sheet
difficulty: beginner | intermediate | advanced
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: []
concepts: []
---
```

### Step 3: 优化可读性
- 段落不超过 6 行
- 大主题切换用 `---` 分隔
- 代码块标注语言
- 对比数据用表格

### Step 4: 术语统一
同一概念全文使用统一术语。

## 产出
写入 `{OUTPUT_PATH}/{topic}/`（或默认 `{SYSTEM_ROOT}/3-published/{topic}/`）：
- `{topic}.md`：最终格式化的 Obsidian 笔记
- `attachments/`：相关图片或文件（如果有）

## 禁止行为
- 不要修改笔记内容或含义
- 不要添加草稿中没有的信息
- 不要删除内容（只能调整呈现方式）
- 不要编造不存在的双链
- 不要删除来源引用
