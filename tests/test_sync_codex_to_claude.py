from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class CodexClaudeSyncTests(unittest.TestCase):
    def test_bash_wrapper_is_executable(self) -> None:
        result = subprocess.run(
            [str(ROOT / ".codex" / "scripts" / "sync-codex-to-claude.sh"), "--check"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_check_reports_and_reconciles_stale_managed_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            shutil.copytree(ROOT / ".codex", project / ".codex")
            stale_file = project / ".claude" / "skills" / "obsolete" / "SKILL.md"
            stale_file.parent.mkdir(parents=True)
            stale_file.write_text("# stale\n", encoding="utf-8")

            sync_script = project / ".codex" / "scripts" / "sync-codex-to-claude.py"
            check_before = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(check_before.returncode, 0)
            self.assertIn("skills/obsolete/SKILL.md", check_before.stdout)

            apply_result = subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(apply_result.returncode, 0, apply_result.stderr)
            self.assertFalse(stale_file.exists())

            check_after = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(check_after.returncode, 0, check_after.stdout)

    def test_check_preserves_claude_only_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            shutil.copytree(ROOT / ".codex", project / ".codex")
            sync_script = project / ".codex" / "scripts" / "sync-codex-to-claude.py"
            subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=True,
            )
            target = project / "claude-only-skill"
            target.mkdir()
            (target / "SKILL.md").write_text("# Claude-only skill\n", encoding="utf-8")
            link = project / ".claude" / "skills" / "skill-creator"
            link.parent.mkdir(parents=True, exist_ok=True)
            link.symlink_to(target)

            result = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout)

    def test_check_ignores_macos_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            shutil.copytree(ROOT / ".codex", project / ".codex")
            sync_script = project / ".codex" / "scripts" / "sync-codex-to-claude.py"
            subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=True,
            )
            metadata_file = project / ".claude" / "rules" / ".DS_Store"
            metadata_file.write_bytes(b"macOS metadata")

            result = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertEqual(result.returncode, 0, result.stdout)

    def test_check_does_not_follow_managed_destination_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            shutil.copytree(ROOT / ".codex", project / ".codex")
            sync_script = project / ".codex" / "scripts" / "sync-codex-to-claude.py"
            subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=True,
            )

            external_target = project / "external-skill"
            external_target.mkdir()
            external_file = external_target / "SKILL.md"
            external_file.write_text("# external content\n", encoding="utf-8")
            managed_directory = project / ".claude" / "skills" / "digest"
            shutil.rmtree(managed_directory)
            managed_directory.symlink_to(external_target, target_is_directory=True)

            check_result = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(check_result.returncode, 0)
            self.assertEqual(external_file.read_text(encoding="utf-8"), "# external content\n")

            apply_result = subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(apply_result.returncode, 0, apply_result.stderr)
            self.assertFalse(managed_directory.is_symlink())
            self.assertEqual(external_file.read_text(encoding="utf-8"), "# external content\n")

            external_skills = project / "external-skills"
            external_skills.mkdir()
            external_skills_file = external_skills / "sentinel.txt"
            external_skills_file.write_text("keep this file\n", encoding="utf-8")
            managed_root = project / ".claude" / "skills"
            shutil.rmtree(managed_root)
            managed_root.symlink_to(external_skills, target_is_directory=True)

            managed_root_check = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(managed_root_check.returncode, 0)
            self.assertEqual(external_skills_file.read_text(encoding="utf-8"), "keep this file\n")
            subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=True,
            )
            self.assertFalse(managed_root.is_symlink())
            self.assertEqual(external_skills_file.read_text(encoding="utf-8"), "keep this file\n")

            external_mirror = project / "external-mirror"
            claude_root = project / ".claude"
            claude_root.rename(external_mirror)
            root_sentinel = external_mirror / "sentinel.txt"
            root_sentinel.write_text("keep root untouched\n", encoding="utf-8")
            claude_root.symlink_to(external_mirror, target_is_directory=True)

            root_check = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(root_check.returncode, 0)
            self.assertEqual(root_sentinel.read_text(encoding="utf-8"), "keep root untouched\n")
            subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=True,
            )
            self.assertFalse(claude_root.is_symlink())
            self.assertEqual(root_sentinel.read_text(encoding="utf-8"), "keep root untouched\n")

    def test_claude_wrapper_checks_canonical_codex_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            shutil.copytree(ROOT / ".codex", project / ".codex")
            sync_script = project / ".codex" / "scripts" / "sync-codex-to-claude.py"
            subprocess.run(
                [sys.executable, str(sync_script)],
                cwd=project,
                text=True,
                capture_output=True,
                check=True,
            )
            codex_file = project / ".codex" / "scripts" / "todo-state.sh"
            codex_file.write_text(
                codex_file.read_text(encoding="utf-8") + "\n# mirror drift\n",
                encoding="utf-8",
            )

            result = subprocess.run(
                [str(project / ".claude" / "scripts" / "sync-codex-to-claude.sh"), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("scripts/todo-state.sh", result.stdout)

    def test_rejects_symlinked_codex_source(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            shutil.copytree(ROOT / ".codex", project / ".codex")
            external_file = project / "external-source.md"
            external_file.write_text("# external source\n", encoding="utf-8")
            source_file = project / ".codex" / "skills" / "digest" / "SKILL.md"
            source_file.unlink()
            source_file.symlink_to(external_file)
            sync_script = project / ".codex" / "scripts" / "sync-codex-to-claude.py"

            result = subprocess.run(
                [sys.executable, str(sync_script), "--check"],
                cwd=project,
                text=True,
                capture_output=True,
                check=False,
            )
            external_content = external_file.read_text(encoding="utf-8")

        self.assertEqual(result.returncode, 2)
        self.assertIn("refusing symlinked source path", result.stderr)
        self.assertEqual(external_content, "# external source\n")


if __name__ == "__main__":
    unittest.main()
