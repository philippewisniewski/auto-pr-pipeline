---
name: diagnose
description: Investigate test failures and bugs found during the feature loop. Report root cause and suggested fix back to the orchestrator.
---

# Diagnose -- Feature-Loop Adaptation

Investigate a failure and return a structured diagnosis. Do NOT fix the code yourself -- report findings back to the orchestrator.

---

## Phase 1 -- Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a fast, deterministic, agent-runnable pass/fail signal for the bug, you will find the cause.

Spend disproportionate effort here. **Be aggressive. Be creative. Refuse to give up.**

### Ways to construct one -- try them in roughly this order

1. **Failing test** at whatever seam reaches the bug -- unit, integration, e2e.
2. **Curl / HTTP script** against a running dev server.
3. **CLI invocation** with a fixture input, diffing stdout against a known-good snapshot.
4. **Headless browser script** (Playwright / Puppeteer) -- drives the UI, asserts on DOM/console/network.
5. **Replay a captured trace.** Save a real network request / payload / event log to disk; replay it through the code path in isolation.
6. **Throwaway harness.** Spin up a minimal subset of the system (one service, mocked deps) that exercises the bug code path with a single function call.
7. **Property / fuzz loop.** If the bug is "sometimes wrong output", run 1000 random inputs and look for the failure mode.
8. **Bisection harness.** If the bug appeared between two known states (commit, dataset, version), automate "boot at state X, check, repeat" so you can `git bisect run` it.
9. **Differential loop.** Run the same input through old-version vs new-version (or two configs) and diff outputs.

Build the right feedback loop, and the bug is 90% fixed.

Do not proceed to Phase 2 without a loop you believe in.

## Phase 2 -- Reproduce

Run the loop. Confirm the failure is:
- [ ] The same failure the test reported
- [ ] Reproducible across multiple runs
- [ ] The exact symptom captured

Do not proceed without reproducing.

## Phase 3 -- Hypothesise

Generate **3-5 ranked hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea.

Each hypothesis must be **falsifiable**: state the prediction it makes.

> Format: "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe -- discard or sharpen it.

## Phase 4 -- Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

Tool preference:

1. **Debugger / REPL inspection** if the env supports it. One breakpoint beats ten logs.
2. **Targeted logs** at the boundaries that distinguish hypotheses.
3. Never "log everything and grep".

**Tag every debug log** with a unique prefix, e.g. `[DEBUG-a4f2]`. Cleanup at the end becomes a single grep.

## Phase 5 -- Report

Return a structured diagnosis to the orchestrator:

<diagnosis-output>
Root cause: <clear explanation of what is wrong>

Evidence: <what was observed, which hypothesis was confirmed>

Suggested fix: <specific code change to make, with file paths>

Files affected: <list of files>

Fix confidence: <high / medium / low -- why?>
</diagnosis-output>

Do NOT modify any files. The orchestrator will dispatch an implementer for the fix.
