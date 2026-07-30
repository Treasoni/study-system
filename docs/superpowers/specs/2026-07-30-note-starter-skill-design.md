# Note Starter Skill Design

## Goal

Add a discoverable `note-starter` skill that serves as the user-facing entry point for a new-topic learning note. It reuses the established planner and workflow rather than duplicating their production logic.

## Scope

In scope:

- A new `.codex/skills/note-starter/` skill with `SKILL.md`, platform manifest, and generated OpenAI UI metadata.
- Routing entries in `AGENTS.md` for natural-language requests such as “开始写笔记”, “启动写笔记”, and “新主题学习笔记”.
- Explicit delegation from `note-starter` to `research-planner`.

Out of scope:

- A slash command in `.codex/commands/`.
- Importing, refreshing, or batch-updating existing notes.
- A new workflow, state-file schema, or workflow-routing table entry.
- Research collection, outline generation, writing, publishing, or MOC updates.

## Skill Interface

`note-starter` triggers when the user asks to start, create, or begin writing a note for a new learning topic. The user provides a topic and can additionally supply depth, existing knowledge, purpose, output target, and Obsidian fields.

The topic is required. When it is absent, the skill asks only for the topic and does not create files or begin research. Missing optional context is delegated to `research-planner`, which already owns the intent-clarification interaction.

## Data Flow

```text
new-topic request
  -> note-starter (scope check and recovery check)
  -> research-planner (clarify intent)
  -> workflow-orchestrator (create or recover named state)
  -> learning-note-flow (phase 0 confirmation)
```

1. Read `.codex/rules/workflow-routing.md` before any state-changing work, then confirm `learning-note-flow` is the matching required workflow.
2. Reject an existing-note import, single-note refresh, or batch update from this entry point and direct it to `legacy-note-importer`, `note-updater`, or `batch-note-updater`.
3. Derive the lower-case, hyphenated run ID convention used by `workflow-orchestrator` and inspect `workspace/workflow-runs/{run_id}.workflow.md`.
4. If that state exists, report its path and recover it; never overwrite it or create a duplicate.
5. If it does not exist, pass the topic and all supplied context to `research-planner`. That skill calls `workflow-orchestrator`, creates the intent file and state file, and stops at the phase-0 user-confirmation checkpoint.

`note-starter` itself does not create state or content files, perform research, or advance workflow phases. Its manifest therefore requests read-only filesystem access, no network or subprocess access, and declares `Skill/research-planner` as its only dependency. The downstream planner retains its existing write and subprocess permissions.

## File Changes

| File | Change |
| --- | --- |
| `.codex/skills/note-starter/SKILL.md` | Concise entry-skill instructions, routing guards, recovery rule, and planner handoff. |
| `.codex/skills/note-starter/manifest.yaml` | Register version `1.0.0`, capability `notes.start`, minimal permissions, and `Skill/research-planner` dependency. |
| `.codex/skills/note-starter/agents/openai.yaml` | Generated list/chip metadata consistent with the skill interface. |
| `AGENTS.md` | Add `note-starter` to the project skill-routing table. |

Because a skill is added, the repository must validate manifests and run the project Codex-to-Claude synchronizer followed by its `--check` mode. The sync operation is the approved exception for updating the generated Claude compatibility mirror.

## Errors and Edge Cases

- Missing topic: ask for the topic; do not initialize a run.
- Existing run: report and recover the state file; do not overwrite it.
- Existing-note request: redirect to the existing specialized skill without initializing a learning-note run.
- Unspecified output location: retain the `research-planner` default of project output; do not require an Obsidian vault.

## Verification

- Run the Skill Creator structural validator for `note-starter`.
- Run the manifest registry validator after adding the new manifest.
- Verify the skill description and `AGENTS.md` include the intended new-topic trigger phrases and exclude old-note paths.
- Run `.codex/scripts/sync-codex-to-claude.sh` and `.codex/scripts/sync-codex-to-claude.sh --check`.
