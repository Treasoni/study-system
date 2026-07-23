# Workflow Governance and Validation Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

Goal: Enforce Study System workflow governance and make all repository safety checks executable locally and in GitHub Actions.

Architecture: State templates declare transition policy and todo-state.sh enforces it. Dependency-free shell and Python tests exercise the state machine, manifest validator, synchronization tool, and lifecycle hook. tests/run.sh becomes both the local command and GitHub Actions gate.

Tech Stack: Bash, Python 3 standard library, GitHub Actions, and the existing Perl secret detector.

## Global Constraints

- Keep Codex configuration in .codex and synchronize the Claude mirror after every .codex change.
- The synchronization utility is the only writer to .claude.
- Add no third-party Python dependency.
- Tests use temporary directories only; they never alter workspace or user notes.
- Write and run every regression test before its production change.
- Before completion, run the test runner, workflow health check, strict env validation, mirror check, and secret audit.

---

## File Map

| Path | Responsibility |
| --- | --- |
| .codex/scripts/todo-state.sh | Enforce confirmations, bounded skips, and mode transitions. |
| .codex/workflows/*/state-template.md | Declare workflow-specific state policy and audit records. |
| tests/test_todo_state.sh | State-transition regression tests. |
| .codex/platform/manifest-registry.py | Dependency-cycle detection. |
| tests/test_manifest_registry.py | Cycle-detection regression test. |
| .codex/scripts/sync-codex-to-claude.py | Deterministic compatibility mirror and --check. |
| tests/test_sync_codex_to_claude.py | Mirror reconciliation regression test. |
| .codex/hooks/post-conversation.sh | Secret-safe opt-in automatic commit. |
| .env.example and .env.optional.example | Real runtime configuration and optional configuration reference. |
| tests/run.sh and .github/workflows/validate.yml | Local and hosted validation gates. |

## Task 1: Enforce State Transitions

Files:
- Create: tests/test_todo_state.sh
- Modify: .codex/scripts/todo-state.sh
- Modify: all three .codex/workflows/*/state-template.md
- Modify: all three .codex/workflows/*/workflow.md

Interfaces:
- Consumes state-file frontmatter: confirmed_phases, skippable_phases, mode_dependent_skips, allowed_modes, and mode_change_phase.
- Produces commands: confirm <phase> <reason> and mode <phase> <mode> <reason>. Invalid transitions exit non-zero.

- [ ] Step 1: Write a failing shell regression test

Create tests/test_todo_state.sh. Its first scenario copies the learning state template to a temporary file, expects skip P0 "attempted bypass" to fail, starts P0, expects complete P0 to fail before confirmation, expects empty confirmation to fail, confirms P0 with a reason, completes P0, and asserts confirmed_phases contains P0.

Its second scenario progresses to P2, checks that mode P1 freeform fails, chooses mode P2 freeform, and verifies that only started P3 and P4 can be skipped with reasons. Its third scenario proves batch P3 cannot be skipped before it is started.

- [ ] Step 2: Prove the test is red

Run: bash tests/test_todo_state.sh

Expected: the first assertion fails because the current tool permits skip P0.

- [ ] Step 3: Declare policy in templates

Add these frontmatter fields after mode in every state template:

    confirmed_phases: ""
    skippable_phases: ""
    mode_dependent_skips: ""
    allowed_modes: ""
    mode_change_phase: ""

Set batch skippable_phases to P3, legacy import skippable_phases to P4, and learning-note skippable_phases to P7, mode_dependent_skips to P3,P4, allowed_modes to outline,freeform, and mode_change_phase to P2.

Add visible 用户确认记录 and 跳过记录 tables directly before 异常记录 in every state template.

- [ ] Step 4: Implement minimum state-machine rules

Add confirm and mode actions to todo-state.sh. Implement helpers named frontmatter_value, csv_contains, require_nonempty_reason, require_phase_in_progress, append_confirmation, and append_skip_record.

confirm requires an in-progress phase and non-empty reason, appends the phase to confirmed_phases, and writes a confirmation-table row. complete requires that phase in confirmed_phases. skip requires an in-progress phase, non-empty reason, and explicit permission; a mode_dependent_skips phase is permitted only with mode freeform. mode requires the configured phase, an allowed mode, an in-progress phase, and non-empty reason.

Update workflow prose so optional phases are started then skipped. Replace the freeform direct frontmatter edit with the mode P2 freeform command.

- [ ] Step 5: Verify green

Run: bash tests/test_todo_state.sh

Expected: exit 0, including rejection of P0 skip and unconfirmed completion.

- [ ] Step 6: Commit

    git add tests/test_todo_state.sh .codex/scripts/todo-state.sh .codex/workflows
    git commit -m "feat: enforce workflow state transitions"

## Task 2: Reject Manifest Dependency Cycles

Files:
- Create: tests/test_manifest_registry.py
- Modify: .codex/platform/manifest-registry.py
- Modify: .codex/skills/manifest-platform/manifest.yaml

Interfaces:
- Consumes Artifact objects from discover_and_validate(root).
- Produces dependency-cycle errors with every participating artifact ID.

- [ ] Step 1: Write a failing Python fixture test

Create a temporary root with copied registry.yaml and two valid Skill directories. The alpha manifest depends on Skill/beta; beta depends on Skill/alpha. Run the real registry script and assert a non-zero return code, the string dependency cycle, Skill/alpha, and Skill/beta in stderr.

- [ ] Step 2: Prove the test is red

Run: python3 tests/test_manifest_registry.py

Expected: failure because cyclic dependencies currently validate.

- [ ] Step 3: Add depth-first cycle detection

Add dependency_cycle_errors accepting the artifact list. Build an adjacency map, track unvisited, visiting, and visited IDs, and render the active DFS stack slice whenever an edge reaches a visiting ID. Append these errors after unknown-dependency errors in discover_and_validate.

- [ ] Step 4: Verify green

Run: python3 tests/test_manifest_registry.py
Run: python3 .codex/platform/manifest-registry.py --root . validate

Expected: both commands exit 0.

- [ ] Step 5: Commit

    git add tests/test_manifest_registry.py .codex/platform/manifest-registry.py .codex/skills/manifest-platform/manifest.yaml
    git commit -m "fix: reject manifest dependency cycles"

## Task 3: Make Compatibility Synchronization Deterministic

Files:
- Create: tests/test_sync_codex_to_claude.py
- Create: .codex/scripts/sync-codex-to-claude.py
- Modify: .codex/scripts/sync-codex-to-claude.sh
- Modify: .codex/rules/common/sync-workflow.md

Interfaces:
- Consumes sync-codex-to-claude.py with an optional --check command.
- Produces --check exit 1 and relative differences for stale paths; default sync reconciles them.

- [ ] Step 1: Write a failing mirror test

Create a temporary project root, copy source .codex, and add .claude/skills/obsolete/SKILL.md. Assert that --check reports skills/obsolete/SKILL.md, a default invocation removes it, and a final --check exits 0.

- [ ] Step 2: Prove the test is red

Run: python3 tests/test_sync_codex_to_claude.py

Expected: a missing synchronizer failure.

- [ ] Step 3: Implement the standard-library synchronizer

Implement pure functions named reconcile, transform_text, expected_mirror, and differing_paths. Manage skills, agents, rules, scripts, platform, and workflows. Preserve only skills/skill-creator, rules/common/hooks.md, rules/common/sync-workflow.md, and scripts/sync-codex-to-claude.sh. Transform .codex to .claude and Codex to Claude Code only in copied .md, .sh, .py, and .yaml files.

Replace the Bash implementation with a stable wrapper that locates the project root and executes the Python synchronizer with its original arguments.

- [ ] Step 4: Verify green

Run: python3 tests/test_sync_codex_to_claude.py
Run: .codex/scripts/sync-codex-to-claude.sh
Run: .codex/scripts/sync-codex-to-claude.sh --check

Expected: all commands exit 0.

- [ ] Step 5: Commit

    git add tests/test_sync_codex_to_claude.py .codex/scripts/sync-codex-to-claude.py .codex/scripts/sync-codex-to-claude.sh .codex/rules/common/sync-workflow.md
    git commit -m "fix: make Claude mirror synchronization checkable"

## Task 4: Harden Environment and Lifecycle Automation

Files:
- Create: .env.optional.example
- Create: tests/test_post_conversation_hook.sh
- Modify: .env.example
- Modify: .codex/hooks/post-conversation.sh
- Modify: .codex/hooks/post-conversation/manifest.yaml
- Modify: README.md, .codex/README.md, and .codex/rules/common/env.md

Interfaces:
- Consumes the minimal .env.example; optional settings are copied explicitly from .env.optional.example.
- Produces strict environment validation success and a hook that commits only after clean working-tree and staged secret scans.

- [ ] Step 1: Write failing validation tests

Create a temporary Git repository in tests/test_post_conversation_hook.sh, copy the hook and secret auditor, create a detector-matching credential file, enable CODEX_AUTO_GIT=1, and assert the HEAD commit count stays at one. The test must inspect only redacted auditor output and commit count.

Add strict env validation to the test-runner draft.

- [ ] Step 2: Prove the tests are red

Run: bash .codex/scripts/check-env-template.sh --strict
Run: bash tests/test_post_conversation_hook.sh

Expected: strict env validation lists unused variables; the current hook can commit the credential fixture.

- [ ] Step 3: Implement the minimum hardening

Replace .env.example with:

    WORKSPACE_PATH=./workspace
    CODEX_AUTO_GIT=0

Move optional paths, provider keys, models, services, and observability entries to .env.optional.example, headed with “not loaded automatically.” Remove CODEX_AUTO_GIT_PUSH from code and documentation.

Before staging, run the working-tree secret audit; after staging, run audit-secrets.sh --staged. A failed scan logs a redacted failure and exits without commit or push. Remove automatic-push behavior and set the Hook manifest network permission to none.

- [ ] Step 4: Verify green

Run: bash .codex/scripts/check-env-template.sh --strict
Run: bash tests/test_post_conversation_hook.sh

Expected: both commands exit 0; the credential fixture creates no automatic commit.

- [ ] Step 5: Commit

    git add .env.example .env.optional.example .codex/hooks README.md .codex/README.md .codex/rules/common/env.md tests/test_post_conversation_hook.sh
    git commit -m "fix: harden lifecycle automation"

## Task 5: Add Unified Local and CI Gates

Files:
- Create: tests/run.sh
- Create: .github/workflows/validate.yml
- Modify: workflow-state, manifest-platform, workflow, and hook manifests

Interfaces:
- Consumes: bash tests/run.sh.
- Produces one exit status for unit, structural, synchronization, environment, and security checks.

- [ ] Step 1: Write a failing runner smoke test

Create tests/test_run.sh containing an invocation of tests/run.sh. Run it before the runner exists.

Expected: missing-file failure.

- [ ] Step 2: Implement the runner and GitHub Action

Create tests/run.sh with these commands in order:

    bash tests/test_todo_state.sh
    python3 tests/test_manifest_registry.py
    python3 tests/test_sync_codex_to_claude.py
    bash .codex/scripts/workflow-health-check.sh
    bash .codex/scripts/check-env-template.sh --strict
    .codex/scripts/sync-codex-to-claude.sh --check
    .codex/skills/security-secret-audit/scripts/audit-secrets.sh --all

Create .github/workflows/validate.yml for push and pull_request, with actions/checkout@v4, actions/setup-python@v5 on Python 3.11, and bash tests/run.sh.

- [ ] Step 3: Bump contracts and synchronize

Bump workflow-todo-state, manifest-platform, all three workflow manifests, and post-conversation from 1.0.0 to 1.1.0. Run the compatibility synchronizer and its --check mode.

- [ ] Step 4: Verify the complete local gate

Run: bash tests/test_run.sh
Run: bash tests/run.sh

Expected: both commands exit 0.

- [ ] Step 5: Commit

    git add tests .github .codex README.md .env.example .env.optional.example
    git commit -m "ci: validate workflow governance"

## Task 6: Final Verification and Review

Files:
- Verify: all changed files

- [ ] Step 1: Run full verification

    bash tests/run.sh
    git diff --check
    git status --short

Expected: the runner and whitespace check exit 0.

- [ ] Step 2: Run final secret audit

    .codex/skills/security-secret-audit/scripts/audit-secrets.sh --all

Expected: Secret audit passed: no potential credentials found.

- [ ] Step 3: Request code review

Dispatch a reviewer with this plan, the design document, base commit cb83a8f, and the implementation HEAD. Resolve every Critical or Important finding before handoff.

