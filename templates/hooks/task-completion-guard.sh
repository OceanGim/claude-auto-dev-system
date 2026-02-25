#!/bin/bash
# Task Completion Guard
# Warns when a new prompt is submitted but there are uncommitted code changes
# from previous work. Reminds to run /commit + /wrap before moving on.

set -uo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // empty')

if [[ -z "$PROMPT" ]]; then
  exit 0
fi

# Skip if user is already doing commit/wrap/done actions
if echo "$PROMPT" | grep -qiE '^/(commit|wrap|begin)|commit|wrap|done|finished'; then
  exit 0
fi

cd {{PROJECT_ROOT}}

# Get uncommitted changes (staged + unstaged + untracked)
CHANGES=$(git status --porcelain 2>/dev/null || true)

if [[ -z "$CHANGES" ]]; then
  exit 0
fi

# Filter out docs-only changes (docs/, LESSONS.md are non-code)
CODE_CHANGES=$(echo "$CHANGES" | grep -vE '^\s*\??\??\s*(docs/|LESSONS\.md)' || true)

if [[ -z "$CODE_CHANGES" ]]; then
  exit 0
fi

# Count changed files
CHANGE_COUNT=$(echo "$CODE_CHANGES" | wc -l | tr -d ' ')

# Build file summary (max 8 lines)
FILE_SUMMARY=$(echo "$CODE_CHANGES" | head -8 | sed 's/^/  /')
if [[ "$CHANGE_COUNT" -gt 8 ]]; then
  FILE_SUMMARY="${FILE_SUMMARY}
  ... and $((CHANGE_COUNT - 8)) more files"
fi

MSG="[TASK-COMPLETION-GUARD] Uncommitted code changes detected (${CHANGE_COUNT} files).
Before starting new work, consider running:
  1. /commit — to commit current changes
  2. /wrap — to update TODO + work log

Changed files:
${FILE_SUMMARY}"

jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
exit 0
