## Tasks

- [x] 1. 在 4 个 agent 定义文件中添加 "skip global init" 指令
  - writer.md: 添加 "忽略 CLAUDE.md 中的 Resource Discovery、Pre-Task Init、Mandatory Triggered Reads"
  - collector.md: 同上
  - curator.md: 同上
  - beautifier.md: 同上

- [x] 2. 在 CLAUDE.md 中添加 "MAIN AGENT ONLY" 标注
  - Resource Discovery 段落标注 "以下指令仅适用于主 Agent"
  - Pre-Task Init 段落标注 "以下步骤仅适用于主 Agent"
  - Mandatory Triggered Reads 表格添加说明 "此表仅约束主 Agent"

- [x] 3. 修复 writer.md 和 beautifier.md 的 wikilink 验证路径
  - writer.md Step 3.5: `Glob **/目标名.md` → `Glob {OUTPUT_PATH}/目标名.md` + `Glob {SYSTEM_ROOT}/**/目标名.md`
  - beautifier.md Step 3b: 同样修改

- [x] 4. 更新 TODO.md 格式支持跨阶段路径传递
  - write/SKILL.md: 更新 Step 2 中对 TODO.md 的引用，添加 input/output 路径字段
  - collect/SKILL.md: 同步更新
  - beautify/SKILL.md: 同步更新

- [ ] 5. 验证修改后 subagent 行为
  - 手动测试：触发一次 collect → write 流程
  - 观察 subagent 的 Glob/Read 调用次数是否显著减少
  - 对比 token 消耗
