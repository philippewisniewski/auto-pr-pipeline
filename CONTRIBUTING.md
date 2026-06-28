# Contributing to orchestrator-loop

Thanks for your interest in contributing! This repo defines the **Orchestrator Loop** — an AI-driven development pipeline using [OpenCode](https://opencode.ai).

## How to Contribute

### Issues

- Open a GitHub issue to report bugs, request features, or propose changes.
- The Orchestrator Loop workflow will automatically triage and process your issue.

### Pull Requests

PRs are created **automatically** by the GitHub Actions workflow. The AI agent handles branch creation, commits, and PR creation based on the pipeline defined in `.opencode/skills/orchestrator-loop/SKILL.md`.

**To propose a change:**

1. Open an issue describing the desired change.
2. The pipeline will analyze, implement, and open a PR for human review.
3. Reviewers can then approve, request changes, or merge.

## Development Setup

1. Clone the repo.
2. Install OpenCode.
3. Open the repo in your editor — no additional build steps or dependencies needed.

## Coding Conventions

- **Indentation:** 2 spaces
- **Line endings:** LF
- **Encoding:** UTF-8
- **Trailing whitespace:** trimmed
- **Final newline:** present

Follow the conventions established in existing files.

## Pipeline Overview

The Orchestrator Loop follows a 6-phase pipeline:

1. **Trigger** — detect intent from issue/comment
2. **Intake** — gather context
3. **Analyze** — explore codebase and slice work
4. **Implement** — execute slices
5. **Review** — verify correctness
6. **Human Handoff** — create PR summary

See `.opencode/skills/orchestrator-loop/SKILL.md` for full details.

## Branch Naming

Branches use a prefix matching the issue label:

| Label | Prefix |
|---|---|
| `bug` / `bugfix` | `bugfix/` |
| `feature` / `enhancement` | `feature/` |
| `docs` | `docs/` |
| (default) | `chore/` |

## License

By contributing, you agree that your contributions will be licensed under the same terms as the project (see the repository for license information).
