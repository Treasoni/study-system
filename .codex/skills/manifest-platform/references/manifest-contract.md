# Manifest Contract

Every artifact uses `apiVersion: agents.study-system/v1` and one of four kinds: `Workflow`, `Skill`, `Subagent`, or `Hook`.

```yaml
apiVersion: agents.study-system/v1
kind: Skill
metadata:
  name: example
  version: 1.0.0
  description: "Short human-readable purpose"
spec:
  entrypoint: SKILL.md
  capabilities:
    - example.execute
  permissions:
    filesystem: read
    network: none
    subprocess: none
    git: none
  dependsOn: []
  lifecycle:
    discoverable: true
    deprecated: false
```

`entrypoint` is resolved relative to the manifest’s directory and must remain inside `.codex/`. `dependsOn` uses exact artifact IDs such as `Skill/research-collector`. A Hook additionally declares `event: Stop` or `event: SessionStart`; it must still be registered in `.codex/hooks.json`.

Permission values are intentionally coarse: `filesystem` is `none`, `read`, or `write`; `network` and `subprocess` are `none` or `allow`; `git` is `none`, `read`, or `write`. Choose the maximum privilege that the artifact can actually request, then enforce a runtime policy that may narrow it further.
