---
name: subagent-generator
description: Claude Code subagent 生成规范。指导如何正确创建、配置和使用 subagent，包括基础用法、高级编排、错误处理和性能优化。触发词：subagent、子代理、并行任务、fork、agent、生成子任务。
---

# Subagent Generator - Claude Code Subagent 生成规范

指导 Claude Code 正确创建、配置和使用 subagent 的完整规范。

## 触发条件

当用户提出以下类型的请求时，调用此技能:

- "帮我创建一个 subagent"
- "如何使用子代理"
- "并行执行多个任务"
- "生成多个 agent"
- "subagent 配置"
- 任何涉及创建、配置、使用 subagent 的请求

## 核心原则

### 1. Subagent 是独立的执行单元

- 每个 subagent 有自己的上下文窗口
- 不共享父 agent 的完整对话历史
- 通过返回值与父 agent 通信

### 2. 明确的输入输出契约

- 给 subagent 清晰的任务描述
- 明确期望的输出格式
- 设定合理的边界和约束

### 3. 失败隔离

- 单个 subagent 失败不应影响其他 subagent
- 设计重试和降级策略
- 保持父 agent 的稳定性

## Subagent 类型

### 1. 通用 Subagent (默认)

**用途**: 执行独立的、可并行的任务

**适用场景**:
- 多关键词搜索
- 信息收集和整理
- 代码审查的不同维度
- 并行处理多个文件

**创建方式**:
```
Agent(
  description: "简短描述（3-5 词）",
  prompt: "详细的任务描述...",
  subagent_type: "general-purpose"  // 默认，可省略
)
```

### 2. 探索型 Subagent (Explore)

**用途**: 快速探索代码库、查找文件、理解结构

**适用场景**:
- 查找特定函数或类
- 理解项目结构
- 搜索特定模式
- 快速定位代码

**创建方式**:
```
Agent(
  description: "探索代码库",
  prompt: "查找...",
  subagent_type: "Explore"
)
```

### 3. 代码审查型 Subagent (code-reviewer)

**用途**: 专门用于代码审查和质量检查

**适用场景**:
- 代码质量检查
- 安全漏洞扫描
- 性能问题识别
- 最佳实践验证

**创建方式**:
```
Agent(
  description: "审查代码变更",
  prompt: "审查...",
  subagent_type: "code-reviewer"
)
```

## 参数配置

### 必需参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `description` | 简短描述（3-5 词） | "搜索 React 教程" |
| `prompt` | 详细的任务描述 | "请搜索关于 React 18 的资料..." |

### 可选参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `subagent_type` | subagent 类型 | "general-purpose" | "Explore" |
| `model` | 使用的模型 | 继承父 agent | "sonnet" |
| `effort` | 推理努力程度 | 继承会话 | "high" |
| `isolation` | 隔离模式 | 无 | "worktree" |
| `run_in_background` | 后台运行 | false | true |

### 模型选择指南

| 模型 | 适用场景 | 特点 |
|------|----------|------|
| `sonnet` | 大多数任务（推荐） | 平衡性能和成本 |
| `opus` | 复杂推理、关键任务 | 最强能力，成本较高 |
| `haiku` | 简单任务、快速响应 | 最快速度，成本最低 |
| `fable` | 创意任务、内容生成 | 创意能力强 |

### Effort 级别

| 级别 | 适用场景 | 说明 |
|------|----------|------|
| `low` | 简单搜索、格式化 | 快速完成 |
| `medium` | 一般任务（推荐） | 平衡速度和质量 |
| `high` | 复杂分析、关键决策 | 深度思考 |
| `xhigh` | 高难度问题 | 最大努力 |
| `max` | 极端复杂任务 | 极限推理 |

## Prompt 工程

### 基础 Prompt 模板

```
你是一个{角色}助手。

## 任务
{明确的任务描述}

## 搜索关键词
{关键词列表}

## 返回格式（严格遵守）
{输出格式要求}

## 约束条件
- {约束 1}
- {约束 2}
- {约束 3}
```

### 结构化输出 Prompt

```
返回格式（严格遵守，每条不超过 150 字）:

1. **标题**: [标题]
   **URL**: [链接]
   **摘要**: [核心观点，150 字内]
   **相关性评分**: [1-5]
   **关键数据**: [1-3 个]
   **来源类型**: [官方文档/博客/论文/社区/新闻]

禁止返回:
- ❌ 完整段落
- ❌ 页面导航信息
- ❌ 广告内容
- ❌ Cookie 提示
- ❌ 无关的侧边栏内容
```

### 代码审查 Prompt

