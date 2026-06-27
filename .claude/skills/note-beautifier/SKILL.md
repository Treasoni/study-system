---
name: note-beautifier
description: Obsidian 笔记智能美化专家。分析笔记内容类型，协调调用 Obsidian 基础技能（/obsidian:markdown、/obsidian:cli、/obsidian:bases）进行美化。触发词：美化、Obsidian、优化格式、笔记美化、beautify。
---

# Note Beautifier - Obsidian 笔记智能美化专家

协调调用 Obsidian 基础技能，为笔记应用专业美化方案。

## 核心架构

```
note-beautifier (协调层)
    │
    ├── 分析笔记类型和内容特征
    │
    ├── 生成美化方案
    │
    └── 调用基础技能执行
         │
         ├── /obsidian:markdown  (Markdown 语法处理)
         ├── /obsidian:cli       (Vault 操作)
         └── /obsidian:bases     (数据库操作)
```

## 触发条件

当用户提出以下类型的请求时，调用此技能:

- "帮我美化一下这个笔记"
- "优化 Obsidian 笔记格式"
- "让笔记更好看"
- "笔记排版优化"
- "应用 Obsidian 美化"
- 任何涉及 Obsidian 笔记美化的请求

## 核心功能

### 功能 1: 笔记类型智能识别

自动分析笔记内容，识别类型并推荐相应的美化方案。

**识别维度**:
```yaml
内容类型:
  - 学习笔记 (教程、课程、学习总结)
  - 读书笔记 (书籍、文章、论文)
  - 项目笔记 (技术文档、方案设计)
  - 会议记录 (会议纪要、讨论记录)
  - 知识卡片 (概念、定义、公式)
  - 工作日志 (日报、周报、复盘)

结构特征:
  - 层级结构 (有无明确的章节划分)
  - 代码比例 (代码块占比)
  - 列表密度 (有序/无序列表数量)
  - 表格使用 (数据表格数量)
  - 引用内容 (引用块占比)
```

### 功能 2: 生成美化任务清单

根据识别结果，生成需要调用的基础技能任务清单。

**任务清单格式**:
```yaml
美化任务:
  - 技能: /obsidian:markdown
    任务: 优化 Callout 块
    优先级: 高

  - 技能: /obsidian:markdown
    任务: 添加双链关联
    优先级: 中

  - 技能: /obsidian:markdown
    任务: 完善标签系统
    优先级: 中

  - 技能: /obsidian:bases
    任务: 生成 Dataview 查询
    优先级: 低

  - 技能: /obsidian:cli
    任务: 文件组织优化
    优先级: 低
```

### 功能 3: 协调调用基础技能

按照任务清单，依次或并行调用基础技能执行美化。

**调用原则**:
```yaml
原则:
  - 分析阶段: 本技能完成
  - 执行阶段: 委派给基础技能
  - 验证阶段: 本技能完成

流程:
  1. 分析笔记 → 生成任务清单
  2. 调用 /obsidian:markdown → 处理 Markdown 语法
  3. 调用 /obsidian:cli → 处理 Vault 操作
  4. 调用 /obsidian:bases → 处理数据库查询
  5. 验证美化效果 → 生成报告
```

### 功能 4: 美化效果验证

在基础技能执行后，验证美化效果并生成报告。

**验证内容**:
```yaml
验证项:
  - Callout 块是否正确应用
  - 双链是否有效
  - 标签是否完整
  - Dataview 查询是否正确
  - 整体格式是否统一
```

## 工作流程

### Step 0: 读取 todo.md 状态（必须执行）

**启动时必须检查 todo.md，确认当前阶段：**

```bash
# 读取 todo.md
cat /workspace/learning_notes/todo.md 2>/dev/null || echo "不存在"
```

**状态检查：**
- 如果 todo.md 不存在：提示用户先运行 `/research-planner` 创建意图文件
- 如果 todo.md 存在但阶段 5 为 ⬜ 或 🔲：提示用户"笔记组装未完成，请先完成 `note-assembler`"
- 如果 todo.md 存在且阶段 5 为 ✅，阶段 6 为 ⬜：允许执行，更新阶段 6 为 🔲 进行中
- 如果 todo.md 存在且阶段 6 为 ✅：提示用户"美化已完成，是否要重新美化？"

**更新 todo.md 状态：**
```bash
# 将当前阶段标记为进行中
sed -i '' 's/⬜ 未开始/🔲 进行中/g' /workspace/learning_notes/todo.md
```

