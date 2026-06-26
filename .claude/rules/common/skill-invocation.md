---
paths:
  - ".claude/skills"
---

# 技能调用指南

当用户请求涉及技能（skill）领域时，优先调用对应技能，而非自行实现。

## 核心原则

1. **技能优先**：用户请求匹配到已有技能时，必须通过 `Skill` 工具调用，不要手动实现技能已覆盖的功能
2. **精准匹配**：根据用户意图和触发词选择最合适的技能，避免误触发或漏触发
3. **不要猜测**：不确定是否有对应技能时，查阅下方技能列表再决定
4. **单一技能**：每次调用一个技能；如需多个技能协作，按顺序逐个调用

## 技能列表

### 插件技能（来自 plugins）

通过 `.claude/settings.local.json` 的 `enabledPlugins` 启用，位于 `.claude/skills/` 目录之外。

#### 文件处理

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `pdf` | 读取、合并、拆分、旋转、加密、填表、OCR 等 PDF 操作 | PDF、.pdf、读取 PDF、合并 PDF |
| `docx` | 创建、读取、编辑 Word 文档 | Word、.docx、文档、docx |
| `xlsx` | 创建、读取、编辑 Excel 表格 | Excel、.xlsx、表格、电子表格 |
| `pptx` | 创建、读取、编辑 PowerPoint 演示文稿 | PPT、PowerPoint、.pptx、幻灯片、演示文稿 |

#### 图表与可视化

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `excalidraw-diagram` | 生成 Excalidraw 流程图、思维导图、架构图 | 画图、流程图、思维导图、Excalidraw、可视化、diagram |
| `json-canvas` | 生成 JSON Canvas 格式的可视化画布 | canvas、画布、JSON Canvas |

#### Obsidian 相关

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `obsidian-markdown` | 处理 Obsidian 特有的 Markdown 语法 | Obsidian、wikilink、双链、嵌入 |
| `obsidian-cli` | 通过 CLI 操作 Obsidian vault | Obsidian 命令行、vault 操作 |
| `obsidian-bases` | 处理 Obsidian Bases 数据库 | Bases、数据库、table view |
#### 内容提取

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `defuddle` | 从网页提取正文内容 | 提取网页、网页正文、defuddle |

#### 开发工具

| 技能 | 触发场景 | 关键触发词 |
|------|----------|-----------|
| `skill-creator` | 创建新的 Claude Code 技能 | 创建 skill、新技能、写一个 skill |

### 本地自定义技能（Local）

位于 `.claude/skills/` 目录下的自定义技能，由项目团队维护。

> 当前无本地自定义技能。如需添加，请在 `.claude/skills/<skill-name>/` 目录下创建 `skill.md`。

## 调用流程

```
用户请求 → 分析意图 → 匹配技能 → 调用 Skill 工具 → 执行技能流程 → 返回结果
                ↓
          无匹配技能 → 直接完成任务
```

### 1. 分析意图

- 用户想做什么？（创建、读取、修改、删除、转换）
- 涉及什么文件类型？（.pdf、.docx、.xlsx、.md）
- 是否属于特定平台？（Obsidian、Excalidraw）

### 2. 匹配技能

- 优先匹配**最具体**的技能
- 触发词可能出现在用户消息的任何位置
- 中英文触发词同等对待

### 3. 调用示例

```bash
# 用户说"帮我读取这个 PDF"
Skill(pdf, args="读取并提取 document.pdf 的文本内容")

# 用户说"画一个登录流程图"
Skill(excalidraw-diagram, args="绘制用户登录流程图")

# 用户说"帮我创建一个新的 skill"
Skill(skill-creator, args="创建一个用于代码审查的 skill")
```

## 注意事项

### 多技能协作

当任务需要多个技能时，按逻辑顺序依次调用：

1. 先用 `defuddle` 提取网页内容
2. 再用 `pdf` 生成 PDF 文档
3. 最后用 `excalidraw-diagram` 生成流程图

### 技能与直接实现的边界

| 场景 | 做法 |
|------|------|
| 用户明确要求使用某个技能 | 直接调用该技能 |
| 用户请求匹配技能触发词 | 调用对应技能 |
| 简单的文件读写（非特定格式） | 无需调用技能，直接操作 |
| 技能无法满足的特殊需求 | 先调用技能获取基础能力，再手动补充 |

### 错误处理

- 技能调用失败时，向用户说明原因并建议替代方案
- 不要静默失败，明确告知用户发生了什么
- 如果技能不支持某个操作，如实告知而非强行实现
