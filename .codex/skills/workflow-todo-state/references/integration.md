# Integration Guide

## Install Into Another Project

Recommended one-command install from this source project:

```bash
.codex/skills/workflow-todo-state/scripts/install.sh /path/to/target-project --with-skill --init-layout --update-agents
```

Script-only install:

```bash
.codex/skills/workflow-todo-state/scripts/install.sh /path/to/target-project
```

Manual fallback:

```bash
mkdir -p /path/to/target-project/.codex/scripts
cp .codex/skills/workflow-todo-state/scripts/todo-state.sh /path/to/target-project/.codex/scripts/todo-state.sh
chmod +x /path/to/target-project/.codex/scripts/todo-state.sh
```

## Recommended Layout

Use named workflow definitions and named run state files:

```text
.codex/workflows/
  feature-development/
    workflow.md
    state-template.md
.codex/rules/
  workflow-routing.md
workspace/workflow-runs/
  payment-refactor.workflow.md
```

`todo-state.sh` accepts any Markdown state file path, so the run file does not need to be named `todo.md`.

## Add Project Rule

Add this to the project entry instructions:

```markdown
Every workflow phase must read the active workflow state file before acting. Workflow state files live under `workspace/workflow-runs/` and should be named after the task, such as `payment-refactor.workflow.md`. Do not skip phases. Change phase state only through `.codex/scripts/todo-state.sh`.
```

## Retrofit Existing State Templates

1. Add YAML frontmatter:
   ```yaml
   ---
   workflow_id: your-flow
   workflow_name: Your Flow
   workflow_version: 1
   state_file_type: workflow-run
   run_id: "{run_id}"
   task: "{task}"
   created_from: ".codex/workflows/your-flow/state-template.md"
   created_at: "{date}"
   last_updated: "{date}"
   current_phase: P0
   current_status: not_started
   mode: standard
   blocked_reason: ""
   ---
   ```
2. Add a visible current phase line:
   ```markdown
   > 当前阶段：阶段 0
   ```
3. Ensure each phase has one unique status line:
   ```markdown
   > [P3] ⬜ 未开始
   ```
4. Replace manual edits:
   ```bash
   .codex/scripts/todo-state.sh "${WORKFLOW_STATE_FILE}" start P3
   .codex/scripts/todo-state.sh "${WORKFLOW_STATE_FILE}" complete P3
   .codex/scripts/todo-state.sh "${WORKFLOW_STATE_FILE}" skip P3 "optional phase not needed"
   .codex/scripts/todo-state.sh "${WORKFLOW_STATE_FILE}" block P3 "waiting for confirmation"
   ```

## Validation Checklist

- `bash -n .codex/scripts/todo-state.sh`
- Start and complete P0 on a copied workflow state file.
- Try starting P2 before P1 is complete; it should fail.
- Try skipping an optional phase; `current_phase` should advance to the next pending phase.
- Confirm `## 异常记录` receives skip/block rows when present.
