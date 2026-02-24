---
name: team
description: Spawn and manage teammates using Claude Code's built-in Agent Teams feature. Each teammate is an independent Claude Code instance with its own context window.
user-invocable: true
allowed-tools: Bash, Read, Grep, Glob
---

# Agent Teams — Template

## What This Is

Claude Code's built-in Agent Teams feature. Spawn independent teammates for parallel work.
Each teammate has its own context window, loads CLAUDE.md, MCP servers, and skills automatically.
The lead's conversation history does NOT carry over to teammates.

## Display Modes

| Mode | How | Terminal requirement |
|------|-----|---------------------|
| **in-process** (default) | All teammates in one terminal. Shift+Down to cycle. | Any terminal |
| **split-pane** | Each teammate in its own tmux/iTerm2 pane. | tmux or iTerm2 only |
| **auto** | split-pane if inside tmux session, otherwise in-process. | None |

In-process controls:
- **Shift+Down**: cycle through teammates
- **Enter**: view a teammate's session
- **Escape**: interrupt their current turn
- **Ctrl+T**: toggle task list

## NEVER Do This

- Do NOT write bash scripts that execute `claude` CLI directly
- Do NOT run `claude --help` to figure out flags
- Do NOT manually create tmux panes or sessions
- Agent Teams is built into Claude Code. Describe the team in natural language.

## How To Use

Describe the team structure in natural language. Claude Code uses its internal tools (TeamCreate, TaskCreate, SendMessage, etc.) automatically.

### Spawn Examples

```
Implement the user authentication system.
Create an agent team:
- backend-developer: Auth service + database schema + middleware
- frontend-developer: Login/signup pages + auth state management
- test-engineer: Auth service tests + E2E login flow tests
Each teammate only modifies files in their own domain.
```

## Agent Roles

Agent roles are defined in `.claude/agents/` directory.
When spawning teammates, include the relevant agent file contents in each teammate's prompt.

**CRITICAL: Always use `subagent_type: "general-purpose"` for all teammates.**

| Agent | Model | Domain | subagent_type |
|-------|-------|--------|---------------|
| `backend-developer` | opus | Server, domain logic, DB, API | **general-purpose** |
| `frontend-developer` | opus | UI, pages, components, state | **general-purpose** |
| `test-engineer` | opus | Tests across all packages | **general-purpose** |
| `docs-writer` | sonnet | Docs, README, LESSONS | **general-purpose** |

## When NOT To Spawn

- Single file edit
- Work within a single module
- Documentation-only changes
- Questions / confirmations / reviews
- Sequential tasks with many dependencies

## Spawn Procedure

1. Analyze task -> determine required agent roles
2. Notify user: "Composing team: [agent list]"
3. Read `.claude/agents/{name}.md` and include in each teammate's spawn prompt
4. Describe team in natural language
5. Lead monitors progress + synthesizes results
6. Report to user when done (completion requires user confirmation only)

## File Conflict Prevention

- Each teammate only modifies files in their own domain
- If two teammates need the same file, process sequentially
- Recommended team size: 2-5

## Known Limitations

- Custom agents in `.claude/agents/` may not receive MCP tools. Use `general-purpose` agent type.
- One team per session. Clean up before starting a new one.
- Teammates cannot spawn their own teams (no nesting).
