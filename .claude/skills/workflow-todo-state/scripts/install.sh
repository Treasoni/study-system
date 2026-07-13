#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  install.sh <target-project> [--with-skill] [--init-layout] [--update-agents] [--force]

Options:
  --with-skill      Copy the whole workflow-todo-state skill into the target project.
  --init-layout     Create .claude/workflows, workspace/workflow-runs, and workflow-routing.md.
  --update-agents   Add an idempotent Workflow Todo State block to AGENTS.md.
  --force           Replace existing installed files by moving them to timestamped backups.

Examples:
  .claude/skills/workflow-todo-state/scripts/install.sh ../other-project
  .claude/skills/workflow-todo-state/scripts/install.sh ../other-project --with-skill --init-layout --update-agents
USAGE
}

if [ "$#" -lt 1 ]; then
  usage
  exit 2
fi

TARGET_PROJECT="$1"
shift

WITH_SKILL=false
INIT_LAYOUT=false
UPDATE_AGENTS=false
FORCE=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --with-skill) WITH_SKILL=true ;;
    --init-layout) INIT_LAYOUT=true ;;
    --update-agents) UPDATE_AGENTS=true ;;
    --force) FORCE=true ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "install: unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

if [ ! -d "$TARGET_PROJECT" ]; then
  echo "install: target project does not exist: $TARGET_PROJECT" >&2
  exit 1
fi

TARGET_PROJECT="$(cd "$TARGET_PROJECT" && pwd)"

backup_existing_file() {
  local path="$1"
  local source="$2"
  if [ -e "$path" ]; then
    if [ -f "$path" ] && cmp -s "$source" "$path"; then
      echo "skipped: unchanged ${path}"
      return 2
    fi
    if [ "$FORCE" != true ]; then
      echo "install: already exists, use --force to replace: $path" >&2
      exit 1
    fi
    mv "$path" "${path}.bak.${STAMP}"
  fi
  return 0
}

backup_existing_path() {
  local path="$1"
  local source="${2:-}"
  if [ -e "$path" ]; then
    if [ -n "$source" ] && [ -d "$path" ] && [ -d "$source" ] && diff -qr "$source" "$path" >/dev/null 2>&1; then
      echo "skipped: unchanged ${path}"
      return 2
    fi
    if [ "$FORCE" != true ]; then
      echo "install: already exists, use --force to replace: $path" >&2
      exit 1
    fi
    mv "$path" "${path}.bak.${STAMP}"
  fi
  return 0
}

install_state_script() {
  local target_dir="${TARGET_PROJECT}/.claude/scripts"
  local target_script="${target_dir}/todo-state.sh"

  mkdir -p "$target_dir"
  if ! backup_existing_file "$target_script" "${SCRIPT_DIR}/todo-state.sh"; then
    return
  fi
  cp "${SCRIPT_DIR}/todo-state.sh" "$target_script"
  chmod +x "$target_script"
  echo "installed: ${target_script}"
}

install_routing_sync_script() {
  local target_dir="${TARGET_PROJECT}/.claude/scripts"
  local target_script="${target_dir}/sync-workflow-routing.sh"

  mkdir -p "$target_dir"
  if ! backup_existing_file "$target_script" "${SCRIPT_DIR}/../../../scripts/sync-workflow-routing.sh"; then
    return
  fi
  cp "${SCRIPT_DIR}/../../../scripts/sync-workflow-routing.sh" "$target_script"
  chmod +x "$target_script"
  echo "installed: ${target_script}"
}

install_skill() {
  local target_skills="${TARGET_PROJECT}/.claude/skills"
  local target_skill="${target_skills}/workflow-todo-state"

  mkdir -p "$target_skills"
  if ! backup_existing_path "$target_skill" "$SKILL_DIR"; then
    return
  fi
  cp -R "$SKILL_DIR" "$target_skill"
  chmod +x "${target_skill}/scripts/todo-state.sh" "${target_skill}/scripts/install.sh"
  echo "installed: ${target_skill}"
}

