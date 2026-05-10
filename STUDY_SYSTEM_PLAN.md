# 学习系统构建计划

## 一、项目愿景

用 Claude Code + Obsidian 构建一个半自动化的技术学习笔记系统：用户说「我想学 X」，系统收集资料 → 整理筛选 → 生成笔记 → 排版美化 → 输出到 Obsidian，全程用户可在关键节点审核和调整方向。

---

## 二、核心架构决策：Skill 而非 Subagent

**结论：使用 Skill 实现，不使用 subagent。**

| 对比维度 | Subagent | Skill |
|---------|----------|-------|
| 状态保持 | 每次调用全新实例，无记忆 | 指令固化，主 Claude 记住上下文 |
| 数据传递 | 无法直接通信 | 通过 Obsidian 文件系统中转 |
| 持久性 | 用完即销毁 | 以 `.md` 文件形式持久存在 |
| 可迭代性 | 每次需重新传入完整上下文 | 可反复调用，指令持续优化 |

架构模型：

```
┌──────────────────────────────────────────────────┐
│              主 Claude（大脑/编排器）                │
│   · 阶段0：询问学习目标 + 笔记输出路径               │
│   · 阶段0：生成执行计划，用户确认                   │
│   · 按阶段依次调用 Skill，每个阶段后用户审核         │
│   · 根据反馈决定：继续 / 返工 / 终止                │
│   · 异常写入 4-meta/error-log.md                  │
└──────────┬───────────────────────────────────────┘
           │ 按流程依次调用
    ┌──────┴───────────────────────────────────────┐
    │                                               │
    ▼         ▼         ▼         ▼         ▼
collect   curate    write    beautify  evaluate
(收集)    (整理)    (写笔记)   (美化)    (评估)

    │         │         │         │         │
    └─────────┴─────────┴────┬────┴─────────┘
                             │ 数据通过文件系统中转
                             ▼
              ┌────────────────────────────┐
              │  {VAULT}/StudySystem/       │
              │  ├── skills/               │
              │  ├── templates/            │
              │  ├── 0-inbox/    ← collect │
              │  ├── 1-curated/  ← curate  │
              │  ├── 2-drafts/   ← write   │
              │  ├── 3-published/ ← beautify│
              │  └── 4-meta/     ← evaluate│
              │                          │
              │  最终笔记也可输出到用户指定路径  │
              │  例如 {VAULT}/Notes/前端/    │
              └────────────────────────────┘
```

---

## 三、目录结构：全部归入一个父文件夹

所有系统文件都放在 `{VAULT_PATH}/StudySystem/` 下，不污染 Vault 根目录。最终笔记的输出路径在阶段 0 由用户指定。

```
{VAULT_PATH}/                   # Obsidian Vault 根目录（用户已有的笔记也在这里）
├── {用户已有的其他笔记}/
│
└── StudySystem/                # ★ 系统唯一入口——所有相关文件都在这个文件夹下
    │
    ├── .obsidian-config.md     # 系统配置（Vault路径、默认输出路径等）
    │
    ├── skills/                 # Skill 定义文件（5个核心Skill）
    │   ├── collect.md
    │   ├── curate.md
    │   ├── write.md
    │   ├── beautify.md
    │   └── evaluate.md
    │
    ├── templates/              # 笔记模板
    │   ├── concept-template.md
    │   ├── practice-template.md
    │   ├── compare-template.md
    │   └── cheat-sheet-template.md
    │
    ├── 0-inbox/                # 阶段1产出：原始收集材料
    │   └── {topic}/
    │       ├── sources.md      # 来源清单（URL、标题、作者、日期）
    │       └── raw/
    │           ├── doc-01.md
    │           ├── doc-02.md
    │           └── ...
    │
    ├── 1-curated/              # 阶段2产出：整理分类后的资料
    │   └── {topic}/
    │       ├── overview.md     # 知识地图
    │       ├── core-concepts.md
    │       ├── practices.md
    │       ├── references.md
    │       └── discarded.md
    │
    ├── 2-drafts/               # 阶段3产出：笔记初稿
    │   └── {topic}/
    │       └── {topic}-笔记.md
    │
    ├── 3-published/            # 阶段4产出：美化后的笔记（默认输出路径）
    │   └── {topic}/
    │       ├── {topic}.md
    │       └── attachments/
    │
    └── 4-meta/                 # 元数据（执行日志、错误记录、评估报告）
        ├── execution-log.md
        ├── error-log.md
        └── evaluation/
            └── {topic}-eval.md
```

### 路径配置说明

