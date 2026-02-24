Perform a git commit following Git Protocol.

Arguments: $ARGUMENTS

## Step 1: Check changes
```bash
git status
git diff --stat
```

## Step 2: Generate commit message
Analyze changes and generate a conventional commit message.

Types:
- `feat:` new feature
- `fix:` bug fix
- `docs:` documentation
- `refactor:` refactoring
- `style:` formatting
- `test:` tests
- `chore:` config, build, other

Format: `type(scope): description`
Example: `feat(auth): add OAuth2 login flow`

If $ARGUMENTS provided, incorporate into commit message.

## Step 3: User confirmation
Show the commit message and ask for approval.
```
Commit: feat(auth): add OAuth2 login flow
Changed files: 5
```

## Step 4: Execute commit
After confirmation:
```bash
git add -A
git commit -m "commit message"
```

## Step 5: Update TODO Work Log
Add commit details to Work Log section in `docs/PROJECT_TODO.md` (index).
If today's date header exists, append under it. Otherwise create new header.

```markdown
### YYYY-MM-DD
- [commit message content]
```

## Rules
- Always get user confirmation before committing
- Use Edit tool for Work Log (modify section only)
- After commit: `git log --oneline -1` to show result
