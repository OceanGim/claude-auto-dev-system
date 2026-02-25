#!/bin/bash
# Task Completion Guard
# Fires on Stop event. Uses phase-based state file to track workflow:
#
#   (no state) → Phase 1: "Need tests?" → state=test
#   state=test → Phase 2: "Commit + TODO?" → state=commit
#   state=commit → skip (already asked)
#   git clean → state file deleted → ready for next cycle

set -uo pipefail

INPUT=$(cat)

STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // empty')
if [[ "$STOP_REASON" != "end_turn" ]]; then
  exit 0
fi

cd {{PROJECT_ROOT}}

STATE_FILE="/tmp/claude-completion-guard-phase"

# ── Check uncommitted code changes ──
CHANGES=$(git status --porcelain 2>/dev/null || true)

if [[ -z "$CHANGES" ]]; then
  rm -f "$STATE_FILE"
  exit 0
fi

CODE_CHANGES=$(echo "$CHANGES" | grep -vE '^\s*\??\??\s*(docs/|LESSONS\.md|\.claude/)' || true)

if [[ -z "$CODE_CHANGES" ]]; then
  rm -f "$STATE_FILE"
  exit 0
fi

# ── Read current phase ──
PHASE=""
if [[ -f "$STATE_FILE" ]]; then
  PHASE=$(cat "$STATE_FILE" 2>/dev/null || true)
fi

if [[ "$PHASE" == "commit" ]]; then
  exit 0
fi

CHANGE_COUNT=$(echo "$CODE_CHANGES" | wc -l | tr -d ' ')
FILE_SUMMARY=$(echo "$CODE_CHANGES" | head -10 | sed 's/^/  /')
if [[ "$CHANGE_COUNT" -gt 10 ]]; then
  FILE_SUMMARY="${FILE_SUMMARY}
  ... and $((CHANGE_COUNT - 10)) more files"
fi

if [[ -z "$PHASE" ]]; then
  # ── Phase 1: Judge test necessity ──
  echo "test" > "$STATE_FILE"

  MSG="[TASK-COMPLETION-GUARD] Uncommitted code changes detected (${CHANGE_COUNT} files).

Changed files:
${FILE_SUMMARY}

Judge whether these changes need tests:
  - Logic, API, state, data processing → tests needed
  - Config, styles, docs, type declarations only → no tests needed

If tests needed:
  Ask user: \"These changes need tests. Shall I write and run them?\"
  After tests pass, the next phase will trigger automatically.

If no tests needed:
  Ask user: \"Work appears complete. Shall I commit and update the TODO?\""

elif [[ "$PHASE" == "test" ]]; then
  # ── Phase 2: Tests done → commit + TODO ──
  echo "commit" > "$STATE_FILE"

  MSG="[TASK-COMPLETION-GUARD] Test phase appears complete.

Changed files:
${FILE_SUMMARY}

Ask user: \"Work and tests are complete. Shall I commit and update the TODO?\""
fi

jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
exit 0
