Read the TODO system (index + active phase file) and perform the requested operation.

Arguments: $ARGUMENTS

## Operations

### No arguments (status view)
If no arguments provided, show a concise status dashboard:
1. Read `docs/PROJECT_TODO.md` -> find active phase from Phase Dashboard
2. Read active phase file -> get task status
3. Show:
   - Current phase and overall progress percentage
   - Active/in-progress tasks
   - Next pending tasks (top 3 from current phase)
   - Blockers if any
   - Last Work Log entry
Format: compact table

### `start <task-keyword>`
Find the matching pending task in the active phase file by keyword search:
1. Change `- [ ]` to `- [x]` and add `In Progress` marker
2. Add `| Started: YYYY-MM-DD` to the task line
3. Update Current Focus in `docs/PROJECT_TODO.md` (index)
4. Save both files
5. Confirm what was started

### `done <task-keyword>`
Find the matching in-progress task in the active phase file:
1. Show the task to user and ask: "Mark this as done?"
2. **Wait for user confirmation.** Do NOT proceed without it.
3. After confirmation: Remove `In Progress` marker
4. Add `Completed | Completed: YYYY-MM-DD`
5. Update Progress Summary table in phase file
6. Update Work Log in `docs/PROJECT_TODO.md` (index) with completion note
7. Increment Phase Dashboard Done count in index
8. Save both files
9. Show next pending task

### `add <phase> <task-description>`
Add a new pending task to the specified phase file:
1. Find the phase file
2. Add `- [ ] **<task>**` at the end of the appropriate section
3. Save the file

### `block <task-keyword> <reason>`
Mark a task as blocked in the active phase file:
1. Add `Blocked: <reason>` to the task line
2. Save the file

### `log <message>`
Add an entry to today's Work Log section in `docs/PROJECT_TODO.md` (index):
1. Find or create today's date header (`### YYYY-MM-DD`)
2. Add `- <message>` under it
3. Save the file

### `phase`
Read the active phase file and show detailed breakdown with completion percentages per section.

### `next`
Read the active phase file for the single next pending task, with its description and related files.

### `history`
Show last 5 Work Log entries from `docs/PROJECT_TODO.md` (index).

## Rules
- Use Edit tool on both files. Phase file for task status, index for Work Log and dashboard.
- Keep all existing formatting and structure
- After any modification, show brief confirmation (1-2 lines)
