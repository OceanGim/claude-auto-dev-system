#!/bin/bash
# Claude Auto-Dev: Research Cache State Writer (PostToolUse)
# Purpose: Creates pending state file to enforce caching via guard hook
# Paired with: research-cache-guard.sh (PreToolUse blocker)

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ -z "$TOOL_NAME" ]]; then
  exit 0
fi

STATE_FILE="/tmp/claude-research-pending"

# Determine category and query
CATEGORY=""
QUERY=""
case "$TOOL_NAME" in
  WebSearch)
    CATEGORY="searches"
    QUERY=$(echo "$INPUT" | jq -r '.tool_input.query // empty')
    ;;
  WebFetch)
    CATEGORY="apis"
    QUERY=$(echo "$INPUT" | jq -r '.tool_input.url // empty')
    ;;
  mcp__context7__resolve-library-id)
    # ID lookup only — no content to cache. Real content comes from query-docs.
    exit 0
    ;;
  mcp__context7__query-docs)
    CATEGORY="libraries"
    QUERY=$(echo "$INPUT" | jq -r '.tool_input.topic // empty')
    ;;
  *)
    exit 0
    ;;
esac

if [[ -z "$QUERY" ]]; then
  exit 0
fi

# Generate slug for suggested filename
SLUG=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-50)
SUGGESTED_PATH="docs/research/${CATEGORY}/${SLUG}.md"
TIMESTAMP=$(date '+%Y-%m-%dT%H:%M:%S')

# Write pending state file (overwrites previous — latest research tracked)
jq -n \
  --arg tool "$TOOL_NAME" \
  --arg query "$QUERY" \
  --arg path "$SUGGESTED_PATH" \
  --arg time "$TIMESTAMP" \
  --arg category "$CATEGORY" \
  '{tool: $tool, query: $query, suggested_path: $path, timestamp: $time, category: $category}' > "$STATE_FILE"

MSG="[RESEARCH-CACHE] You MUST cache this research result!
- Save to: ${SUGGESTED_PATH}
- Template: docs/research/TEMPLATE.md
- Index: Add row to docs/research/00_INDEX.md
- Skip: Add SKIP row to index (if not worth caching)
Next tool call will be BLOCKED until save/skip is complete."

jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
exit 0