**完成后更新状态：**
```bash
# 将当前阶段标记为完成
sed -i '' 's/🔲 进行中/✅ 已完成/g' /workspace/learning_notes/todo.md
```

---

### Step 1: 读取笔记内容

1. 读取目标笔记文件
2. 分析内容结构和特征
3. 识别笔记类型

### Step 2: 智能分析并生成美化方案

**分析维度**:
```yaml
结构分析:
  - 标题层级深度
  - 章节划分清晰度
  - 内容组织逻辑

内容分析:
  - 代码块占比
  - 表格数量
  - 列表密度
  - 引用内容

元素分析:
  - 已有 Callout
  - 已有 Dataview
  - 已有双链
  - 已有标签
```

**生成美化方案**:
```markdown
## 美化方案

### 识别结果
- 笔记类型: 学习笔记
- 主要特征: 多代码块、有表格、概念密集

### 美化任务清单
1. [ ] 调用 /obsidian:markdown 优化 Callout 块
2. [ ] 调用 /obsidian:markdown 添加双链关联
3. [ ] 调用 /obsidian:markdown 完善标签系统
4. [ ] 调用 /obsidian:cli 生成 Dataview 查询
5. [ ] 调用 /obsidian:markdown 优化表格格式
```

### Step 3: 协调调用基础技能执行美化

**调用策略**:

#### 3.1 Markdown 语法美化 → `/obsidian:markdown`

```markdown
调用 /obsidian:markdown 执行以下任务：

1. **Callout 块优化**
   - 将重要概念用 `[!note]` 或 `[!abstract]` 包装
   - 将实用技巧用 `[!tip]` 标记
   - 将注意事项用 `[!warning]` 标记

2. **双链添加**
   - 识别笔记中的关键概念
   - 添加相关概念的 `[[双链]]`
   - 构建知识关联网络

3. **标签系统完善**
   - 添加 frontmatter 标签
   - 根据内容生成分类标签
   - 添加状态和优先级标签

4. **表格格式优化**
   - 统一对齐格式
   - 添加适当的 emoji 增强可读性
```

#### 3.2 Vault 操作 → `/obsidian:cli`

```markdown
调用 /obsidian:cli 执行以下任务：

1. **文件组织**
   - 确保笔记在正确的目录结构中
   - 创建必要的索引文件

2. **链接验证**
   - 检查现有双链的有效性
   - 修复失效的链接
```

#### 3.3 数据库查询 → `/obsidian:bases`（如需要）

```markdown
调用 /obsidian:bases 执行以下任务：

1. **生成 Dataview 查询**
   - 创建学习进度追踪查询
   - 创建知识关联网络查询
   - 创建相关笔记推荐查询

2. **添加查询到笔记**
   - 在适当位置插入 Dataview 代码块
   - 配置查询参数
```

### Step 4: 验证美化效果

```markdown
## 美化验证清单

### Callout 块
- [ ] 核心概念已用 `[!note]` 包装
- [ ] 实用技巧已用 `[!tip]` 标记
- [ ] 注意事项已用 `[!warning]` 标记

### 双链
- [ ] 关键概念已添加双链
- [ ] 链接目标存在且有效
- [ ] 提供了链接上下文

### 标签
- [ ] frontmatter 标签完整
- [ ] 分类标签准确
- [ ] 标签层级清晰

### Dataview（如适用）
- [ ] 查询语法正确
- [ ] 查询结果符合预期
- [ ] 放置位置恰当
```

### Step 5: 生成美化报告

```markdown
## ✅ Obsidian 笔记美化完成

### 文件信息
- 文件: Python学习笔记.md
- 美化时间: 2024-01-15 14:30

### 调用的基础技能
| 技能 | 任务 | 状态 |
|:-----|:-----|:-----|
| /obsidian:markdown | Callout 优化 | ✅ |
| /obsidian:markdown | 双链添加 | ✅ |
| /obsidian:markdown | 标签完善 | ✅ |
| /obsidian:cli | 文件组织 | ✅ |
| /obsidian:bases | Dataview 查询 | ✅ |

### 美化内容
| 美化项 | 数量 | 说明 |
|:-------|:-----|:-----|
| Callout 块 | +5 | 核心概念、技巧、注意事项 |
| 双链 | +8 | 相关概念、扩展阅读 |
| 标签 | +4 | 分类标签、优先级标签 |
| Dataview | +2 | 进度追踪、知识关联 |

### 美化效果
- ✅ 内容层次更清晰
- ✅ 核心概念更突出
- ✅ 知识关联更紧密
- ✅ 视觉效果更美观

### 文件位置
- 原始文件: `/path/to/original.md`
- 美化后: `/path/to/original.md` (已覆盖)

### 后续建议
1. 在 Obsidian 中预览确认效果
2. 根据需要微调美化内容
3. 保持标签系统一致性
```

