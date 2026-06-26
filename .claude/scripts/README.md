# Git Auto-Commit Hook

## Overview

This hook automatically commits changes when Claude Code stops (completes a conversation). It follows the git-workflow rules defined in `.claude/rules/common/git-workflow.md`.

## How It Works

1. **Trigger**: Runs automatically when Claude Code session ends
2. **Detection**: Checks for any uncommitted changes in the working directory
3. **Staging**: Automatically stages all changes (`git add -A`)
4. **Commit**: Creates a commit with a formatted message following git-workflow conventions

## Commit Message Format

The hook generates commit messages in the format: `<type>: <description>`

### Supported Types

| Type | When Used |
|------|-----------|
| `docs` | Documentation changes (`.md` files) |
| `chore` | Configuration files, scripts, tooling |
| `feat` | New functionality in `src/` or `lib/` |
| `fix` | Bug fixes (detected by filename patterns) |

### Examples

```
docs: update documentation
chore: update configuration files
feat: add new functionality
fix: resolve issues
```

## Configuration

The hook is configured in `.claude/settings.local.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/scripts/git-autocommit.sh"
          }
        ]
      }
    ]
  }
}
```

## Manual Testing

To test the hook manually:

```bash
# Make some changes
echo "test" > test.txt

# Run the hook script
bash .claude/scripts/git-autocommit.sh

# Check the commit
git log --oneline -1
```

## Customization

Edit `.claude/scripts/git-autocommit.sh` to:

- Change commit type detection logic
- Add more file pattern matching
- Modify the commit message format
- Add additional git operations (push, etc.)

## Disabling the Hook

Remove the `hooks` section from `.claude/settings.local.json` or set the script to exit early:

```bash
exit 0  # Add at the beginning of the script
```

## Notes

- The hook only commits if there are actual changes
- It follows atomic commit principles (one logical change per commit)
- Commit messages are generated based on file patterns
- The hook does not push automatically (manual push required)
