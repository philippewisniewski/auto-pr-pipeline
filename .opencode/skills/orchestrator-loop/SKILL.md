---
name: orchestrator-loop
description: >-
  Run a full feature implementation pipeline from user prompt or GitHub issue
  through to a reviewed PR. Covers the complete workflow: trigger → intake →
  analyze → implement → review → merge. Use when the user wants to fix a bug,
  implement a feature, review a PR, plan work, or triage an issue — whether
  prompted locally or via a GitHub event.
metadata:
  version: "3.0"
---

# Orchestrator Loop

6-phase pipeline from trigger to PR. Starts with the human, ends with the
human. Announce each phase transition with `→ Phase <N>: <NAME>`.

## Phase 1: Trigger (Intent Detection)

Infer intent from natural language or GitHub event context:

| If the user... | Intent |
|---|---|
| Mentions an issue, bug, or says "fix this" | `bugfix` |
| Asks for a feature or enhancement | `feature` |
| Says "review this PR" or "review #N" | `review` |
| Asks to plan, design, or explore | `plan` |
| Reports something vague — "look at this" | `triage` |
| Says "run the loop" with no context | Use `question` to clarify |

Set `intent` and proceed to Phase 2.

## Phase 2: Intake (Context Gathering)

Branch on intent:

**bugfix** — `gh-issue_view(number=N, includeComments=true)`.
  Extract reproduction steps, expected vs actual behavior, environment.

**feature** — `gh-issue_view(number=N, includeComments=true)`.
  Extract requirements, acceptance criteria, constraints.

**review** — `gh-pr_view(number=N)`. Read diff and conversation.
  Does not need Phases 3-4. Proceed: Phase 5, then Phase 6 if changes made.

**plan** — `question` to gather goals and constraints from the user.
  Does not need Phases 3/5/6. Proceed: Phase 4 (produce a plan document).

**triage** — `gh-issue_view(number=N)`. Classify, add labels, comment.
  Pipeline complete — no further phases.

## Phase 3: Analyze (Explore + Slice)

Skip if `review`, `plan`, or `triage` intent.

1. `task(explore, ...)` — dispatch read-only explore subagent on the codebase
   - Include: context from Phase 2, files to look at, patterns to find
2. Collect explore's findings
3. Primary agent slices the work into 1-3 ordered units
4. Each slice has: scope, files involved, acceptance criteria
5. `todowrite` — record slices

## Phase 4: Implement (Execute Slices)

For `plan` intent: produce a plan document and stop.

For `bugfix`/`feature`: execute each slice in order.

1. `task(general, ...)` — dispatch general subagent with full slice context
   - Include: slice scope, relevant files, conventions, build/lint/test commands
2. Run verification: typecheck → lint → test
3. If a step fails → re-dispatch once with the error output
4. `todowrite` — mark slice complete
5. During implementation, if external docs are needed (library APIs, SDK refs),
   use `task(scout, ...)` to fetch via `webfetch`

After all slices, run the full verification suite once more.

## Phase 5: Review (Verify + Fix)

For `review` intent: start here. For `bugfix`/`feature`: after Phase 4.

1. `task(general, ...)` — fresh agent reviews the diff
   - Prompt includes: context, acceptance criteria, correctness, edge cases,
     security
2. If issues found:
   - **Small fixes** — reviewer uses `apply_patch` directly
   - **Architecture problems** — reviewer reports back, primary returns to
     Phase 4 for rework
3. Re-review after fixes. Repeat until satisfied.
4. `todowrite` — mark review complete

## Phase 6: Merge (Human Handoff)

1. Determine branch prefix from issue label:
   - `bug`/`bugfix` → `bugfix/`
   - `feature`/`enhancement` → `feature/`
   - `docs` → `docs/`
   - Default → `chore/`
2. `git checkout -b {prefix}{N}-short-name`
3. `git add -A && git commit -m 'type: description (#N)'`
4. `git push origin HEAD`
5. `gh-pr_create(title, body, head, base="main")`
   - Body includes: `Closes #N`, summary, AC status, caveats

PR is opened for human review.

## Gotchas

- `task(explore)` is read-only. Do not ask it to make changes.
- If the reviewer sends architecture-level feedback, the primary re-evaluates
  the approach — do not re-dispatch the same implementation unchanged.
- For `apply_patch` to work, the review agent needs the `edit` permission.
- For `review` intent, skip Phases 3-4 and go to Phase 5 directly.
- For `plan` intent, produce a plan document and stop after Phase 4.
- For `triage` intent, the pipeline is complete after Phase 2.
- Slices should be 1-3 at most. One slice is preferred if the work is focused
  on a single area.
