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


if __name__ == "__main__":
    unittest.main()
