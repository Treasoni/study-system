#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install.sh --target <project-directory> [--force] [--validate]

Install the Agent Platform registry into <project-directory>/.codex/platform.
Existing differing registry files are preserved unless --force is supplied.
USAGE
}

TARGET=""
FORCE=0
VALIDATE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --validate) VALIDATE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "--target is required" >&2
  usage >&2
  exit 2
fi

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../assets/platform" && pwd)"
TARGET_ROOT="$(cd "$TARGET" && pwd)"
TARGET_DIR="$TARGET_ROOT/.codex/platform"
mkdir -p "$TARGET_DIR"
for file in manifest-registry.py manifest.schema.json registry.yaml README.md; do
  source_file="$SOURCE_DIR/$file"
  target_file="$TARGET_DIR/$file"
  if [ -f "$target_file" ] && ! cmp -s "$source_file" "$target_file" && [ "$FORCE" -ne 1 ]; then
    echo "Refusing to overwrite $target_file; rerun with --force after reviewing it." >&2
    exit 1
  fi
  cp "$source_file" "$target_file"
done
chmod +x "$TARGET_DIR/manifest-registry.py"
echo "Installed Agent Platform registry at ${TARGET_DIR#$TARGET_ROOT/}."
if [ "$VALIDATE" -eq 1 ]; then
  python3 "$TARGET_DIR/manifest-registry.py" --root "$TARGET_ROOT" validate
fi
