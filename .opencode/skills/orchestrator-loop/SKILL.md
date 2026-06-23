---
name: orchestrator-loop
description: >-
  Lightweight autonomous implementation loop. SELECT -> INTAKE -> ANALYZE ->
  IMPLEMENT -> MERGE. Uses only OpenCode built-in tools. Load
  references/N-name.md for whichever stage you are in.
metadata:
  version: "2.1"
---

# Orchestrator Loop v2

A lightweight loop that takes a GitHub issue and produces a PR. Built on OpenCode built-in tools.

**Mode:** HITL initial selection, then AFK execution. Announce each stage transition with `→ Stage <N>: <NAME>`.

## Stage Sequence

For each stage, load the corresponding reference file and follow its steps:

| Stage | Load | Summary |
|---|---|---|
| 1: SELECT | `read references/1-select.md` | Pick or create a work item |
| 2: INTAKE | `read references/2-intake.md` | Understand the work item |
| 3: ANALYZE | `read references/3-analyze.md` | Understand the codebase |
| 4: IMPLEMENT | `read references/4-implement.md` | Implement, review, verify |
| 5: MERGE | `read references/5-merge.md` | Branch, commit, push, PR |

## Gotchas

- `block.json` paths are relative to the block's own directory. `editorScript` must be `file:../../build/{block}/index.js` for `src/{block}/block.json`. Not relative to project root.
- CSS `url()` must quote paths: `url("image.jpg")`. Unquoted URLs break on filenames with special characters.
- Multi-entry webpack (e.g., 5 blocks) requires an entry stub for every block. If only implementing one, create minimal stubs for the others.
- `register_block_type()` takes the path to `block.json`. That `block.json` then resolves `editorScript` relative to itself — not to the plugin root.
- Reviewer must prefix actionable changes with `[EDIT] path/to/file | OLD TEXT | NEW TEXT` so changes can be auto-applied by the orchestrator.

## Completion

Return a summary with PR link, what was implemented, acceptance criteria status, and any caveats.
