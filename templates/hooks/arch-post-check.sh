#!/bin/bash
# Claude Auto-Dev: Architecture Post-Check Hook
# Event: PostToolUse (Write|Edit)
# Purpose: Reminds verification checklist after code is written
#
# CUSTOMIZE: Define layer-specific verification checklists for your project.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

PROJECT_ROOT="{{PROJECT_ROOT}}"
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

REMINDER=""

# ── CUSTOMIZE: Define verification checklists per layer ──

# Domain layer — most critical
if [[ "$REL_PATH" == src/domain/* || "$REL_PATH" == src/modules/*/domain/* ]]; then
  REMINDER="[POST-CHECK] Domain code written. VERIFY:
1. Zero infrastructure imports?
2. Names match domain language?
3. Factory methods present? (static create + hydrate)
4. Value objects immutable? (readonly properties)
5. Domain events raised for state changes?"
fi

# Application layer
if [[ "$REL_PATH" == src/application/* || "$REL_PATH" == src/modules/*/application/* ]]; then
  REMINDER="[POST-CHECK] Use Case / Service written. VERIFY:
1. Only orchestration? (load -> call domain method -> save)
2. No if/else business logic? (move to domain if found)
3. Dependencies injected via constructor?
4. Thin? (<30 lines)"
fi

# Infrastructure / persistence
if [[ "$REL_PATH" == src/infrastructure/* || "$REL_PATH" == src/modules/*/infrastructure/* ]]; then
  REMINDER="[POST-CHECK] Infrastructure code written. VERIFY:
1. Implements domain interface?
2. Persistence models separate from domain models?
3. Full aggregate load/save (not partial)?
4. Error handling and retries for external calls?"
fi

# Controllers / API layer
if [[ "$REL_PATH" == src/controllers/* || "$REL_PATH" == src/routes/* || "$REL_PATH" == src/api/* ]]; then
  REMINDER="[POST-CHECK] Controller/API written. VERIFY:
1. Delegates to use case? (no business logic)
2. Input validation present?
3. Domain exceptions mapped to HTTP errors?
4. Response DTO separate from domain model?"
fi

# Test files
if [[ "$REL_PATH" == tests/* || "$REL_PATH" == *__tests__/* || "$REL_PATH" == *.test.* || "$REL_PATH" == *.spec.* ]]; then
  REMINDER="[POST-CHECK] Test written. VERIFY:
1. No infrastructure dependencies in domain tests?
2. Tests aggregate invariants and edge cases?
3. Uses factory functions for test data?
4. Mocks only at boundaries?"
fi

# Shared types
if [[ "$REL_PATH" == src/shared/* || "$REL_PATH" == packages/shared/* ]]; then
  REMINDER="[POST-CHECK] Shared type written. VERIFY:
1. Mirrors corresponding domain model?
2. Uses domain language in naming?
3. Corresponding domain type updated if needed?"
fi

# Documentation
if [[ "$REL_PATH" == docs/* ]]; then
  REMINDER="[POST-CHECK] Documentation written. VERIFY:
1. Uses correct domain terminology?
2. Consistent with other docs?
3. Cross-references updated if needed?"
fi

if [[ -n "$REMINDER" ]]; then
  jq -n --arg ctx "$REMINDER" '{ systemMessage: $ctx }'
  exit 0
fi

exit 0
