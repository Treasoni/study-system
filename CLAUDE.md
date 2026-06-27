# Study System

学习笔记自动化生产系统。

## 完整工作流

```
用户输入学习主题
    │
    ▼
[阶段 0] 意图澄清      → /research-planner
    │                     输出: 00_intent.md
    │
    ▼
[阶段 1] 探测式收集    → /research-collector
    │
    ▼
[阶段 2] 深度收集      → /research-collector
    │                     输出: 02_deep_research.md
    │
    ▼
[阶段 3] 大纲生成      → outline-generator (agent)
    │                     输出: 03_outline.md + 用户确认
    │
    ▼
[阶段 4] 逐章写作      → chapter-writer (agent)
    │                     输出: chapters/{N}_{章节名}.md
    │
    ▼
[阶段 5] 收尾组装      → note-assembler (agent)
    │                     输出: output/final_note.md
    │
    ▼
[阶段 6] 美化输出      → /note-beautifier
                          输出: output/final_note.{format}
```

## 文件结构

```
/workspace/learning_notes/
├── 00_intent.md              ← 意图文件（阶段 0）
├── 02_deep_research.md       ← 素材文件（阶段 2）
├── 03_outline.md             ← 大纲文件（阶段 3）
├── todo.md                   ← 执行检查清单
├── chapters/
│   ├── 01_xxx.md
│   └── ...
└── output/
    └── final_note.md/pdf     ← 最终产物
```

## 各阶段职责

### 阶段 0: 意图澄清 — `/research-planner`

在收集资料前，通过轻量级提问和探测式引导，帮用户明确方向。

- 判断用户信息充足/模糊/无方向
- 场景 B: 问 3 个核心问题（笔记类型、学习深度、现有基础）
- 场景 B/C: 派发 subagent 探测，展示方向菜单
- 生成意图文件 `00_intent.md`，等待用户确认

**输出产物**: `/workspace/learning_notes/00_intent.md`

### 阶段 1-2: 资料收集 — `/research-collector`

基于意图文件，分两阶段收集资料：先探测式广撒网，再深度挖掘重点。

- 探测式收集: 多角度快速扫描，发现有价值的资料
- 深度收集: 围绕重点方向深入挖掘，整理成结构化素材

**输出产物**: `/workspace/learning_notes/02_deep_research.md`

### 阶段 3: 大纲生成 — `outline-generator` agent

基于意图文件和素材文件，生成学习笔记大纲。

- 读取 `00_intent.md` 和 `02_deep_research.md`
- 按主题逻辑组织章节结构
- 输出大纲后等待用户确认顺序和深度

**输出产物**: `/workspace/learning_notes/03_outline.md`

### 阶段 4: 逐章写作 — `chapter-writer` agent

按大纲逐章写作学习笔记。

- 每次只写一章
- 写完后等待用户确认
- 用户确认后才继续下一章
- 支持中途调整方向

**输出产物**: `/workspace/learning_notes/chapters/{N}_{章节名}.md`

### 阶段 5: 收尾组装 — `note-assembler` agent

将所有章节组装成完整笔记。

- 拼接章节内容
- 添加过渡段落
- 生成目录

**组装选项**:
- A: 按当前顺序拼成随笔笔记
- B: 重新排序整理成结构化笔记
- C: 保持零散片段，仅加最小格式

**输出产物**: `/workspace/learning_notes/output/final_note.md`

### 阶段 6: 美化输出 — `/note-beautifier`

对最终笔记进行格式美化和导出。

- 支持 Obsidian 格式优化
- 支持 PDF/Word/PPT 导出

**输出产物**: `/workspace/learning_notes/output/final_note.{format}`

## 工作流执行规则（强制）

**核心原则：每个技能/Agent 启动时必须先读取 todo.md，确认当前阶段状态，不可跳步，不可不做。**

### 断点恢复机制

1. **读取状态**：每个技能启动时，读取 `todo.md` 中的 `当前阶段` 和各阶段状态
2. **验证前置**：检查前置阶段是否已完成（标记为 ✅），未完成则阻止并提示用户
3. **更新状态**：技能开始时，将当前阶段状态改为 `🔲 进行中`；完成后改为 `✅ 已完成`
4. **阶段推进**：更新 `{current_phase}` 为下一阶段

### 状态流转示例

```
阶段 0：意图澄清
  - research-planner 启动 → 读取 todo.md → 当前阶段: 阶段 0
  - 完成后 → 更新阶段 0 为 ✅，current_phase 改为 "阶段 1：探测式收集"

阶段 1：探测式收集
  - research-collector 启动 → 读取 todo.md → 验证阶段 0 为 ✅
  - 开始收集 → 更新阶段 1 为 🔲 进行中
  - 完成后 → 更新阶段 1 为 ✅，current_phase 改为 "阶段 2：深度收集"

...以此类推
```

### todo.md 状态格式

| 状态 | 含义 | 操作 |
|------|------|------|
| ⬜ 未开始 | 未执行 | 等待前置完成 |
| 🔲 进行中 | 正在执行 | 允许操作 |
| ✅ 已完成 | 执行完成 | 允许下一阶段 |
| ⏭️ 跳过 | 用户选择跳过 | 等同于 ✅ |

### 阶段完成检查点

每阶段结束都必须让用户确认后才进入下一阶段:

| 阶段 | 检查点内容 |
|------|-----------|
| 0 → 1 | 用户确认意图文件和研究计划 |
| 1 → 2 | 用户确认素材质量 |
| 2 → 3 | 用户确认大纲顺序和深度 |
| 3 → 4 | 用户确认大纲（大纲模式） |
| 4 → 5 | 所有章节写作完成 |
| 5 → 6 | 用户确认组装结果 |

## 错误处理

| 情况 | 处理方式 |
|------|---------|
| 缺少意图文件 | 重新调用 `/research-planner` |
| 缺少素材文件 | 重新调用 `/research-collector` |
| 缺少大纲文件 | 重新调用 `outline-generator` |
| 缺少章节文件 | 重新调用 `chapter-writer` |
| 工具缺失 | 提示用户安装（如 pandoc） |

## 技能依赖关系

```
learning-note-orchestrator
    │
    ├── /research-planner      (意图澄清)
    ├── /research-collector    (资料收集)
    ├── outline-generator      (大纲生成 - agent)
    ├── chapter-writer         (逐章写作 - agent)
    ├── note-assembler         (收尾组装 - agent)
    └── /note-beautifier       (美化输出)
```
