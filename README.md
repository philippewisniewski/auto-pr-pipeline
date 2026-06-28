# Orchestrator Loop

AI-powered pipeline that auto-processes GitHub issues and PRs via [opencode](https://opencode.ai). Submit a feature request, bug report, or `gh pr create` — the pipeline analyzes, implements, reviews, and opens a PR automatically.

## Quick Start

1. **Fork or clone** this repo and push to your own GitHub account.

2. **Enable PR creation** in your repo settings:

   `Settings → Actions → General → Workflow permissions`
   → **Read and write permissions**
   → **Allow GitHub Actions to create and approve pull requests** ✅

3. **Create an issue** — the pipeline runs automatically and opens a PR.

4. **Optional: Add API keys** as GitHub Secrets for more capable models:
   - `ANTHROPIC_API_KEY` — Claude models
   - `OPENAI_API_KEY` — GPT models

   If neither is set, the free `opencode/big-pickle` model is used.

## Usage

| Trigger | How |
|---------|-----|
| **New issue** | Create an issue → pipeline auto-detects intent (feature / bugfix / triage) → runs full pipeline → opens PR |
| **New PR** | Open a PR → pipeline runs a review and posts results as a comment |
| **Comment `/opencode`** | Comment `/opencode <request>` on an issue or PR → pipeline interprets the request and acts |
| **Comment `/opencode plan`** | Asks the pipeline to produce a plan document (no code changes) |

## Pipeline Phases

```
→ Phase 1: Trigger — Intent detection
  Classifies the request: feature, bugfix, review, plan, or triage.

→ Phase 2: Intake — Context gathering
  Reads the issue/PR body, comments, and relevant GitHub context.

→ Phase 3: Analyze — Explore + Slice
  Dispatch a read-only explore agent to understand the codebase.
  Primary agent slices work into ordered units (1–3 slices).

→ Phase 4: Implement — Execute slices
  Dispatch a general agent per slice with full context.
  Runs verification (typecheck → lint → test) after each slice.

→ Phase 5: Review — Verify + Fix
  A fresh agent reviews the diff for correctness, edge cases, and security.
  Small fixes applied inline; architecture issues sent back to Phase 4.

→ Phase 6: Human Handoff — PR summary
  Writes summary files (.opencode/last-run/summary.md + meta.json).
  The GitHub Actions workflow reads these to create the PR.
```

## Tools & Agents

| Agent | Role |
|-------|------|
| **Primary** | Orchestrates the pipeline — detects intent, slices work, delegates |
| **Explore** | Read-only codebase exploration during Phase 3 |
| **General** | Implements slices (Phase 4) and reviews diffs (Phase 5) |

## How the Workflow Works

`.github/workflows/orchestrator-loop.yml` runs on:
- `issues: [opened, reopened]` — auto-trigger
- `pull_request: [opened, synchronize, reopened]` — auto-review (skips branches starting with `opencode/` to prevent recursive loops)
- `issue_comment` — when a comment contains `/opencode` or `/oc`
- `pull_request_review_comment` — when a review comment contains `/opencode` or `/oc`

The workflow:
1. Checks out the repo with full git history
2. Runs opencode with the `orchestrator-loop` skill loaded
3. Pushes any changes and creates/updates a PR via the post-step
