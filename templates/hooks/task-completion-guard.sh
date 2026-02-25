#!/bin/bash
# Task Completion Guard
# Fires on Stop event (after Claude's turn ends).
# Flow:
#   1. Uncommitted code changes detected?
#   2. Test files exist for changed code? → force test first
#   3. Tests pass (or no tests needed)? → ask user to commit + TODO update

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
FILE_SUMMARY=$(echo "$CODE_CHANGES" | head -8 | sed 's/^/  /')
if [[ "$CHANGE_COUNT" -gt 8 ]]; then
  FILE_SUMMARY="${FILE_SUMMARY}
  ... and $((CHANGE_COUNT - 8)) more files"
fi

# ── Detect if tests exist for changed files ──
# CUSTOMIZE: adjust extensions and test file patterns for your project
NEEDS_TEST="false"
TEST_FILES=""

CHANGED_PATHS=$(echo "$CODE_CHANGES" | sed 's/^...//' | tr -d '"')

while IFS= read -r FILE_PATH; do
  # Skip non-source files (CUSTOMIZE: add your source extensions)
  if ! echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs)$'; then
    continue
  fi
  # Skip test files themselves, config files
  if echo "$FILE_PATH" | grep -qiE '\.(test|spec|e2e)\.|__tests__|\.config\.|\.d\.ts$'; then
    continue
  fi

  DIR=$(dirname "$FILE_PATH")
  BASE=$(basename "$FILE_PATH" | sed 's/\.[^.]*$//')

  # CUSTOMIZE: add test file patterns for your project
  for PATTERN in \
    "${DIR}/${BASE}.test.ts" \
    "${DIR}/${BASE}.test.tsx" \
    "${DIR}/${BASE}.spec.ts" \
    "${DIR}/${BASE}.spec.tsx" \
    "${DIR}/__tests__/${BASE}.test.ts" \
    "${DIR}/__tests__/${BASE}.test.tsx" \
    "${DIR}/${BASE}_test.go" \
    "${DIR}/test_${BASE}.py"; do
    if [[ -f "$PATTERN" ]]; then
      NEEDS_TEST="true"
      TEST_FILES="${TEST_FILES}
  ${PATTERN}"
      break
    fi
  done
done <<< "$CHANGED_PATHS"

# ── Set cooldown ──
touch "$STATE_FILE"

# ── Build message based on test requirement ──
if [[ "$NEEDS_TEST" == "true" ]]; then
  UNIQUE_TESTS=$(echo "$TEST_FILES" | sort -u | grep -v '^$')
  MSG="[TASK-COMPLETION-GUARD] Uncommitted code changes detected (${CHANGE_COUNT} files).
Related test files found — run tests before committing.

Changed files:
${FILE_SUMMARY}

Related tests:
${UNIQUE_TESTS}

Proceed in this order:
  1. Run the related tests
  2. Verify tests pass
  3. If passed, ask user: \"Tests passed. Shall I commit and update the TODO?\"
  4. If failed, fix and re-run"
else
  MSG="[TASK-COMPLETION-GUARD] Uncommitted code changes detected (${CHANGE_COUNT} files).
No related test files found — ready to commit.

Changed files:
${FILE_SUMMARY}

Ask the user: \"Work appears complete. Shall I commit and update the TODO?\""
fi

jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
exit 0
