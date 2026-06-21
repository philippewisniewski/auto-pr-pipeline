---
name: orchestrator-loop
description: Autonomous implementation loop. INTAKE -> ANALYZE -> DECOMPOSE -> IMPLEMENT -> TEST -> REVIEW -> MERGE. Spawns subagents for implementation and review.
---

# Orchestrator Loop

An autonomous loop that takes a work item (issue/PR/description) and produces a branch with tested code, then opens a PR.

**Mode: HITL initial selection, then AFK execution.** The INTAKE phase asks the user which work item to work on. Once selected, the loop runs autonomously and opens a PR for human review.

When exploring the codebase, use the project's domain glossary, read AGENTS.md (or package.json scripts as fallback) for build/lint/test commands, and check ADRs in the area you're touching.

At each phase transition, announce the phase with text:
→ Phase <N>: <NAME>

---

## Pre-Phase -- SELECTION

Identify what to work on.

1. If the session already has an explicit target (issue/PR number, GitHub Action context), skip the Pre-Phase and go to INTAKE.

2. If the user says "implement this plan" (or similar), check the recent conversation history for structured plan output. A plan typically contains sections like **Summary**, **File Changes**, **Implementation** (or **Steps**), and **Testing**.

   a. Look backwards through the conversation for a message with this structure. Use the most recent matching message.

   b. Extract the plan summary (the text after **Summary** or the first substantive paragraph) as the issue title, and the full plan text as the issue body.

   c. Create an issue using the `gh-issue_create` tool with title="<plan summary>" and body="<full plan>". The tool returns JSON with `url` and `number`. Extract `issue_number` from the result.
   d. Announce:
      ```
      → Created issue #<issue_number> from Plan mode.
      → SELECTED: Issue #<issue_number>. Starting orchestrator loop.
      ```
   e. Proceed to INTAKE.

   If no plan is found in history, fall through to step 3 (normal question flow).

3. List open issues and PRs using custom tools:
   - Use `gh-issue_list` with limit=10, state="open"
   - Use `gh-pr_list` with limit=5, state="open"

   Note: Empty list from `gh-pr_list` means no open PRs — that's normal; proceed.

4. Present the list to the user via the `question` tool and ask which to work on:

   The user can pick an existing item or type their own (issue number, PR number, or free-text feature description).

   ```
   question({
     questions: [
       {
         header: "Feature Loop — select work item",
         question: "Which issue, PR, or feature should I implement?",
         options: [
           { label: "Issue #<N>: <title>", description: "<brief>" },
           { label: "PR #<N>: <title>", description: "<brief>" }
         ]
       }
     ]
   })
    ```
 5. Once the user selects:
    - If the answer is free-text (not "Issue #<N>" or "PR #<N>"):
      Create an issue using `gh-issue_create` with title and body set to the user's text. Extract `number` from the JSON result.
      Announce:
      ```
      → Created issue #<issue_number> for tracking.
      → SELECTED: Issue #<issue_number>. Starting orchestrator loop.
      ```
    - If the answer is an existing issue or PR number:
      Announce:
      ```
      → SELECTED: <answer>. Starting orchestrator loop.
      ```
    In either case, the selected issue/PR number enters Phase 1 as `<N>`.

 6. **Label detection** (existing issues only): Use `gh-issue_view` with number=<N> to fetch issue details. Extract the `labels` array from the result and map each label name to determine the work type:

    | Label contains | type | branch_prefix |
    |---|---|---|
    | `bug`, `bugfix` | bugfix | `bugfix/` |
    | `hotfix`, `critical` | hotfix | `hotfix/` |
    | `docs`, `documentation` | docs | `docs/` |
    | `chore`, `dependencies` | chore | `chore/` |
    | `enhancement`, `feature` | feature | `feature/` |
    | *(no match / no labels)* | feature | `feature/` |

    For free-text and plan-mode selections, default to type `feature` with prefix `feature/`.

    The user can override the type in natural language (e.g. "implement this bugfix issue").
    Store `work_type` and `branch_prefix` in context for Phase 7.

---

## Phase 1 -- INTAKE

→ Phase 1: INTAKE

Gather details on the selected work item.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 1: INTAKE", status: "in_progress", priority: "high" }
{ content: "Fetch issue/PR details", status: "in_progress", priority: "high" }
{ content: "Identify acceptance criteria", status: "pending", priority: "medium" }
```

1. If an issue or PR number was provided, use the custom tools:
   - Use `gh-issue_view` with number=<N> and includeComments=true
   - Use `gh-pr_view` with number=<N>
   The tools return structured JSON with title, body, comments, and labels.
   The tool handles the 0-comments edge case internally.
2. If free-text was provided, use that as the feature description.
3. Identify the type of work: use the `work_type` from Pre-Phase label detection, or determine from context (new feature, bug fix, refactor, enhancement).
4. Announce a summary:
   ```
   → INTAKE complete. Selected: <item>. Now proceeding to ANALYZE.
   ```

Required before proceeding:
- [ ] I have a clear description of what needs to be built or fixed
- [ ] I know the acceptance criteria

---

## Phase 2 -- ANALYZE

Understand the codebase well enough to decompose the work.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 2: ANALYZE", status: "in_progress", priority: "high" }
{ content: "Explore codebase and patterns", status: "in_progress", priority: "high" }
{ content: "Identify test seams", status: "pending", priority: "medium" }
```

