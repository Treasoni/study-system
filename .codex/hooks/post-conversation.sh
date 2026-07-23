#!/usr/bin/env bash
# Project-local Codex Stop hook for Study System.
# Default behavior reports project changes. CODEX_AUTO_GIT=1 enables a
# secret-audited automatic commit; pushing always remains a manual action.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$BASH_SOURCE")/../.." && pwd)"
cd "$PROJECT_ROOT"

LOG_FILE="/tmp/study-system-post-conversation.log"
SECRET_AUDIT=".codex/skills/security-secret-audit/scripts/audit-secrets.sh"

log() {
  local message="$1"
  local line
  line="[$(date '+%Y-%m-%d %H:%M:%S')] $message"
  echo "$line"
  echo "$line" >> "$LOG_FILE" 2>/dev/null || true
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed_files="$(git status --short)"
if [ -z "$changed_files" ]; then
  log "Study System: no project changes."
  exit 0
fi

log "Study System: project changes detected:"
echo "$changed_files"
echo "$changed_files" >> "$LOG_FILE" 2>/dev/null || true

if [ "$(printenv CODEX_AUTO_GIT 2>/dev/null || true)" != "1" ]; then
  log "Auto commit disabled because CODEX_AUTO_GIT is not 1."
  exit 0
fi

if ! "$SECRET_AUDIT"; then
  log "Automatic commit blocked by working-tree secret audit."
  exit 1
fi

log "Running git add -A."
git add -A

if git diff --cached --quiet; then
  log "No staged changes after git add."
  exit 0
fi

if ! "$SECRET_AUDIT" --staged; then
  log "Automatic commit blocked by staged secret audit."
  exit 1
fi

log "Creating automatic commit."
".codex/scripts/git-autocommit.sh"
log "Automatic commit complete. Push manually after review."
