# Prompt Cache Templates

这组文件可直接复用到任何同时使用 Codex、Claude Code 或两者的项目中。

| 文件 | 用途 |
| --- | --- |
| `prompt-cache-bootstrap.sh` | 自动安装规则、更新入口文件，并检查常见缓存破坏项 |
| `prompt-cache-rules.md` | 可复制到 `rules/prompt-cache.md` 的完整规则 |
| `AGENTS-cache-snippet.md` | 可粘贴到 `AGENTS.md` 的精简入口规则 |
| `prompt-cache-playbook.md` | 设计原理、反例、指标与落地检查清单 |
| `prompt-cache-optimizer-prompt.md` | 交给 AI agent 的项目审计与优化提示词 |
| `llm-usage-event.schema.json` | 供应商无关的单次 LLM 调用日志字段合同 |
| `prompt-cache-regression-cases.json` | 固定回归样本与前后对比基线模板 |
| `prompt-cache-measurement.md` | 指标采集与回归对比说明 |

## Quick Start

先检查目标项目，不会写入文件：

```bash
bash templates/prompt-cache-bootstrap.sh --check --platform both --target /path/to/project
```

确认后安装 Codex 和 Claude Code 两套规则：

```bash
bash templates/prompt-cache-bootstrap.sh --apply --platform both --target /path/to/project
```

只配置一个平台时，将 `--platform both` 换成 `codex` 或 `claude`。

运行脚本时，请保留 `prompt-cache-bootstrap.sh`、`llm-usage-event.schema.json` 和 `prompt-cache-regression-cases.json` 在同一目录；脚本会从同目录复制这两个资产。

## What The Script Changes

- Codex：创建 `.codex/rules/common/prompt-cache.md`，并向 `AGENTS.md` 追加带标记的入口规则。
- Claude Code：创建 `.claude/rules/common/prompt-cache.md`，并向 `CLAUDE.md` 追加带标记的入口规则。
- 可观测性：创建 `.llm/prompt-cache/llm-usage-event.schema.json` 和 `.llm/prompt-cache/regression-cases.json`。
- 检查 `prompts/`、`.codex/prompts/`、`.claude/prompts/` 中可能放错位置的时间戳、UUID、git 状态等动态字段。

脚本不会改写现有业务提示词，也不会覆盖已存在的规则文件。重复执行是安全的：它会保留现有规则，并识别已插入的入口块。

## Recommended Workflow

1. 执行 `--check` 查看缺失项和警告。
2. 执行 `--apply` 安装基础规范。
3. 把高频提示词整理到 `prompts/`，使用稳定前缀和末尾参数块。
4. 将 `prompt-cache-optimizer-prompt.md` 与检查结果、调用日志一起交给 agent 做项目级审计和优化。
5. 根据 `prompt-cache-measurement.md` 接入 token、缓存读取 token、延迟和费用指标，并填写回归样本。
