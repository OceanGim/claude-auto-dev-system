#!/bin/bash
# Claude Auto-Dev: Architecture Documentation Guard Hook
# Event: PreToolUse (Read|Write|Edit)
# Purpose: Scans docs for terminology violations (warns, does not block)
#
# CUSTOMIZE: Define your project's Ubiquitous Language / terminology rules.
# This hook catches when someone uses wrong/outdated terms in documentation.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

PROJECT_ROOT="{{PROJECT_ROOT}}"
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# ── Only handle docs/ paths ──
if [[ "$REL_PATH" != docs/* ]]; then
  exit 0
fi

# ============================================================
# WRITE/EDIT: Terminology violation scan
# ============================================================

if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then

  CONTENT=""
  if [[ "$TOOL_NAME" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
  else
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
  fi

  if [[ -z "$CONTENT" ]]; then
    exit 0
  fi

  # Strip code blocks to reduce false positives
  SCAN_TEXT=$(echo "$CONTENT" | sed '/^```/,/^```/d' | grep -vE '^\|.*\|$' | grep -vE '^#{1,6} ')

  VIOLATIONS=""

  # ── CUSTOMIZE: Add your terminology rules ──
  # Format: if wrong_term found -> suggest correct_term

  # Example rules (replace with your project's domain language):
  # if echo "$SCAN_TEXT" | grep -qiE '\bBlogPost\b'; then
  #   VIOLATIONS="${VIOLATIONS}\n- 'BlogPost' -> ContentSource is the correct domain term"
  # fi
  # if echo "$SCAN_TEXT" | grep -qiE '\buser account\b'; then
  #   VIOLATIONS="${VIOLATIONS}\n- 'user account' -> Profile is the correct domain term"
  # fi

  if [[ -n "$VIOLATIONS" ]]; then
    REASON="[ARCH-DOCS-GUARD] Terminology violations detected (${REL_PATH}):${VIOLATIONS}

This is a warning, not a block. Proceed if the usage is intentional."

    jq -n --arg reason "$REASON" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  fi
fi

exit 0
