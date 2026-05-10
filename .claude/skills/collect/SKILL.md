---
name: collect
description: 收集学习资料阶段。根据用户的学习主题，搜索官方文档和社区内容，抓取并保存原始资料。触发时机：用户确认学习计划后，Phase 1。
---

# Skill: collect（收集资料）

## 触发时机
用户确认学习计划后。

## 输入
- `topic`: 学习主题
- `direction`: 概念理解 / 实战上手 / 体系梳理 / 问题排查
- `depth`: 入门 / 进阶 / 深入原理

## 执行步骤

### Step 1: 搜索官方文档
- 用 `WebSearch` 搜索：`{topic} official documentation`
- 用 `WebSearch` 搜索：`{topic} official guide tutorial`
- 锁定官方文档入口 URL

### Step 2: 抓取官方文档
- 用 `WebFetch` 抓取官方文档概览页和关键子页面
- 至少覆盖：概述、入门、核心概念页面

### Step 3: 搜索社区内容
- `WebSearch`: `{topic} tutorial {当前年份}`（优先近期内容）
- `WebSearch`: `{topic} best practices github`
- `WebSearch`: `{topic} common pitfalls`
- `WebSearch`: `{topic} advanced guide deep dive`

### Step 4: 过滤
- 优先级：官方文档 > 知名作者 > 社区
- 时效性：优先近 2 年内的内容
- 唯一性：同一内容保留质量最高的来源
- 多样性：保留有独特视角的资料

### Step 5: 保存
用 `WebFetch` 抓取每个入选来源，保存为 `raw/doc-NN.md`

## 产出
写入 `{SYSTEM_ROOT}/0-inbox/{topic}/`：

### sources.md
```markdown
# Sources for {topic}

| # | Title | URL | Author | Date | Type | Notes |
|---|-------|-----|--------|------|------|-------|
```

### raw/doc-NN.md
```markdown
# {Title}
- **Source**: {URL}
- **Author**: {name}
- **Date**: {date}
- **Type**: {official|blog|tutorial|discussion}

---
{raw content}
```

## 禁止行为
- 不要整理或总结内容（curate 的事）
- 不要评判资料好坏（只记录元数据）
- 不要跳过低热度但有独特视角的资料
- 不要编造 URL 或来源信息
