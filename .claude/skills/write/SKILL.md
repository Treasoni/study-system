---
name: write
description: 写笔记阶段。根据整理好的资料和用户偏好的笔记类型（概念/实战/对比/速查），选择模板，提取关键信息，用学习者友好的语言生成笔记初稿。触发时机：用户审核通过 curate 产出后，Phase 3。
---

# Skill: write（写笔记）

## 触发时机
用户审核通过 curate 产出后。

## 输入
- `{SYSTEM_ROOT}/1-curated/{topic}/` 中整理好的资料
- 用户偏好的笔记类型：concept / practice / compare / cheat-sheet

## 执行步骤

### Step 1: 选择模板
根据笔记类型匹配模板：
- 概念笔记 → `concept-template.md`
- 实战笔记 → `practice-template.md`
- 对比笔记 → `compare-template.md`
- 速查表 → `cheat-sheet-template.md`

### Step 2: 提取关键信息
从整理资料中读取：
- `core-concepts.md` → 定义、原理
- `practices.md` → 示例、代码、步骤
- `overview.md` → 结构、关系
- `references.md` → 来源引用

### Step 3: 填充模板
- 用学习者友好的语言（像给同事讲解一样）
- 加入类比帮助理解
- 插入代码示例（来自源材料）
- 描述有助于理解的图表
- 内联引用来源：`[来源: R1]`

### Step 4: 生成思考题
3-5 个有深度的问题：
- 概念理解检查
- 应用场景
- 边界情况思考

### Step 5: 自检
- 每个观点都能追溯到来源？
- 有无未覆盖的缺口？有则标记 `[待补充]`
- 难度是否匹配目标层次？

## 产出
写入 `{SYSTEM_ROOT}/2-drafts/{topic}/`：
- `{topic}-笔记.md`：主体笔记初稿（含 YAML frontmatter + 内联引用 + 思考题）

## 禁止行为
- 不要做美化排版（beautify 的事）
- 不要添加 curate 阶段未确认的内容
- 不要编造引用
- 不要省略来源标注
