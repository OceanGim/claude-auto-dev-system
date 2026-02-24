#!/bin/bash
# Claude Auto-Dev: Architecture Guard Hook
# Event: PreToolUse (Read|Write|Edit)
# Purpose: Enforces architecture rules and injects layer-specific context
#
# CUSTOMIZE THIS FILE for your project's architecture.
# This template provides a generic layered architecture example.
# Replace LAYER DEFINITIONS and VIOLATION RULES with your own patterns.

set -uo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# ── CUSTOMIZE: Set your project root ──
PROJECT_ROOT="{{PROJECT_ROOT}}"
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# ============================================================
# SECTION 1: VIOLATION DETECTION (Block on Write/Edit)
# ============================================================
# CUSTOMIZE: Define what imports are forbidden in which layers

if [[ "$TOOL_NAME" == "Write" || "$TOOL_NAME" == "Edit" ]]; then

  CONTENT=""
  if [[ "$TOOL_NAME" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
  else
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
  fi

  # ── Example: Domain layer must not import infrastructure ──
  # CUSTOMIZE: Replace path patterns and import patterns for your project
  if [[ "$REL_PATH" == src/domain/* ]]; then
    VIOLATIONS=""

    # Check for database imports in domain layer
    if echo "$CONTENT" | grep -qE "from 'pg'|import.*prisma|require.*sequelize|from 'typeorm'|from 'mongoose'"; then
      VIOLATIONS="${VIOLATIONS}\n- Database library import in domain layer"
    fi
    # Check for HTTP/framework imports in domain layer
    if echo "$CONTENT" | grep -qE "from 'express'|from 'fastify'|from 'koa'|from 'next'|import.*axios"; then
      VIOLATIONS="${VIOLATIONS}\n- HTTP/Framework import in domain layer"
    fi
    # Check for environment variable access in domain layer
    if echo "$CONTENT" | grep -qE "process\.env|import.*config"; then
      VIOLATIONS="${VIOLATIONS}\n- Environment variable / config access in domain layer"
    fi
    # Check for infrastructure path imports
    if echo "$CONTENT" | grep -qE "from '\.\./infrastructure|from '\.\./adapters|from '\.\./controllers"; then
      VIOLATIONS="${VIOLATIONS}\n- Infrastructure/adapter/controller import in domain layer"
    fi

    if [[ -n "$VIOLATIONS" ]]; then
      echo "ARCHITECTURE VIOLATION in domain layer ($REL_PATH):$VIOLATIONS" >&2
      echo "" >&2
      echo "Domain layer must have ZERO infrastructure imports." >&2
      echo "Move infrastructure concerns to src/infrastructure/" >&2
      exit 2
    fi
  fi

  # ── Example: Cross-module direct imports ──
  # CUSTOMIZE: Adjust for your module structure
  if [[ "$REL_PATH" == src/modules/*/domain/* ]]; then
    CURRENT_MODULE=$(echo "$REL_PATH" | sed -n 's|src/modules/\([^/]*\)/.*|\1|p')
    if [[ -n "$CURRENT_MODULE" ]]; then
      OTHER_MODULE=$(echo "$CONTENT" | grep -oE "from '\.\./[a-z_-]+/" | sed "s/from '\.\.\///" | sed 's/\///' | grep -v "^${CURRENT_MODULE}$" | grep -v "^shared$" | head -1)
      if [[ -n "$OTHER_MODULE" ]]; then
        echo "ARCHITECTURE VIOLATION: Cross-module import in $REL_PATH" >&2
        echo "- Importing from modules/$OTHER_MODULE/ inside modules/$CURRENT_MODULE/" >&2
        echo "Use IDs for cross-module references, not direct imports." >&2
        exit 2
      fi
    fi
  fi
fi

# ============================================================
# SECTION 2: CONTEXT INJECTION (Guide loading on any tool)
# ============================================================
# CUSTOMIZE: Define layer-specific guidance messages

CONTEXT=""

# ── Layer-based context injection ──

# Domain layer
if [[ "$REL_PATH" == src/domain/* || "$REL_PATH" == src/modules/*/domain/* ]]; then
  CONTEXT="[ARCH-GUARD] DOMAIN layer.
RULES: Zero infra imports | Rich domain language | Factory methods | Immutable value objects | ID-only cross-module refs"
fi

# Application layer (Use Cases / Services)
if [[ "$REL_PATH" == src/application/* || "$REL_PATH" == src/modules/*/application/* ]]; then
  CONTEXT="[ARCH-GUARD] APPLICATION layer (Use Cases/Services).
RULES: Orchestrate only (load->call->save) | No business logic branching | Constructor injection | Thin services"
fi

# Infrastructure layer
if [[ "$REL_PATH" == src/infrastructure/* || "$REL_PATH" == src/modules/*/infrastructure/* ]]; then
  CONTEXT="[ARCH-GUARD] INFRASTRUCTURE layer.
RULES: Implement domain interfaces | Map domain models <-> persistence models | External API isolation | Retries/timeouts here"
fi

# Controllers / API layer
if [[ "$REL_PATH" == src/controllers/* || "$REL_PATH" == src/routes/* || "$REL_PATH" == src/api/* ]]; then
  CONTEXT="[ARCH-GUARD] CONTROLLER/API layer.
RULES: Delegate to use cases | No business logic | Map domain exceptions to HTTP errors | Input validation here"
fi

# Test files
if [[ "$REL_PATH" == tests/* || "$REL_PATH" == *__tests__/* || "$REL_PATH" == *.test.* || "$REL_PATH" == *.spec.* ]]; then
  CONTEXT="[ARCH-GUARD] TEST files.
RULES: Domain tests = no infrastructure | Use factory functions for test data | Mock external dependencies | Test invariants and edge cases"
fi

# Shared types
if [[ "$REL_PATH" == src/shared/* || "$REL_PATH" == packages/shared/* ]]; then
  CONTEXT="[ARCH-GUARD] SHARED layer.
RULES: Types must mirror domain models | Use domain language in naming | Update when domain changes"
fi

# Output context if any was collected
if [[ -n "$CONTEXT" ]]; then
  jq -n --arg ctx "$CONTEXT" '{ systemMessage: $ctx }'
  exit 0
fi

exit 0