| 路径 | 含义 | 何时确定 |
|------|------|---------|
| `VAULT_PATH` | Obsidian Vault 的根目录 | **首次使用时配置**，写入 `.obsidian-config.md` |
| `SYSTEM_ROOT` | = `{VAULT_PATH}/StudySystem/`，所有系统文件的家 | 固定，不需要用户指定 |
| `OUTPUT_PATH` | 最终笔记保存位置 | **每次执行时在阶段 0 由 Claude 询问**。用户可以指定 Vault 内任意路径，不填则默认 `{SYSTEM_ROOT}/3-published/` |

这样：
- 所有中间产物（0-inbox、1-curated、2-drafts、4-meta）永远在 `StudySystem/` 下
- 最终笔记可以输出到用户指定的任意 Obisidian 路径，方便与已有笔记体系融合
- Skill 和模板存放在 `StudySystem/skills/` 和 `StudySystem/templates/`，与 Vault 其他内容隔离

---

## 四、5 个 Skill 详细规格

### Skill 1：collect（收集资料）

**触发时机**：用户确认学习计划后

**输入**：
- 用户想学的主题
- 用户选择的学习方向（概念理解 / 实战上手 / 体系梳理 / 问题排查）
- 用户期望的深度（入门 / 进阶 / 深入原理）

**执行步骤**：
1. 使用 `WebSearch` 搜索官方文档入口
2. 使用 `WebFetch` 抓取官方文档页面
3. 搜索高热度社区文章（GitHub、Stack Overflow、技术博客）
4. 过滤标准：优先官方文档 + 发布日期在最近 2 年内
5. 对比多个来源，去除重复内容

**产出**（写入 `{SYSTEM_ROOT}/0-inbox/{topic}/`）：
- `sources.md`：所有来源的元数据清单
- `raw/`：各来源的原始内容文件

**禁止行为**：
- 不要整理或总结内容（那是 curate 的事）
- 不要评判资料好坏（只记录来源和数据）
- 不要跳过低热度但有独特视角的资料

---

### Skill 2：curate（整理资料）

**触发时机**：用户审核通过 collect 产出后

**输入**：
- `{SYSTEM_ROOT}/0-inbox/{topic}/` 中的所有原始资料

**执行步骤**：
1. 遍历所有原始资料
2. 按以下维度打分（1-5）：
   - 权威性（官方 > 知名作者 > 社区）
   - 时效性（越新越高）
   - 完整性（覆盖主题的程度）
   - 可读性（对学习者的友好程度）
3. 去重：相同内容保留质量最高的来源
4. 分类归入：核心概念 / 实战示例 / 进阶原理 / 争议/不同观点
5. 标记信息缺口：哪些子话题资料不足

**产出**（写入 `{SYSTEM_ROOT}/1-curated/{topic}/`）：
- `overview.md`：知识地图（主题 → 子主题 → 关键点）
- `core-concepts.md`：核心概念及出处
- `practices.md`：实战示例汇总
- `references.md`：参考资料速查表
- `discarded.md`：被舍弃的资料及舍弃原因

**禁止行为**：
- 不要开始写笔记（那是 write 的事）
- 不要改变原始资料的内容
- 不要添加自己的理解（保持资料原意）

---

### Skill 3：write（写笔记）

**触发时机**：用户审核通过 curate 产出后

**输入**：
- `{SYSTEM_ROOT}/1-curated/{topic}/` 中整理好的资料
- 用户偏好的笔记类型（概念/实战/对比/速查）

**执行步骤**：
1. 根据用户选择匹配对应模板
2. 从整理资料中提取关键信息填入模板
3. 用学习者友好的语言组织内容
4. 插入代码示例、图表描述、类比解释
5. 标注内容来源（引用 `references.md` 中的条目）
6. 生成关键问题/思考题帮助复习

**产出**（写入 `{SYSTEM_ROOT}/2-drafts/{topic}/`）：
- `{topic}-笔记.md`：主体笔记初稿

**禁止行为**：
- 不要做美化排版（那是 beautify 的事）
- 不要添加未经 curate 阶段确认的内容
- 不要用 AI 编造的虚假引用

---

### Skill 4：beautify（美化排版）

**触发时机**：用户审核通过 write 产出后

**输入**：
- `{SYSTEM_ROOT}/2-drafts/{topic}/` 中的笔记初稿

**执行步骤**：
1. 套用 Obsidian Markdown 规范
2. 添加以下 Obsidian 特性：
   - **双链 `[[]]`**：关联已有笔记中的概念
   - **标签 `#tag`**：按主题、类型、难度打标签
   - **Callout 块**：重点、警告、提示、示例等
   - **Mermaid 图表**：将文字描述的流程/架构转为图表
   - **Dataview 元数据**：在笔记头部添加 YAML frontmatter
