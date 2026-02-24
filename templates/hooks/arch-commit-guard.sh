#!/bin/bash
# Claude Auto-Dev: Architecture Commit Guard Hook
# Event: PreToolUse (Bash)
# Purpose: Warns when a git commit touches multiple modules/domains
#
# CUSTOMIZE: Replace MODULE_LIST with your project's module/domain names.

set -uo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only trigger on git commit commands
if ! echo "$COMMAND" | grep -qE '^git commit'; then
  exit 0
fi

PROJECT_ROOT="{{PROJECT_ROOT}}"
cd "$PROJECT_ROOT"

# Check staged files for module mixing
STAGED=$(git diff --cached --name-only 2>/dev/null || true)
if [[ -z "$STAGED" ]]; then
  exit 0
fi

# ── CUSTOMIZE: List your modules/domains/bounded contexts ──
MODULE_LIST="auth users content orders payments notifications"

MODULES_TOUCHED=""
for MODULE in $MODULE_LIST; do
  if echo "$STAGED" | grep -qi "$MODULE"; then
    MODULES_TOUCHED="${MODULES_TOUCHED} ${MODULE}"
  fi
done

MODULE_COUNT=$(echo "$MODULES_TOUCHED" | wc -w | tr -d ' ')

if [[ "$MODULE_COUNT" -gt 1 ]]; then
  CONTEXT="[ARCH-GUARD] COMMIT SCOPE WARNING
This commit touches multiple modules/domains:${MODULES_TOUCHED}
Consider splitting into separate commits per module for cleaner history.
Each commit should ideally affect one module only."

  jq -n --arg ctx "$CONTEXT" '{ systemMessage: $ctx }'
  exit 0
fi

exit 0
