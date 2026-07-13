# Workflow Routing

本规则汇总项目内可用工作流，并说明什么时候使用哪个工作流。

## Directory Layout

```text
.claude/workflows/{workflow-id}/workflow.md
.claude/workflows/{workflow-id}/state-template.md
workspace/workflow-runs/{task}.workflow.md
```

## Available Workflows

<!-- workflow-routing:generated:start -->
| Workflow ID | Required | When To Use | Positive Triggers | Excludes | Definition | State File Pattern |
| --- | --- | --- | --- | --- | --- | --- |
| `batch-note-update-flow` | yes | 多篇既有笔记批量更新、逐篇局部 patch | 批量更新旧笔记；多篇笔记过时；更新一个目录的笔记；refresh multiple notes | 只更新单篇笔记；仅生成 MOC | `.claude/workflows/batch-note-update-flow/workflow.md` | `workspace/workflow-runs/update-{scope}.workflow.md` |
| `learning-note-flow` | yes | 新主题学习笔记生产、资料收集、逐章写作、Obsidian 发布 | 想学；帮我整理；研究一下；了解一下；不知道从哪开始；research planning；explore topic | 仅回答一般知识问题；仅修改既有笔记；仅生成 MOC | `.claude/workflows/learning-note-flow/workflow.md` | `workspace/workflow-runs/{topic}.workflow.md` |
| `legacy-note-import-flow` | yes | 旧笔记批量导入、盘点、规范化、可选更新 | 旧笔记导入；已有笔记；一堆笔记；批量整理；迁移到这个项目；按项目规范；import existing notes；normalize notes | 仅更新已有笔记内容；仅生成 MOC | `.claude/workflows/legacy-note-import-flow/workflow.md` | `workspace/workflow-runs/import-{source}.workflow.md` |
<!-- workflow-routing:generated:end -->

## Routing Rules

- 在任何会修改项目文件、运行项目命令或调用外部服务的操作前，先读取本文件，并根据用户原始请求匹配 `Workflow ID`。
- 正向触发条件命中且未命中排除条件时，必须选择对应 `workflow_id`；`Required: yes` 不允许改走普通执行路径。
- 多个工作流同时命中时选择更具体者；仍无法区分时先请求用户确认。
- 如果 `workspace/workflow-runs/` 中已有匹配状态文件，优先恢复已有运行，不要重复创建。
- 如果没有状态文件，按对应 workflow 模板创建命名状态文件。
- 状态文件不要统一命名为 `todo.md`；除非项目只有一个固定工作流。
- 创建或恢复运行后，读取当前状态文件，并通过 `.claude/scripts/todo-state.sh` 启动当前 phase，才能执行该 phase 的工作。
- 每阶段开始前必须读取当前状态文件。
- 阶段状态只能通过 `.claude/scripts/todo-state.sh` 更新。
- 工作流新增、修改、重命名或删除后，必须运行 `.claude/scripts/sync-workflow-routing.sh`；`--check` 未通过时更新不算完成。

## Active Runs

| State File | Workflow ID | Task | Current Phase | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| | | | | | |
