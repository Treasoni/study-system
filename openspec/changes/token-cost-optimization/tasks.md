# Tasks

## Phase 1: 脚本层

- [ ] 创建 `scripts/batch_fetch.py` — 并发网页抓取脚本
- [ ] 创建 `scripts/merge_sources.py` — 多文件合并脚本
- [ ] 创建 `scripts/requirements.txt` — Python 依赖清单
- [ ] 编写脚本单元测试

## Phase 2: Subagent 修改

- [ ] 修改 `.claude/agents/collector.md` — 用 batch_fetch.py 替代串行 WebFetch
- [ ] 修改 `.claude/agents/writer.md` — 用 merge_sources.py 替代串行 Read
- [ ] 修改 `.claude/agents/curator.md` — 用 merge_sources.py 替代串行 Read
- [ ] 修改 `.claude/skills/collect/SKILL.md` — 传递脚本路径参数

## Phase 3: 验证

- [ ] 端到端测试：收集阶段 Token 消耗对比
- [ ] 端到端测试：写作阶段 Token 消耗对比
- [ ] 错误处理测试：脚本失败降级
- [ ] 错误处理测试：Agent 自修复 L2/L4
