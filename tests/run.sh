#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
cd "$ROOT"

bash tests/test_todo_state.sh
python3 tests/test_manifest_registry.py
python3 tests/test_sync_codex_to_claude.py
bash tests/test_post_conversation_hook.sh
bash .codex/scripts/workflow-health-check.sh
bash .codex/scripts/check-env-template.sh --strict
./.codex/scripts/sync-codex-to-claude.sh --check
./.codex/skills/security-secret-audit/scripts/audit-secrets.sh --all

printf 'All Study System validations passed.\n'
