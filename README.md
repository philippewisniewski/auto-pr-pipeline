# Orchestrator Loop v2

**Lightweight autonomous feature implementation for OpenCode.** Takes a GitHub issue and produces a tested PR. Built entirely on OpenCode built-in tools — no custom tools, no external skills, no META phase.

> This is not a standalone CLI tool. It's an **OpenCode skill** that turns OpenCode's agent runtime into an autonomous feature factory.

---

## How It Works (10-Second View)

1. **You pick a work item** — The orchestrator lists open issues, you select one (or type free-text)
2. **It runs autonomously** through 5 stages: SELECT → INTAKE → ANALYZE → IMPLEMENT → MERGE
3. **You review the result** — A PR is opened with tested code. You approve and merge.

---

## The 5 Stages

### Stage 1: SELECT

Pick or create a work item.

| Step | Tool | What it does |
|---|---|---|
| 1a | `gh-issue_list` | Fetch open issues (limit 10) |
| 1b | `gh-pr_list` | Fetch open PRs (limit 5) |
| 1c | `question` | Present options to user, or accept free-text |
| 1d | `gh-issue_create` | If free-text, create tracking issue |
| 1e | `gh-issue_view` | Detect labels → branch prefix |

### Stage 2: INTAKE

Understand the work item.

| Step | Tool | What it does |
|---|---|---|
| 2a | `gh-issue_view`(includeComments=true) | Get title, body, comments, labels |
| 2b | `read`(package.json) | Get build/lint/test commands |
| 2c | `todowrite` | Mark complete; add 1-3 slice items |

### Stage 3: ANALYZE

Understand the codebase.

| Step | Tool | What it does |
|---|---|---|
| 3a | `glob` | Find relevant files |
| 3b | `grep` | Find existing patterns and conventions |
| 3c | `task`(explore) | If needed for multi-area features |
| 3d | `todowrite` | Mark ANALYZE complete |

### Stage 4: IMPLEMENT

Implement and verify in one pass.

For each slice:

| Step | Tool | What it does |
|---|---|---|
| 4a | `task`(implementer) | Dispatch implementer with slice + criteria |
| 4b | `bash`("npm run typecheck") | Run typecheck |
| 4c | `bash`("npm run lint") | Run lint |
| 4d | `bash`("npm test") | Run tests |
| 4e | `todowrite` | Mark slice complete |

After all slices:

| 4f | `task`(reviewer) | Single review pass on the full diff |
|---|---|---|
| 4g | — | If CHANGES_REQUESTED, fix inline and re-run checks |

### Stage 5: MERGE

Create a branch, commit, push, and open a PR.

| Step | Tool | What it does |
|---|---|---|
| 5a | `bash`("git checkout -b {prefix}N-name") | Create branch |
| 5b | `bash`("git add -A && git commit -m 'msg'") | Commit with issue reference |
| 5c | `bash`("git push origin HEAD") | Push |
| 5d | `gh-pr_create` | Open PR with description and issue reference |

---

## Work Type Detection

| Label | Branch prefix |
|---|---|
| `bug`, `bugfix` | `bugfix/` |
| `hotfix`, `critical` | `hotfix/` |
| `docs`, `documentation` | `docs/` |
| `chore`, `dependencies` | `chore/` |
| `enhancement`, `feature` | `feature/` |
| *(no match)* | `feature/` |

Override with natural language: "implement this bugfix issue".

---

## Installation

### Prerequisites

- [OpenCode](https://opencode.ai) installed
- `jq` (optional — for automatic config merging): `brew install jq`

### Install

```bash
git clone https://github.com/philippewisniewski/orchestrator-loop.git
cd orchestrator-loop
bash install.sh
```

This copies the skill and agent definitions to `~/.config/opencode/` and merges the orchestrator agent into your global OpenCode config.

### Uninstall

```bash
bash uninstall.sh
```

---

## Usage

1. Navigate to any project repo: `cd my-project`
2. Open OpenCode: `opencode`
3. Switch to the `orchestrator` agent (Tab key)
4. Select a work item when prompted
5. Let it run — the loop is fully autonomous after selection

---

## What's Different from v1

| v1 (496 lines, 8 phases) | v2 (~100 lines, 5 stages) |
|---|---|
| Custom TypeScript tools for GitHub | OpenCode built-in `gh-issue_*` / `gh-pr_*` tools |
| 3 peer skills (diagnose, to-issues, to-prd) | No peer skills |
| 3 prompt files (orchestrator, implementer, meta-analyst) | All instructions inline in SKILL.md |
| 3-round review loop with feedback injection | Single review pass |
| Separate TEST phase | Tests run inline in IMPLEMENT |
| META phase with session traces and analysis | Dropped |
| Findings board for cross-slice sharing | Dropped |
| Pre-merge review gate | Dropped |
| BLOCKER escalation protocol | Dropped |
| GitHub Actions workflow | Kept |

---

## License

MIT
