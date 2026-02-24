---
name: work-init
description: Initialize 3-document task memory system for big tasks. Creates plan.md, context.md, checklist.md in docs/work/{task-name}/. Use when starting a non-trivial task that spans multiple files or sessions.
triggers:
  - work init
  - task init
  - init work
  - big task
---

# Work Init — 3-Document Task Memory System

When starting a non-trivial task (multi-file, multi-session), create 3 documents to prevent memory loss.

## When to Activate

Activate automatically when:
- Task touches 3+ files
- Task involves multiple modules/domains
- Task requires more than 1 session to complete
- User explicitly says "work init" or "big task"

Do NOT activate for:
- Single file edits
- Quick bug fixes
- Documentation-only changes

## Workflow

### Step 1: Create Task Folder

```
docs/work/{task-name}/
├── plan.md          # What to build (blueprint)
├── context.md       # Why these decisions (specification)
└── checklist.md     # What's done, what's left (progress)
```

`{task-name}` should be kebab-case (e.g., `auth-system-impl`, `api-endpoints`).

### Step 2: Write plan.md

```markdown
# {Task Name} — Plan

## Goal
[One sentence: what does "done" look like?]

## Scope
- Files to create: [list]
- Files to modify: [list]
- Files NOT touched: [explicit exclusions]

## Steps (ordered)
1. [Step with expected output]
2. [Step with expected output]
3. ...

## Dependencies
- [What must exist before this task starts]
- [Related tasks or blockers]

## Estimated Size
- Files: [count]
- Modules: [which ones]
- Sessions: [estimate]
```

### Step 3: Write context.md

```markdown
# {Task Name} — Context

## Decision Log
| Date | Decision | Reason | Alternatives Considered |
|------|----------|--------|------------------------|

## Key References
- [Relevant docs, files, or external links]

## Assumptions
- [What we're assuming to be true]

## Risks
- [What could go wrong]
```

### Step 4: Write checklist.md

```markdown
# {Task Name} — Checklist

## Status: IN PROGRESS
Started: {date}
Last Updated: {date}

## Tasks
- [ ] Step 1 description
- [ ] Step 2 description
- [ ] Step 3 description
...

## Completed
(move items here when done)
- [x] {description} — {date}
```

## During Work

- Before each work session: Read checklist.md to know where you left off
- After completing a step: Update checklist.md (move [ ] to [x] with date)
- When making a decision: Add entry to context.md Decision Log
- When scope changes: Update plan.md

## On Completion

1. Move all items in checklist.md to Completed
2. Set status to COMPLETED with end date
3. Update docs/PROJECT_TODO.md to reflect completion
4. Add final context.md entry summarizing outcome

## Rules

1. NEVER skip creating these 3 documents for qualifying tasks
2. ALWAYS update checklist.md after completing each step
3. ALWAYS log decisions in context.md with reasoning
4. NEVER delete work folders — they serve as project memory
