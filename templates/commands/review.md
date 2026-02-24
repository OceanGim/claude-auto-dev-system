# /review — Quality Review Orchestrator

## Usage

```
/review pre-build               # Review all task specs (pre-build)
/review code TASK-{ID}          # Code quality review (post-implementation)
/review integration session {N} # Session integration review
/review phase                   # Phase completion review
```

## Arguments

- `$ARGUMENTS` — The review target (gate level + optional scope)

---

## Pre-Build Review (Spec Quality)

> Validates spec/plan quality before any code is written.

### Steps
1. Load all task specs and project docs
2. Check for:
   - Dependency consistency
   - File manifest conflicts (no two tasks create same file)
   - TODO mapping accuracy
   - Scope clarity
3. Report issues with severity (HIGH/MEDIUM/LOW)
4. Fix HIGH issues before proceeding to /build

---

## Code Review (Post-Implementation)

> Reviews code quality after implementation.

### Steps
1. Identify scope (which files were created/modified)
2. Check:
   - Architecture compliance
   - Type consistency across packages
   - Security (no hardcoded secrets, proper auth)
   - Error handling (no silent failures)
   - Pattern consistency (naming, imports, structure)
3. Report per-file issues with severity
4. HIGH issues must be fixed before integration

---

## Integration Review (Post-Session)

> Full validation after completing a group of tasks.

### Steps
1. Run full project typecheck + build + lint
2. Check cross-package type consistency
3. Verify dependency audit
4. Report results

---

## Phase Review (Phase Completion)

> Comprehensive review when a phase is done.

### Steps
1. Run all test suites
2. Check coverage targets
3. Run E2E smoke tests (if applicable)
4. Performance baseline check
5. Report overall phase quality

---

## Review Flow Summary

```
Pre-Build:     /review pre-build        -> Spec quality check
                                           (all specs valid)
Per-Task:      /review code TASK-X      -> Code quality
                                           (code is correct)
Per-Session:   /review integration N    -> Integration check
                                           (everything works)
Phase End:     /review phase            -> Full validation
                                           (ready for production)
```