```
你是一个代码审查专家。请审查以下代码变更:

## 变更文件
{文件列表}

## 审查维度
1. 代码质量
2. 安全风险
3. 性能问题
4. 最佳实践

## 返回格式
{
  "findings": [
    {
      "severity": "high|medium|low",
      "category": "quality|security|performance|best-practice",
      "file": "文件路径",
      "line": 行号,
      "description": "问题描述",
      "suggestion": "修复建议"
    }
  ],
  "summary": "总体评价"
}
```

## 并行执行模式

### 模式 1: 简单并行

**场景**: 多个独立任务同时执行

```
主 Agent
  ├── Subagent 1: 任务 A
  ├── Subagent 2: 任务 B
  └── Subagent 3: 任务 C
       ↓
  等待所有完成
       ↓
  聚合结果
```

**实现**:
```javascript
// 使用 Agent 工具并行创建
const results = await Promise.all([
  Agent({ description: "任务 A", prompt: "..." }),
  Agent({ description: "任务 B", prompt: "..." }),
  Agent({ description: "任务 C", prompt: "..." })
]);
```

### 模式 2: 流水线并行

**场景**: 多阶段任务，每个阶段可以并行处理多个项目

```
Stage 1: 批量处理
  ├── Item 1 → Subagent 1
  ├── Item 2 → Subagent 2
  └── Item 3 → Subagent 3

Stage 2: 深度处理（基于 Stage 1 结果）
  ├── High-priority → Subagent A
  └── Medium-priority → Subagent B
```

**实现**:
```javascript
// Stage 1: 并行粗筛
const stage1 = await Promise.all(items.map(item =>
  Agent({ description: `处理 ${item}`, prompt: "..." })
));

// Stage 2: 基于结果并行精读
const highPriority = stage1.filter(r => r.score >= 4);
const stage2 = await Promise.all(highPriority.map(item =>
  Agent({ description: `精读 ${item}`, prompt: "..." })
));
```

### 模式 3: 混合并行

**场景**: 需要同时执行不同类型的任务

```
┌─────────────────────────────────────┐
│           主 Agent                    │
├─────────────────────────────────────┤
│  Search Agent  │  Analysis Agent    │
│  (搜索资料)    │  (分析数据)        │
├─────────────────────────────────────┤
│  Code Agent    │  Review Agent      │
│  (编写代码)    │  (审查代码)        │
└─────────────────────────────────────┘
```

## 错误处理

### 错误类型

| 类型 | 说明 | 处理策略 |
|------|------|----------|
| API 错误 | 网络或服务问题 | 重试 2-3 次 |
| 超时错误 | 任务执行时间过长 | 设置超时，降级处理 |
| 格式错误 | 输出不符合要求 | 重新 prompt 或降级 |
| 逻辑错误 | 任务执行失败 | 记录日志，跳过或重试 |

### 重试策略

```
重试次数: 2-3 次
重试间隔: 指数退避 (1s, 2s, 4s)
降级策略: 使用更简单的模型或方法
```

### 错误处理模板

```javascript
async function safeAgentCall(config, retries = 2) {
  for (let i = 0; i <= retries; i++) {
    try {
      const result = await Agent(config);
      return { success: true, data: result };
    } catch (error) {
      if (i === retries) {
        return { success: false, error: error.message };
      }
      await delay(Math.pow(2, i) * 1000);
    }
  }
}
```

## 性能优化

### 1. 控制并发数量

**原则**: 同时最多 5 个 subagent，避免过载

```javascript
// 使用 p-limit 或类似机制
const limit = pLimit(5);
const tasks = items.map(item =>
  limit(() => Agent({ description: item, prompt: "..." }))
);
```

### 2. 优化 Prompt 长度

**原则**: Prompt 越短，响应越快，成本越低

**优化技巧**:
- 使用结构化格式而非长篇描述
- 明确列出约束条件
- 避免重复信息

### 3. 选择合适的模型

**原则**: 根据任务复杂度选择模型

```
简单搜索 → haiku
一般任务 → sonnet（推荐）
复杂推理 → opus
创意内容 → fable
```

### 4. 使用缓存

**原则**: 缓存可复用的结果

```javascript
// 检查缓存
const cached = await checkCache(cacheKey);
if (cached) return cached;

// 执行任务
const result = await Agent({...});

// 写入缓存
await writeCache(cacheKey, result);
```

## 隔离模式

### Worktree 隔离

**用途**: 当 subagent 需要修改文件时，避免与其他 subagent 冲突

**适用场景**:
- 并行修改不同文件
- 并行运行测试
- 并行执行可能失败的操作

**实现**:
```javascript
Agent({
  description: "修改代码",
  prompt: "...",
  isolation: "worktree"
})
```

