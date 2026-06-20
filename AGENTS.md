# Orchestrator Loop

This project is the development workspace for the orchestrator-loop workflow.

## What this is

An autonomous feature implementation loop for opencode. It takes a feature
request (issue, PR, or description) and produces a branch with tested code,
then opens a PR for human review.

## Structure

.opencode/skills/orchestrator-loop/SKILL.md   Main orchestration protocol
.opencode/skills/to-issues/SKILL.md      Feature decomposition
.opencode/skills/to-prd/SKILL.md         Formal feature analysis
.opencode/skills/diagnose/SKILL.md       Test failure investigation

opencode.json                             Agent config (orchestrator, implementer, reviewer)

.opencode/prompts/orchestrator.txt       Orchestrator system prompt
.opencode/prompts/implementer.txt        Dynamic implementer prompt template

## Model Configuration

No models are hardcoded. Agents use your globally configured default model.
Subagents (`implementer`, `reviewer`) inherit the orchestrator's model.

To use different models per agent, add a `model` field in the agent config
inside `opencode.json`. For example:

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

For GitHub Actions, set the repository variable `OPENCODE_MODEL` to your
preferred model ID, or edit `.github/workflows/orchestrator-loop.yml` directly.

## Install Globally

Run `./install.sh` to copy agents, skills, and prompts to ~/.config/opencode/.

Once installed, open opencode in any project, switch to the `orchestrator`
agent (Tab key), and describe the work item you want implemented.

## Recommended Workflow: Plan → Implement

For best results with complex work items, use opencode's built-in Plan mode
first, then switch to the orchestrator to implement:

1. **Plan mode** — Enter Plan mode (`Cmd+Shift+P` or `/plan`). Describe the
   work item at a high level. The agent produces a structured plan with a
   Summary, File Changes, Implementation steps, and Testing approach.

2. **Switch to orchestrator** — Tab to the `orchestrator` agent. Say
   "implement this plan" (or similar).

3. **Orchestrator detects the plan** — The Pre-Phase finds the plan in
   conversation history, creates a tracking issue from it, and runs Phases
   1-7 using the plan as the specification.

No copy-paste needed — the plan is already in the conversation when you
switch agents.

## Work Type Detection

When you select an existing issue, the orchestrator reads its labels and
uses the branch prefix accordingly:

| Label | Branch prefix |
|---|---|
| `bug`, `bugfix` | `bugfix/` |
| `hotfix`, `critical` | `hotfix/` |
| `docs`, `documentation` | `docs/` |
| `chore`, `dependencies` | `chore/` |
| `enhancement`, `feature` | `feature/` |
| *(no labels / default)* | `feature/` |

For free-text and plan-mode selections, the default is `feature/`. You can
override by saying e.g. "implement this bugfix" — the orchestrator respects
natural language.