init_layout() {
  local workflows_dir="${TARGET_PROJECT}/.claude/workflows"
  local rules_dir="${TARGET_PROJECT}/.claude/rules"
  local runs_dir="${TARGET_PROJECT}/workspace/workflow-runs"
  local routing_file="${rules_dir}/workflow-routing.md"
  local routing_template="${SKILL_DIR}/references/workflow-routing-template.md"

  mkdir -p "$workflows_dir" "$rules_dir" "$runs_dir"

  if ! backup_existing_file "$routing_file" "$routing_template"; then
    echo "initialized: ${workflows_dir}"
    echo "initialized: ${runs_dir}"
    return
  fi

  cp "$routing_template" "$routing_file"
  echo "initialized: ${workflows_dir}"
  echo "initialized: ${runs_dir}"
  echo "installed: ${routing_file}"
}

workflow_agents_block() {
  cat <<'AGENTS_BLOCK'
<!-- workflow-todo-state:start -->
## Workflow Todo State

Named workflow state files are the source of truth for every routed workflow.

- Workflow definitions live under `.claude/workflows/{workflow-id}/`.
- Workflow state files live under `workspace/workflow-runs/` and should be named after the task, for example `payment-refactor.workflow.md`.
- Before any action that changes project files, runs project commands, or calls external services, read `.claude/rules/workflow-routing.md` and match the user's original request against its triggers and exclusions.
- When a `Required: yes` workflow matches, read its `workflow.md`, create or resume its state file, and start the current phase before doing the work. Do not take the ordinary execution path instead.
- If the route is ambiguous, ask the user before acting.
- Read the active workflow state file before starting any phase; do not skip prerequisite phases.
- Change phase state only through `.claude/scripts/todo-state.sh`.
- Use one unique phase status line per phase, for example `> [P0] ⬜ 未开始`.
- On resume after interruption, inspect the YAML frontmatter and current phase before acting.
- Each workflow directory must contain a `routing.yaml`. After creating, changing, renaming, or deleting a workflow, run `.claude/scripts/sync-workflow-routing.sh`; the update is incomplete until `.claude/scripts/sync-workflow-routing.sh --check` passes.
<!-- workflow-todo-state:end -->
AGENTS_BLOCK
}

update_agents() {
  local agents_file="${TARGET_PROJECT}/AGENTS.md"
  local start_marker="<!-- workflow-todo-state:start -->"
  local end_marker="<!-- workflow-todo-state:end -->"

  if [ ! -f "$agents_file" ]; then
    printf '# Project Instructions\n' > "$agents_file"
  fi

  local block
  block="$(workflow_agents_block)"

  if grep -qF "$start_marker" "$agents_file"; then
    if ! grep -qF "$end_marker" "$agents_file"; then
      echo "install: workflow-todo-state block has no end marker: $agents_file" >&2
      exit 1
    fi
    BLOCK="$block" START_MARKER="$start_marker" END_MARKER="$end_marker" perl -0pi -e '
      my $start = quotemeta($ENV{START_MARKER});
      my $end = quotemeta($ENV{END_MARKER});
      my $block = $ENV{BLOCK};
      my $count = s/$start.*?$end/$block/s;
      die "install: could not replace workflow-todo-state block\n" unless $count == 1;
    ' "$agents_file"
    echo "updated: ${agents_file}"
    return
  fi

  printf '\n%s\n' "$block" >> "$agents_file"

  echo "updated: ${agents_file}"
}

install_state_script
install_routing_sync_script

if [ "$WITH_SKILL" = true ]; then
  install_skill
fi

if [ "$INIT_LAYOUT" = true ]; then
  init_layout
fi

if [ "$UPDATE_AGENTS" = true ]; then
  update_agents
fi

cat <<EOF

Done.

Next:
  1. Create a workflow definition under .claude/workflows/{workflow-id}/.
  2. Add routing metadata at .claude/workflows/{workflow-id}/routing.yaml.
  3. Run .claude/scripts/sync-workflow-routing.sh.
  4. Create a named state file under workspace/workflow-runs/{task}.workflow.md.
  5. Test: .claude/scripts/todo-state.sh workspace/workflow-runs/{task}.workflow.md start P0
EOF