**注意**:
- 每个 worktree 消耗额外磁盘空间
- 仅在必要时使用
- 完成后自动清理

### 远程隔离

**用途**: 在远程环境执行任务

**适用场景**:
- 需要特定环境配置
- 长时间运行的任务
- 需要隔离的敏感操作

## 输出格式规范

### JSON Schema 约束

对于需要结构化输出的场景，使用 JSON Schema:

```javascript
const FINDINGS_SCHEMA = {
  type: "object",
  properties: {
    findings: {
      type: "array",
      items: {
        type: "object",
        properties: {
          title: { type: "string" },
          severity: { type: "string", enum: ["high", "medium", "low"] },
          file: { type: "string" },
          line: { type: "number" },
          description: { type: "string" }
        },
        required: ["title", "severity", "file", "description"]
      }
    }
  },
  required: ["findings"]
};

const result = await Agent({
  description: "审查代码",
  prompt: "...",
  schema: FINDINGS_SCHEMA
});
```

### Markdown 输出

对于非结构化输出，使用 Markdown:

```markdown
## 结果

### 发现 1: {标题}
- **严重程度**: 高/中/低
- **文件**: {路径}
- **描述**: {问题描述}
- **建议**: {修复建议}

### 发现 2: {标题}
...
```

## 最佳实践

### 1. 明确任务边界

**DO**:
- 每个 subagent 只做一件事
- 明确输入和输出
- 设定合理的超时时间

**DON'T**:
- 让一个 subagent 做太多事
- 依赖 subagent 之间的共享状态
- 假设 subagent 会记住之前的对话

### 2. 设计容错机制

**DO**:
- 检查 subagent 返回值
- 处理 null/undefined 情况
- 提供降级方案

**DON'T**:
- 假设 subagent 总是成功
- 忽略错误日志
- 在关键路径上不做错误处理

### 3. 优化资源使用

**DO**:
- 控制并发数量
- 选择合适的模型
- 使用缓存

**DON'T**:
- 同时启动太多 subagent
- 对简单任务使用复杂模型
- 重复执行相同任务

### 4. 保持可维护性

**DO**:
- 使用有意义的 description
- 记录重要的 subagent 配置
- 定期清理不再需要的 worktree

**DON'T**:
- 使用模糊的 description
- 留下未清理的临时文件
- 硬编码配置参数

## 常见问题

### Q: 什么时候使用 subagent？

**A**: 当任务满足以下条件时:
- 可以并行执行
- 不需要共享上下文
- 结果可以独立聚合
- 任务相对独立

### Q: 如何选择 subagent 类型？

**A**: 根据任务性质:
- 通用任务 → general-purpose
- 代码探索 → Explore
- 代码审查 → code-reviewer
- 特定领域 → 自定义类型

### Q: 如何处理 subagent 失败？

**A**: 采用分层策略:
1. 重试 2-3 次
2. 使用更简单的模型
3. 降级到手动处理
4. 记录日志并继续

### Q: 如何优化 subagent 性能？

**A**: 从以下方面优化:
1. 缩短 prompt 长度
2. 选择合适的模型
3. 控制并发数量
4. 使用缓存
5. 设置合理的超时

## 输出示例

### 示例 1: 简单并行搜索

```
用户: 帮我收集 React 18 相关的资料

AI: 我来并行搜索 React 18 相关的资料...

[派发 3 个 subagent]

Subagent 1: 搜索 "React 18 新特性"
Subagent 2: 搜索 "React 18 迁移指南"
Subagent 3: 搜索 "React 18 性能优化"

[等待所有完成]

搜索完成！共发现 15 条相关资料:

| # | 标题 | 评分 | 来源 |
|---|------|------|------|
| 1 | React 18 新特性详解 | 5/5 | 官方文档 |
| 2 | React 18 迁移指南 | 4/5 | 技术博客 |
| ... | ... | ... | ... |
```

### 示例 2: 流水线并行

```
用户: 审查这个 PR 的代码质量

AI: 我来并行审查代码的不同维度...

[Stage 1: 并行审查]
Subagent 1: 审查代码质量
Subagent 2: 检查安全风险
Subagent 3: 分析性能问题

[Stage 2: 基于结果深入分析]
Subagent 4: 深入分析发现的高风险问题

审查完成！发现 3 个高风险问题，5 个中风险问题...
```

## 注意事项

1. **并发限制**: 同时最多 5 个 subagent
2. **超时设置**: 合理设置超时，避免长时间等待
3. **错误处理**: 始终检查返回值，处理失败情况
4. **资源清理**: 及时清理 worktree 等临时资源
5. **日志记录**: 记录重要的 subagent 操作，便于调试
6. **成本控制**: 根据任务复杂度选择合适的模型
