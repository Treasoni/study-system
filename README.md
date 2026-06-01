# Study System

基于 **Claude Code + Obsidian** 的半自动化技术学习笔记系统。你说「我想学 X」，系统经历 6 个阶段产出高质量 Obsidian 笔记，全程在关键节点由你审核把控。

## 快速开始

### 1. 前置依赖

- [Claude Code](https://claude.ai/code) — 编排引擎
- [Obsidian](https://obsidian.md) — 笔记存储和浏览

### 2. 安装

```bash
git clone git@github.com:Treasoni/study-system.git
cd study-system
npm install
```

### 3. 配置 Vault 路径

首次使用时，告诉 Claude Code 你的 Obsidian Vault 路径。系统会自动在 Vault 内创建 `StudySystem/` 目录结构。

### 4. 配置自治级别（可选）

编辑 `.study-config.yaml`：

```yaml
autonomy:
  level: 1  # 0=每步确认, 1=每阶段确认(默认), 2=关键点确认, 3=全自动
```

### 5. 开始学习

在 Claude Code 中说「我想学 X」，系统会引导你完成需求发现，然后依次执行各阶段。

## 工作流程

**研究驱动型（概念/实战/对比/速查）：**

```
"我想学 React Hooks"
  ↓
Phase 0 · 需求发现 → 明确方向/深度/笔记类型
  ↓
Phase 1 · 收集     → Subagent 搜索官方文档 + 社区内容
  ↓
Phase 2 · 整理     → 打分、去重、分类、标记知识缺口
  ↓
Phase 3 · 撰写     → 选模板、提取关键信息、生成笔记初稿
  ↓
Phase 4 · 美化     → Obsidian Markdown 美化、双链、标签、图表
  ↓
Phase 5 · 评估     → 五维质量评分 + 自我学习
```

**心得笔记（用户经验驱动）：**

```
"我想写一篇关于 XX 的心得笔记"
  ↓
用户提供原始内容 → 审核准确性 → 可选补充研究 → 撰写 → 美化 → 评估
```

每个阶段完成后暂停，等待你审核确认再继续（可配置自治级别减少确认）。

## 笔记类型

**单一类型：**

| 类型 | 说明 |
|------|------|
| 概念笔记 | 一句话解释 → 核心原理 → 常见误区 → 概念关联 |
| 实战笔记 | 目标 → 环境准备 → 分步操作 → 踩坑记录 |
| 对比笔记 | 并列对比多个方案的优劣势和适用场景 |
| 速查表 | 精简的 Cheat Sheet，适合快速查阅 |
| 心得笔记 | 用户提供项目经验，系统审核准确性、补充研究、生成结构化笔记 |

**混合类型（最多 2 种组合）：**

| 组合 | 说明 |
|------|------|
| 概念+实战 | 概念解释 + 实战示例 |
| 对比+速查 | 对比分析 + 速查清单 |
| 心得+概念 | 学习心得 + 核心概念 |
| 概念+速查 | 核心概念 + 速查清单 |

## 自治级别

| 级别 | 确认频率 | 适用场景 |
|------|---------|---------|
| Level 0 | 每步确认 | 新用户、重要笔记 |
| Level 1 | 每阶段确认 | 默认，平衡效率和控制 |
| Level 2 | 关键点确认 | 熟练用户、大量笔记 |
| Level 3 | 全自动 | 仅最终确认 |

## 目录结构

```
{VAULT_PATH}/StudySystem/
├── templates/          # 5 种笔记模板 + 混合类型定义
├── 0-inbox/            # Phase 1 产出：原始资料
├── 2-drafts/           # Phase 3 产出：笔记初稿
├── 3-published/        # Phase 4 产出：美化后的最终笔记
└── 4-meta/             # 元数据：日志、错误记录、评估报告
```

最终笔记可输出到 Vault 任意位置（Phase 0 由你指定），不限于 `3-published/`。

## 核心 Skill

| Skill | 阶段 | 职责 |
|-------|------|------|
| requirement-discovery | Phase 0 | 需求发现，明确学习目的和笔记类型 |
| collect | Phase 1 | Subagent 搜索收集原始资料 |
| curate | Phase 2 | 打分、去重、分类、标记缺口 |
| write | Phase 3 | 选模板生成笔记初稿 |
| beautify | Phase 4 | Obsidian 美化排版 |
| evaluate | Phase 5 | 五维质量评估 + 自我学习 |
| update | 维护 | 更新已有笔记 |

## 设计原则

- 所有系统文件归入 `StudySystem/`，不污染 Vault 根目录
- 每个 Skill 只负责自己的阶段，不越界
- 数据通过文件传递，每个阶段的产出是下一阶段的输入
- Subagent 架构，重计算任务委托给专用子代理
- 每个阶段后由你审核，不搞全自动
- 优先官方文档和一手资料，所有来源可追溯

## 更多文档

| 文档 | 内容 |
|------|------|
| [docs/phases.md](docs/phases.md) | Phase 0-5 详细步骤 |
| [docs/experience-notes.md](docs/experience-notes.md) | 心得笔记工作流 |
| [docs/updating-notes.md](docs/updating-notes.md) | 更新已有笔记 |
| [docs/architecture.md](docs/architecture.md) | 设计 rationale |
