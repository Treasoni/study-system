#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  .codex/scripts/sync-workflow-routing.sh [--check]

Generate the managed Available Workflows table in
.codex/rules/workflow-routing.md from .codex/workflows/*/routing.yaml.

Options:
  --check    Do not write files. Exit non-zero when the generated routing block is stale.
USAGE
}

MODE="write"
case "${1:-}" in
  "") ;;
  --check) MODE="check" ;;
  -h|--help) usage; exit 0 ;;
  *)
    echo "sync-workflow-routing: unknown option: $1" >&2
    usage >&2
    exit 2
    ;;
esac

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOWS_DIR="${PROJECT_ROOT}/.codex/workflows"
ROUTING_FILE="${PROJECT_ROOT}/.codex/rules/workflow-routing.md"
START_MARKER="<!-- workflow-routing:generated:start -->"
END_MARKER="<!-- workflow-routing:generated:end -->"

if [ ! -f "$ROUTING_FILE" ]; then
  echo "sync-workflow-routing: routing file not found: $ROUTING_FILE" >&2
  exit 1
fi

if [ "$(grep -cF "$START_MARKER" "$ROUTING_FILE")" -ne 1 ] || [ "$(grep -cF "$END_MARKER" "$ROUTING_FILE")" -ne 1 ]; then
  echo "sync-workflow-routing: routing file must contain exactly one generated marker pair" >&2
  exit 1
fi

read_scalar() {
  local file="$1"
  local key="$2"
  local value
  value="$(awk -v key="$key" '
    index($0, key ":") == 1 {
      value = substr($0, length(key) + 2)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      print value
      exit
    }
  ' "$file")"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  printf '%s' "$value"
}

require_scalar() {
  local file="$1"
  local key="$2"
  local value
  value="$(read_scalar "$file" "$key")"
  if [ -z "$value" ]; then
    echo "sync-workflow-routing: missing ${key} in ${file}" >&2
    exit 1
  fi
  if [[ "$value" == *"|"* ]] || [[ "$value" == *$'\n'* ]]; then
    echo "sync-workflow-routing: ${key} in ${file} cannot contain a Markdown table separator" >&2
    exit 1
  fi
  printf '%s' "$value"
}

render_generated_block() {
  printf '%s\n' "$START_MARKER"
  printf '%s\n' '| Workflow ID | Required | When To Use | Positive Triggers | Excludes | Definition | State File Pattern |'
  printf '%s\n' '| --- | --- | --- | --- | --- | --- | --- |'

  if [ -d "$WORKFLOWS_DIR" ]; then
    find "$WORKFLOWS_DIR" -mindepth 2 -maxdepth 2 -name routing.yaml -type f -print | sort | while IFS= read -r metadata; do
      workflow_dir="$(dirname "$metadata")"
      directory_id="$(basename "$workflow_dir")"
      workflow_id="$(require_scalar "$metadata" workflow_id)"
      required="$(require_scalar "$metadata" required)"
      when_to_use="$(require_scalar "$metadata" when_to_use)"
      triggers="$(require_scalar "$metadata" triggers)"
      excludes="$(require_scalar "$metadata" excludes)"
      state_file_pattern="$(require_scalar "$metadata" state_file_pattern)"

      if [ "$workflow_id" != "$directory_id" ]; then
        echo "sync-workflow-routing: workflow_id ${workflow_id} does not match directory ${directory_id}" >&2
        exit 1
      fi
      if [ "$required" != "true" ] && [ "$required" != "false" ]; then
        echo "sync-workflow-routing: required in ${metadata} must be true or false" >&2
        exit 1
      fi
      if [ ! -f "${workflow_dir}/workflow.md" ] || [ ! -f "${workflow_dir}/state-template.md" ]; then
        echo "sync-workflow-routing: ${workflow_dir} must contain workflow.md and state-template.md" >&2
        exit 1
      fi

      required_label="no"
      if [ "$required" = "true" ]; then
        required_label="yes"
      fi
      printf '| `%s` | %s | %s | %s | %s | `.codex/workflows/%s/workflow.md` | `%s` |\n' \
        "$workflow_id" "$required_label" "$when_to_use" "$triggers" "$excludes" "$workflow_id" "$state_file_pattern"
    done
  fi

  printf '%s\n' "$END_MARKER"
}

EXPECTED_BLOCK="$(render_generated_block)"
ACTUAL_BLOCK="$(sed -n "/^${START_MARKER}$/,/^${END_MARKER}$/p" "$ROUTING_FILE")"

if [ "$EXPECTED_BLOCK" = "$ACTUAL_BLOCK" ]; then
  echo "workflow routing is up to date"
  exit 0
fi

if [ "$MODE" = "check" ]; then
  echo "workflow routing is stale; run .codex/scripts/sync-workflow-routing.sh" >&2
  exit 1
fi

GENERATED_BLOCK="$EXPECTED_BLOCK" awk -v start="$START_MARKER" -v end="$END_MARKER" '
  BEGIN {
    generated = ENVIRON["GENERATED_BLOCK"] "\n"
  }
  $0 == start {
    printf "%s", generated
    in_generated = 1
    next
  }
  $0 == end && in_generated {
    in_generated = 0
    next
  }
  !in_generated { print }
' "$ROUTING_FILE" > "${ROUTING_FILE}.tmp"

mv "${ROUTING_FILE}.tmp" "$ROUTING_FILE"
echo "updated: ${ROUTING_FILE}"
