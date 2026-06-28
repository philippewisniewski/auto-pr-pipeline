# Auto-PR Pipeline

OpenCode Pipeline that auto-processes GitHub issues and PRs via [opencode](https://opencode.ai). Submit a feature request, bug report, or `gh pr create` — the pipeline analyzes, implements, reviews, and opens a PR automatically.

## Quick Start (This Repo)

1. **Enable PR creation** in this repo's settings:

   `Settings → Actions → General → Workflow permissions`
   → **Read and write permissions**
   → **Allow GitHub Actions to create and approve pull requests** ✅

2. **Create an issue** — the pipeline runs automatically and opens a PR.

3. **Optional: Add API keys** as GitHub Secrets for more capable models:
   - `ANTHROPIC_API_KEY` — Claude models
   - `OPENAI_API_KEY` — GPT models

   If neither is set, the free `opencode/big-pickle` model is used.

## Use in Any Repo (Global Install)

Install the skill globally so the pipeline is available from any directory:

```bash
# Install the global skill once
mkdir -p ~/.config/opencode/skills/auto-pr-pipeline/
cp .opencode/skills/auto-pr-pipeline/SKILL.md ~/.config/opencode/skills/auto-pr-pipeline/SKILL.md

# Point opencode to the global skill
echo '{"instructions": ["skills/auto-pr-pipeline/SKILL.md"]}' > ~/.config/opencode/opencode.jsonc
```

Then in any repo:

```bash
cd ~/some-project
opencode "fix the login timeout bug"
```

**The AI auto-bootstraps the repo on first use:**
1. Creates `.github/workflows/auto-pr-pipeline.yml` — a caller workflow that delegates to the central pipeline
2. Creates `opencode.json` at the repo root (if missing)
3. Enables PR creation via the GitHub API
4. Commits and pushes these bootstrap files
5. Proceeds to fulfill your request, handling all git operations itself (since no workflow is in place yet)

On subsequent runs, the workflow catches the trigger and the full CI pipeline runs automatically. Zero manual setup per repo.

## Usage

| Trigger | How |
|---------|-----|
| **New issue** | Create an issue → pipeline auto-detects intent (feature / bugfix / triage) → runs full pipeline → opens PR |
| **New PR** | Open a PR → pipeline runs a review and posts results as a comment |
| **Comment `/opencode`** | Comment `/opencode <request>` on an issue or PR → pipeline interprets the request and acts |
| **Comment `/opencode plan`** | Asks the pipeline to produce a plan document (no code changes) |
| **Local `opencode`** | Run `opencode "<request>"` in any repo with the global skill installed → auto-bootstraps if needed |

## Pipeline Phases

```
→ Preamble: Bootstrap — One-time repo setup (if no workflow present)
  Creates the caller workflow, opencode.json, enables PR creation,
  commits and pushes bootstrap files.

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
  On bootstrap runs, creates the PR directly. On subsequent runs, the
  GitHub Actions workflow reads these files to create the PR.
```

## Tools & Agents

| Agent | Role |
|-------|------|
| **Primary** | Orchestrates the pipeline — detects intent, slices work, delegates |
| **Explore** | Read-only codebase exploration during Phase 3 |
| **General** | Implements slices (Phase 4) and reviews diffs (Phase 5) |

## How the Workflow Works

### Central Workflow (this repo)

`.github/workflows/auto-pr-pipeline.yml` runs on:
- `workflow_call` — so other repos can call it as a reusable workflow
- `issues: [opened, reopened]` — auto-trigger
- `pull_request: [opened, synchronize, reopened]` — auto-review (skips branches starting with `opencode/` to prevent recursive loops)
- `issue_comment` — when a comment contains `/opencode` or `/oc`
- `pull_request_review_comment` — when a review comment contains `/opencode` or `/oc`

The workflow:
1. Checks out the repo with full git history
2. Runs opencode with the `auto-pr-pipeline` skill loaded
3. Pushes any changes and creates/updates a PR via the post-step

### Caller Workflow (other repos)

Other repos use a 12-line caller workflow that delegates here:

```yaml
name: auto-pr-pipeline
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, reopened]
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
jobs:
  run:
    uses: philippewisniewski/auto-pr-pipeline/.github/workflows/auto-pr-pipeline.yml@main
```

This caller is auto-created by the AI during the bootstrap step — no manual setup needed.

## Architecture

```
                  ┌─────────────────────────────┐
                  │  Any GitHub Repo             │
                  │  .github/workflows/          │
                  │    caller-*.yml ───┐         │
                  └───────────────────│─────────┘
                                      │ uses:
                                      ▼
                  ┌─────────────────────────────────────┐
                  │  auto-pr-pipeline (central repo)     │
                  │  .github/workflows/auto-pr-pipeline │
                  │    .yml [workflow_call + triggers]  │
                  │  .opencode/skills/auto-pr-pipeline/ │
                  │    SKILL.md                         │
                  └─────────────────────────────────────┘
                                      │ runs opencode with
                                      ▼
                  ┌─────────────────────────────────────┐
                  │  OpenCode Agent (auto-pr-pipeline   │
                  │  skill)                             │
                  │  → Preamble: Bootstrap (if needed)  │
                  │  → Phase 1-6: Full pipeline         │
                  └─────────────────────────────────────┘
```
