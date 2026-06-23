## Stage 4: IMPLEMENT

Implement, review, and verify in one pass.

### For each slice (in order)

| Step | Tool | What it does |
|---|---|---|
| 4a | `task`(implementer, message) | Dispatch implementer with slice + criteria + build commands + extracted patterns |
| 4b | `bash`("npm run typecheck") | Run typecheck (or equivalent from package.json) |
| 4c | `bash`("npm run lint") | Run lint |
| 4d | `bash`("npm test") | Run tests (if no test command found, skip) |
| 4e | `todowrite` | Mark slice complete |

**On failure:** Re-dispatch implementer once with the error output appended. If still fails, log it in the PR body and continue.

### After all slices

| Step | Tool | What it does |
|---|---|---|
| 4f | `task`(reviewer, message) | Single review pass on the full diff |
| 4g | — | Parse reviewer output for `[EDIT]` lines and apply them automatically. Then re-run 4b-4d. No round counters. |

### Reviewer message template

```
Review this diff. Context: <brief>.
Focus on correctness, edge cases, security, and alignment with the acceptance criteria.
Start your response with one of:
- APPROVED
- CHANGES_REQUESTED: <reason>
Then list each specific issue as a bullet point.

For each change needed, output on its own line:
[EDIT] path/to/file | exact old text | exact new text
The orchestrator will auto-apply these.
```

### Auto-apply convention

Parse reviewer output for lines matching `[EDIT] path | old | new`. Call `edit(filePath, oldString, newString)` for each one. If a match fails, log it and continue — don't block the whole review.
