#!/bin/bash
# Task Completion Guard
# Fires on Stop event (after Claude's turn ends).
# If there are uncommitted code changes, tells Claude to ask user
# whether to commit + update TODO.

set -uo pipefail

INPUT=$(cat)

# Read stop reason from Stop event
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // empty')

# Only trigger on end_turn (normal completion), not on tool use or error
if [[ "$STOP_REASON" != "end_turn" ]]; then
  exit 0
fi

cd {{PROJECT_ROOT}}

# Prevent repeated triggers — check if we already reminded this cycle
STATE_FILE="/tmp/claude-completion-guard-reminded"
if [[ -f "$STATE_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    CREATED=$(stat -f %m "$STATE_FILE" 2>/dev/null || echo 0)
  else
    CREATED=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
  fi
  NOW=$(date +%s)
  AGE=$(( NOW - CREATED ))
  if [[ "$AGE" -lt 300 ]]; then
    exit 0
  fi
  rm -f "$STATE_FILE"
fi

# Get uncommitted changes
CHANGES=$(git status --porcelain 2>/dev/null || true)

if [[ -z "$CHANGES" ]]; then
  exit 0
fi

# Filter out docs-only changes
CODE_CHANGES=$(echo "$CHANGES" | grep -vE '^\s*\??\??\s*(docs/|LESSONS\.md)' || true)

if [[ -z "$CODE_CHANGES" ]]; then
  exit 0
fi

CHANGE_COUNT=$(echo "$CODE_CHANGES" | wc -l | tr -d ' ')

FILE_SUMMARY=$(echo "$CODE_CHANGES" | head -8 | sed 's/^/  /')
if [[ "$CHANGE_COUNT" -gt 8 ]]; then
  FILE_SUMMARY="${FILE_SUMMARY}
  ... and $((CHANGE_COUNT - 8)) more files"
fi

# Mark as reminded to prevent loop
touch "$STATE_FILE"

MSG="[TASK-COMPLETION-GUARD] Uncommitted code changes detected (${CHANGE_COUNT} files).
Ask the user whether to proceed with git commit + TODO update.

Changed files:
${FILE_SUMMARY}

Ask the user: \"Work appears complete. Shall I commit and update the TODO?\""

jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
exit 0
