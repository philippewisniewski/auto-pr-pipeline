---
name: to-prd
description: Formalize a feature request into a structured analysis with user stories, implementation decisions, and testing approach.
---

# To PRD -- Feature-Loop Adaptation

Synthesize what you've learned in the ANALYZE phase into a structured analysis.

Do NOT interview the user -- synthesize from the issue/PR description and codebase exploration.

---

## Process

1. Use the project's domain glossary from the codebase exploration
2. Sketch the test seams -- existing seams preferred, new seams proposed at the highest level possible

## Output: Structured Analysis

Write this into the conversation context (no external publication):

### Problem Statement

The problem the feature solves, from the user's perspective.

### Solution

The solution approach, from the user's perspective.

### User Stories

1. As an <actor>, I want <feature>, so that <benefit>
2. ...

### Implementation Decisions

- Modules that will be created or modified
- Interfaces that will change
- Architectural decisions
- Schema changes
- API contracts

### Testing Decisions

- What makes a good test for this feature
- Which seams will be used
- Prior art in the codebase

### Out of Scope

What this feature explicitly does NOT include.

---

This analysis feeds into the to-issues decomposition phase.
