# Claude Auto-Dev System

**Turn Claude Code into an autonomous development partner with persistent memory, architecture enforcement, and team orchestration.**

> A production-tested framework extracted from a real Electron + TypeScript + DDD project.
> Drop it into any project — Claude Code becomes session-aware, architecture-enforcing, and team-ready.

## What This Does

Without this system, every Claude Code session starts from zero. With it:

| Problem | Solution |
|---------|----------|
| Claude forgets what you did last session | **Session Restore** hook auto-detects in-progress work |
| Claude doesn't know your project's architecture rules | **Architecture Guard** hooks block violations + inject context |
| External research gets lost between sessions | **Research Cache** forces all WebSearch/Context7 results into local docs |
| No progress tracking across sessions | **Hierarchical TODO** system with phase dashboard + work log |
| Manual "read this file first" every time | **Intent Router** auto-suggests relevant docs based on keywords |
| Claude marks things done without asking | **No Unilateral Completion** rule — only you decide when tasks are done |
| Scaling to parallel work is manual | **Agent Teams** with role-based agents + file conflict prevention |

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Claude Code Session                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  CLAUDE.md ──> Auto Behaviors (6 protocols)             │
│       │        Planning | Coding | Review               │
│       │        Wrap | Research | Git                     │
│       │                                                 │
│       ▼                                                 │
│  .claude/                                               │
│  ├── settings.json ── Hook wiring + permissions         │
│  ├── hooks/ ───────── 8 shell scripts                   │
│  │   ├── SessionStart ──> session-restore.sh            │
│  │   ├── UserPromptSubmit ──> intent-router.sh          │
│  │   ├── PreToolUse ──┬──> research-cache-guard.sh      │
│  │   │                ├──> research-cache-check.sh      │
│  │   │                ├──> arch-guard.sh                │
│  │   │                ├──> arch-docs-guard.sh           │
│  │   │                └──> arch-commit-guard.sh         │
│  │   └── PostToolUse ─┬──> research-cache-remind.sh     │
│  │                    └──> arch-post-check.sh           │
│  ├── commands/ ────── 6 slash commands                  │
│  │   /begin /wrap /todo /commit /build /review          │
│  ├── skills/ ──────── Domain knowledge                  │
│  │   work-init (3-doc memory) + team (agent teams)      │
│  └── agents/ ──────── Teammate role definitions         │
│      backend + frontend + test-engineer + docs-writer   │
│                                                         │
│  Persistent State                                       │
│  ├── docs/PROJECT_TODO.md ─── Phase Dashboard           │
│  ├── docs/phases/*.md ─────── Task Checkboxes           │
│  ├── docs/work/*/ ─────────── Active Task Memory        │
│  ├── docs/research/ ───────── Cached External Knowledge │
│  └── LESSONS.md ───────────── Mistake Patterns          │
└─────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Clone this repo somewhere accessible
git clone https://github.com/oceangim/claude-auto-dev-system.git

# 2. Go to YOUR project
cd /path/to/your-project

# 3. Run setup (creates .claude/, docs/, CLAUDE.md, LESSONS.md)
bash /path/to/claude-auto-dev-system/setup.sh

# 4. Customize (replace {{PLACEHOLDER}} values)
#    - CLAUDE.md: project name, tech stack, coding standards
#    - .claude/hooks/arch-guard.sh: your architecture rules
#    - .claude/hooks/intent-router.sh: your keyword→doc mappings
#    - .claude/agents/*.md: your team role definitions

