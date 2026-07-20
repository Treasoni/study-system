# Agent Platform Registry

`manifest.yaml` is the contract for every Workflow, Skill, Subagent and Hook. The registry discovers manifests from the four configured `.codex/` directories, validates their version, dependencies and requested permissions, and checks that each Hook is registered in `.codex/hooks.json`.

The registry is declarative: permissions are requests that a runtime policy must enforce; this validator does not grant tools or bypass Codex approvals.

## Commands

```bash
python3 .codex/platform/manifest-registry.py --root . validate
python3 .codex/platform/manifest-registry.py --root . list
python3 .codex/platform/manifest-registry.py --root . init \
  --kind Skill --name example --entrypoint SKILL.md \
  --description "Describe the new artifact"
```

Keep an artifact's `manifest.yaml` in `.codex/{skills,workflows,agents,hooks}/{name}/`. During migration, an agent or hook manifest may use a relative entrypoint such as `../outline-generator.md`; entrypoints may never leave `.codex/`.

The validator also fails if a conventional `SKILL.md`, `workflow.md`, flat agent `.md`, or flat hook `.sh` has no matching manifest. Bump `metadata.version` using SemVer: MAJOR for an incompatible contract, MINOR for compatible capabilities or dependencies, and PATCH for metadata-only corrections.

The supported YAML subset deliberately uses mappings, block lists, quoted strings, booleans, and empty `[]`/`{}` values. This keeps the validator dependency-free. Use the JSON Schema for editor completion or a fuller YAML toolchain.
