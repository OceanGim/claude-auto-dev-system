#!/bin/bash
# Task Completion Guard
# Fires on Stop event (after Claude's turn ends).
# Flow:
#   1. Uncommitted code changes detected?
#   2. Claude judges: does this change need tests?
#      → Yes: write tests → run → pass → commit + TODO
#      → No: commit + TODO directly

set -uo pipefail

INPUT=$(cat)

STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // empty')
if [[ "$STOP_REASON" != "end_turn" ]]; then
  exit 0
fi

cd {{PROJECT_ROOT}}

# ── Cooldown: prevent repeated triggers (5 min) ──
STATE_FILE="/tmp/claude-completion-guard-reminded"
if [[ -f "$STATE_FILE" ]]; then
  if [[ "$(uname)" == "Darwin" ]]; then
    CREATED=$(stat -f %m "$STATE_FILE" 2>/dev/null || echo 0)
  else
    CREATED=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
  fi
  NOW=$(date +%s)
  if [[ $(( NOW - CREATED )) -lt 300 ]]; then
    exit 0
  fi
  rm -f "$STATE_FILE"
fi

# ── Check uncommitted code changes ──
CHANGES=$(git status --porcelain 2>/dev/null || true)
if [[ -z "$CHANGES" ]]; then
  exit 0
fi

CODE_CHANGES=$(echo "$CHANGES" | grep -vE '^\s*\??\??\s*(docs/|LESSONS\.md|\.claude/)' || true)
if [[ -z "$CODE_CHANGES" ]]; then
  exit 0
fi

CHANGE_COUNT=$(echo "$CODE_CHANGES" | wc -l | tr -d ' ')
FILE_SUMMARY=$(echo "$CODE_CHANGES" | head -10 | sed 's/^/  /')
if [[ "$CHANGE_COUNT" -gt 10 ]]; then
  FILE_SUMMARY="${FILE_SUMMARY}
  ... and $((CHANGE_COUNT - 10)) more files"
fi

# ── Set cooldown ──
touch "$STATE_FILE"

MSG="[TASK-COMPLETION-GUARD] Uncommitted code changes detected (${CHANGE_COUNT} files).

Changed files:
${FILE_SUMMARY}

Follow this sequence with the user:

Step 1: Judge whether tests are needed
  - Evaluate if the changes involve testable logic (business logic, API, state, data flow)
  - Config, styles, docs, type declarations = no test needed
  - If tests needed: ask user \"These changes need tests. Shall I write and run them?\"
  - If no tests needed: go to Step 3

Step 2: Run tests (if Step 1 determined tests are needed)
  - Write tests or run existing ones
  - If pass → go to Step 3
  - If fail → fix and re-run

Step 3: Commit + TODO update
  - Ask user: \"Shall I commit and update the TODO?\""

jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
exit 0