1. Call `@explore` to understand the project structure, relevant modules, and existing patterns
2. If the feature touches external dependencies or needs library research, call `@scout`
3. Read AGENTS.md (or package.json scripts as fallback) and any relevant ADRs in the area
4. Optionally load the `to-prd` skill for formal analysis if the feature is complex
5. Identify the test seams: how will each slice be tested?

Load the `to-prd` skill when:
- The feature spans 5+ files or 3+ modules
- The feature requires architectural decisions
- The implementation order is non-obvious

Required before proceeding:
- [ ] I understand the relevant parts of the codebase
- [ ] I know the test framework and test commands
- [ ] I have a mental model of the implementation approach

---

## Phase 3 -- DECOMPOSE

Break the feature into independently implementable vertical slices.

Load the `to-issues` skill.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 3: DECOMPOSE", status: "in_progress", priority: "high" }
{ content: "Draft vertical slices", status: "in_progress", priority: "high" }
```

1. Draft 2-10 vertical slices following the tracer-bullet pattern
2. Each slice must be independently testable
3. Identify slice dependencies (blocked-by relationships)
4. Create a `todowrite` list with all slices
5. Mark slices that can run in parallel vs. serial

Required before proceeding:
- [ ] Each slice is a thin vertical cut through all layers
- [ ] No slice depends on unimplemented prior slices (unless explicitly noted)
- [ ] All slices have clear acceptance criteria
- [ ] The implementation order is determined

---

## Phase 4 -- IMPLEMENT

For each slice (in dependency order), dispatch an implementer subagent.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 4: IMPLEMENT", status: "in_progress", priority: "high" }
{ content: "Implement slices", status: "in_progress", priority: "high" }
```

**Cross-slice knowledge sharing:** Before dispatching any slices, create a shared findings board at `.opencode/findings-board.md` with content `# Findings Board\n`. Each implementer will read from and write to this file to share discoveries (existing patterns, test helpers, gotchas) with parallel slices.

For each slice:

1. Construct a dynamic prompt containing:
   - The slice description and acceptance criteria
   - Relevant codebase context from Phase 2
   - The implementer prompt template (`.opencode/prompts/implementer.txt`)
   - The project's build/lint/test commands (from AGENTS.md or package.json scripts)
   - Which earlier slices are already in place (for context)
   - **The findings board path** (`.opencode/findings-board.md`) — instruct the implementer to read it before starting and append any discoveries during implementation
   - **The target branch name** (`{branch_prefix}<issue-number>-<short-name>`) so the implementer checks out the correct base

2. Spawn an `implementer` via the task tool:
   ```
   task({ agent: "implementer", message: "<dynamic prompt>" })
   ```

3. After the implementer returns:
   - [ ] Run `npm run typecheck` (or equivalent)
   - [ ] Run `npm run lint` (or equivalent)
   - [ ] Run the relevant tests

4. If any check fails:
   - If the failure is local to this slice, construct a follow-up prompt and dispatch again (max 2 retries)
   - If the failure reveals a deeper bug, load the `diagnose` skill for investigation

5. Update `todowrite` -- mark the slice complete

Parallel execution: independent slices (no blocked-by relationship) can run in parallel. Spawn them simultaneously via the task tool.

After all slices complete, clean up: `rm -f .opencode/findings-board.md`

Required before proceeding:
- [ ] All slices are complete
- [ ] All typecheck/lint/test checks pass
- [ ] `todowrite` shows all items complete
- [ ] Findings board cleaned up

---

## Phase 5 -- TEST

Run the full project test suite to catch regressions.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 5: TEST", status: "in_progress", priority: "high" }
{ content: "Run full test suite", status: "in_progress", priority: "high" }
{ content: "Run typecheck and lint", status: "pending", priority: "medium" }
```

1. Run `npm test` (or `bun test`, `pytest`, etc. -- from AGENTS.md or package.json scripts)
2. If tests fail:
   - Load the `diagnose` skill
   - Investigate the root cause
   - If the failure is in the new code: dispatch an implementer for the fix
   - If the failure is a pre-existing issue: note it but do NOT block
   - If pre-existing: record it in `.opencode/known-failures.md` with the test command and error signature so subsequent sessions can skip or proactively fix known issues
3. Re-run tests after any fix
4. Run `npm run typecheck` and `npm run lint` (or equivalents)

Required before proceeding:
- [ ] Full test suite passes
- [ ] Typecheck passes
- [ ] Lint passes

---

## Phase 6 -- VERIFICATION LOOP

Review the full diff in structured rounds with feedback injection. MAX_RETRIES=3.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 6: VERIFICATION LOOP", status: "in_progress", priority: "high" }
{ content: "Review round 1/3", status: "in_progress", priority: "high" }
```

