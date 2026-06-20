---
name: to-issues
description: Break a feature into vertical implementation slices with acceptance criteria and dependency ordering. Outputs structured slice descriptions for subagent dispatch.
---

# To Issues -- Feature-Loop Adaptation

Break the feature into independently-implementable vertical slices.

---

## 1. Gather context

Work from the conversation context already established (INTAKE + ANALYZE phases complete). The codebase has been explored, the feature is understood.

## 2. Draft vertical slices

Break the feature into **tracer bullet** slices. Each slice is a thin vertical cut through ALL integration layers end-to-end.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
- Prefer slices that can run in parallel
</vertical-slice-rules>

## 3. Output structure

For each slice, produce:

```
Slice <N>: <short name>
  Description: <2-3 sentences>
  Acceptance criteria:
  - [ ] <criterion 1>
  - [ ] <criterion 2>
  Dependencies: <earlier slices this depends on, or "none">
  Files likely touched: <list>
  Parallel-safe: <yes/no>
```

## 4. Create todowrite list

Convert each slice into a `todowrite` item. Order by dependency (blockers first).

## 5. Store slice data for orchestration

Each slice's data will be used by the orchestrator to construct implementer prompts. Store the mapping -- this feeds directly into the IMPLEMENT phase.
