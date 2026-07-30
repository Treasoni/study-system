#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
cd "$ROOT"

bash tests/test_todo_state.sh
python3 tests/test_manifest_registry.py
python3 tests/test_validate_portability.py
bash tests/test_post_conversation_hook.sh
bash .codex/scripts/workflow-health-check.sh
bash .codex/scripts/check-env-template.sh --strict
python3 .agent-sync/sync_agents.py --check
./.agents/skills/security-secret-audit/scripts/audit-secrets.sh --all

printf 'All Study System validations passed.\n'
