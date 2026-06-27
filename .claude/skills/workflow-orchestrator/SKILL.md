---
name: workflow-orchestrator
description: 工作流编排器。根据用户需求选择合适的工作流模板，生成对应的 todo.md 执行检查清单。触发词：工作流、流程、开始学习、新建项目、workflow、orchestrator。
---

# Workflow Orchestrator - 工作流编排器

根据用户需求选择合适的工作流模板，生成对应的 todo.md 执行检查清单。

## 核心架构

```
workflow-orchestrator (本技能)
    │
    ├── 扫描 templates/ 目录
    │
    ├── 分析用户需求
    │
    ├── 选择工作流模板
    │
    ├── 生成 todo.md
    │
    └── 返回项目路径
```

## 触发条件

当用户提出以下类型的请求时，调用此技能:

- "我想学习 XX"
- "开始学习 React"
- "新建一个学习项目"
- "帮我创建一个项目"
- "我想研究 XX 技术"
- 任何涉及创建新学习项目的请求

## 核心功能

### 功能 1: 工作流模板管理

**模板存储位置**: `templates/` 目录

**当前可用模板**:

| 模板名称 | 文件名 | 用途 | 阶段数 |
|---------|--------|------|--------|
| learning-note-flow | learning-note-flow.md | 完整学习笔记生产 | 7 (阶段 0-6) |

**模板格式要求**:
- 每个模板必须包含: 工作流名称、描述、各阶段定义
- 每个阶段必须包含: 名称、负责技能、检查项、输出文件、状态
- 支持自定义阶段数和检查项

### 功能 2: 智能选择工作流

**分析维度**:
```yaml
用户输入:
  - 学习目标 (要学什么)
  - 学习深度 (入门/上手/精通)
  - 输出类型 (笔记/代码/项目)
  - 时间约束

匹配规则:
  - 学习类需求 → learning-note-flow
  - 项目类需求 → (未来扩展)
  - 阅读类需求 → (未来扩展)
```

**选择逻辑**:
1. 扫描 templates/ 目录获取所有可用模板
2. 解析每个模板的适用场景
3. 根据用户输入匹配最合适的模板
4. 如果没有匹配，提示用户可用的工作流

### 功能 3: 生成 todo.md

**从模板生成定制化的 todo.md，包含**:
- 项目基本信息 (主题、slug、创建时间)
- 各阶段状态 (初始为 ⬜ 未开始)
- 当前阶段标记
- 异常记录表
- 方向调整记录表
- 最终产出表

**生成逻辑**:
```bash
# 1. 生成项目 slug
PROJECT_SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# 2. 创建项目目录
mkdir -p /workspace/${PROJECT_SLUG}

# 3. 读取模板并替换变量
sed -e "s/{topic}/$TOPIC/g" \
    -e "s/{project_slug}/$PROJECT_SLUG/g" \
    -e "s/{date}/$(date +%Y-%m-%d)/g" \
    -e "s/{current_phase}/阶段 0/g" \
    templates/learning-note-flow.md > /workspace/${PROJECT_SLUG}/todo.md
```

## 工作流程

### Step 1: 读取可用模板

扫描 `templates/` 目录，读取所有工作流模板文件。

```bash
# 列出所有可用模板
ls -1 templates/*.md
```

**输出**: 可用模板列表及其描述

### Step 2: 分析用户需求

**收集关键信息**:
- 学习主题是什么？
- 学习深度 (入门/上手/精通)
- 输出期望 (笔记/代码/项目)
- 时间限制

**需求分类**:
- **学习类**: 想要系统学习某个技术/概念
- **项目类**: 想要从零开始做一个项目
- **阅读类**: 想要阅读论文/书籍/文章
- **调研类**: 想要进行技术选型/对比分析

### Step 3: 选择并定制工作流

1. **选择模板**: 根据需求分类选择最匹配的模板
2. **定制内容**: 根据用户输入调整阶段内容
3. **生成 todo.md**: 使用模板生成项目特定的 todo.md

### Step 4: 创建项目目录

```bash
# 创建项目目录
PROJECT_DIR="/workspace/${PROJECT_SLUG}"
mkdir -p ${PROJECT_DIR}

# 生成 todo.md
# (从模板读取，替换变量)
```

### Step 5: 输出结果

**返回信息**:
- 项目目录路径
- todo.md 内容预览
- 可用工作流列表
- 后续步骤提示

