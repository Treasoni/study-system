---
name: research-planner
description: 学习笔记需求澄清与引导。分析用户学习需求，引导明确学习目标和方向，调用 workflow-orchestrator 生成项目结构。触发词：想学、帮我整理、研究一下、了解一下、不知道从哪开始、research planning、explore topic。
---

# Research Planner - 学习笔记需求澄清与引导

分析用户学习需求，引导明确学习目标和方向。

## 核心职责

1. **意图澄清**: 通过提问和探测，帮用户明确学习方向
2. **调用编排器**: 调用 workflow-orchestrator 生成项目结构和 todo.md

## 触发条件

当用户提出以下类型的请求时，调用此技能:

- "我想学 XX"
- "帮我研究一下 XX"
- "不知道从哪开始学"
- "帮我整理 XX 相关的知识"
- 任何涉及学习新主题的请求

## 工作流程

### Step 0: 读取 todo.md 状态（必须执行）

**启动时必须确定项目文件夹并检查 todo.md：**

```bash
# 从用户输入生成项目 slug
TOPIC="用户输入的主题"
PROJECT_SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
PROJECT_DIR="/workspace/${PROJECT_SLUG}"

# 读取 todo.md
cat ${PROJECT_DIR}/todo.md 2>/dev/null || echo "不存在"
```

**状态检查：**
- 如果 todo.md 不存在：继续执行 Step 1
- 如果 todo.md 存在但阶段 0 为 ⬜ 或 🔲：允许重新执行
- 如果 todo.md 存在且阶段 0 为 ✅：提示用户"意图阶段已完成，是否要重新开始？"

---

### Step 1: 分析用户需求

**收集关键信息**:

```yaml
必填信息:
  - 学习主题: 要学什么？
  
可选信息 (如未提供，通过提问收集):
  - 学习深度: 入门/上手/精通
  - 现有基础: 零基础/有了解/熟悉
  - 学习目的: 实战/概念/心得/对比
  - 时间限制: 期望多久完成
```

**需求分类**:
- **学习类**: 想要系统学习某个技术/概念
- **项目类**: 想要从零开始做一个项目
- **阅读类**: 想要阅读论文/书籍/文章
- **调研类**: 想要进行技术选型/对比分析

---

### Step 2: 探测式引导

**场景判断**:

#### 场景 A: 信息充足
用户已经明确说明学习主题、深度、目的。

**操作**: 直接进入 Step 3

#### 场景 B: 方向模糊
用户有学习主题，但方向不明确。

**操作**:
1. 派发 2-3 个 subagent 并行探测
2. 每个 subagent 搜索不同角度:
   - Subagent 1: 搜索 "XX 入门教程"
   - Subagent 2: 搜索 "XX 最佳实践"
   - Subagent 3: 搜索 "XX 常见问题"
3. 汇总探测结果，展示方向菜单
4. 等待用户选择

#### 场景 C: 完全无方向
用户只有模糊的兴趣，不知道从哪开始。

**操作**:
1. 派发更多 subagent 进行深度探测
2. 搜索 "XX 是什么"、"XX 能做什么"、"XX 学习路线"
3. 提供完整选项菜单
4. 引导用户做出选择

---

### Step 3: 调用 workflow-orchestrator

**调用方式**:

```markdown
调用 /workflow-orchestrator 执行:
1. 选择 learning-note-flow 工作流模板
2. 生成 /workspace/${PROJECT_SLUG}/todo.md
```

**传递参数**:
- 主题 (topic)
- 学习深度 (depth)
- 用户基础 (level)
- 学习目的 (purpose)

---

### Step 4: 生成意图文件

基于用户确认的方向，生成意图文件:

```bash
# 文件路径
/workspace/${PROJECT_SLUG}/00_intent.md
```

**意图文件格式**:

```markdown
# {主题} - 意图文件

## 基本信息

- **主题**: {topic}
- **项目标识**: {project_slug}
- **创建时间**: {date}
- **当前阶段**: 阶段 0

## 学习目标

### 笔记类型
{实战笔记/概念笔记/心得笔记/对比笔记}

### 学习深度
{入门/上手/精通}

### 用户基础
{零基础/有了解/熟悉}

## 研究计划

### 探索方向
1. {方向 1}
2. {方向 2}
3. {方向 3}

### 重点收集
- **核心概念**: {列出需要理解的核心概念}
- **实战代码**: {列出需要的代码示例}
- **常见坑**: {列出需要避免的问题}
- **工具链**: {列出相关工具和生态}

### 信源偏好
- 官方文档: {是/否}
- 技术博客: {是/否}
- 社区讨论: {是/否}
- 学术论文: {是/否}

## 备注

{其他需要注意的事项}
```

---

### Step 5: 输出结果

**返回信息**:

```markdown
## ✅ 意图澄清完成

### 项目信息
- 主题: {topic}
- 目录: /workspace/{project_slug}/
- 工作流: learning-note-flow

### 意图文件
已生成: `/workspace/{project_slug}/00_intent.md`

### todo.md
已生成: `/workspace/{project_slug}/todo.md`

### 后续步骤
1. 系统将调用 `/research-collector` 收集资料
2. 按照 todo.md 执行各阶段任务
3. 每阶段完成后需要用户确认
```

## 与其他技能的关系

```
用户输入学习主题
    │
    ▼
research-planner (本技能)
    │
    ├──→ workflow-orchestrator (生成 todo.md)
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

### 示例 1: 明确需求

```markdown
用户：我想学习 React Server Components，帮我整理一下

助手：
1. 分析用户需求
   - 学习主题: React Server Components
   - 学习深度: 待确认
   - 学习目的: 学习笔记

2. 调用 workflow-orchestrator
   - 选择 learning-note-flow 工作流
   - 生成 /workspace/react-server-components/todo.md

3. 生成意图文件
   - /workspace/react-server-components/00_intent.md

4. 返回后续步骤
```

### 示例 2: 模糊需求

```markdown
用户：我想学 React，不知道从哪开始

助手：
1. 分析用户需求
   - 学习主题: React
   - 学习深度: 不明确
   - 学习目的: 不明确

2. 探测式引导
   - 派发 subagent 探测不同方向
   - 展示方向菜单:
     A. React 基础入门
     B. React 状态管理
     C. React 性能优化
     D. React 项目实战

3. 等待用户选择后，继续执行 Step 3-5
```

## 注意事项

1. **必须调用 workflow-orchestrator**: 不要手动创建 todo.md
2. **保持意图文件简洁**: 只记录关键信息，不要过度详细
3. **等待用户确认**: 关键选择需要用户确认
4. **支持中断恢复**: 如果用户中途退出，下次可以继续
