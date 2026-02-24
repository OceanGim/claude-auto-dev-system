#!/bin/bash
# Claude Auto-Dev: Session Restore Hook
# Event: SessionStart
# Purpose: Scans docs/work/ for in-progress tasks and injects context
#
# CUSTOMIZE: Change PROJECT_ROOT and WORK_DIR paths

set -uo pipefail

PROJECT_ROOT="{{PROJECT_ROOT}}"
WORK_DIR="${PROJECT_ROOT}/docs/work"

# Skip if no work directory
if [[ ! -d "$WORK_DIR" ]]; then
  exit 0
fi

# Find in-progress tasks
ACTIVE_TASKS=""
for TASK_DIR in "$WORK_DIR"/*/; do
  if [[ ! -d "$TASK_DIR" ]]; then
    continue
  fi

  CHECKLIST="${TASK_DIR}checklist.md"
  if [[ ! -f "$CHECKLIST" ]]; then
    continue
  fi

  # Check if status is IN PROGRESS
  if grep -q "IN PROGRESS" "$CHECKLIST" 2>/dev/null; then
    TASK_NAME=$(basename "$TASK_DIR")
    TOTAL=$(grep -cE '^\- \[[ x]\]' "$CHECKLIST" 2>/dev/null || echo 0)
    DONE=$(grep -cE '^\- \[x\]' "$CHECKLIST" 2>/dev/null || echo 0)

    # macOS stat vs Linux stat
    if [[ "$(uname)" == "Darwin" ]]; then
      LAST_UPDATED=$(stat -f "%Sm" -t "%Y-%m-%d" "$CHECKLIST" 2>/dev/null || echo "unknown")
    else
      LAST_UPDATED=$(stat -c "%y" "$CHECKLIST" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
    fi

    # Get next pending item
    NEXT_ITEM=$(grep -m1 '^\- \[ \]' "$CHECKLIST" 2>/dev/null | sed 's/^- \[ \] //' || echo "none")

    ACTIVE_TASKS="${ACTIVE_TASKS}
- ${TASK_NAME}: ${DONE}/${TOTAL} completed (last updated: ${LAST_UPDATED})
  Next: ${NEXT_ITEM}
  Docs: docs/work/${TASK_NAME}/"
  fi
done

if [[ -n "$ACTIVE_TASKS" ]]; then
  MSG="[SESSION-RESTORE] Active work sessions detected:
${ACTIVE_TASKS}

Read the checklist.md of the active task to resume where you left off.
Read context.md for decision history and key references."

  jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
  exit 0
fi

exit 0
