---
name: manifest-platform
description: Install, migrate, and validate a unified manifest registry for Agent Platform Workflows, Skills, Subagents, and Hooks. Use when a project needs manifest.yaml-based discovery, artifact versioning, dependency checks, capability declarations, permission-policy review, or reusable agent-platform setup.
---

# Manifest Platform

Install the bundled registry before changing artifacts:

```bash
.claude/skills/manifest-platform/scripts/install.sh --target .
```

Read `assets/platform/README.md` when defining the manifest contract or using its commands.

## Workflow

1. Inspect the project’s existing `.claude/` layout and preserve unrelated changes.
2. Install the registry with `scripts/install.sh`; do not overwrite a divergent registry without reviewing it and receiving authority to use `--force`.
3. Add `manifest.yaml` for every existing Workflow, Skill, Subagent, and Hook. Keep the artifact name equal to its containing directory.
4. Declare the narrowest truthful permissions. A manifest requests permissions; it never grants them. Keep runtime enforcement in the host’s policy/tool gateway.
5. Add dependency IDs only after their target manifests exist. For a Hook, also retain the actual registration in `.claude/hooks.json`.
6. Run `python3 .claude/platform/manifest-registry.py --root . validate` and fix every failure before handoff.

## Reuse

Copy or install this Skill into another project’s `.claude/skills/`, then run its installer against that project. The installer supplies a dependency-free validator, JSON Schema, registry policy, and documentation; use `manifest-registry.py init` to create an initial manifest before refining its capabilities and permissions.

Do not treat the manifest as a sandbox. Integrate its requested permissions with the host’s approval and tool policy before relying on it for execution control.
