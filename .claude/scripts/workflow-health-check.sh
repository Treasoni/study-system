#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

this_dir=".claude"
codex_dir=".co""dex"
claude_dir=".$(printf '%s' "claude")"
other_dir="$claude_dir"
if [ "$this_dir" = "$claude_dir" ]; then
  other_dir="$codex_dir"
fi

other_skill_pattern='\.claude/skills'
if [ "$other_dir" = "$codex_dir" ]; then
  other_skill_pattern='\.co'"dex"'/skills'
fi

status=0

fail() {
  printf '\nFAIL: %s\n' "$1" >&2
  status=1
}

run_forbidden_rg() {
  local label="$1"
  local pattern="$2"
  shift 2

  local tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/workflow-health.XXXXXX")"
  if rg -n --hidden -g '!.git/**' -g "!${other_dir}/**" -g '!workspace/**' "$pattern" "$@" > "$tmp"; then
    printf '\n%s\n' "$label" >&2
    cat "$tmp" >&2
    fail "$label"
  fi
  rm -f "$tmp"
}

echo "Workflow health check"

run_forbidden_rg \
  "Project-scoped todo.md references in active workflow instructions:" \
  '\$\{PROJECT_DIR\}/todo\.md|\$PROJECT_DIR/todo\.md' \
  "$this_dir/agents" \
  "$this_dir/skills/research-collector" \
  "$this_dir/skills/note-beautifier" \
  "$this_dir/skills/workflow-orchestrator" \
  "$this_dir/workflows"

run_forbidden_rg \
  "Manual phase-status sed edits in active workflow instructions:" \
  'sed -i .*\[P[0-9]' \
  "$this_dir/agents" \
  "$this_dir/skills/research-collector" \
  "$this_dir/skills/note-beautifier" \
  "$this_dir/skills/workflow-orchestrator" \
  "$this_dir/workflows"

run_forbidden_rg \
  "Skill docs must not point to the other assistant namespace:" \
  "$other_skill_pattern" \
  "$this_dir/skills"

if [ -d "$this_dir/skills/workflow-orchestrator/templates" ] &&
  find "$this_dir/skills/workflow-orchestrator/templates" -type f -name '*-todo.md' | grep -q .; then
  find "$this_dir/skills/workflow-orchestrator/templates" -type f -name '*-todo.md' >&2
  fail "Legacy workflow-orchestrator todo templates are still present."
fi

if ! "$this_dir/scripts/sync-workflow-routing.sh" --check; then
  fail "Workflow routing table is stale."
fi

if ! python3 "$this_dir/platform/manifest-registry.py" --root . validate; then
  fail "Agent Platform manifest registry validation failed."
fi

if [ "$status" -eq 0 ]; then
  echo "Workflow health check passed."
fi

exit "$status"
