---
name: resume
description: Use when the user wants to continue a ganbuild build that was interrupted, or when they say "resume", "continue building", or "pick up where we left off"
---

# ganbuild:resume

Resume a ganbuild session from the last completed sprint. Reads the experiment ledger to find progress and continues the build loop.

## Prerequisites

- A ganbuild project with `experiments.jsonl` and `sprint-contracts.md`
- A `design-system/MASTER.md` from a previous design research step

## Process

1. Read `experiments.jsonl` to find the last completed sprint
2. Read `sprint-contracts.md` to find the next sprint
3. Verify the dev server starts with the current codebase
4. Continue the Build Loop from the next incomplete sprint
5. After all sprints complete, run Phase 3 (Human Review) and Phase 4 (Polish)

## Does NOT

- Re-run the Planner or re-confirm the plan
- Re-run Design Research (uses existing `design-system/MASTER.md`)
- Re-build already completed sprints
