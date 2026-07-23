#!/usr/bin/env python3
"""Synchronize managed Codex configuration into the Claude compatibility mirror."""

from __future__ import annotations

import argparse
import os
import shutil
import tempfile
from pathlib import Path


MANAGED_DIRECTORIES = ("skills", "agents", "rules", "scripts", "platform", "workflows")
TEXT_SUFFIXES = {".md", ".sh", ".py", ".yaml"}
EXCLUSIONS = {
    "skills": {Path("skill-creator")},
    "rules": {Path("common/hooks.md"), Path("common/sync-workflow.md")},
    "scripts": {Path("sync-codex-to-claude.sh")},
    "agents": set(),
    "platform": set(),
    "workflows": set(),
}


def remove_path(path: Path) -> None:
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


def is_excluded(relative_path: Path, exclusions: set[Path]) -> bool:
    return any(relative_path == excluded or excluded in relative_path.parents for excluded in exclusions)


def transform_text(path: Path) -> None:
    if path.suffix not in TEXT_SUFFIXES:
        return
    try:
        original = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return
    transformed = original.replace(".codex", ".claude").replace("Codex", "Claude Code")
    if transformed != original:
        path.write_text(transformed, encoding="utf-8")


def reconcile(source: Path, destination: Path, exclusions: set[Path]) -> None:
    if not source.is_dir():
        return

    desired_paths: set[Path] = set()
    for source_path in sorted(source.rglob("*")):
        relative_path = source_path.relative_to(source)
        if is_excluded(relative_path, exclusions):
            continue
        desired_paths.add(relative_path)
        destination_path = destination / relative_path
        if source_path.is_dir():
            if destination_path.exists() and not destination_path.is_dir():
                remove_path(destination_path)
            destination_path.mkdir(parents=True, exist_ok=True)
            continue

        destination_path.parent.mkdir(parents=True, exist_ok=True)
        if destination_path.is_dir():
            remove_path(destination_path)
        shutil.copy2(source_path, destination_path)
        transform_text(destination_path)

    if not destination.exists():
        return
    for destination_path in sorted(destination.rglob("*"), key=lambda path: len(path.parts), reverse=True):
        relative_path = destination_path.relative_to(destination)
        if is_excluded(relative_path, exclusions) or relative_path in desired_paths:
            continue
        if destination_path.is_dir() and any(destination_path.iterdir()):
            continue
        remove_path(destination_path)


def apply_sync(root: Path) -> None:
    codex_root = root / ".codex"
    claude_root = root / ".claude"
    claude_root.mkdir(parents=True, exist_ok=True)
    for directory in MANAGED_DIRECTORIES:
        reconcile(codex_root / directory, claude_root / directory, EXCLUSIONS[directory])


def expected_mirror(root: Path, temporary_root: Path) -> Path:
    expected_root = temporary_root / ".claude"
    actual_root = root / ".claude"
    if actual_root.exists():
        shutil.copytree(actual_root, expected_root, symlinks=True)
    else:
        expected_root.mkdir(parents=True)

    codex_root = root / ".codex"
    for directory in MANAGED_DIRECTORIES:
        reconcile(codex_root / directory, expected_root / directory, EXCLUSIONS[directory])
    return expected_root


def tree_entries(root: Path) -> dict[Path, tuple[str, bytes | str | None]]:
    entries: dict[Path, tuple[str, bytes | str | None]] = {}
    if not root.exists():
        return entries
    for path in sorted(root.rglob("*")):
        relative_path = path.relative_to(root)
        if path.is_symlink():
            entries[relative_path] = ("symlink", os.readlink(path))
        elif path.is_dir():
            entries[relative_path] = ("directory", None)
        else:
            entries[relative_path] = ("file", path.read_bytes())
    return entries


def differing_paths(expected: Path, actual: Path) -> list[str]:
    expected_entries = tree_entries(expected)
    actual_entries = tree_entries(actual)
    differences: list[str] = []
    for path in sorted(set(expected_entries) | set(actual_entries)):
        expected_entry = expected_entries.get(path)
        actual_entry = actual_entries.get(path)
        if expected_entry is None:
            differences.append(f"unexpected: {path.as_posix()}")
        elif actual_entry is None:
            differences.append(f"missing: {path.as_posix()}")
        elif expected_entry != actual_entry:
            differences.append(f"different: {path.as_posix()}")
    return differences


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Report mirror drift without writing files.")
    parser.add_argument("--root", default=".", help="Project root containing .codex (default: current directory).")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    if not (root / ".codex").is_dir():
        print(f"sync-codex-to-claude: expected .codex under {root}", file=os.sys.stderr)
        return 2

    if not args.check:
        apply_sync(root)
        print("Synced portable Codex config to Claude Code config.")
        return 0

    with tempfile.TemporaryDirectory(prefix="study-system-claude-check.") as temporary_dir:
        expected = expected_mirror(root, Path(temporary_dir))
        differences = differing_paths(expected, root / ".claude")
    if differences:
        print("Claude compatibility mirror is stale:")
        for difference in differences:
            print(f"  - {difference}")
        return 1

    print("Claude compatibility mirror is up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
