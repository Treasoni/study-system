from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / ".codex" / "platform" / "manifest-registry.py"
REGISTRY_CONFIG = ROOT / ".codex" / "platform" / "registry.yaml"


def manifest(name: str, dependency: str) -> str:
    return f'''apiVersion: agents.study-system/v1
kind: Skill
metadata:
  name: {name}
  version: 1.0.0
  description: "Fixture skill {name}."
spec:
  entrypoint: SKILL.md
  capabilities:
    - fixture.{name}
  permissions:
    filesystem: read
    network: none
    subprocess: none
    git: none
  dependsOn:
    - {dependency}
  lifecycle:
    discoverable: true
    deprecated: false
'''


class ManifestRegistryTests(unittest.TestCase):
    def test_rejects_dependency_cycle(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            project = Path(temporary_dir)
            platform = project / ".codex" / "platform"
            platform.mkdir(parents=True)
            shutil.copy2(REGISTRY_CONFIG, platform / "registry.yaml")

            for name, dependency in (("alpha", "Skill/beta"), ("beta", "Skill/alpha")):
                skill = project / ".codex" / "skills" / name
                skill.mkdir(parents=True)
                (skill / "SKILL.md").write_text(f"# {name}\n", encoding="utf-8")
                (skill / "manifest.yaml").write_text(manifest(name, dependency), encoding="utf-8")

            result = subprocess.run(
                [sys.executable, str(REGISTRY), "--root", str(project), "validate"],
                text=True,
                capture_output=True,
                check=False,
            )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("dependency cycle", result.stderr)
        self.assertIn("Skill/alpha", result.stderr)
        self.assertIn("Skill/beta", result.stderr)


if __name__ == "__main__":
    unittest.main()
