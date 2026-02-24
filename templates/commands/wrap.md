End the session. Update both TODO files (index + active phase file).

## Step 1: Report completed items (checkoff only after user confirmation)
List tasks completed this session and ask "Mark these as done?"
Only after user confirms, update the active phase file:
- `- [ ]` -> `- [x]`
- Add `Completed | Completed: YYYY-MM-DD`
- Update Progress Summary table

**Marking tasks complete without user confirmation is treated as false reporting.**

## Step 2: Mark in-progress items
Add `In Progress` marker to tasks still in progress in the active phase file (skip if none)

## Step 3: Write Work Log
Add entry to Work Log section in `docs/PROJECT_TODO.md` (index):
```markdown
### YYYY-MM-DD
- [what was done specifically]
- [files changed]
- [remaining work if any]
```
Update Phase Dashboard Done count in index if tasks were completed.

## Step 4: Git commit (after user confirmation)
1. `git status` to check changed files
2. Generate conventional commit message and show to user
3. After confirmation: `git add -A && git commit`

## Step 5: Update Work Documents (if active)
1. Check `docs/work/` for any IN PROGRESS task folders
2. For each active folder:
   - Update `checklist.md`: mark completed steps, add date
   - Update `context.md`: log any decisions made this session
   - If all checklist items done: set status to COMPLETED

## Step 6: Record new lessons (only if applicable)
If new mistake patterns or lessons emerged this session, add to LESSONS.md.
Skip if nothing new.

## Rules
- Use Edit tool to modify specific sections only (never overwrite entire file)
- Report failures honestly (no sugarcoating)
- After logging: output "Session closed. Run `/begin` to start next session."
