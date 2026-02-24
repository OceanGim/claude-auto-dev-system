#!/bin/bash
# Claude Auto-Dev: Intent Router Hook
# Event: UserPromptSubmit
# Purpose: Analyzes user prompt keywords to suggest relevant docs BEFORE work starts
#
# CUSTOMIZE: Add your own keyword -> doc path mappings below

set -uo pipefail

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.user_prompt // empty')

if [[ -z "$PROMPT" ]]; then
  exit 0
fi

# ── CUSTOMIZE: Define your reference docs directory ──
REF_DIR="docs"
SUGGESTIONS=""

# ── CUSTOMIZE: Add keyword -> doc mappings for your project ──

# Example: Backend / API work
if echo "$PROMPT" | grep -qiE 'backend|server|API|endpoint|database|model|schema'; then
  SUGGESTIONS="${SUGGESTIONS}
- Architecture: ${REF_DIR}/architecture.md"
fi

# Example: Frontend / UI work
if echo "$PROMPT" | grep -qiE 'frontend|component|UI|page|screen|React|CSS|layout'; then
  SUGGESTIONS="${SUGGESTIONS}
- UI Patterns: ${REF_DIR}/ui-patterns.md"
fi

# Example: Testing
if echo "$PROMPT" | grep -qiE 'test|testing|validate|pytest|jest|e2e|coverage'; then
  SUGGESTIONS="${SUGGESTIONS}
- Testing Strategy: ${REF_DIR}/testing.md"
fi

# Example: Database / Migration
if echo "$PROMPT" | grep -qiE 'migration|database|table|schema|SQL'; then
  SUGGESTIONS="${SUGGESTIONS}
- Database Schema: ${REF_DIR}/database.md"
fi

# Example: New feature / Implementation
if echo "$PROMPT" | grep -qiE 'implement|create|build|add|new|feature'; then
  SUGGESTIONS="${SUGGESTIONS}
- Project Conventions: CLAUDE.md"
fi

# Example: Research / Investigation
if echo "$PROMPT" | grep -qiE 'research|investigate|look up|search for'; then
  SUGGESTIONS="${SUGGESTIONS}
- Research Cache Index: docs/research/00_INDEX.md"
fi

# Example: Documentation
if echo "$PROMPT" | grep -qiE 'document|docs|README|guide|wiki'; then
  SUGGESTIONS="${SUGGESTIONS}
- Documentation Guide: ${REF_DIR}/documentation.md"
fi

# Output suggestions if any
if [[ -n "$SUGGESTIONS" ]]; then
  # Deduplicate lines
  UNIQUE_SUGGESTIONS=$(echo "$SUGGESTIONS" | sort -u | grep -v '^$')
  MSG="[INTENT-ROUTER] Relevant docs for this task. Read what you need before starting:
${UNIQUE_SUGGESTIONS}"
  jq -n --arg ctx "$MSG" '{ systemMessage: $ctx }'
  exit 0
fi

exit 0
