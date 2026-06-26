#!/bin/bash

# Stop hook script for auto git workflow
# This script runs when Claude Code is about to stop
# Follows git-workflow rules: type: description format

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Not in a git repository, skipping..."
  exit 0
fi

# Check for uncommitted changes
CHANGES=$(git status --porcelain)

if [ -z "$CHANGES" ]; then
  echo "No changes to commit."
  exit 0
fi

# Show current status
echo "=== Git Auto-Commit Hook ==="
echo "Changes detected:"
git status --short

echo ""
echo "=== Staged changes will be committed ==="
git add -A

# Get staged changes for commit message
STAGED=$(git diff --cached --stat)

if [ -z "$STAGED" ]; then
  echo "No staged changes to commit."
  exit 0
fi

# Generate commit message based on changes
# Follows git-workflow rules: <type>: <description>

# Get list of changed files
CHANGED_FILES=$(git diff --cached --name-only)

# Determine commit type based on file patterns
COMMIT_TYPE="chore"
COMMIT_DESC="update project"

# Check for documentation changes
if echo "$CHANGED_FILES" | grep -q "\.md$"; then
  COMMIT_TYPE="docs"
  if echo "$CHANGED_FILES" | grep -q "^\.claude/"; then
    COMMIT_DESC="update claude code configuration"
  else
    COMMIT_DESC="update documentation"
  fi
# Check for configuration files
elif echo "$CHANGED_FILES" | grep -q "\.yaml$\|\.json$\|\.toml$"; then
  COMMIT_TYPE="chore"
  COMMIT_DESC="update configuration files"
# Check for script changes
elif echo "$CHANGED_FILES" | grep -q "\.sh$\|\.py$\|\.js$\|\.ts$"; then
  COMMIT_TYPE="chore"
  COMMIT_DESC="update scripts"
# Check for new features
elif echo "$CHANGED_FILES" | grep -q "^src/\|^lib/"; then
  COMMIT_TYPE="feat"
  COMMIT_DESC="add new functionality"
# Check for bug fixes
elif echo "$CHANGED_FILES" | grep -q "fix\|bug\|patch"; then
  COMMIT_TYPE="fix"
  COMMIT_DESC="resolve issues"
fi

# Create commit message following git-workflow format
COMMIT_MSG="${COMMIT_TYPE}: ${COMMIT_DESC}"

# Add body with file details
COMMIT_BODY=$(git diff --cached --stat | sed 's/^/  /')

# Commit with the generated message
if [ -n "$COMMIT_BODY" ]; then
  git commit -m "$COMMIT_MSG

$COMMIT_BODY"
else
  git commit -m "$COMMIT_MSG"
fi

echo ""
echo "=== Committed successfully ==="
git log --oneline -1
