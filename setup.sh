#!/bin/bash
# Claude Auto-Dev System — One-Command Setup
#
# Usage:
#   cd /path/to/your-project
#   bash /path/to/claude-auto-dev-system/setup.sh
#
# Creates the full auto-development infrastructure in the CURRENT directory.
# Existing files are never overwritten.

set -euo pipefail

# ── Detect template directory (where this script lives) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="${SCRIPT_DIR}/templates"
PROJECT_ROOT="$(pwd)"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "ERROR: templates/ directory not found at ${TEMPLATE_DIR}"
  echo "Make sure you're running the script from its original location."
  exit 1
fi

echo ""
echo "  Claude Auto-Dev System"
echo "  ======================"
echo ""
echo "  Project:   ${PROJECT_ROOT}"
echo "  Templates: ${TEMPLATE_DIR}"
echo ""

# ── Step 1: Create directory structure ──

echo "[1/7] Creating directory structure..."

mkdir -p .claude/{hooks,commands,agents}
mkdir -p .claude/skills/{work-init,team}
mkdir -p docs/{phases,work}
mkdir -p docs/research/{searches,apis,libraries}

echo "  Done."

# ── Step 2: Copy CLAUDE.md ──

echo "[2/7] Copying CLAUDE.md template..."

if [[ ! -f "CLAUDE.md" ]]; then
  cp "${TEMPLATE_DIR}/CLAUDE.md.template" CLAUDE.md
  echo "  Created: CLAUDE.md (edit {{PLACEHOLDER}} values)"
else
  echo "  Skipped: CLAUDE.md already exists"
fi

# ── Step 3: Copy core documents ──

echo "[3/7] Copying core documents..."

for pair in \
  "LESSONS.md.template:LESSONS.md" \
  "PROJECT_TODO.md.template:docs/PROJECT_TODO.md" \
  "research-TEMPLATE.md:docs/research/TEMPLATE.md" \
  "research-INDEX.md:docs/research/00_INDEX.md"
do
  SRC="${pair%%:*}"
  DST="${pair##*:}"
  if [[ ! -f "$DST" ]]; then
    cp "${TEMPLATE_DIR}/${SRC}" "$DST"
    echo "  Created: ${DST}"
  else
    echo "  Skipped: ${DST} already exists"
  fi
done

# ── Step 4: Deploy hooks ──

echo "[4/7] Deploying hook scripts..."

HOOK_COUNT=0
for HOOK_FILE in "${TEMPLATE_DIR}"/hooks/*.sh; do
  HOOK_NAME=$(basename "$HOOK_FILE")
  TARGET=".claude/hooks/${HOOK_NAME}"
  if [[ ! -f "$TARGET" ]]; then
    cp "$HOOK_FILE" "$TARGET"
    # Replace {{PROJECT_ROOT}} placeholder with actual path
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" "$TARGET" 2>/dev/null || true
    else
      sed -i "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" "$TARGET" 2>/dev/null || true
    fi
    HOOK_COUNT=$((HOOK_COUNT + 1))
  fi
done

chmod +x .claude/hooks/*.sh 2>/dev/null || true
echo "  Created: ${HOOK_COUNT} hook scripts"

# ── Step 5: Deploy commands ──

echo "[5/7] Deploying slash commands..."

CMD_COUNT=0
for CMD_FILE in "${TEMPLATE_DIR}"/commands/*.md; do
  CMD_NAME=$(basename "$CMD_FILE")
  TARGET=".claude/commands/${CMD_NAME}"
  if [[ ! -f "$TARGET" ]]; then
    cp "$CMD_FILE" "$TARGET"
    CMD_COUNT=$((CMD_COUNT + 1))
  fi
done

echo "  Created: ${CMD_COUNT} slash commands"

# ── Step 6: Deploy skills ──

echo "[6/7] Deploying skills..."

SKILL_COUNT=0
if [[ ! -f ".claude/skills/work-init/SKILL.md" ]]; then
  cp "${TEMPLATE_DIR}/skills/work-init.md" .claude/skills/work-init/SKILL.md
  SKILL_COUNT=$((SKILL_COUNT + 1))
fi
if [[ ! -f ".claude/skills/team/SKILL.md" ]]; then
  cp "${TEMPLATE_DIR}/skills/team.md" .claude/skills/team/SKILL.md
  SKILL_COUNT=$((SKILL_COUNT + 1))
fi

echo "  Created: ${SKILL_COUNT} skills"

# ── Step 7: Deploy agents + settings ──

echo "[7/7] Deploying agents and settings..."

AGENT_COUNT=0
for AGENT_FILE in "${TEMPLATE_DIR}"/agents/*.md; do
  AGENT_NAME=$(basename "$AGENT_FILE")
  TARGET=".claude/agents/${AGENT_NAME}"
  if [[ ! -f "$TARGET" ]]; then
    cp "$AGENT_FILE" "$TARGET"
    AGENT_COUNT=$((AGENT_COUNT + 1))
  fi
done

echo "  Created: ${AGENT_COUNT} agent definitions"

# Settings
if [[ ! -f ".claude/settings.json" ]]; then
  cp "${TEMPLATE_DIR}/settings.json.template" .claude/settings.json
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" .claude/settings.json 2>/dev/null || true
  else
    sed -i "s|{{PROJECT_ROOT}}|${PROJECT_ROOT}|g" .claude/settings.json 2>/dev/null || true
  fi
  echo "  Created: .claude/settings.json"
else
  echo "  Skipped: .claude/settings.json already exists"
fi

if [[ ! -f ".claude/settings.local.json" ]]; then
  cp "${TEMPLATE_DIR}/settings.local.json.template" .claude/settings.local.json
  echo "  Created: .claude/settings.local.json"
else
  echo "  Skipped: .claude/settings.local.json already exists"
fi

# ── Done ──

echo ""
echo "  Setup Complete!"
echo ""
echo "  Next steps:"
echo "    1. Edit CLAUDE.md — replace {{PLACEHOLDER}} values with your project info"
echo "    2. Edit docs/PROJECT_TODO.md — define your phases and milestones"
echo "    3. Edit .claude/hooks/arch-guard.sh — customize architecture rules"
echo "    4. Edit .claude/hooks/intent-router.sh — add keyword -> doc mappings"
echo "    5. Edit .claude/agents/*.md — customize teammate roles"
echo "    6. Start a Claude Code session and type /begin"
echo ""
