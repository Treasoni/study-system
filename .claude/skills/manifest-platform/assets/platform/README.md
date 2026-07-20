# Agent Platform Registry

`manifest.yaml` is the contract for every Workflow, Skill, Subagent and Hook. The registry discovers manifests from the four configured `.claude/` directories, validates their version, dependencies and requested permissions, and checks that each Hook is registered in `.claude/hooks.json`.

The registry is declarative: permissions are requests that a runtime policy must enforce; this validator does not grant tools or bypass Claude Code approvals.

## Commands

```bash
python3 .claude/platform/manifest-registry.py --root . validate
python3 .claude/platform/manifest-registry.py --root . list
python3 .claude/platform/manifest-registry.py --root . init \
  --kind Skill --name example --entrypoint SKILL.md \
  --description "Describe the new artifact"
```

Keep an artifact's `manifest.yaml` in `.claude/{skills,workflows,agents,hooks}/{name}/`. During migration, an agent or hook manifest may use a relative entrypoint such as `../outline-generator.md`; entrypoints may never leave `.claude/`.

The validator also fails if a conventional `SKILL.md`, `workflow.md`, flat agent `.md`, or flat hook `.sh` has no matching manifest. Bump `metadata.version` using SemVer: MAJOR for an incompatible contract, MINOR for compatible capabilities or dependencies, and PATCH for metadata-only corrections.

The supported YAML subset deliberately uses mappings, block lists, quoted strings, booleans, and empty `[]`/`{}` values. This keeps the validator dependency-free. Use the JSON Schema for editor completion or a fuller YAML toolchain.
