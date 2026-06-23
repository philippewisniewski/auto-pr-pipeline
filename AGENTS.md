# Orchestrator Loop v2

This project is the development workspace for the orchestrator-loop v2 workflow.

## What this is

A lightweight autonomous feature implementation loop for OpenCode.
Takes a GitHub issue and produces a tested PR. Built entirely on OpenCode built-in tools.

## Structure

.opencode/skills/orchestrator-loop/SKILL.md  Main orchestration protocol (the loop)
opencode.json                                Agent config (orchestrator, implementer, reviewer)

## Install Globally

Run `./install.sh` to copy the skill and agent config to ~/.config/opencode/.

Once installed, open OpenCode in any project, switch to the `orchestrator` agent, and select a work item.

## Model Configuration

No models are hardcoded. Agents use your globally configured default model.
Subagents (`implementer`, `reviewer`) inherit the orchestrator's model.

To use different models per agent:
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
