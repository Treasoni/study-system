# Study System

学习笔记自动化生产系统。

## 可用工作流

每个工作流由「planner + orchestrator + 模板文件对」组成：

| 工作流 | 对应 planner | 模板文件对 | 用途 |
|-------|-------------|-----------|------|
| learning-note-flow | `/research-planner` | learning-note-flow.md / learning-note-todo.md | 完整学习笔记生产 |

> 新增工作流：在 `.claude/skills/workflow-orchestrator/templates/` 创建说明书 + todo 模板文件对，并新建对应 planner。
> orchestrator 不直接面向用户，由各 planner 调用。planner 负责领域特定的意图澄清，orchestrator 负责生成 todo.md。

## 核心原则

### 必须执行 todo.md

**每个技能/Agent 启动时必须:**
1. 读取项目目录下的 `todo.md`
2. 确认当前阶段状态
3. 不可跳步，不可不做

**状态流转（[PN] 标记精准定位，不跨阶段污染）**:
```
[PN] ⬜ 未开始 → [PN] 🔲 进行中 → [PN] ✅ 已完成
```

### 断点恢复机制

1. **读取状态**: 每个技能启动时读取 todo.md
2. **验证前置**: 检查前置阶段是否为 ✅
3. **更新状态**: 开始时改为 🔲，完成后改为 ✅
4. **阶段推进**: 更新 `当前阶段` 字段

## 文件结构

```
/workspace/
├── {topic-slug}/
│   ├── 00_intent.md
│   ├── 01_explore_result.md
│   ├── 02_deep_research.md
│   ├── 03_outline.md
│   ├── todo.md
│   ├── chapters/
│   └── output/
└── ...
```

## 技能依赖关系

完整编排流程见 `.claude/skills/workflow-orchestrator/SKILL.md`，各工作流的阶段执行流见 `templates/` 下对应说明书。核心链路：

```
research-planner → workflow-orchestrator（生成 todo.md）
→ research-collector → outline-generator → chapter-writer
→ note-assembler → note-beautifier
```

## 工作流执行规则

### 阶段完成检查点

每阶段结束都必须让用户确认后才进入下一阶段:

| 阶段 | 检查点内容 |
|------|-----------|
| 0 → 1 | 用户确认意图文件和研究计划 |
| 1 → 2 | 用户确认素材质量 |
| 2 → 3 | 用户确认大纲顺序和深度 |
| 3 → 4 | 用户确认大纲（大纲模式） |
| 4 → 5 | 所有章节写作完成 |
| 5 → 6 | 用户确认组装结果 |

### 错误处理

| 情况 | 处理方式 |
|------|---------|
| 缺少意图文件 | 重新调用 `/research-planner` |
| 缺少素材文件 | 重新调用 `/research-collector` |
| 缺少大纲文件 | 重新调用 `outline-generator` |
| 缺少章节文件 | 重新调用 `chapter-writer` |
| 工具缺失 | 提示用户安装（如 pandoc） |
