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

expect_fail "$STATE_TOOL" "$learning_state" skip P0 "attempted bypass"
"$STATE_TOOL" "$learning_state" start P0
expect_fail "$STATE_TOOL" "$learning_state" complete P0
expect_fail "$STATE_TOOL" "$learning_state" confirm P0 ""
"$STATE_TOOL" "$learning_state" confirm P0 "user approved intent"
"$STATE_TOOL" "$learning_state" complete P0
assert_contains "$learning_state" 'confirmed_phases: "P0"'
assert_contains "$learning_state" '| P0 | user approved intent |'

advance_confirmed_phase "$learning_state" P1
"$STATE_TOOL" "$learning_state" start P2
expect_fail "$STATE_TOOL" "$learning_state" mode P1 freeform "wrong phase"
"$STATE_TOOL" "$learning_state" mode P2 freeform "user chose direct note"
"$STATE_TOOL" "$learning_state" confirm P2 "user approved research"
"$STATE_TOOL" "$learning_state" complete P2
"$STATE_TOOL" "$learning_state" start P3
"$STATE_TOOL" "$learning_state" skip P3 "freeform mode omits outline"
"$STATE_TOOL" "$learning_state" start P4
"$STATE_TOOL" "$learning_state" skip P4 "freeform mode omits chapter drafting"
assert_contains "$learning_state" 'mode: freeform'
assert_contains "$learning_state" '| P3 | user approved skip | freeform mode omits outline |'

batch_state="$TEST_ROOT/batch.workflow.md"
cp "$ROOT/.codex/workflows/batch-note-update-flow/state-template.md" "$batch_state"
advance_confirmed_phase "$batch_state" P0
advance_confirmed_phase "$batch_state" P1
advance_confirmed_phase "$batch_state" P2
expect_fail "$STATE_TOOL" "$batch_state" skip P3 "not started"
"$STATE_TOOL" "$batch_state" start P3
"$STATE_TOOL" "$batch_state" skip P3 "shared research not needed"

printf 'todo-state tests passed.\n'
