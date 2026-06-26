---
name: learning-note-orchestrator
description: 学习笔记全流程编排器：从意图澄清到最终输出的完整工作流协调。自动调用现有 skills 和 agents 完成各阶段任务。触发词：学习笔记、完整流程、从头开始、全流程、orchestrator、workflow、learning notes workflow。
---

# Learning Note Orchestrator - 学习笔记全流程编排器

协调从资料收集到最终输出的完整学习笔记工作流，自动调用现有 skills 和 agents 完成各阶段任务。

## 触发条件

当用户提出以下类型的请求时，调用此技能:

- "我想写一篇完整的学习笔记"
- "从头开始，帮我做一篇关于 XX 的笔记"
- "走一遍完整流程"
- "学习笔记全流程"
- "orchestrator" / "workflow"
- 任何涉及完整学习笔记工作流的请求

## 核心原则

1. **技能复用**：调用现有 skills/agents，不重复实现
2. **阶段检查点**：每阶段结束让用户确认
3. **进度跟踪**：自动更新 todo.md
4. **中间产物文件化**：每个阶段输出落盘

## 工作流程

```
阶段 0: 意图澄清      → 调用 /research-planner
    ↓ 输出: 00_intent.md
阶段 1: 探测式收集    → 调用 /research-collector
阶段 2: 深度收集      → 调用 /research-collector
    ↓ 输出: 02_deep_research.md
阶段 3: 大纲生成      → 调用 outline-generator agent
    ↓ 输出: 03_outline.md
阶段 4: 逐章写作      → 调用 chapter-writer agent
    ↓ 输出: chapters/{N}_{章节名}.md
阶段 5: 收尾组装      → 调用 note-assembler agent
    ↓ 输出: output/final_note.md
阶段 6: 美化输出      → 调用 /note-beautifier
    ↓ 输出: output/final_note.{format}
```

## 详细执行步骤

### 阶段 0: 意图澄清

**调用技能**: `/research-planner`

**操作**:
1. 创建工作目录
   ```bash
   mkdir -p /workspace/learning_notes/chapters
   mkdir -p /workspace/learning_notes/output
   ```

2. 初始化 Todo 文件
   - 复制模板到 `/workspace/learning_notes/todo.md`

3. 调用 `/research-planner` 进行需求澄清
   - 技能会自动处理：意图分析、轻量级提问、探测式引导
   - 生成意图文件：`/workspace/learning_notes/00_intent.md`

**检查点**: 研究计划确认后进入下一阶段

### 阶段 1-2: 资料收集

**调用技能**: `/research-collector`

**操作**:
1. 调用 `/research-collector "{主题} {方向}"`
   - 技能会自动处理：探测式收集、深度收集、两阶段策略
   - 生成素材文件：`/workspace/learning_notes/02_deep_research.md`

2. 向用户确认素材质量

**检查点**: 素材确认后进入下一阶段

### 阶段 3: 大纲生成（大纲模式）

**调用 Agent**: `outline-generator`

**操作**:
```bash
# 使用 Agent 工具调用 outline-generator
Agent(
  subagent_type: "outline-generator",
  prompt: "基于 /workspace/learning_notes/00_intent.md 和 /workspace/learning_notes/02_deep_research.md 生成大纲"
)
```

- Agent 自动读取素材并生成大纲
- 输出到：`/workspace/learning_notes/03_outline.md`

**检查点**: 大纲确认后进入下一阶段

**注意**: 随性模式跳过此阶段

### 阶段 4: 逐章写作

**调用 Agent**: `chapter-writer`

**操作**:
```bash
# 使用 Agent 工具调用 chapter-writer
Agent(
  subagent_type: "chapter-writer",
  prompt: "基于 /workspace/learning_notes/03_outline.md 逐章写作"
)
```

- Agent 自动逐章写作，每章完成后暂停等待确认
- 章节输出到：`/workspace/learning_notes/chapters/`

**检查点**: 每章写完都暂停确认

### 阶段 5: 收尾组装

**调用 Agent**: `note-assembler`

**操作**:
```bash
# 使用 Agent 工具调用 note-assembler
Agent(
  subagent_type: "note-assembler",
  prompt: "组装 /workspace/learning_notes/chapters/ 下的所有章节"
)
```

- Agent 自动组装章节，添加过渡、生成目录
- 输出到：`/workspace/learning_notes/output/final_note.md`

**检查点**: 组装结果确认后进入下一阶段

### 阶段 6: 美化输出

**调用技能**: `/note-beautifier`

**操作**:
1. 询问用户输出格式（PDF/Word/PPT）
2. 调用 `/note-beautifier` 进行格式转换
3. 输出到：`/workspace/learning_notes/output/final_note.{format}`

**检查点**: 输出结果确认

## Todo 进度跟踪

在每个阶段完成时，更新 `/workspace/learning_notes/todo.md`:

```markdown
## 阶段 X: {阶段名}
- [x] 任务 1
- [x] 任务 2
- [ ] 任务 3

**状态**：✅ 已完成
```

## 文件结构

```
/workspace/learning_notes/
├── 00_intent.md              ← 意图文件
├── 02_deep_research.md       ← 素材文件
├── 03_outline.md             ← 大纲文件（大纲模式）
├── todo.md                   ← 执行检查清单
├── chapters/
│   ├── 01_xxx.md
│   └── ...
└── output/
    └── final_note.md/pdf     ← 最终产物
```

## 错误处理

| 情况 | 处理方式 |
|------|---------|
| 缺少意图文件 | 重新调用 `/research-planner` |
| 缺少素材文件 | 重新调用 `/research-collector` |
| 缺少大纲文件 | 重新调用 `outline-generator` |
| 缺少章节文件 | 重新调用 `chapter-writer` |
| 工具缺失 | 提示用户安装（如 pandoc） |

## 技能依赖关系

```
learning-note-orchestrator (本技能)
    │
    ├── /research-planner      (意图澄清)
    ├── /research-collector    (资料收集)
    ├── outline-generator      (大纲生成 - agent)
    ├── chapter-writer         (逐章写作 - agent)
    ├── note-assembler         (收尾组装 - agent)
    └── /note-beautifier       (美化输出)
```

## 注意事项

1. **不要重复实现**：每个阶段都调用对应的 skill/agent
2. **检查点必须执行**：每阶段结束让用户确认
3. **进度必须更新**：及时更新 todo.md
4. **支持断点续传**：根据 todo.md 判断从哪继续
