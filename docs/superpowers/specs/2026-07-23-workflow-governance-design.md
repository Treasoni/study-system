# Workflow Governance and Validation Design

## Goal

Make Study System's workflow rules enforceable by code, and make every
repository change verifiable locally and in GitHub Actions.

## Scope

This design implements every improvement identified in the 2026-07-23 project
audit:

1. Enforce phase confirmation, permitted skips, and learning-note mode changes.
2. Add dependency-cycle validation to the manifest registry.
3. Add dependency-free regression tests and one local test entry point.
4. Add GitHub Actions validation for pushes and pull requests.
5. Reduce `.env.example` to real runtime configuration and move optional
   configuration to a separate example file.
6. Make automatic commits secret-safe and remove automatic pushes.
7. Make the Codex-to-Claude mirror deterministic and checkable without
   requiring `rsync`.

## Non-goals

- This does not introduce a general workflow engine, a database, or a package
  manager.
- This does not alter the content-production phases themselves or add a fourth
  workflow.
- This does not rewrite Git history or change remote repository settings.

## State-machine contract

Every generated workflow state file will declare the following frontmatter
fields:

- `confirmed_phases`: a comma-separated list of completed phases approved by
  the user.
- `skippable_phases`: phases that may be skipped after they are started.
- `mode_dependent_skips`: phases that may only be skipped when the state file
  has `mode: freeform`.
- `allowed_modes` and `mode_change_phase`: present only for workflows with a
  user-selectable mode.

`todo-state.sh` will expose six operations:

```text
start <phase>
confirm <phase> <reason>
complete <phase>
skip <phase> <reason>
block <phase> <reason>
mode <phase> <mode> <reason>
```

The script will reject a completion that lacks a confirmation, a skip of an
unlisted or unstarted phase, a skip without a reason, and a mode change outside
the configured phase or mode list. A confirmation and every skip will be added
to visible audit tables as well as frontmatter.

The learning-note flow may select `freeform` at P2. Only in that mode may P3
and P4 be skipped. P7 remains independently skippable because MOC publication
is optional. Batch updates permit P3 to be skipped, while legacy imports permit
P4 to be skipped. All other phases are mandatory.

## Validation architecture

The repository will have a `tests/run.sh` entry point that invokes shell and
Python standard-library tests. Tests will create isolated temporary fixtures;
they will not edit workflow runs or user notes.

The test suite will cover the state-machine rejection and success paths,
manifest dependency cycles, and mirror `--check` behavior. It will be the
single source invoked by GitHub Actions.

The existing health check remains the structural integration check. The test
entry point will also run strict environment-template validation, routing
freshness validation, manifest validation, and the scoped secret audit.

## Environment configuration

`.env.example` will contain only variables that project scripts actually read.
`.env.optional.example` will document optional paths and provider settings;
copying values from it into an untracked `.env` remains an explicit user
choice. Strict validation must pass after the split.

## Secure lifecycle hook

The Stop hook continues to report changes by default. When an explicit
`CODEX_AUTO_GIT=1` opt-in requests an automatic commit, it must scan both the
working tree and the staged content before committing. Any finding stops the
commit and leaves the index available for human review. Automatic push support
is removed; pushing remains a deliberate manual action.

## Deterministic compatibility mirror

A Python standard-library synchronizer will replace the `rsync`-dependent
implementation. It will copy each managed `.codex` directory into `.claude`,
preserve the documented Claude-only exclusions, remove stale managed files, and
apply the existing namespace substitutions only to copied text files.

`--check` will construct the expected mirror in a temporary directory and
report differences without changing `.claude`. The regular sync command will
apply that exact same reconciliation.

## Manifest validation

The registry will build a directed graph from `dependsOn` and report every
cycle with the participating artifact IDs. Existing checks for unknown
dependencies remain unchanged. The modified workflow-state, manifest-platform,
workflow, and hook manifests will receive SemVer minor-version increments.

## Continuous integration

`.github/workflows/validate.yml` will run on pushes and pull requests. It will
set up Python, execute `tests/run.sh`, and therefore enforce the same checks
that contributors can run locally. The workflow uses no package installation
or third-party action beyond checkout and Python setup.

## Acceptance criteria

- P0 cannot be skipped, and P0 cannot be completed without a recorded user
  confirmation.
- Freeform mode can be chosen only at learning-note P2 and authorizes only P3
  and P4 skips.
- Each configured optional phase can be skipped only after it is started and
  with a non-empty reason.
- Manifest cycles fail validation with a useful error.
- `tests/run.sh`, strict environment validation, workflow health validation,
  mirror `--check`, and secret audit pass on the final repository.
- The Stop hook never automatically pushes and never automatically commits
  potential credentials.
