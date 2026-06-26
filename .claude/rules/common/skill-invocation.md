
# 技能调用指南

当用户请求涉及技能（skill）领域时，优先调用对应技能，而非自行实现。

## 核心原则

1. **技能优先**：用户请求匹配到已有技能时，必须通过 `Skill` 工具调用，不要手动实现技能已覆盖的功能
2. **精准匹配**：根据用户意图和触发词选择最合适的技能，避免误触发或漏触发
3. **不要猜测**：不确定是否有对应技能时，查阅下方技能列表再决定
4. **单一技能**：每次调用一个技能；如需多个技能协作，按顺序逐个调用

## Plugin Skills 命名空间

Plugin 中的 skills 会显示为 `/plugin-name:skill-name` 的形式，而不是直接的 `/skill-name`。

例如，如果 plugin 名为 `obsidian`，其中的 skill 会显示为：
- `/obsidian:markdown` (而不是 `obsidian-markdown`)
- `/obsidian:cli` (而不是 `obsidian-cli`)
- `/obsidian:bases` (而不是 `obsidian-bases`)

## 技能列表

#### 图表与可视化

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `excalidraw-diagram` | 生成 Excalidraw 流程图、思维导图、架构图 | 画图、流程图、思维导图、Excalidraw、可视化、diagram |
| `json-canvas` | 生成 JSON Canvas 格式的可视化画布 | canvas、画布、JSON Canvas |

#### Obsidian 相关 (Plugin: obsidian)

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `/obsidian:markdown` | 处理 Obsidian 特有的 Markdown 语法 | Obsidian、wikilink、双链、嵌入 |
| `/obsidian:cli` | 通过 CLI 操作 Obsidian vault | Obsidian 命令行、vault 操作 |
| `/obsidian:bases` | 处理 Obsidian Bases 数据库 | Bases、数据库、table view |
#### 资料研究

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `research-planner` | 资料收集前的需求澄清与引导 | 想学、帮我整理、研究一下、了解一下、不知道从哪开始、帮我看看、research planning、explore topic |
| `research-collector` | 多策略高效资料收集 | 收集资料、研究资料、搜集信息、资料整理、research、gather information、collect资料 |

#### 学习笔记工作流

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `learning-note-orchestrator` | 学习笔记全流程编排：从意图澄清到最终输出 | 学习笔记、完整流程、从头开始、全流程、orchestrator、workflow、learning notes workflow |
| `note-assembler` | 将章节组装成完整笔记（由 agent 调用） | 组装、合并章节、收尾、拼装、assemble |
| `note-beautifier` | Obsidian 笔记智能美化专家 | 美化、Obsidian、优化格式、笔记美化、beautify |


#### 内容提取

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `defuddle` | 从网页提取正文内容 | 提取网页、网页正文、defuddle |

#### 工具发现

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `tool-discovery` | 查看可用的资料收集工具 | 可用工具、有哪些工具、工具列表、收集工具、search tools |

#### 开发工具

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `skill-creator` | 创建新的 Claude Code 技能 | 创建 skill、新技能、写一个 skill |

### 1. 分析意图

- 用户想做什么？（创建、读取、修改、删除、转换）
- 涉及什么文件类型？（.pdf、.docx、.xlsx、.md）
- 是否属于特定平台？（Obsidian、Excalidraw）

### 2. 匹配技能

- 优先匹配**最具体**的技能
- 触发词可能出现在用户消息的任何位置
- 中英文触发词同等对待


### 错误处理

- 技能调用失败时，向用户说明原因并建议替代方案
- 不要静默失败，明确告知用户发生了什么
- 如果技能不支持某个操作，如实告知而非强行实现
