## Stage 1: SELECT

Pick or create a work item.

| Step | Tool | What it does |
|---|---|---|
| 1a | `gh-issue_list`(limit=10, state="open") | Fetch open issues |
| 1b | `gh-pr_list`(limit=5, state="open") | Fetch open PRs |
| 1c | `question` | Present options to user, or accept free-text |
| 1d | `gh-issue_create` | If free-text, create tracking issue |
| 1e | `gh-issue_view`(number=N) | Detect labels for branch prefix: `bugfix/`, `feature/`, `docs/`, `chore/` |

If the session already has an explicit target (issue/PR number), skip to Stage 2.
