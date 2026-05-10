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

## Pre-Task Initialization

Before starting any new Study System task (Phase 0), internalize past learnings:

1. Read `.learnings/RULES.md` — compact, actionable rules from past sessions
2. Note what to do, what to avoid, what patterns to watch for
3. Do NOT read raw `.learnings/LEARNINGS.md` or `.learnings/ERRORS.md` — those are for the digest agent only

If `.learnings/RULES.md` doesn't exist yet (first run), skip this step.

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

### Phase 5 (Optional): Evaluate + Self-Improvement (质量评估 + 自我学习)

1. Ask: "Evaluate this note's quality and capture learnings?"
2. If yes, invoke the `evaluate` agent — it will:
   - Score on 5 dimensions (completeness, accuracy, readability, practicality, connectivity)
   - Cross-validate claims against curated source materials
   - Write evaluation report to `4-meta/evaluation/{topic}-eval.md`
   - Log session learnings and errors to `.learnings/LEARNINGS.md` and `.learnings/ERRORS.md`
3. Present evaluation results, improvement suggestions, and captured learnings summary

## Error Handling (Phase 1-4)

During Phase 1-4 execution, if any error occurs or you manually intervene to correct the model's output, **record only, do not analyze**. Append a plain-text entry to `{SYSTEM_ROOT}/4-meta/error-log.md`:

```
[YYYY-MM-DD HH:MM] {phase} - {brief description of what went wrong}
{correction taken, if any}
```

Rules:
- Plain text only — no markdown headers, no bold, no analysis
- One entry per incident, separated by blank line
- Just state what happened and what was done — no root cause analysis, no impact assessment
- After recording, ask user how to proceed (retry / skip / abort / manual fix)

## Learnings Digest

To prevent `.learnings/` files from growing unbounded, the evaluate agent runs a digest cycle when thresholds are exceeded.

### Thresholds

| File | Threshold | Action |
|------|-----------|--------|
| `.learnings/LEARNINGS.md` | > 100 lines | Compress before logging new entries |
| `.learnings/ERRORS.md` | > 100 lines | Compress before logging new entries |
| `.learnings/RULES.md` | > 50 lines | Review and promote to CLAUDE.md, trim RULES.md |

### Digest Process

When triggered (in evaluate agent Step 7):

1. Read all entries in `.learnings/LEARNINGS.md` and `.learnings/ERRORS.md`
2. Group similar entries, deduplicate, extract patterns
3. Write compact rules to `.learnings/RULES.md`:
   - One rule per line under `## Do` / `## Don't` / `## Watch For`
   - Merge recurring entries with a counter: `(3x) Use X not Y`
   - Drop one-off noise that never recurred
4. Promote critical rules to CLAUDE.md if they affect the core orchestration flow
5. Archive old entries to `.learnings/archive/YYYY-MM-DD.md`
6. Truncate `.learnings/LEARNINGS.md` and `.learnings/ERRORS.md` — keep headers only

### RULES.md Format

```markdown
# Rules
Compressed, deduplicated learnings from past sessions.

## Do
- Prefer X over Y for Z scenarios (2x)
- Always check A before B (3x)

## Don't
- Never skip cross-validation (2x)

## Watch For
- opencli adapters can return empty results for Chinese queries
```

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
