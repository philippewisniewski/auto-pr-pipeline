# Auto-PR Pipeline

An AI pipeline that auto-processes GitHub issues and PRs. Create an issue, open a PR, or comment `/opencode` — the pipeline analyzes, implements, reviews, and opens a PR automatically.

Powered by [opencode](https://opencode.ai).

---

## How It Works

```
GitHub Event (issue / PR / comment)
  │
  ▼
GitHub Actions Workflow ─── runs opencode with the auto-pr-pipeline skill
  │                              │
  │                              ▼
  │                         AI Agent:
  │                         → Preamble: Bootstrap repo (first use only)
  │                         → Phase 1:  Detect intent (bug / feature / review / plan / triage)
  │                         → Phase 2:  Gather context (issue body, comments, codebase)
  │                         → Phase 3:  Explore codebase, slice work into steps
  │                         → Phase 4:  Implement each slice with verification
  │                         → Phase 5:  Review diff for correctness and edge cases
  │                         → Phase 6:  Write summary files
  │                              │
  │                              ▼
  └── Push commits + Create PR ──┘
```

---

## Prerequisites

- A **GitHub account**
- **Admin access** to the repo you want to use (needed to enable PR creation in settings)
- **opencode CLI** installed ([docs](https://opencode.ai))
- Optional: `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` for better AI models (falls back to free `opencode/big-pickle` if unset)

---

## Quick Start (This Repo)

1. **Clone and enable PR creation**

   ```bash
   git clone https://github.com/philippewisniewski/auto-pr-pipeline.git
   cd auto-pr-pipeline
   ```

   Then go to `Settings → Actions → General → Workflow permissions` and enable:
   - **Read and write permissions**
   - **Allow GitHub Actions to create and approve pull requests**

   > ⚠️ You need **admin** access on the repo to change this setting.

2. **Create an issue** — the workflow triggers and the pipeline opens a PR automatically.

3. **(Optional) Add API keys** as repository secrets:
   - `ANTHROPIC_API_KEY` — Claude models
   - `OPENAI_API_KEY` — GPT models

   Without these, the free `opencode/big-pickle` model is used.

---

## Use in Any Repo (Global Install)

Install the skill once so the pipeline works from any directory:

```bash
# Clone the repo (if you haven't already)
git clone https://github.com/philippewisniewski/auto-pr-pipeline.git
cd auto-pr-pipeline

# Install the skill globally
mkdir -p ~/.config/opencode/skills/auto-pr-pipeline/
cp .opencode/skills/auto-pr-pipeline/SKILL.md ~/.config/opencode/skills/auto-pr-pipeline/SKILL.md

# Point opencode to the global skill
echo '{"instructions": ["skills/auto-pr-pipeline/SKILL.md"]}' > ~/.config/opencode/opencode.jsonc
```

Now in **any** repo:

```bash
cd ~/some-project
opencode "fix the login timeout bug"
```

### What happens on first use (auto-bootstrap)

The AI checks if `.github/workflows/auto-pr-pipeline.yml` exists. If not, it:

1. Creates the caller workflow file that delegates to the central pipeline
2. Creates `opencode.json` at the repo root (if missing)
3. Tries to enable PR creation via `gh api` (requires admin — warns if it fails)
4. Commits and pushes these bootstrap files
5. Fulfills your request, handling all git operations itself (there's no workflow yet)

On subsequent runs, the workflow catches the trigger and runs the full pipeline. Zero manual setup per repo.

---

## Git Workflow Detail

`.github/workflows/auto-pr-pipeline.yml` has one job with four steps:

### Step 1 — Checkout
Checks out the repo with full git history (`fetch-depth: 0`) so the AI can explore branches and diffs.

### Step 2 — Configure git
Sets `user.name` and `user.email` so any commits the AI makes have a valid author.

### Step 3 — Run opencode
Runs opencode with the auto-pr-pipeline skill. The prompt sent to the AI depends on what triggered it:

| Event | Prompt |
|-------|--------|
| New issue | `"New issue #N: title"` — AI reads the issue body via `gh` |
| Comment with `/opencode` | The comment body — AI interprets the request |
| New PR | `"New PR #N: title"` — AI reviews the diff |
| Comments on other events | Ignored (filtered by the `if` condition) |

The model is configured via the `OPENCODE_MODEL` repository variable (defaults to `opencode/big-pickle` if unset). The step uses `continue-on-error: true` so the push/PR step still runs even if opencode exits with a non-zero status.

### Step 4 — Push and create PR
Runs after opencode finishes (even on failure):

```bash
# Only push if local has commits the remote doesn't
if [ "$REMOTE_SHA" != "$LOCAL_SHA" ]; then
  git push origin "$BRANCH"
fi

# Read the summary file the AI wrote in Phase 6, create a PR
if [ -f .opencode/last-run/summary.md ]; then
  TITLE=$(head -1 summary.md | sed 's/^# //')
  gh pr create --base main --head "$BRANCH" --title "$TITLE" --body-file summary.md
fi
```

The first block avoids redundant pushes. The second block reads `summary.md` (written by the AI in Phase 6), extracts the title from the `# Heading` on line 1, and creates a PR. `|| true` silently handles cases where a PR already exists.

### Trigger filtering

The job has a guard condition that prevents wasted runs:

| Event | Runs when... |
|-------|-------------|
| Issue comment | Body contains `/opencode` or `/oc` |
| Review comment | Body contains `/opencode` or `/oc` |
| Issue | Always (opened or reopened) |
| Pull request | Always, **except** branches starting with `opencode/` (prevents the AI from re-triggering on its own PRs) |

---

## Usage

| Trigger | How |
|---------|-----|
| **New issue** | Create an issue → pipeline auto-detects intent → runs full pipeline → opens PR |
| **New PR** | Open a PR → pipeline runs a review and posts results as a comment |
| **Comment `/opencode`** | Comment `/opencode <request>` on an issue or PR → pipeline acts on the request |
| **Comment `/opencode plan`** | Produces a plan document (no code changes) |
| **Local `opencode`** | Run `opencode "<request>"` in any repo with the global skill installed → auto-bootstraps if needed |
