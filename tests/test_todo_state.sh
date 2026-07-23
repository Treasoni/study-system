#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_TOOL="$ROOT/.codex/scripts/todo-state.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/study-system-todo-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

expect_fail() {
  local exit_code
  set +e
  "$@" >/dev/null 2>&1
  exit_code=$?
  set -e
  if [ "$exit_code" -eq 0 ]; then
    fail "expected failure: $*"
  fi
}

assert_contains() {
  local file="$1"
  local expected="$2"
  rg -qF "$expected" "$file" || fail "missing '$expected' in $file"
}

advance_confirmed_phase() {
  local state="$1"
  local phase="$2"
  "$STATE_TOOL" "$state" start "$phase"
  "$STATE_TOOL" "$state" confirm "$phase" "user approved $phase"
  "$STATE_TOOL" "$state" complete "$phase"
}

learning_state="$TEST_ROOT/learning.workflow.md"
cp "$ROOT/.codex/workflows/learning-note-flow/state-template.md" "$learning_state"

"$STATE_TOOL" "$learning_state" start P0
expect_fail "$STATE_TOOL" "$learning_state" skip P0 "attempted bypass"
expect_fail "$STATE_TOOL" "$learning_state" complete P0
expect_fail "$STATE_TOOL" "$learning_state" confirm P0 ""
"$STATE_TOOL" "$learning_state" confirm P0 "user approved intent"
"$STATE_TOOL" "$learning_state" complete P0
assert_contains "$learning_state" 'confirmed_phases: "P0"'
assert_contains "$learning_state" '| P0 | user approved intent |'

advance_confirmed_phase "$learning_state" P1
"$STATE_TOOL" "$learning_state" start P2
expect_fail "$STATE_TOOL" "$learning_state" skip P2 "research is required"
expect_fail "$STATE_TOOL" "$learning_state" mode P2 freeform ""
"$STATE_TOOL" "$learning_state" mode P2 freeform "user chose direct note"
"$STATE_TOOL" "$learning_state" confirm P2 "user approved research"
"$STATE_TOOL" "$learning_state" complete P2
"$STATE_TOOL" "$learning_state" start P3
expect_fail "$STATE_TOOL" "$learning_state" skip P3 ""
"$STATE_TOOL" "$learning_state" skip P3 "freeform mode omits outline"
"$STATE_TOOL" "$learning_state" start P4
"$STATE_TOOL" "$learning_state" skip P4 "freeform mode omits chapter drafting"
advance_confirmed_phase "$learning_state" P5
"$STATE_TOOL" "$learning_state" start P6
expect_fail "$STATE_TOOL" "$learning_state" skip P6 "assembly is required"
"$STATE_TOOL" "$learning_state" confirm P6 "user approved assembly"
"$STATE_TOOL" "$learning_state" complete P6
"$STATE_TOOL" "$learning_state" start P7
expect_fail "$STATE_TOOL" "$learning_state" skip P7 ""
"$STATE_TOOL" "$learning_state" skip P7 "publication was declined"
assert_contains "$learning_state" 'mode: freeform'
assert_contains "$learning_state" '| P3 | user approved skip | freeform mode omits outline |'
assert_contains "$learning_state" '| P7 | user approved skip | publication was declined |'

outline_state="$TEST_ROOT/outline.workflow.md"
cp "$ROOT/.codex/workflows/learning-note-flow/state-template.md" "$outline_state"
advance_confirmed_phase "$outline_state" P0
advance_confirmed_phase "$outline_state" P1
advance_confirmed_phase "$outline_state" P2
"$STATE_TOOL" "$outline_state" start P3
expect_fail "$STATE_TOOL" "$outline_state" mode P3 freeform "wrong phase"
expect_fail "$STATE_TOOL" "$outline_state" skip P3 "outline mode requires an outline"
"$STATE_TOOL" "$outline_state" confirm P3 "user approved outline"
"$STATE_TOOL" "$outline_state" complete P3
"$STATE_TOOL" "$outline_state" start P4
expect_fail "$STATE_TOOL" "$outline_state" skip P4 "outline mode requires drafting"

batch_state="$TEST_ROOT/batch.workflow.md"
cp "$ROOT/.codex/workflows/batch-note-update-flow/state-template.md" "$batch_state"
advance_confirmed_phase "$batch_state" P0
advance_confirmed_phase "$batch_state" P1
advance_confirmed_phase "$batch_state" P2
expect_fail "$STATE_TOOL" "$batch_state" skip P3 "not started"
"$STATE_TOOL" "$batch_state" start P3
expect_fail "$STATE_TOOL" "$batch_state" skip P3 ""
"$STATE_TOOL" "$batch_state" skip P3 "shared research not needed"

legacy_state="$TEST_ROOT/legacy.workflow.md"
cp "$ROOT/.codex/workflows/legacy-note-import-flow/state-template.md" "$legacy_state"
advance_confirmed_phase "$legacy_state" P0
advance_confirmed_phase "$legacy_state" P1
advance_confirmed_phase "$legacy_state" P2
advance_confirmed_phase "$legacy_state" P3
"$STATE_TOOL" "$legacy_state" start P4
expect_fail "$STATE_TOOL" "$legacy_state" skip P4 ""
"$STATE_TOOL" "$legacy_state" skip P4 "no stale content found"
assert_contains "$legacy_state" '| P4 | user approved skip | no stale content found |'

printf 'todo-state tests passed.\n'
