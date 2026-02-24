# /build — Build Orchestrator

## Usage

```
/build Phase1                   # Run next pending session
/build Phase1 session {N}       # Run specific session
/build TASK-{ID}                # Run single task
/build Phase1 status            # Show current progress
```

## Arguments

- `$ARGUMENTS` — The build target

---

## Orchestration Flow

### Step 1: Read Current State

```
Read: docs/PROJECT_TODO.md         (index — phase dashboard)
Read: docs/phases/{active}.md      (active phase — task checkboxes)
Read: LESSONS.md
```

Determine:
- Which tasks are already completed (checked off in active phase file)
- Which group of tasks is next
- Any lessons or patterns to watch for

### Step 2: Show Plan to User

Present the build plan and wait for confirmation:

```
Build Phase — Session {N}

Tasks to build:
  - {TASK}: {title} -> {agent}
  - {TASK}: {title} -> {agent}

Agents needed: {list}
Estimated scope: {files count}

Proceed? (y/n)
```

Do NOT proceed without user confirmation.

### Step 3: Spawn Agent Team (if parallel work needed)

Create a team and spawn agents as teammates:
- Each agent gets their task spec and relevant context
- Independent tasks run in parallel
- Dependent tasks are sequenced with blockedBy

### Step 4: Monitor Progress

Wait for agent completion messages. For each completed task:
- Verify validation commands passed
- Note any issues reported

### Step 5: Run Integration Check

After all agents report completion:
- Run full project typecheck
- Run build
- Run lint

### Step 6: Report Results

```
Session {N} Complete

Results:
  - TASK-{ID}: {title} — PASS
  - TASK-{ID}: {title} — PASS

Integration:
  - typecheck: PASS
  - build: PASS
  - lint: PASS

Next: Session {N+1}
```

### Step 7: Update TODO Files

With user confirmation:
- Mark completed tasks in active phase file
- Update Phase Dashboard Done count in index
- Add session entry to Work Log

### Step 8: Cleanup

Shutdown agents and delete team after all confirm.

---

## Status Mode (`/build PhaseN status`)

Show current progress with per-session breakdown.

---

## Error Handling

### Agent Fails Validation
1. Send error details to agent with fix request
2. Agent fixes and re-runs validation
3. If still failing after 2 attempts, escalate to lead

### Integration Check Fails
1. Identify which task broke the build
2. Send fix to responsible agent (or fix directly)
3. Re-run integration check after fix