3. 检查层级结构（标题不越级、不超过 4 级深度）
4. 统一术语（同一概念全文用同一个词）
5. 优化段落长度（每个段落不超过 6 行）

**产出**（写入 `{OUTPUT_PATH}` 或默认 `{SYSTEM_ROOT}/3-published/{topic}/`）：
- `{topic}.md`：最终排版好的笔记

**YAML Frontmatter 示例**：
```yaml
---
topic: "React Hooks"
type: "concept"
difficulty: "intermediate"
tags: ["react", "hooks", "frontend"]
created: 2026-05-10
updated: 2026-05-10
sources:
  - "React 官方文档"
  - "Dan Abramov - A Complete Guide to useEffect"
concepts:
  - "[[useState]]"
  - "[[useEffect]]"
  - "[[useRef]]"
---
```

**禁止行为**：
- 不要修改笔记的内容和含义
- 不要添加内容中没有的信息
- 不要删除内容（只能调整呈现方式）

---

### Skill 5：evaluate（评估效果）

**触发时机**：用户审核通过 beautify 产出后（可选执行）

**输入**：
- `{OUTPUT_PATH}` 中的最终笔记

**评估维度**：
1. **完整性**：主题的核心概念是否都覆盖了？（0-10）
2. **准确性**：内容是否与原始资料一致？（0-10）
3. **可读性**：是否易于理解和消化？（0-10）
4. **实用性**：是否有可操作的示例或行动指南？（0-10）
5. **关联性**：是否正确使用了双链关联知识？（0-10）

**产出**（写入 `{SYSTEM_ROOT}/4-meta/evaluation/`）：
- `{topic}-eval.md`：评估报告，包含每个维度的打分和改进建议

**处理逻辑**：
- 总分 ≥ 40 且单项无 < 5：标记为「优秀 - 可直接使用」
- 总分 30-39：标记为「良好 - 建议小幅修改」，列出具体修改点
- 总分 < 30 或单项 < 5：标记为「需要返工 - 建议重新执行对应阶段」

---

## 五、主 Claude 编排流程

### 阶段 0：需求澄清 + 路径确认

```
用户："我想学 React Hooks"
  ↓
主 Claude 分两轮询问：

第一轮：明确学习目标
  "你想学哪个方向？
   a) 理解概念和原理
   b) 实战——动手写项目
   c) 梳理完整知识体系
   d) 解决某个具体问题

   你想达到什么深度？入门 / 进阶 / 深入源码？

   你想要哪种笔记类型？概念笔记 / 实战笔记 / 对比笔记 / 速查表？"

第二轮：确定路径
  "最终笔记保存到哪个路径？
   默认：{SYSTEM_ROOT}/3-published/{topic}/
   你也可以指定 Vault 中的其他位置，例如：
     - Notes/前端/React/
     - 02-技术笔记/React/

   本次学习的主题名称（用作文件夹名，默认：React-Hooks）："

  ↓
用户回答后 → Claude 生成执行计划并展示：
   - 学习目标：[概念理解 / 进阶]
   - 笔记类型：[概念笔记]
   - 输出路径：[Notes/前端/React/]
   - 执行阶段：收集 → 整理 → 写笔记 → 美化 → [评估]
   - 预计收集来源类型：官方文档 + 社区热门 + 实战示例
  ↓
用户确认计划 → 写入执行日志 → 进入阶段1
```

### 阶段 1：收集资料

```
主 Claude → 调用 collect Skill
  ↓
collect 产出 → {SYSTEM_ROOT}/0-inbox/{topic}/
  ↓
主 Claude → 展示收集概要给用户审核
  - 收集了多少来源
  - 覆盖了哪些子话题
  - 是否有明显缺口
  ↓
用户：确认 / 补充方向 / 要求重新收集
```

### 阶段 2：整理资料

```
主 Claude → 调用 curate Skill
  ↓
curate 产出 → {SYSTEM_ROOT}/1-curated/{topic}/
  ↓
主 Claude → 展示整理结果给用户审核
  - 知识地图概要
  - 舍弃了哪些资料及原因
  - 哪些子话题资料不足
  ↓
用户：确认 / 调整 / 补充资料后重来
```

### 阶段 3：生成笔记

```
主 Claude → 询问笔记类型偏好（阶段0已问则跳过）
  ↓
主 Claude → 调用 write Skill
  ↓
write 产出 → {SYSTEM_ROOT}/2-drafts/{topic}/
  ↓
主 Claude → 展示笔记初稿给用户审核
  - 结构是否合理
  - 是否有理解偏差
  - 是否有遗漏
  ↓
用户：确认 / 修改意见 / 重写
```

