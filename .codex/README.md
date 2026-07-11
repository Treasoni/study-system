# Codex Compatibility Layer

这个目录是 Study System 的 Codex 专用配置层，用来复用原 Claude Code 工作流，但不修改 `.claude/`。

## Layout

- `skills/`：从 `.claude/skills/` 派生的 Codex skill 副本。
- `rules/`：从 `.claude/rules/` 派生的 Codex rules 副本。
- `rules/obsidian/`：Obsidian 输出、双链、MOC、本地发布规则。
- `agents/`：从 `.claude/agents/` 派生的 agent 角色说明，供 Codex 在当前线程中模拟执行。
- `hooks.json`：本项目 Codex hooks 注册表。
- `hooks/`：本项目 Codex hook 脚本。
- `scripts/`：Codex 可用的辅助脚本副本。
- `commands/`：预留给 Codex prompt/command 封装。

## Isolation

Codex 运行时应写本项目 `.codex/` 或学习项目工作区，不写 `.claude/`，也不写全局 `~/.codex/`。如果需要同时维护 Claude Code 与 Codex 两套配置，先修改本项目 `.codex/`，再由用户确认是否同步回 `.claude/`。

## Project-Local Hooks

本项目 hooks 只在 `.codex/hooks.json` 中注册：

- `Stop` -> `.codex/hooks/post-conversation.sh`

默认 Stop hook 会在检测到项目改动时执行 `git add -A` 并自动提交，不自动推送。需要临时禁用自动提交时，设置 `CODEX_AUTO_GIT=0`；需要推送时再额外设置 `CODEX_AUTO_GIT_PUSH=1`。

## Note Workflow Extensions

本项目面向“写学习笔记”而不是泛用文档生成：

- 新笔记：按 `research-planner -> ... -> note-beautifier -> moc-organizer` 执行。
- 旧笔记导入：使用 `legacy-note-importer` 先盘点和生成迁移计划，再按批次规范化。
- 旧笔记更新：使用 `note-updater`，只局部更新过时段落。
- 多篇旧笔记批量更新：使用 `batch-note-updater` 先生成更新清单和批量计划，再逐篇调用 `note-updater`。
- Obsidian 美化：只输出 Obsidian Markdown，不默认导出 PDF/Word/PPT。
- 输出位置：每次发布前由用户指定 vault 路径和 vault 内目录。
- MOC：每次发布或更新笔记后同步一次，不复制正文。
- Token 优化：读取大文件时按阶段、章节、关键词局部读取。
