#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$BASH_SOURCE")/.." && pwd)"
TEST_ROOT="$(mktemp -d /private/tmp/study-system-hook-test.XXXXXX)"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

prepare_project() {
  local project="$1"
  mkdir -p "$project/.codex/hooks" "$project/.codex/scripts" "$project/.codex/skills/security-secret-audit/scripts"
  cp "$ROOT/.codex/hooks/post-conversation.sh" "$project/.codex/hooks/"
  cp "$ROOT/.codex/scripts/git-autocommit.sh" "$project/.codex/scripts/"
  cp "$ROOT/.codex/skills/security-secret-audit/scripts/audit-secrets.sh" "$project/.codex/skills/security-secret-audit/scripts/"
  cp "$ROOT/.codex/skills/security-secret-audit/scripts/detect-secrets.pl" "$project/.codex/skills/security-secret-audit/scripts/"

  git -C "$project" init -q
  git -C "$project" config user.name "Hook Test"
  git -C "$project" config user.email "hook-test@example.invalid"
  printf '# fixture\n' > "$project/README.md"
  git -C "$project" add README.md
  git -C "$project" commit -qm "test: initial fixture"
}

secret_project="$TEST_ROOT/secret"
prepare_project "$secret_project"
secret_prefix="sk-"
secret_tail="abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz"
printf 'OPENAI_API_KEY=%s%s\n' "$secret_prefix" "$secret_tail" > "$secret_project/credentials.env"
before_count="$(git -C "$secret_project" rev-list --count HEAD)"
set +e
CODEX_AUTO_GIT=1 bash "$secret_project/.codex/hooks/post-conversation.sh" > "$secret_project/hook.log" 2>&1
hook_status=$?
set -e
after_count="$(git -C "$secret_project" rev-list --count HEAD)"
[ "$after_count" = "$before_count" ] || fail "hook committed a potential credential"
[ "$hook_status" -ne 0 ] || fail "hook reported success after a potential credential"
rg -q 'Potential credentials found' "$secret_project/hook.log" || fail "hook did not report the redacted audit failure"

clean_project="$TEST_ROOT/clean"
prepare_project "$clean_project"
printf 'safe change\n' >> "$clean_project/README.md"
before_count="$(git -C "$clean_project" rev-list --count HEAD)"
CODEX_AUTO_GIT=1 bash "$clean_project/.codex/hooks/post-conversation.sh" > "$clean_project/hook.log" 2>&1
after_count="$(git -C "$clean_project" rev-list --count HEAD)"
[ "$after_count" -eq $((before_count + 1)) ] || fail "hook did not commit clean changes"

printf 'post-conversation hook tests passed.\n'