# 5. Start a session
#    Type /begin in Claude Code
```

## What Gets Created

```
your-project/
├── CLAUDE.md                          # Project config + auto behaviors
├── LESSONS.md                         # Mistake pattern tracker
├── .claude/
│   ├── settings.json                  # Hook wiring + permissions
│   ├── settings.local.json            # MCP + model settings
│   ├── hooks/
│   │   ├── session-restore.sh         # Detects in-progress work on session start
│   │   ├── intent-router.sh           # Suggests relevant docs by keyword
│   │   ├── research-cache-guard.sh    # Blocks until research is cached
│   │   ├── research-cache-check.sh    # Checks cache before external calls
│   │   ├── research-cache-remind.sh   # Forces caching after external calls
│   │   ├── arch-guard.sh             # Blocks architecture violations
│   │   ├── arch-docs-guard.sh        # Warns on terminology misuse in docs
│   │   ├── arch-commit-guard.sh      # Warns on cross-module commits
│   │   └── arch-post-check.sh        # Reminds verification after code writes
│   ├── commands/
│   │   ├── begin.md                   # /begin — start session, read state
│   │   ├── wrap.md                    # /wrap — end session, update TODO
│   │   ├── todo.md                    # /todo — manage tasks
│   │   ├── commit.md                  # /commit — conventional commits
│   │   ├── build.md                   # /build — orchestrate parallel builds
│   │   └── review.md                  # /review — quality gate reviews
│   ├── skills/
│   │   ├── work-init/SKILL.md         # 3-doc task memory system
│   │   └── team/SKILL.md             # Agent team management
│   └── agents/
│       ├── backend-developer.md
│       ├── frontend-developer.md
│       ├── test-engineer.md
│       └── docs-writer.md
└── docs/
    ├── PROJECT_TODO.md                # Phase dashboard + work log
    ├── phases/                        # Task checkboxes per phase
    ├── work/                          # Active task memory (3-doc folders)
    └── research/
        ├── 00_INDEX.md                # Research cache index
        ├── TEMPLATE.md                # Cache document template
        ├── searches/                  # WebSearch results
        ├── apis/                      # WebFetch results
        └── libraries/                 # Context7 library docs