**Round N (starts at 1, ends at MAX_RETRIES=3):**

1. Spawn a `reviewer` via the task tool:
   ```
   task({
     agent: "reviewer",
     message: "Review round ROUND/MAX_RETRIES. Review this diff. Context: <brief>.
     Focus on correctness, edge cases, security, and alignment with the acceptance criteria.
     Start your response with one of:
     - APPROVED
     - CHANGES_REQUESTED (critical): <reason>
     - CHANGES_REQUESTED (minor): <reason>
     Then list each specific issue as a bullet point."
   })
   ```

2. Read the reviewer's verdict:
   - **APPROVED**: Proceed to Phase 7. Update todowrite: `"Review round N/3"`→"completed"
   - **CHANGES_REQUESTED (minor)**: Fix issues directly, no round increment. Re-run tests/typecheck/lint. Re-spawn reviewer for same round to re-confirm.
   - **CHANGES_REQUESTED (critical)**: Go to step 3.

   **Fix approach for critical issues:** For simple issues (1-2 line changes, straightforward fixes like null checks or status codes), the orchestrator may fix them directly and skip implementer dispatch. For complex or multi-file changes requiring new logic or architectural shifts, always dispatch through the implementer (step 3). Use your judgment — when in doubt, dispatch the implementer.

3. **Critical issues — feedback injection:**
   - Store the reviewer's specific issue list as `feedback_history[round]`
   - Construct a dynamic implementer prompt containing:
     - The original slice context and acceptance criteria
     - The specific reviewer issues from this round
     - The full `feedback_history` (all prior rounds) so the implementer can see what's already been tried
     - "Focus ONLY on the issues listed. Do not refactor unrelated code."
   - Dispatch implementer:
     ```
     task({
       agent: "implementer",
       message: "<feedback-injection prompt>"
     })
     ```
   - After implementer returns: run tests, typecheck, lint
   - If checks fail: diagnose + fix within this round (no round increment)
   - Update todowrite: `"Review round N/3"`→"completed", add `"Review round N+1/3"`→"in_progress"
   - Go to step 1 (next round)

4. **Escalation (round > MAX_RETRIES):**
   If after 3 rounds the reviewer still flags critical issues, open the PR with a BLOCKER tag:
   - Create the branch, commit, and push as normal
   - When opening the PR, prepend the body with:
     ```
     ⚠️ BLOCKER: This PR has unresolved review issues after 3 rounds.
     **Known issues:**
     <all feedback_history items concatenated>
     ```
   - Continue to Phase 7
   - The BLOCKER tag signals the human reviewer that this needs special attention

Track `review_rounds` count in context for Phase 8 meta-analysis:
- Store the final round count (e.g. `review_rounds: 2`)
- Store whether escalation was triggered (`escalated: true/false`)

Required before proceeding:
- [ ] Reviewer has approved, or round > MAX_RETRIES (escalated)
- [ ] All tests/typecheck/lint pass after each implementer round
- [ ] `review_rounds` and `escalated` captured for Phase 8

---

## Phase 7 -- MERGE