**输出格式**:
```markdown
## ✅ 项目已创建

### 项目信息
- 主题: {topic}
- 目录: /workspace/{project_slug}/
- 工作流: learning-note-flow

### todo.md 已生成
[预览 todo.md 内容]

### 后续步骤
1. 运行 `/research-planner` 进行意图澄清
2. 系统将自动调用 workflow-orchestrator 生成 todo.md
3. 按照 todo.md 执行各阶段任务
```

## 模板格式规范

每个模板文件必须包含以下结构:

```markdown
# {工作流名称}

## 工作流描述

{简要描述工作流的用途}

## 阶段定义

### 阶段 0: {阶段名称}
- **负责技能**: /skill-name 或 agent-name
- **前置条件**: {阶段 N 完成} (可选)
- **检查项**:
  - [ ] 检查项 1
  - [ ] 检查项 2
- **输出文件**: `filename.md`
- **状态**: ⬜ 未开始

### 阶段 1: {阶段名称}
...

## 目录结构

```
/workspace/${PROJECT_SLUG}/
├── file1.md
├── file2.md
└── ...
```

## 状态流转

```
⬜ 未开始 → 🔲 进行中 → ✅ 已完成
```
```

## 与其他技能的关系

```
用户输入学习主题
    │
    ▼
research-planner (意图澄清)
    │
    ├──→ workflow-orchestrator (本技能)
    │       │
    │       ├── 扫描 templates/
    │       ├── 选择工作流
    │       └── 生成 todo.md
    │
    └──→ 生成 00_intent.md
         │
         ▼
research-collector (阶段 1-2)
         │
         ▼
outline-generator (阶段 3)
         │
         ▼
chapter-writer (阶段 4)
         │
         ▼
note-assembler (阶段 5)
         │
         ▼
note-beautifier (阶段 6)
```

## 调用示例

### 示例 1: 创建学习项目

```markdown
用户：我想学习 React Server Components

助手：
1. 扫描可用工作流模板
   - learning-note-flow (学习笔记生产)

2. 分析用户需求
   - 学习主题: React Server Components
   - 学习深度: 待确认
   - 输出类型: 学习笔记

3. 选择 learning-note-flow 模板

4. 生成 /workspace/react-server-components/todo.md

5. 返回项目路径和后续步骤
```

### 示例 2: 查看可用工作流

```markdown
用户：有哪些可用的工作流？

助手：
当前可用的工作流:

| 工作流 | 用途 | 阶段数 |
|-------|------|--------|
| learning-note-flow | 完整学习笔记生产 | 7 |

使用方式:
- 运行 `/research-planner` 创建新项目
- 系统会自动选择合适的工作流

添加新工作流:
- 在 `.claude/skills/workflow-orchestrator/templates/` 目录添加模板文件
- 遵循模板格式规范
```

## 扩展指南

### 添加新工作流

1. **创建模板文件**:
   ```bash
   # 在 templates/ 目录创建新模板
   touch .claude/skills/workflow-orchestrator/templates/{workflow-name}.md
   ```

2. **遵循模板格式**:
   - 包含工作流描述
   - 定义各阶段 (名称、负责技能、检查项、输出文件)
   - 说明目录结构

3. **更新 SKILL.md**:
   - 在"当前可用模板"表格中添加新行
   - 说明触发条件和适用场景

4. **测试验证**:
   - 运行 `/research-planner` 测试新工作流
   - 验证 todo.md 生成正确
   - 检查阶段依赖关系

### 模板示例

```markdown
# 项目实战工作流

## 工作流描述

从零开始完成一个完整项目的流程。

## 阶段定义

### 阶段 0: 需求分析
- **负责技能**: /research-planner
- **检查项**:
  - [ ] 项目目标已明确
  - [ ] 技术栈已确定
  - [ ] 功能范围已界定
- **输出文件**: `00_requirements.md`
- **状态**: ⬜ 未开始

### 阶段 1: 设计规划
...
```

## 注意事项

1. **模板兼容性**: 新模板必须遵循格式规范
2. **阶段依赖**: 确保前置条件正确设置
3. **输出文件**: 使用固定命名，方便下游读取
4. **状态管理**: 正确维护 ⬜/🔲/✅ 状态
5. **用户确认**: 关键阶段需要用户确认后才继续
