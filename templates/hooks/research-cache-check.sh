#!/bin/bash
# Claude Auto-Dev: Research Cache Check (PreToolUse)
# Purpose: Checks docs/research/00_INDEX.md for existing cached research before external lookups
# Prevents redundant external API calls by checking local cache first.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ -z "$TOOL_NAME" ]]; then
  exit 0
fi

INDEX_FILE="docs/research/00_INDEX.md"

if [[ ! -f "$INDEX_FILE" ]]; then
  exit 0
fi

# Extract search keyword based on tool type
KEYWORD=""
case "$TOOL_NAME" in
  WebSearch)
    KEYWORD=$(echo "$INPUT" | jq -r '.tool_input.query // empty')
    ;;
  WebFetch)
    KEYWORD=$(echo "$INPUT" | jq -r '.tool_input.url // empty')
    ;;
  mcp__context7__resolve-library-id)
    KEYWORD=$(echo "$INPUT" | jq -r '.tool_input.libraryName // empty')
    ;;
  mcp__context7__query-docs)
    KEYWORD=$(echo "$INPUT" | jq -r '.tool_input.topic // empty')
    ;;
  *)
    exit 0
    ;;
esac

if [[ -z "$KEYWORD" ]]; then
  exit 0
fi

# Split keyword into individual words and search each
HITS=""
for word in $KEYWORD; do
  # Skip short words (2 chars or less) and common stop words
  if [[ ${#word} -le 2 ]]; then
    continue
  fi
  MATCH=$(grep -i "$word" "$INDEX_FILE" 2>/dev/null | grep '|' | head -3)
  if [[ -n "$MATCH" ]]; then
    HITS="${HITS}${MATCH}
"
  fi
done

# Deduplicate hits
if [[ -n "$HITS" ]]; then
  UNIQUE_HITS=$(echo "$HITS" | sort -u | grep -v '^$' | head -5)
  if [[ -n "$UNIQUE_HITS" ]]; then
    # Extract file paths from matched rows
    FILES=$(echo "$UNIQUE_HITS" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $7); if ($7 != "" && $7 != "File") print $7}' | sort -u)
    MSG="[RESEARCH-CACHE HIT] Related cached documents found. Check before making external calls:
${FILES}

Search term: ${KEYWORD}
Matched index rows:
${UNIQUE_HITS}"
    jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
    exit 0
  fi
fi

# Cache MISS - proceed without interference
exit 0
