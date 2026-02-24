#!/bin/bash
# Claude Auto-Dev: Research Cache Guard (PreToolUse)
# Purpose: Blocks ALL tool calls until pending research is cached or skipped.
# Paired with: research-cache-remind.sh (PostToolUse state writer)
#
# Allowed actions when state is pending:
#   - Write/Edit to docs/research/* (caching the results)
#   - Read docs/research/* (reading template/index)
#   - Bash mkdir for docs/research/ subdirectories
# Everything else is BLOCKED until 00_INDEX.md is updated (clears state).

set -uo pipefail

STATE_FILE="/tmp/claude-research-pending"

# No pending research -> allow everything
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

# Stale state check (older than 2 hours -> auto-clear)
if [[ "$(uname)" == "Darwin" ]]; then
  STATE_AGE=$(( $(date +%s) - $(stat -f %m "$STATE_FILE" 2>/dev/null || echo "0") ))
else
  STATE_AGE=$(( $(date +%s) - $(stat -c %Y "$STATE_FILE" 2>/dev/null || echo "0") ))
fi
if [[ $STATE_AGE -gt 7200 ]]; then
  rm -f "$STATE_FILE"
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ -z "$TOOL_NAME" ]]; then
  exit 0
fi

# --- Allow cache-related operations ---

# Write/Edit to docs/research/ -> allow AND clear state (caching completed)
if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  if [[ "$FILE_PATH" == *"docs/research/"* ]]; then
    rm -f "$STATE_FILE"
    exit 0
  fi
fi

# Read docs/research/ -> allow (reading template/index for caching)
if [[ "$TOOL_NAME" == "Read" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  if [[ "$FILE_PATH" == *"docs/research/"* ]]; then
    exit 0
  fi
fi

# Bash mkdir for research subdirectories -> allow
if [[ "$TOOL_NAME" == "Bash" ]]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
  if echo "$COMMAND" | grep -q "docs/research/"; then
    exit 0
  fi
fi

# --- Block everything else ---

PENDING_TOOL=$(jq -r '.tool // "unknown"' "$STATE_FILE" 2>/dev/null)
PENDING_QUERY=$(jq -r '.query // "unknown"' "$STATE_FILE" 2>/dev/null)
SUGGESTED_PATH=$(jq -r '.suggested_path // "unknown"' "$STATE_FILE" 2>/dev/null)

REASON="[RESEARCH-CACHE BLOCK] Previous research result not cached yet.
Tool: ${PENDING_TOOL}
Query: ${PENDING_QUERY}
Suggested path: ${SUGGESTED_PATH}

Do one of the following FIRST:
1. Save cache: Write -> ${SUGGESTED_PATH} (use TEMPLATE.md format) + Edit -> docs/research/00_INDEX.md (add row)
2. Skip: Edit -> docs/research/00_INDEX.md (add SKIP row)
   Example: | date | category | topic | tool | SKIPPED: reason | - |"

jq -n --arg reason "$REASON" '{ "decision": "block", "reason": $reason }'
exit 0