### 阶段 4：美化排版

```
主 Claude → 调用 beautify Skill
  ↓
beautify 产出 → {OUTPUT_PATH}（用户指定）或 {SYSTEM_ROOT}/3-published/{topic}/
  ↓
主 Claude → 展示最终效果
  ↓
用户：确认 / 微调
```

### 阶段 5（可选）：评估

```
主 Claude → "要评估这篇笔记的质量吗？"
  ↓
用户同意 → 调用 evaluate Skill
  ↓
evaluate 产出 → {SYSTEM_ROOT}/4-meta/evaluation/{topic}-eval.md
  ↓
主 Claude → 展示评估结果 + 改进建议
```

---

## 六、监督机制的实现方式

**不单独做一个 Skill**，而是融入主 Claude 的编排逻辑：

1. **前置检查**：每个阶段开始前，主 Claude 检查上一阶段的产出文件是否完整
2. **执行中检查**：每个 Skill 执行完毕后，主 Claude 检查：
   - 产出文件是否成功写入
   - 文件内容是否为空或不完整
   - 是否与上一阶段的输入一致
3. **错误处理**：所有异常写入 `{SYSTEM_ROOT}/4-meta/error-log.md`，格式：
   ```markdown
   ## [2026-05-10 14:30] collect 阶段异常
   - **问题**：WebFetch 超时，无法抓取 React 官方文档
   - **影响**：缺少官方文档来源
   - **处理**：已记录，建议用户手动提供或稍后重试
   ```

---

## 七、笔记模板

### concept-template.md（概念理解）

```markdown
---
type: concept
topic: ""
difficulty: ""
tags: []
created: 
updated: 
sources: []
---

# {概念名称}

## 一句话解释
{用一句话说清楚这是什么}

## 为什么存在？（解决什么问题）
{没有它之前是什么样，有了它解决了什么}

## 核心原理
{用类比/图表/简单代码解释原理}

## 关键要点
- 要点1
- 要点2

## 常见误区
- 误区1 → 正解

## 与其他概念的关系
- [[相关概念1]] - 关系说明
- [[相关概念2]] - 关系说明

## 一句话总结
{记忆口诀或一句话概括}
```

### practice-template.md（实战笔记）

```markdown
---
type: practice
topic: ""
difficulty: ""
tags: []
created: 
updated: 
sources: []
---

# {实战主题}

## 目标
{这次实战要达成什么}

## 环境准备
- 需要安装的
- 需要配置的

## 步骤

### 步骤 1：{标题}
```bash
# 代码
```

### 步骤 2：{标题}
```bash
# 代码
```

## 踩坑记录
> [!warning] 坑点1
> 现象 → 原因 → 解决

## 延伸
- 这篇文章让你能做什么？
- 下一步可以学什么：[[下一步主题]]
```

---

## 八、实施优先级

| 优先级 | 任务 | 说明 |
|-------|------|------|
| P0 | 首次配置：确定 Vault 路径，创建 `StudySystem/` 目录结构 | 一次性操作，所有后续工作的基础 |
| P0 | 编写 CLAUDE.md（主 Claude 编排指令） | 定义阶段 0 的询问流程和整体调度逻辑 |
| P0 | 编写 collect Skill | 入口，没有它后面都跑不了 |
| P1 | 编写 curate Skill | 核心价值——从信息到知识的关键一步 |
| P1 | 编写 write Skill | 核心产出 |
| P1 | 编写笔记模板（4个） | 标准化产出，write 和 beautify 都依赖 |
| P2 | 编写 beautify Skill | 提升体验 |
| P2 | 编写 evaluate Skill | 质量保障 |
| P3 | 监督/错误处理机制 | 健壮性 |
| P3 | 根据使用反馈迭代优化 | 持续改进 |

---

## 九、关键设计原则

1. **所有系统文件归入一个父文件夹** `StudySystem/`，不污染 Vault 根目录。
2. **笔记输出路径在阶段 0 由用户指定**，不硬编码。支持输出到 Vault 任意位置。
3. **每个 Skill 只管自己的阶段**，不越界。collect 不整理，curate 不写笔记，write 不美化。
4. **数据通过文件传递**，不是通过内存。每个阶段的产出物是下一阶段的输入。
5. **用户在每个阶段后审核**，不搞全自动。学习笔记的质量需要人判断。
6. **优先官方文档和一手资料**，避免二手三手转载的失真。
7. **所有来源可追溯**，笔记中的每个观点都能追溯到原始出处。
