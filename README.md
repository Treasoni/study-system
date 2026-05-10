# study-system

基于 **Claude Code + Obsidian** 的半自动化技术学习笔记系统。你说「我想学 X」，系统经历 5 个阶段产出高质量 Obsidian 笔记，全程在关键节点由你审核把控。

## 工作流程

**研究驱动型（概念/实战/对比/速查）：**
```
用户："我想学 React Hooks"
  ↓
Phase 0 · 需求澄清 → 明确方向/深度/笔记类型/输出路径
  ↓
Phase 1 · collect  → 搜索官方文档 + 社区内容，保存原始资料
  ↓
Phase 2 · curate   → 打分、去重、分类、标记知识缺口
  ↓
Phase 3 · write    → 选模板、提取关键信息、生成笔记初稿
  ↓
Phase 4 · beautify → Obsidian Markdown 美化、双链、标签、图表
  ↓
Phase 5 · evaluate → 五维评分 + 自我学习（可选）
```

**心得笔记（用户经验驱动）：**
```
用户："我想写一篇关于 XX 的心得笔记"
  ↓
用户提供原始内容 → 审核准确性 → 可选补充研究 → write → beautify → evaluate
```

每个阶段完成后暂停，等待你审核确认再继续。

## 前置依赖

- [Claude Code](https://claude.ai/code) — 作为编排引擎
- [Obsidian](https://obsidian.md) — 笔记存储和浏览

## 快速开始

**1. Clone 到本地**

```bash
git clone git@github.com:Treasoni/study-system.git
cd study-system
```

**2. 配置 Vault 路径**

首次使用时，告诉 Claude Code 你的 Obsidian Vault 路径。系统会自动在 Vault 内创建 `StudySystem/` 目录结构。

**3. 开始学习**

在 Claude Code 中说「我想学 X」，系统会引导你完成 Phase 0 的需求澄清，然后依次执行各阶段。

## 目录结构

```
{VAULT_PATH}/StudySystem/
├── templates/          # 5 种笔记模板
│   ├── concept-template.md       # 概念理解
│   ├── practice-template.md      # 实战上手
│   ├── compare-template.md       # 对比分析
│   ├── cheat-sheet-template.md   # 速查表
│   └── experience-template.md    # 心得笔记
│
├── 0-inbox/            # Phase 1 产出：原始资料
│   └── {topic}/
│
├── 1-curated/          # Phase 2 产出：整理分类后的资料
│   └── {topic}/
│
├── 2-drafts/           # Phase 3 产出：笔记初稿
│   └── {topic}/
│
├── 3-published/        # Phase 4 产出：美化后的最终笔记（默认路径）
│   └── {topic}/
│
└── 4-meta/             # 元数据：执行日志、错误记录、评估报告
    ├── execution-log.md
    ├── error-log.md
    └── evaluation/
```

最终笔记可输出到 Vault 任意位置（Phase 0 由你指定），不限于 `3-published/`。

本仓库还包含：
- `.claude/skills/` — 16 个 Skill 定义文件
- `.claude/agents/` — 1 个子代理（evaluate 评估代理）
- `.learnings/` — 自我学习记录，驱动持续改进

## 6 个核心 Skill

| Skill | 阶段 | 职责 |
|-------|------|------|
| **collect** | Phase 1 | 搜索收集原始资料，保存到 `0-inbox/` |
| **curate** | Phase 2 | 打分、去重、分类、标记缺口，输出知识地图 |
| **write** | Phase 3 | 选模板生成笔记初稿到 `2-drafts/` |
| **beautify** | Phase 4 | Obsidian 美化排版，输出到用户指定路径 |
| **evaluate** | Phase 5 | 五维质量评估 + 自我学习捕获（子代理） |
| **update** | 维护 | 更新已有笔记，支持插入新内容和刷新过时内容 |

## 笔记类型

- **概念笔记** — 一句话解释 → 核心原理 → 常见误区 → 概念关联
- **实战笔记** — 目标 → 环境准备 → 分步操作 → 踩坑记录
- **对比笔记** — 并列对比多个方案的优劣势和适用场景
- **速查表** — 精简的 Cheat Sheet，适合快速查阅
- **心得笔记** — 用户提供项目经验，系统审核准确性、补充研究、生成结构化笔记

## 自我学习机制

系统通过 `.learnings/` 持续改进：

- **RULES.md** — 每次新任务前读取，包含压缩提炼的行动规则
- **LEARNINGS.md / ERRORS.md** — 每次评估后记录经验教训
- **Digest 循环** — 当文件超过阈值时自动压缩、去重、提炼规则

## 设计原则

- 所有系统文件归入 `StudySystem/`，不污染 Vault 根目录
- 每个 Skill 只负责自己的阶段，不越界
- 数据通过文件传递，每个阶段的产出是下一阶段的输入
- 每个阶段后由你审核，不搞全自动
- 优先官方文档和一手资料，所有来源可追溯
