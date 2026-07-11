#!/bin/bash
# Project-local Codex Stop hook for Study System.
# Default behavior is git add/commit. Set CODEX_AUTO_GIT=0 to disable.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

LOG_FILE="${TMPDIR:-/tmp}/study-system-post-conversation.log"
log() {
  local message="$1"
  local line
  line="[$(date '+%Y-%m-%d %H:%M:%S')] ${message}"
  echo "$line"
  printf '%s\n' "$line" >> "$LOG_FILE" 2>/dev/null || true
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed_files="$(git status --short)"
if [ -z "$changed_files" ]; then
  log "Study System: no project changes."
  exit 0
fi

log "Study System: project changes detected:"
printf '%s\n' "$changed_files"
printf '%s\n' "$changed_files" >> "$LOG_FILE" 2>/dev/null || true

if [ "${CODEX_AUTO_GIT:-1}" != "1" ]; then
  log "Auto commit disabled because CODEX_AUTO_GIT=${CODEX_AUTO_GIT:-0}."
  exit 0
fi

log "Running git add -A."
git add -A

if git diff --cached --quiet; then
  log "No staged changes after git add."
  exit 0
fi

log "Creating automatic commit."
".codex/scripts/git-autocommit.sh"
log "Automatic commit complete."

if [ "${CODEX_AUTO_GIT_PUSH:-0}" = "1" ]; then
  current_branch="$(git branch --show-current)"
  if [ -n "$current_branch" ]; then
    log "Pushing branch ${current_branch}."
    git push origin "$current_branch"
  fi
fi