**Update todo.md status after beautification:**
```bash
# Mark Phase 6 as complete (all phases done!)
sed -i '' 's/🔲 进行中/✅ 已完成/g' /workspace/learning_notes/todo.md
```

## 美化模板库

> **注意**: 具体的美化模板和语法细节由 `/obsidian:markdown` 等基础技能处理。
> 本技能负责分析笔记类型并协调调用基础技能。

### 美化方案模板

#### 学习笔记美化方案
```yaml
美化重点:
  - Callout: 核心概念、实用技巧、注意事项
  - 双链: 相关概念、扩展阅读
  - 标签: 学习、学科、难度等级
  - Dataview: 学习进度追踪、知识关联

调用技能:
  - /obsidian:markdown: Callout、双链、标签
  - /obsidian:bases: Dataview 查询
```

#### 读书笔记美化方案
```yaml
美化重点:
  - Callout: 核心观点、章节要点、个人思考
  - 表格: 书籍信息、章节对比
  - 标签: 读书、书名、作者
  - 任务列表: 阅读进度

调用技能:
  - /obsidian:markdown: Callout、表格、任务列表
```

#### 项目笔记美化方案
```yaml
美化重点:
  - Callout: 项目简介、模块说明、技术决策
  - 表格: 项目信息、进度追踪
  - 标签: 项目、技术栈、状态
  - 代码块: 项目结构、核心代码

调用技能:
  - /obsidian:markdown: Callout、表格、代码块
  - /obsidian:cli: 文件组织
```

## 美化规则（委派给基础技能）

> **重要**: 以下规则仅供参考，实际执行由 `/obsidian:markdown` 等基础技能负责。

### 1. Callout 使用规范

**适用场景**:
- `[!note]` - 概念定义、重要说明
- `[!tip]` - 实用技巧、经验分享
- `[!warning]` - 注意事项、常见错误
- `[!example]` - 示例说明、代码演示
- `[!abstract]` - 核心摘要、总结提炼
- `[!question]` - 思考问题、讨论点

### 2. 双链使用规范

**适用场景**:
- 相关概念引用
- 知识网络构建
- 扩展阅读链接
- 脚注和补充说明

### 3. 标签使用规范

**标签结构**:
```yaml
主标签:
  - 学习
  - 项目
  - 读书
  - 工作

子标签:
  - {学科}/{具体领域}
  - {项目名}/{模块}
  - {书名}/{章节}

状态标签:
  - 进行中
  - 已完成
  - 待复习
  - 暂停

优先级标签:
  - 重要
  - 紧急
  - 普通
```

## 与其他技能的关系

```
research-collector (资料收集)
    ↓ 生成研究素材
note-beautifier (本技能 - 协调层)
    ↓ 分析笔记类型
    ↓ 生成美化方案
    ↓
    ├──→ /obsidian:markdown (Callout、双链、标签)
    ├──→ /obsidian:cli (文件组织)
    └──→ /obsidian:bases (Dataview 查询)
    ↓
Obsidian 美化笔记
    ↓
note-assembler (组装)
    ↓ 组装成完整笔记
    ↓
note-beautifier (再次美化协调)
    ↓
最终输出
```

## 调用示例

### 示例 1: 美化学习笔记

```markdown
用户：帮我美化这个学习笔记

助手：
1. 读取笔记内容
2. 分析笔记类型（学习笔记，多代码块）
3. 生成美化方案
4. 调用 /obsidian:markdown 优化 Callout 块
5. 调用 /obsidian:markdown 添加双链
6. 调用 /obsidian:markdown 完善标签
7. 调用 /obsidian:bases 添加 Dataview 查询
8. 生成美化报告
```

### 示例 2: 美化读书笔记

```markdown
用户：优化这个读书笔记的格式

助手：
1. 读取笔记内容
2. 分析笔记类型（读书笔记，章节结构）
3. 生成美化方案
4. 调用 /obsidian:markdown 优化 Callout 块
5. 调用 /obsidian:markdown 完善表格格式
6. 调用 /obsidian:markdown 添加任务列表
7. 生成美化报告
```
