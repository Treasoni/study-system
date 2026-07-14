# Study System

Study System 是一个面向学习笔记生产的 Codex 项目模板。它把资料收集、结构化写作、旧笔记导入、旧笔记更新、Obsidian 美化和 MOC 索引整理拆成可恢复的阶段，让你可以用 Codex 按步骤产出可维护的 Markdown 学习笔记。

这个仓库同时保留 Claude Code 配置镜像，但日常使用 Codex 时只需要关注 `AGENTS.md` 和 `.codex/`。

## 适合做什么

- 从零研究一个主题，并产出完整学习笔记。
- 把已有 Markdown 或 Obsidian 笔记批量接入统一规范。
- 批量更新多篇过时笔记，并保留逐篇更新报告。
- 把最终笔记美化成 Obsidian 友好的 Markdown。
- 为 Obsidian vault 维护 MOC（Map of Content）目录笔记。
- 给其他项目复用 prompt cache 优化模板。

## 快速开始

### 1. 准备项目

```bash
git clone <your-repo-url> study-system
cd study-system
cp .env.example .env
```

按需编辑 `.env`：

```bash
WORKSPACE_PATH=./workspace
NOTES_OUTPUT_PATH=${WORKSPACE_PATH}/output
CHAPTERS_PATH=${WORKSPACE_PATH}/chapters
MINIMAX_API_KEY=your-key-here
```

`.env` 不要提交到 Git。默认工作区是 `./workspace`，没有特别需要时不要改成绝对路径。

### 2. 在 Codex 中打开项目

把 Codex 的工作目录切到本仓库根目录。Codex 会读取 `AGENTS.md`，并按 `.codex/rules/`、`.codex/skills/` 和 `.codex/workflows/` 中的项目规则执行。

常用说法示例：

```text
我想学 React Server Components，帮我整理成 Obsidian 笔记
```

```text
把 notes/old 里的旧笔记导入这个项目，并按 Obsidian 规范整理
```

```text
批量更新 vault/AI 目录下关于 OpenAI API 的旧笔记
```

Codex 会先判断是否命中强制工作流。命中后会创建或恢复 `workspace/workflow-runs/*.workflow.md` 状态文件，并在每个阶段结束时让你确认后再继续。

## 三条核心工作流

### 新主题学习笔记

适合“想学”“研究一下”“帮我整理某个主题”。

```text
research-planner
-> research-collector
-> outline-generator
-> chapter-writer
-> note-assembler
-> note-beautifier
-> moc-organizer
```

主要产物通常位于：

```text
workspace/<project-slug>/
├── 00_intent.md
├── 01_explore_result.md
├── 02_deep_research.md
├── 03_outline.md
├── chapters/
└── output/final_note.md
```

如果要发布到 Obsidian，请告诉 Codex vault 路径、目标目录和可选 MOC 路径。未指定时，最终笔记只会写入项目 `output/`。

### 旧笔记导入

适合“已有一堆笔记”“迁移到这个项目”“按项目规范整理”。

```text
legacy-note-importer
-> note-beautifier
-> note-updater（可选）
-> moc-organizer
```

流程会先盘点旧笔记，生成迁移计划，经你确认后再分批规范化。默认不会覆盖原始文件，除非你明确要求原地 patch。

### 多篇旧笔记批量更新

适合“多篇笔记过时了”“更新一个目录的笔记”“refresh multiple notes”。

```text
batch-note-updater
-> note-updater
-> moc-organizer（可选）
```

流程会先生成更新清单和批量计划，再逐篇做局部更新。它的重点是小范围 patch，而不是重写整篇笔记。

## 常用目录

```text
.
├── AGENTS.md                  # Codex 项目入口规则
├── .env.example               # 环境变量模板
├── .codex/
│   ├── skills/                # 项目级 Codex skills
│   ├── workflows/             # 命名工作流定义
│   ├── rules/                 # 长期规则
│   ├── agents/                # 可模拟的写作 agent 角色
│   ├── scripts/               # 状态、同步和辅助脚本
│   └── hooks.json             # 项目本地 hooks
├── templates/                 # prompt cache 优化模板
└── workspace/                 # 默认运行产物目录，按需生成
```

Codex 专用配置只写在 `.codex/`。不要手动把 Codex 配置写到全局 `~/.codex/`，也不要在普通 Codex 任务里修改 `.claude/`。

## 状态文件怎么用

每个强制工作流都有一个命名状态文件，例如：

```text
workspace/workflow-runs/react-server-components.workflow.md
workspace/workflow-runs/import-old-notes.workflow.md
workspace/workflow-runs/update-ai-notes.workflow.md
```

状态切换由脚本维护：

```bash
.codex/scripts/todo-state.sh workspace/workflow-runs/demo.workflow.md start P0
.codex/scripts/todo-state.sh workspace/workflow-runs/demo.workflow.md complete P0
.codex/scripts/todo-state.sh workspace/workflow-runs/demo.workflow.md skip P3 "用户选择随性模式"
.codex/scripts/todo-state.sh workspace/workflow-runs/demo.workflow.md block P2 "素材来源不足"
```

通常不需要你手动运行这些命令；Codex 会按工作流规则调用。你只需要在阶段检查点确认方向、质量和输出位置。

## 使用 prompt cache 模板

`templates/` 目录可复制到其他项目，用来优化 Codex、Claude Code 或两者的提示缓存命中率。

先只检查，不写入文件：

```bash
bash templates/prompt-cache-bootstrap.sh --check --platform both --target /path/to/project
```

确认后安装：

```bash
bash templates/prompt-cache-bootstrap.sh --apply --platform both --target /path/to/project
```

只配置一个平台时，把 `both` 换成 `codex` 或 `claude`。

## 协作和安全约定

- 提交前先查看 `git status --short`，不要覆盖他人的未提交改动。
- 不提交 `.env`、API key、token、私钥或本地个人配置。
- 不把用户机器上的绝对路径硬编码进项目产物。
- 修改 `.codex/skills`、`.codex/agents`、`.codex/rules` 或 `.codex/scripts` 后，需要运行 `.codex/scripts/sync-codex-to-claude.sh` 维护 Claude Code 镜像。
- 新增、修改、重命名或删除工作流后，需要运行 `.codex/scripts/sync-workflow-routing.sh`，并确保 `--check` 通过。
- Obsidian 发布前先确认目标 vault、目录和同名文件处理策略。

## 给使用者的推荐流程

1. 先用自然语言告诉 Codex 你的目标、已有材料、期望深度和输出位置。
2. 等 Codex 生成阶段计划或状态文件后，确认第一阶段是否符合你的意图。
3. 每个检查点只反馈方向、删改要求和质量标准，不需要手动维护中间文件。
4. 最终发布前确认保存到项目 `output/` 还是 Obsidian vault。
5. 发布后如需要索引，提供 MOC 文件路径，让 Codex 只追加索引，不复制正文。

## 排错

| 问题 | 处理方式 |
| --- | --- |
| 不确定该走哪个流程 | 直接描述目标，Codex 会按 `.codex/rules/workflow-routing.md` 判断；无法判断时会询问你 |
| 工作流中断 | 让 Codex 读取 `workspace/workflow-runs/*.workflow.md` 并从当前阶段恢复 |
| 没有指定 Obsidian 路径 | 先输出到项目 `workspace/<project-slug>/output/` |
| 旧笔记怕被覆盖 | 选择复制到 `normalized/` 或 `updates/`，不要选择原地 patch |
| 资料需要联网 | 明确告诉 Codex 需要收集最新资料，并确认可用来源范围 |

## 许可证

如果你要对外发布或复用本项目，请先补充明确的许可证文件。