Commit, push, and open a pull request.

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 7: MERGE", status: "in_progress", priority: "high" }
{ content: "Create branch", status: "in_progress", priority: "high" }
{ content: "Commit and push", status: "pending", priority: "medium" }
{ content: "Pre-merge review", status: "pending", priority: "high" }
{ content: "Open PR", status: "pending", priority: "medium" }
```

1. Create a branch: `git checkout -b {branch_prefix}<issue-number>-<short-name>`
2. Stage and commit the changes with a descriptive message referencing the issue
3. Push: `git push origin {branch_prefix}<branch-name>`
4. **Pre-merge review gate:**
   Spawn a fresh reviewer subagent with the complete diff and context:
   ```
   task({
     agent: "reviewer",
     message: "Final pre-merge review. Review the full diff. Context: <brief>.
     Start your response with one of:
     - APPROVED
     - CHANGES_REQUESTED (critical): <reason>
     - CHANGES_REQUESTED (minor): <reason>
     Then list each specific issue as a bullet point."
   })
   ```
   - **APPROVED**: Proceed to step 5.
   - **CHANGES_REQUESTED**: Fix all listed issues directly. Re-run tests/typecheck/lint. Re-spawn the reviewer for one more round (max 1 retry). If still not approved, add a BLOCKER note to the PR body and proceed.
5. Open a PR using `gh-pr_create` with title, body, head=<branch>, and base="main". Include in the PR body: "🤖 This PR was auto-generated by the orchestrator-loop. Human review and approval required before merging."
6. The PR is now ready for human review. The orchestrator cannot merge its own PRs — a human must review and approve before merging.

Required before completing:
- [ ] Branch pushed to remote
- [ ] Pre-merge review passed
- [ ] PR created with description and issue reference

---

## Completion

The loop is done. The PR is open for human review. **Important:** The orchestrator cannot merge its own PRs — a human must review, approve, and merge. Return a summary:
- Link to the PR
- What was implemented
- Acceptance criteria status
- Any known issues or caveats
- META suggestions (if any were generated — see Phase 8)

---

## Phase 8 -- META (Optional)

Analyze the session and improve the harness for the next run. Skip if the loop failed early (before Phase 4).

Use these exact todowrite items (include all prior items unchanged, then add these):
```
{ content: "Phase 8: META", status: "in_progress", priority: "low" }
{ content: "Collect session trace", status: "in_progress", priority: "low" }
{ content: "Run analysis agent", status: "pending", priority: "low" }
{ content: "Apply safe suggestions", status: "pending", priority: "low" }
```

### 8a — Collect session trace (stub)

Append a stub entry to `.opencode/session-stats.json` with `"meta": "in_progress"`. Populate the fields as follows:

- **phase_timing**: Estimate seconds spent in each phase. If you didn't track exact timestamps, log `"0"` for untracked phases — the meta-analyst still benefits from the phases you did track.
- **bottlenecks**: List any phases that required retries, course correction, or felt unusually slow. Examples: `"implement: slice 2 needed 2 retries — missing test context"`, `"review: 3 rounds needed — acceptance criteria ambiguous"`. Leave empty array `[]` if none.

```json
{
  "sessions": [
    {
      "ts": "<ISO timestamp>",
      "issue": <issue_number>,
      "pr": <pr_number>,
      "type": "<work_type>",
      "outcome": "success" | "escalated" | "partial",
      "review_rounds": <N>,
      "escalated": true | false,
      "implement_retries": <total retries across all slices>,
      "tests": { "pass": <N>, "fail": <N> },
      "errors": ["<brief error description>"],
      "phases": {
        "intake": "ok",
        "analyze": "ok",
        "decompose": "ok",
        "implement": "ok" | "retries",
        "test": "ok" | "fail_then_fix",
        "review": "N_rounds",
        "merge": "ok",
        "meta": "in_progress"
      },
      "bottlenecks": [
        "<phase>: <description of retries or slowness>"
      ],
      "phase_timing": {
        "intake": "<seconds>",
        "analyze": "<seconds>",
        "decompose": "<seconds>",
        "implement": "<seconds>",
        "test": "<seconds>",
        "review": "<seconds>",
        "merge": "<seconds>"
      },
      "pr_link": "<pr_url>"
    }
  ]
}
```

- **If file doesn't exist**: Create it with the JSON above (containing one entry in `sessions`).
- **If file exists**: Read the file, parse as JSON, push the new entry into the `sessions` array, then write back as valid JSON. Do NOT append raw text — this will break JSON formatting (missing commas).

The `meta` field will be updated to `"ok"` in step 8d.

### 8b — Run analysis agent

Read `.opencode/prompts/meta-analyst.txt` (or `~/.config/opencode/prompts/meta-analyst.txt` as fallback) and use its content as the task message. If neither file exists, use this default instruction:

```
Analyze session traces for bottlenecks, error patterns, and phase-timing anomalies. Return SUGGEST lines.
```

Dispatch:

```
task({
  agent: "explore",
  message: "<content of meta-analyst prompt or default>"
})
```

(Read the file and inline the content — `{file:}` syntax is not supported inside task messages.)

### 8c — Apply or report suggestions

For each suggestion returned:

- **safe**: Apply automatically via the `edit` tool. Read the target file, make the change, and log: `META: Applied: <description> (target)`
- **needs_review**: Collect in a list. Append to the Completion summary:
  ```
  META suggestions for your review:
  - <description> (target)
  ```

### 8d — Finalize session trace

Update the session entry in `.opencode/session-stats.json`: change `"meta": "in_progress"` to `"meta": "ok"`. Read the file, modify the last entry's phases.meta, and write it back. (This ensures the trace captures the outcome of the analysis, not just the pre-analysis state.)

If any suggestions were applied, re-run the install script to propagate changes to the global config.

Required before completing:
- [ ] Session trace stub written (8a)
- [ ] Analysis agent ran (even if no suggestions)
- [ ] Safe suggestions applied, needs-review suggestions reported
- [ ] Session trace finalized — phases.meta set to "ok" (8d)
