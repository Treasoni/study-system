#!/usr/bin/env python3
"""Regression test for portable shared agent configuration."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".agent-sync"))

from validate_portability import validate_tree  # noqa: E402


class PortabilityTests(unittest.TestCase):
    def test_shared_agent_files_are_portable_to_every_target(self) -> None:
        for platform in ("windows", "macos", "linux"):
            self.assertEqual([], validate_tree(ROOT, platform), platform)


if __name__ == "__main__":
    unittest.main()
