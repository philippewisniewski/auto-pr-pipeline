# Orchestrator Loop

**Autonomous feature implementation for opencode.** Takes a work item (GitHub issue, PR, or free-text description) and produces a tested branch with an open PR — all within opencode's agent framework.

> This is not a standalone CLI tool. It's an **opencode skill pack** that turns opencode's agent runtime into an autonomous feature factory.

---

## How It Works (30-Second View)

1. **You pick a work item** — The orchestrator lists open issues/PRs, you select one (or type free-text)
2. **It runs autonomously** through 8 phases: INTAKE → ANALYZE → DECOMPOSE → IMPLEMENT → TEST → VERIFY → MERGE → META
3. **You review the result** — A PR is opened on your repo with tested code. You approve and merge.

---

## Installation

### Prerequisites

- [opencode](https://opencode.ai) installed
- `jq` (optional — for automatic config merging): `brew install jq`

### Install

```bash
git clone https://github.com/philippewisniewski/orchestrator-loop.git
cd orchestrator-loop
bash install.sh
```

This copies all skills, prompts, tools, and agent definitions to `~/.config/opencode/` and merges the orchestrator agent into your global opencode config.

### Uninstall

```bash
bash uninstall.sh
```

Removes all installed skills, prompts, and tools. The agent definitions in `opencode.json` are left for manual cleanup.

---

## User Guide

### Basic Usage

1. Navigate to any project repo: `cd my-project`
2. Open opencode: `opencode`
3. Switch to the `orchestrator` agent (Tab key)
4. Select a work item when prompted — the orchestrator lists open issues and PRs
5. Let it run — the loop is fully autonomous after selection

### Plan → Implement Workflow

For complex features, use opencode's **Plan mode** first:

1. Enter Plan mode (`Cmd+Shift+P` or `/plan`)
2. Describe the feature at a high level
3. The agent produces a structured plan
4. Switch to the `orchestrator` agent
5. Say "implement this plan"
6. The orchestrator detects the plan in conversation history, creates a tracking issue, and runs through all 8 phases

### Work Type Detection

The orchestrator reads issue labels to determine the branch prefix:

| Label | Branch prefix |
|---|---|
| `bug`, `bugfix` | `bugfix/` |
| `hotfix`, `critical` | `hotfix/` |
| `docs`, `documentation` | `docs/` |
| `chore`, `dependencies` | `chore/` |
| `enhancement`, `feature` | `feature/` |
| *(no match)* | `feature/` |

Override with natural language: "implement this bugfix issue".

### GitHub Actions (CI Mode)

The repo includes `.github/workflows/orchestrator-loop.yml` for trigger-based execution:

```bash
cp .github/workflows/orchestrator-loop.yml <target-project>/.github/workflows/
```

Add `ANTHROPIC_API_KEY` and `OPENAI_API_KEY` as repository secrets. Trigger with `/opencode orchestrator-loop` on any issue or PR comment.

### Per-Agent Models

```jsonc
{
  "agent": {
    "implementer": {
      "model": "opencode/gpt-4o-mini"
    },
    "reviewer": {
      "model": "opencode/gpt-4o"
    }
  }
}
```

---

## Architecture

```
                               ┌─────────────────────────────────┐
                               │       Pre-Phase: SELECTION      │
                               │  Lists issues/PRs → user picks  │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 1: INTAKE             │
                               │  Fetches issue/PR details, ACs  │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 2: ANALYZE             │
                               │  Explore codebase, test seams   │
                               │  (optional: to-prd skill)       │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 3: DECOMPOSE          │
                               │  Vertical slices (to-issues)    │
                               └──────────┬──────────────────────┘
                                          │
            ┌─────────────────────────────┼──────────────────────────────┐
            │                             │                              │
            ▼                             ▼                              ▼
   ┌──────────────────┐       ┌──────────────────┐            ┌──────────────────┐
   │  Slice 1 (impl)  │       │  Slice 2 (impl)  │    ...     │  Slice N (impl)  │
   │  subagent task   │       │  subagent task   │            │  subagent task   │
   │  .──────────────. │       │  .──────────────. │            │  .──────────────. │
   │ │  findings     ││       │ │  findings     ││            │ │  findings     ││
   │ │  board (R/W)  ││◄──────►│ │  board (R/W)  ││◄──────────►│ │  board (R/W)  ││
   │ │               ││       │ │               ││            │ │               ││
   └──────────────────┘       └──────────────────┘            └──────────────────┘
            │                             │                              │
            └─────────────────────────────┼──────────────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 4: IMPLEMENT          │
                               │  All slices done, lint+test    │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 5: TEST               │
                               │  Full suite + known-failures    │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 6: VERIFY LOOP        │
                               │  Reviewer subagent (max 3 rds)  │
                               │  CHANGES_REQUESTED → fix+retry  │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 7: MERGE              │
                               │  Pre-merge review gate → PR     │
                               └──────────┬──────────────────────┘
                                          │
                                          ▼
                               ┌─────────────────────────────────┐
                               │     Phase 8: META (optional)    │
                               │  Session trace → meta-analyst   │
                               │  → safe auto-apply / report     │
                               └─────────────────────────────────┘
```

---

## File-by-File Breakdown

### Core Protocol

| File | Purpose |
|---|---|
| `.opencode/skills/orchestrator-loop/SKILL.md` | **The orchestrator protocol** — 496 lines, 8 phases + pre-phase. The orchestrator loads this skill at startup and follows it phase-by-phase. All state management (todowrite), phase transitions, gate checks, and escalation logic live here. |
| `.opencode/prompts/orchestrator.txt` | **Orchestrator system prompt** (31 lines). Instructs the orchestrator to load the SKILL.md, announces phase transitions, references available peer skills and custom tools. |
| `.opencode/prompts/implementer.txt` | **Implementer prompt template** (50 lines). Dynamic template injected with slice description, ACs, codebase context, findings board path, and target branch. Supports the cross-slice knowledge sharing pattern. |
| `.opencode/prompts/meta-analyst.txt` | **Meta-analysis prompt** (36 lines). Instructs the explore agent to analyze session traces across 5 categories: prompt clarity, bottlenecks, phase transitions, acceptance criteria, error patterns. Returns SUGGEST lines for auto-application. |

### Agent Configuration

| File | Purpose |
|---|---|
| `opencode.json` | Defines 3 agents: `orchestrator` (primary, full permissions + task dispatch), `implementer` (subagent, read/edit/bash), `reviewer` (subagent, read-only + git diff). The install.sh script merges these into the global config. |
| `AGENTS.md` | Project-level context for development. Documents structure, model configuration, install instructions, Plan→Implement workflow, and work type detection. |

### Peer Skills (loaded dynamically)

| Skill | When Loaded | Purpose |
|---|---|---|
| `diagnose/SKILL.md` | Phase 5 (test failures) | Investigates test failures and returns structured diagnosis. 5-phase protocol: feedback loop → reproduce → hypothesize → instrument → report. Does NOT edit files — reports findings to orchestrator. |
| `to-issues/SKILL.md` | Phase 3 (decompose) | Breaks a feature into vertical tracer-bullet slices with ACs, dependency ordering, and parallel-safety flags. |
| `to-prd/SKILL.md` | Phase 2 (analyze, optional) | Formal structured analysis for complex features spanning 5+ files or requiring architectural decisions. Outputs problem statement, user stories, implementation decisions, testing approach. |

### Custom Tools

| Tool | Exports | Purpose |
|---|---|---|
| `gh-issue.ts` | `list`, `view`, `create` | GitHub issue operations via `gh` CLI. Handles JSON parsing, 0-comments edge case, shell escaping. |
| `gh-pr.ts` | `list`, `view`, `create` | GitHub PR operations via `gh` CLI. Body written to temp file to avoid shell escaping issues. |

### Support Files

| File | Purpose |
|---|---|
| `install.sh` | Copies all files to `~/.config/opencode/`, rewrites `.opencode/prompts/` → `prompts/` paths for global install, merges agent config with `jq`, installs tool dependencies. |
| `uninstall.sh` | Removes all orchestrator-loop artifacts from `~/.config/opencode/` while leaving other user config intact. |
| `.github/workflows/orchestrator-loop.yml` | GitHub Action workflow for comment-triggered execution (`/opencode orchestrator-loop`). Requires API keys as repo secrets. |
| `.opencode/session-stats.json` | Session trace database. Appended to in Phase 8a, finalized in 8d. Contains phase_timing, bottlenecks, review_rounds, error signatures per session. Analyzed by the meta-analyst across the last 5 runs. |

---

## The 8 Phases in Detail

### Pre-Phase: SELECTION
Lists open issues and PRs using `gh-issue_list` and `gh-pr_list`. User picks one (or types free-text/plan-mode). Detects labels for branch prefix mapping.

### Phase 1: INTAKE
Fetches full issue/PR details including title, body, comments, and labels using the custom tools. Identifies acceptance criteria and work type.

### Phase 2: ANALYZE
Explores the codebase via the `explore` agent. Optionally loads `to-prd` skill for features spanning 5+ files. Identifies test seams, reads AGENTS.md for build commands.

### Phase 3: DECOMPOSE
Loads the `to-issues` skill to break the feature into 2-10 vertical tracer-bullet slices, each independently testable with dependency ordering.

### Phase 4: IMPLEMENT
Dispatches implementer subagents for each slice. Creates a shared `.opencode/findings-board.md` for cross-slice knowledge sharing. Runs typecheck/lint/tests per slice. Max 2 retries per slice.

### Phase 5: TEST
Runs the full test suite. On failure: loads `diagnose` skill, dispatches fixes for new-code failures, records pre-existing failures in `.opencode/known-failures.md`. Re-runs typecheck and lint.

### Phase 6: VERIFY LOOP
Spawns a `reviewer` subagent to review the full diff. Max 3 rounds:
- **APPROVED** → proceed
- **CHANGES_REQUESTED (minor)** → fix directly, re-test, same round
- **CHANGES_REQUESTED (critical)** → feedback injection to implementer, next round
- **>3 rounds** → escalate with BLOCKER tag in PR

### Phase 7: MERGE
Creates branch, commits, pushes. **Pre-merge review gate**: fresh reviewer pass before opening PR. Opens PR with auto-generation notice and issues reference.

### Phase 8: META (optional, runs if Phase 4+ was reached)
1. **8a** — Appends session trace to `.opencode/session-stats.json` with phase_timing, bottlenecks, review_rounds
2. **8b** — Spawns meta-analyst (explore agent) to analyze last 5 sessions across 5 categories
3. **8c** — Auto-applies safe suggestions; reports needs-review suggestions
4. **8d** — Finalizes session trace (meta → "ok"), re-runs install.sh if changes applied

---

## Testing and Verification Strategy

Each gate in the loop verifies at a different level:

| Gate | What it catches | Where |
|---|---|---|
| Per-slice typecheck | Compile errors, type mismatches | Phase 4 step 3 |
| Per-slice lint | Code style, unused imports | Phase 4 step 3 |
| Per-slice tests | Slice-level regressions | Phase 4 step 3 |
| Full test suite | Cross-slice regressions, pre-existing failures | Phase 5 |
| Reviewer (rounds 1-3) | Logic errors, edge cases, security | Phase 6 |
| Pre-merge review | Last-pass correctness | Phase 7 step 4 |

Pre-existing test failures are recorded in `.opencode/known-failures.md` so subsequent sessions can skip or proactively fix them.

---

## Safe Suggestions (META Phase)

The META phase enables **recursive self-improvement**. The meta-analyst analyzes session traces and returns suggestions with a safeness level:

| Level | Meaning | Action |
|---|---|---|
| `safe` | Low-risk prompt tweaks, tool field additions | Auto-applied via edit tool |
| `needs_review` | Structural changes, new phases | Reported in completion summary for human review |

Analysis categories:
1. **Prompt clarity** — Prompts consistently misunderstood?
2. **Bottlenecks** — Which phases have retries/delays? (uses `bottlenecks[]` and `phase_timing{}` from session-stats)
3. **Phase transitions** — Which transitions needed course correction?
4. **Acceptance criteria** — Criteria consistently missed?
5. **Error patterns** — Repeated error categories across sessions

---

## Inspirations

This project was inspired by and references ideas from:

- **Claude Code and the OpenCode Agent Protocol** — The agent-to-subagent task dispatch model, skills system, and tool-permission framework are built on opencode's native primitives.
- **Anthropic's research on recursive self-improvement** — The META phase (Phase 8) implements a practical version of "agents that improve their own prompts": session trace collection, automated bottleneck analysis, and safe suggestion auto-application. See: [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) and related Anthropic research on agent evaluation and improvement loops.
- **Tracer bullet development** — The vertical slice decomposition in Phase 3 follows the tracer-bullet pattern described in *The Pragmatic Programmer*: thin end-to-end cuts through all layers rather than horizontal layer-by-layer builds.
- **Reviewer feedback injection** — The Phase 6 verification loop is inspired by RLHF (reinforcement learning from human feedback) and constitutional AI patterns, adapted for code review: structured rounds with explicit feedback history passed to the implementer.

---

## License

MIT
