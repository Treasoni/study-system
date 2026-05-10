# CLAUDE.md

This repository contains the **Study System** — a semi-automated technical learning note system built with Claude Code + Obsidian.

## How It Works

1. User says "I want to learn X"
2. Main Claude orchestrates 5 phases: collect → curate → write → beautify → evaluate
3. Each phase reads/writes files under `{VAULT_PATH}/StudySystem/`
4. User reviews and approves at each phase boundary

## Configuration

Before first use, configure the Obsidian vault path:
- Read `.obsidian-config.md` from this repo
- Ask user for their Obsidian vault path
- Write it to `{VAULT_PATH}/StudySystem/.obsidian-config.md`

## Orchestration Flow

### Phase 0: Requirement Clarification + Path Confirmation

When user expresses intent to learn something, ask in two rounds:

**Round 1: Learning goals**
Ask the user:
1. "Which direction?"
   - a) 概念理解 (Understand concepts and principles)
   - b) 实战上手 (Hands-on practice)
   - c) 体系梳理 (Build complete knowledge system)
   - d) 问题排查 (Solve a specific problem)
2. "What depth?" → 入门 / 进阶 / 深入源码
3. "What note type?" → 概念笔记 / 实战笔记 / 对比笔记 / 速查表

**Round 2: Path configuration**
Ask the user:
1. "Where to save the final note?"
   - Default: `{SYSTEM_ROOT}/3-published/{topic}/`
   - Can specify any path within the vault, e.g. `Notes/前端/React/`
2. "Topic name for folder?" (default: sanitized topic name)

**After user answers → Generate and present execution plan:**
```
## Execution Plan
- Topic: {topic}
- Direction: {direction}
- Depth: {depth}
- Note type: {note_type}
- Output path: {output_path}
- Phases: collect → curate → write → beautify → [evaluate]

Proceed?
```

Write plan to `{SYSTEM_ROOT}/4-meta/execution-log.md`:
```markdown
## [{date}] {topic}
- Direction: {direction}
- Depth: {depth}
- Note type: {note_type}
- Output path: {output_path}
- Status: started
```

### Phase 1: Collect (资料收集)

1. Invoke `/collect` — it will search for official docs and community content, fetch and save raw materials to `0-inbox/{topic}/`
2. Present summary to user:
   - How many sources collected
   - Which sub-topics are covered
   - Any obvious gaps
3. User: confirm / supplement / re-collect

### Phase 2: Curate (资料整理)

1. Invoke `/curate` — it will score, deduplicate, and categorize all sources, write curated files to `1-curated/{topic}/`
2. Present summary to user:
   - Knowledge map overview
   - Which sources were discarded and why
   - Which sub-topics lack sufficient material
3. User: confirm / adjust / supplement then redo

### Phase 3: Write (生成笔记)

1. Confirm note type preference (skip if already set in Phase 0)
2. Invoke `/write` — it will select template from `templates/`, extract info from curated materials, write draft to `2-drafts/{topic}/`
3. Present draft to user:
   - Structure review
   - Accuracy check
   - Any missing content
4. User: confirm / modify / rewrite

### Phase 4: Beautify (美化排版)

1. Invoke `/beautify` — it will apply Obsidian Markdown formatting, add wikilinks, tags, callouts, Mermaid diagrams, write final note to the user-specified output path
2. Present final result to user → **Pause here. Do not proceed.** Ask: "Any changes needed?"
3. User reviews and may request modifications
4. When user gives feedback: **implement minimal, targeted fixes only** — do NOT regenerate the entire note. Fix just what was flagged, keeping other content untouched
5. Repeat 2-4 until user approves
6. User: confirm → proceed to Phase 5 (if desired)

### Phase 5 (Optional): Evaluate (质量评估)

1. Ask: "Evaluate this note's quality?"
2. If yes, invoke the `evaluate` subagent — it will score on 5 dimensions (completeness, accuracy, readability, practicality, connectivity), write report to `4-meta/evaluation/{topic}-eval.md`
3. Present results and improvement suggestions

### Post-Phase 5: Self-Improvement (自我学习)

After all phases (including optional evaluate) are complete, invoke the self-improving agent:

```
Skill({skill: "self-improving-agent"})
```

This captures learnings, errors, and corrections from the entire session to improve future Study System runs.

## Error Handling

**Every phase must report issues back to Claude Code.** When any anomaly occurs during a phase (skill/subagent failure, empty output, data inconsistency, permission error, etc.):

1. **Report immediately** — describe the issue, impact, and what action was taken
2. **Write to error log** — append to `{SYSTEM_ROOT}/4-meta/error-log.md`:
```markdown
## [{timestamp}] {phase} phase anomaly
- **Issue**: {description}
- **Impact**: {what's affected}
- **Action**: {what was done}
```
3. **Ask user** how to proceed (retry / skip / abort / manual fix)

This applies to all phases: collect, curate, write, beautify, evaluate.

## Quality Gates

Between each phase, check:
- Previous phase output files exist and are non-empty
- Output content is consistent with input
- If checks fail → log to error-log.md → ask user how to proceed

## Directory Convention

```
{VAULT_PATH}/StudySystem/
├── templates/       # Note templates
├── 0-inbox/         # Phase 1: raw collected materials
├── 1-curated/       # Phase 2: organized and scored materials
├── 2-drafts/        # Phase 3: draft notes
├── 3-published/     # Phase 4: final beautified notes (default output)
└── 4-meta/          # Logs, errors, evaluations
```

## Key Principles

1. All system files live under `StudySystem/` — don't pollute the vault root
2. Output path is set by user in Phase 0 — never hardcoded
3. Each skill only handles its own phase — no crossing boundaries
4. Data passes through files, not memory — each phase's output is the next phase's input
5. User reviews after every phase — no full automation
6. Prefer official docs and primary sources
7. Every claim must be traceable to its source
