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
- `platform/`：统一 manifest 注册表、Schema 和权限策略。
- `commands/`：预留给 Codex prompt/command 封装。

## Isolation

Codex 运行时应写本项目 `.codex/` 或学习项目工作区，不写 `.claude/`，也不写全局 `~/.codex/`。修改 `.codex/skills`、`.codex/agents`、`.codex/rules` 或 `.codex/scripts` 后，按项目规则运行同步脚本维护 Claude Code 镜像。

## Project-Local Hooks

本项目 hooks 只在 `.codex/hooks.json` 中注册：

- `Stop` -> `.codex/hooks/post-conversation.sh`

默认 Stop hook 只报告检测到的项目改动，不提交也不推送。设置 `CODEX_AUTO_GIT=1` 才会在工作区和暂存区密钥扫描通过后执行 `git add -A` 和自动提交；推送始终需要人工执行。

## Agent Platform Registry

Workflow、Skill、Subagent 和 Hook 都以相邻的 `manifest.yaml` 作为统一注册契约。注册表按目录自动发现它们，并校验入口、SemVer 版本、依赖、权限声明及 Hook 注册：

```bash
python3 .codex/platform/manifest-registry.py --root . validate
python3 .codex/platform/manifest-registry.py --root . list
```

`manifest-platform` Skill 携带可复制的安装器；其他项目安装后可使用同一份 Schema 和校验器。manifest 声明权限请求，但不会绕过 Codex 的用户授权或工具策略。

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
