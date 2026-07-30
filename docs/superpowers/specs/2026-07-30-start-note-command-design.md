# `/start-note` Command Design

## Goal

Provide one discoverable Codex command for starting a **new-topic learning note**. The command standardizes the handoff to the existing `research-planner` and `learning-note-flow`; it does not replace either component.

## Scope

In scope:

- A Markdown command prompt at `.codex/commands/start-note.md`.
- Discoverability documentation in `.codex/commands/README.md`.
- Starting a new-topic learning-note run from a topic and optional context.
- Detecting an existing same-topic run and directing the assistant to resume it.

Out of scope:

- Importing, refreshing, or batch-updating existing notes.
- Research collection, outline generation, chapter writing, publishing, or MOC updates.
- A new skill, workflow, state-file schema, or routing rule.

## Command Interface

Users invoke the command as:

```text
/start-note <topic>
```

`topic` is required. The command accepts any additional user-provided context as optional values for learning depth, prior knowledge, note purpose, output target, and Obsidian location.

When optional values are missing, the command delegates clarification to `research-planner`, which already owns the existing intent-clarification flow. It asks only for information needed to initialize the run, one question at a time when clarification is necessary.

## Behavior and Data Flow

1. Validate that the request describes a new topic. If it is an existing-note import, refresh, or batch update, point the user to the relevant existing skill rather than attempting to route it.
2. Derive the same safe, lower-case, hyphenated run identifier convention used by `workflow-orchestrator`.
3. Check `workspace/workflow-runs/{run_id}.workflow.md`. If it exists, report the path and direct the assistant to recover the run; do not overwrite it or create a second run.
4. If no run exists, pass the topic and all supplied optional context to `research-planner`.
5. `research-planner` initializes `learning-note-flow` through `workflow-orchestrator`, creates the intent file and named state file, and leaves the run at the phase-0 user-confirmation checkpoint.

The command must read the workflow-routing rules before a state-changing action and preserve the workflow's explicit user confirmations. It never starts research or writes note content on its own.

## File Changes

| File | Change |
| --- | --- |
| `.codex/commands/start-note.md` | New command prompt specifying scope, inputs, recovery behavior, delegation, and guardrails. |
| `.codex/commands/README.md` | Document `/start-note` as the recommended new-topic learning-note entry point. |

Commands are prompt assets, not Skills, Workflows, Agents, or Hooks; therefore no new platform manifest or workflow-routing entry is required. Existing `research-planner`, `workflow-orchestrator`, and `learning-note-flow` remain the implementation dependencies.

## Errors and Edge Cases

- Missing topic: ask for a topic and do not initialize a run.
- Existing run: report it and resume according to the current state file rather than overwrite it.
- Existing-note request: direct to `legacy-note-importer`, `note-updater`, or `batch-note-updater`, depending on the request.
- No output location: preserve the existing default of project `output/`; do not require an Obsidian vault upfront.

## Verification

- Inspect the command prompt for the required guards and delegation path.
- Confirm README references the command and does not imply it handles old notes.
- Run the repository's manifest validation to ensure the unchanged registry remains valid.
- Run the Codex-to-Claude synchronization required for changes to project Codex configuration, then verify its result.
