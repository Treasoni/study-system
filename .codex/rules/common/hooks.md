# Codex Hooks 规范（项目本地）

本项目只使用项目内 `.codex/hooks.json` 和 `.codex/hooks/`。不要把本项目 hooks 写入全局 `~/.codex/config.toml`。

## 配置位置

| 文件 | 作用域 | 提交 git |
|------|--------|----------|
| `.codex/hooks.json` | 本项目 hooks 注册表 | ✅ |
| `.codex/hooks/*.sh` | 本项目 hook 脚本 | ✅ |
| `~/.codex/config.toml` | 全局 Codex 状态/信任记录 | ❌ 不由本项目维护 |

## 事件速查

| 事件 | 时机 | 可阻止 |
|------|------|--------|
| `SessionStart` | 会话开始 | 通常用于读取项目记忆 |
| `Stop` | Codex 停止响应/会话收尾 | 通常用于状态整理 |

当前项目只注册 `Stop`，见 `.codex/hooks.json`。

## hooks.json

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "./hooks/post-conversation.sh",
            "statusMessage": "整理项目状态..."
          }
        ]
      }
    ]
  }
}
```

## 脚本约定

1. 默认只做状态输出，不自动提交、不推送。
2. 自动提交必须显式设置 `CODEX_AUTO_GIT=1`。
3. 自动推送必须额外设置 `CODEX_AUTO_GIT_PUSH=1`。
4. 脚本必须可执行：`chmod +x .codex/hooks/*.sh`。
5. 脚本内部必须定位到项目根目录，避免受 Codex 当前工作目录影响。
