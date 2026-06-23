## Stage 3: ANALYZE

Understand the codebase enough to implement.

| Step | Tool | What it does |
|---|---|---|
| 3a | `glob`(pattern) | Find relevant files |
| 3b | `grep`(pattern) | Find existing patterns and conventions |
| 3c | `task`(explore) | If the feature spans multiple areas, dispatch an explore agent |
| 3d | `todowrite` | Mark ANALYZE complete |

**Skip the explore task** if the feature is small and well-understood (one file, one component). Read relevant files directly.

**Pattern extraction:** Before dispatching the implementer, extract key conventions from existing code (registration patterns, path conventions, build config). Pass these as structured context to the implementer.