```

## Components

### Hooks (8 scripts)

The core automation layer. Shell scripts that fire on Claude Code events.

| Hook | Event | What It Does |
|------|-------|-------------|
| **session-restore** | SessionStart | Scans `docs/work/` for IN PROGRESS tasks, injects context so Claude resumes where you left off |
| **intent-router** | UserPromptSubmit | Pattern-matches your prompt against keywords, suggests relevant project docs to read first |
| **research-cache-check** | PreToolUse | Before any WebSearch/WebFetch/Context7 call, checks if the answer is already cached locally |
| **research-cache-guard** | PreToolUse | If a previous research result hasn't been cached yet, **blocks all other tool calls** until you cache or skip it |
| **research-cache-remind** | PostToolUse | After any external lookup completes, creates a pending state that triggers the guard |
| **arch-guard** | PreToolUse | **Blocks** architecture violations (e.g., infrastructure imports in domain layer) and injects layer-specific guidance |
| **arch-docs-guard** | PreToolUse | **Warns** (asks permission) when documentation uses wrong domain terminology |
| **arch-commit-guard** | PreToolUse | **Warns** when a git commit touches multiple modules/domains |
| **arch-post-check** | PostToolUse | After writing code, reminds a verification checklist specific to that layer |

### Slash Commands (6 commands)

| Command | Purpose |
|---------|---------|
| `/begin` | Start session: reads TODO state, finds in-progress work, suggests next task |
| `/wrap` | End session: marks progress, writes work log, commits, updates LESSONS.md |
| `/todo [op]` | Manage tasks: `status`, `start`, `done`, `add`, `block`, `log`, `next`, `phase`, `history` |
| `/commit` | Git commit: analyzes diff, generates conventional commit message, updates work log |
| `/build` | Build orchestrator: loads task specs, spawns agent teams, runs quality gates |
| `/review` | Quality review: pre-build spec check, code review, integration test, phase validation |

### Skills (2 skills)

| Skill | Triggers On | What It Does |
|-------|------------|-------------|
| **work-init** | Tasks touching 3+ files or spanning multiple sessions | Creates `docs/work/{task}/` with plan.md + context.md + checklist.md |
| **team** | Parallel work needed across domains | Defines agent team patterns, spawn procedures, file conflict prevention |

### Agents (4 roles)

| Agent | Model | Domain |
|-------|-------|--------|
| **backend-developer** | opus | Domain logic, database, API, external integrations |
| **frontend-developer** | opus | UI components, pages, state management |
| **test-engineer** | opus | Unit, integration, E2E tests across all packages |
| **docs-writer** | sonnet | Documentation consistency, work logs, README |

### TODO System (3 levels)

```
Level 1: docs/PROJECT_TODO.md     — Phase Dashboard, Milestones, Work Log
Level 2: docs/phases/*.md          — Task checkboxes with status markers
Level 3: docs/work/{task}/         — Active task memory (plan + context + checklist)
```

### Research Cache

Forces Claude to save all external research locally. No more re-searching the same things.

```
Flow: External call → PostToolUse creates pending state → All tools blocked
      → Claude saves to docs/research/{category}/{slug}.md → Updates 00_INDEX.md
      → Block cleared → Normal operation resumes
```

## Customization

### Choose Your Hook Level

| Level | Hooks | Best For |
|-------|-------|----------|
| **Minimal** | session-restore + intent-router | Personal projects, quick iterations |
| **Standard** | + research-cache (3 scripts) | Medium projects, external API usage |
| **Full** | + arch-guard (4 scripts) | Large projects, team dev, architecture matters |

To disable hooks you don't need, remove their entries from `.claude/settings.json`.

### Customize Architecture Guard

Edit `.claude/hooks/arch-guard.sh` — the template includes examples for:

| Pattern | Guard Strategy |
|---------|---------------|
| **DDD** | Block infra imports in domain layer, inject bounded context info |
| **Clean Architecture** | Block framework imports in entities, inject layer responsibilities |
| **MVC** | Block view imports in models, inject MVC responsibilities |
| **Modular Monolith** | Block cross-module direct imports, inject module boundaries |

### Customize Intent Router

Edit `.claude/hooks/intent-router.sh` — add keyword→doc mappings:

```bash
# Example: when user mentions "auth", suggest auth docs
if echo "$PROMPT" | grep -qiE 'auth|login|OAuth|JWT'; then
  SUGGESTIONS="${SUGGESTIONS}
- Auth Architecture: docs/auth-design.md"
fi
```

### Customize Agents

Edit `.claude/agents/*.md` — define domains, responsibilities, and rules for each teammate role.

## Project Type Recommendations

| Project Type | Hooks | Commands | Agents |
|-------------|-------|----------|--------|
| **Full-stack Web App** | Full | All 6 | backend + frontend + test |
| **Backend API** | arch + research + session | begin/wrap/todo/commit | backend + test |
| **Frontend SPA** | research + session | begin/wrap/todo/commit | frontend + test |
| **Library/SDK** | arch + research | begin/wrap/todo/commit | backend + test + docs |
| **Data Pipeline** | research + session | begin/wrap/todo/commit | backend + test |
| **Mobile App** | Full | All 6 | mobile + frontend + test |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `jq` available in PATH (used by hook scripts)
- Bash 4+ (macOS and Linux compatible)

## FAQ

**Q: Does this work with any programming language?**
A: Yes. The hooks, commands, and TODO system are language-agnostic. Only the architecture guard needs customization for your specific patterns.

**Q: Will this conflict with my existing CLAUDE.md?**
A: The setup script skips existing files. You can merge the Auto Behaviors section manually.

**Q: How do I disable a specific hook?**
A: Remove its entry from `.claude/settings.json` under the relevant event.

**Q: Does this work without MCP servers?**
A: Yes. MCP-related features (Context7, Sequential Thinking) are optional. The research cache gracefully handles their absence.

## Origin

Extracted and generalized from [ZeroO2 v3](https://zeroo2.ai) — an Electron + TypeScript + DDD desktop application with 100+ tasks across 5 development phases. Every component was battle-tested over weeks of real development before being standardized into this template.

## License

MIT
