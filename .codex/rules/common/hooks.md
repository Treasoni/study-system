# Codex Hooks 规范（项目本地）

本项目只使用项目内 `.codex/hooks.json` 和 `.codex/hooks/`。不要把本项目 hooks 写入全局 `~/.codex/config.toml`。

## 配置位置

| 文件 | 作用域 | 提交 git |
|------|--------|----------|
| `.codex/hooks.json` | 本项目 hooks 注册表 | ✅ |
| `.codex/hooks/*.sh` | 本项目 hook 脚本 | ✅ |
| `.codex/hooks/{name}/manifest.yaml` | Hook 入口、版本、能力和请求权限契约 | ✅ |
| `~/.codex/config.toml` | 全局 Codex 状态/信任记录 | ❌ 不由本项目维护 |

## 事件速查

| 事件 | 时机 | 可阻止 |
|------|------|--------|
| `SessionStart` | 会话开始 | 通常用于读取项目记忆 |
| `Stop` | Codex 停止响应/会话收尾 | 通常用于状态整理 |

当前项目只注册 `Stop`，见 `.codex/hooks.json`。

每个 Hook 还必须具有对应 `manifest.yaml`，并通过 `python3 .codex/platform/manifest-registry.py --root . validate` 验证注册表与实际入口一致。manifest 只声明请求权限；Codex 的用户授权和运行时策略仍是唯一的权限授予来源。

## hooks.json

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash -lc 'if [ -x .codex/hooks/post-conversation.sh ]; then exec .codex/hooks/post-conversation.sh; fi; if [ -x hooks/post-conversation.sh ]; then exec hooks/post-conversation.sh; fi; echo \"Study System: post-conversation hook not found\"; exit 0'",
            "statusMessage": "检查项目状态..."
          }
        ]
      }
    ]
  }
}
```

## 脚本约定

1. 默认只检查并记录项目状态，不执行 `git add`、提交或推送。
2. 设置 `CODEX_AUTO_GIT=1` 后才执行 `git add -A` 和自动提交。
3. 自动推送必须额外设置 `CODEX_AUTO_GIT_PUSH=1`。
4. 脚本必须可执行：`chmod +x .codex/hooks/*.sh`。
5. 脚本内部必须定位到项目根目录，避免受 Codex 当前工作目录影响。
6. hook 日志写入 `${TMPDIR:-/tmp}/study-system-post-conversation.log`，日志写入失败不影响提交主流程。
