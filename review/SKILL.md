---
name: review
description: Use when the user wants to review and annotate a ganbuild app after building, or when they say "review my app", "annotate", or "let me check the build"
---

# ganbuild:review

Launch human review on an existing ganbuild project. Starts the dev server, opens the app in your browser, and enters the annotation watch loop.

## Prerequisites

- A ganbuild project with at least one completed sprint (`experiments.jsonl` has a `"status":"keep"` entry)
- Agentation MCP installed (`npm install -g agentation-mcp && npx agentation-mcp init`)

## Process

1. Verify the project has been built (check `experiments.jsonl`)
2. Detect the dev server command from `package.json`
3. Start the dev server and confirm it responds
4. Open the app in the user's default browser: `open {DEV_URL}`
5. Tell the user:

> **Your app is ready for review.**
> Use the Agentation toolbar to annotate anything you want changed.
> - "feedback" annotations for bugs or issues
> - "placement" annotations to move elements
> - "rearrange" annotations for layout changes
>
> Say **"done reviewing"** when finished.

6. Enter the annotation watch loop:

```
WHILE user has not said "done reviewing":
  Check agentation_get_all_pending
  IF pending annotations:
    Sort by severity: blocking > important > suggestion
    FOR each annotation:
      agentation_acknowledge(annotation.id)
      Implement the requested change
      git commit -m "review: {annotation summary}"
      agentation_resolve(annotation.id, "Fixed: {what was done}")
  IF no pending:
    agentation_watch_annotations (blocks until new)
```

7. After user says "done reviewing":
   - Commit remaining changes
   - Log review stats to `experiments.jsonl`
   - Ask if the user wants to run Phase 4 (Polish + Feel + Humanizer)

## Does NOT

- Re-run the Planner
- Re-run Design Research
- Re-run the Build Loop
- Re-run sprints
