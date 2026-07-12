#!/bin/bash
# Sync portable project configuration from .codex to .claude.
# This keeps Claude Code usable after Codex-side workflow updates.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

copy_dir() {
  local src="$1"
  local dst="$2"
  shift 2

  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude ".DS_Store" "$@" "$src/" "$dst/"
  else
    # Fallback keeps extra files instead of deleting them.
    cp -R "$src/." "$dst/"
  fi
}

copy_dir ".codex/skills" ".claude/skills" --exclude "skill-creator"
copy_dir ".codex/agents" ".claude/agents"
copy_dir ".codex/rules" ".claude/rules" --exclude "common/hooks.md" --exclude "common/sync-workflow.md"
copy_dir ".codex/scripts" ".claude/scripts" --exclude "sync-codex-to-claude.sh"
if [ -d ".codex/workflows" ]; then
  copy_dir ".codex/workflows" ".claude/workflows"
fi

# Claude Code should read/write the Claude namespace, not .codex paths.
find .claude/skills .claude/agents .claude/rules .claude/scripts .claude/workflows \
  -type f \( -name "*.md" -o -name "*.sh" \) \
  ! -path ".claude/rules/common/hooks.md" \
  ! -path ".claude/rules/common/sync-workflow.md" \
  -exec perl -pi -e 's/\.codex/\.claude/g; s/Codex/Claude Code/g' {} +

echo "Synced portable Codex config to Claude Code config."
