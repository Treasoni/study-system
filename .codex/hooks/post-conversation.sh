#!/bin/bash
# Project-local Codex Stop hook for Study System.
# Default behavior is read-only status reporting. Set CODEX_AUTO_GIT=1 to commit.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$PROJECT_ROOT"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed_files="$(git status --short)"
if [ -z "$changed_files" ]; then
  echo "Study System: no project changes."
  exit 0
fi

echo "Study System: project changes detected:"
echo "$changed_files"

if [ "${CODEX_AUTO_GIT:-0}" != "1" ]; then
  echo "Auto commit disabled. Set CODEX_AUTO_GIT=1 to enable project-local auto commit."
  exit 0
fi

git add -A

if git diff --cached --quiet; then
  echo "No staged changes after git add."
  exit 0
fi

".codex/scripts/git-autocommit.sh"

if [ "${CODEX_AUTO_GIT_PUSH:-0}" = "1" ]; then
  current_branch="$(git branch --show-current)"
  if [ -n "$current_branch" ]; then
    git push origin "$current_branch"
  fi
fi
