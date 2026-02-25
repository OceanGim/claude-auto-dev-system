#!/bin/bash
# Document Link Guard Hook
# PostToolUse: Write/Edit on docs/ paths
# Detects cross-reference links in modified content and reminds to update backlinks + registry
#
# Requires: docs/LINK_REGISTRY.md and scripts/check-doc-links.js to exist
# If you don't use the wiki-style link system, remove this hook from settings.json

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

PROJECT_ROOT="{{PROJECT_ROOT}}"
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# Only handle docs/ paths
if [[ "$REL_PATH" != docs/* ]]; then
  exit 0
fi

# Get the content that was written/edited
CONTENT=""
if [[ "$TOOL_NAME" == "Write" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [[ "$TOOL_NAME" == "Edit" ]]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
fi

if [[ -z "$CONTENT" ]]; then
  exit 0
fi

# Scan for markdown links to .md files (cross-references)
# Pattern: [text](path/to/file.md) or [text](./file.md#anchor)
LINKS=$(echo "$CONTENT" | grep -oE '\[[^]]*\]\([^)]*\.md[^)]*\)' 2>/dev/null || true)

if [[ -z "$LINKS" ]]; then
  exit 0
fi

# Count unique target files
TARGETS=$(echo "$LINKS" | grep -oE '\([^)]*\.md' | sed 's/^(//' | sort -u)
LINK_COUNT=$(echo "$TARGETS" | wc -l | tr -d ' ')

# Check if this is a Backlinks section edit (don't remind for backlink edits themselves)
if echo "$CONTENT" | grep -q '## Backlinks'; then
  exit 0
fi

# Check if this is LINK_REGISTRY.md itself
if [[ "$REL_PATH" == "docs/LINK_REGISTRY.md" ]]; then
  exit 0
fi

REMINDER="[DOC-LINK-GUARD] ${REL_PATH} contains ${LINK_COUNT} document cross-reference(s):
$(echo "$TARGETS" | head -5)

Document Link Protocol checklist:
1. Add this document to the target doc's ## Backlinks table
2. Update docs/LINK_REGISTRY.md (forward + backlink rows)
3. After all changes: run node scripts/check-doc-links.js"

jq -n --arg ctx "$REMINDER" '{ systemMessage: $ctx }'
exit 0
