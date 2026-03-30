---
name: ganbuild
description: Use when building a complete application from a short brief, when the user wants autonomous multi-agent development with separated generation and evaluation, or when the user invokes /ganbuild. GAN-inspired architecture where Generator builds and Evaluator critiques.
---

# ganbuild

GAN-inspired autonomous app builder. Three agents — Planner, Generator, Evaluator — build applications from a 1-4 sentence brief. The Generator builds features sprint-by-sprint. A separate Evaluator agent critiques each sprint through live browser interaction. The tension between them drives quality. Failed approaches are discarded via git reset; successful ones are merged. Every experiment is logged to prevent repeating mistakes.

## Invocation

```
/ganbuild "a retro arcade game collection with leaderboards"
/ganbuild --interactive "a project management dashboard"
/ganbuild --no-review "a markdown note-taking app"
/ganbuild --resume
```

**Flags:**
- `--interactive` — Check for human annotations between sprints (not just at the end)
- `--no-review` — Skip Phase 3 human review (no agentation)
- `--resume` — Resume from last completed sprint (reads experiments.jsonl)

---

## Phase 0: Setup

**Run every check. Install what's missing. Do NOT ask the user — just fix it.**

```bash
# 1. Git repo
[ ! -d .git ] && git init && git add -A && git commit -m "initial: ganbuild scaffold" 2>/dev/null

# 2. Experiment tracking
[ ! -f experiments.jsonl ] && echo '{"event":"init","timestamp":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > experiments.jsonl

# 3. Agentation MCP (for Phase 3 human review)
# Check if agentation tools are available in the MCP tool list
# If not: npm install -g agentation-mcp && npx agentation-mcp init
# If --no-review flag is set, skip this check
```

### Project Detection

```
IF package.json exists:
  Read it. Detect framework (React, Vue, Next, Svelte, etc.)
  Detect dev server command (npm run dev, etc.)
  Use existing project as-is.

IF no project exists:
  Ask the user ONE question: "What kind of app? (web/fullstack/mobile)"
  Scaffold based on answer:
    web       → React + Vite + TypeScript + Tailwind
    fullstack → React + Vite + FastAPI (or Express if user prefers JS-only)
    mobile    → Expo + React Native
  npm install / pip install as needed
  git add -A && git commit -m "scaffold: project initialized"
```

### Browser Tool Detection

The Evaluator needs browser access. Detect what's available in this priority order:

```
1. gstack /browse skill    → BEST. ~100ms per command, persistent sessions.
2. mcp chrome tools        → GOOD. claude-in-chrome or chrome-devtools-mcp.
3. Playwright via bash     → FALLBACK. npx playwright install && use directly.
```

Store the detected browser tool in a variable for the Evaluator to reference:
```
BROWSER_TOOL = "browse" | "chrome-mcp" | "playwright"
```

### Create ganbuild branch

```bash
git checkout -b ganbuild/$(date +%Y%m%d-%H%M%S)
```

---

## Phase 1: Plan

Spawn a **Planner Agent** using the Agent tool:

```
subagent_type: general-purpose
name: ganbuild-planner
```

### Planner Prompt

```
You are the PLANNER in ganbuild, a multi-agent app builder.

## Your Task
Expand this brief into a detailed product specification:

BRIEF: {user_brief}

## Output Two Files

### 1. spec.md
Write a comprehensive product specification:
- Product overview and target user
- Core features (prioritized)
- User flows (step by step)
- Data model (entities and relationships)
- Tech stack decisions (respect existing project if one exists)
- UI/UX direction (layout, aesthetic, key interactions)
- Edge cases and error states to handle

### 2. sprint-contracts.md
Break the spec into 3-7 sprints. Each sprint:

```markdown
## Sprint N: {Name}

### Deliverables
- [ ] Concrete feature 1
- [ ] Concrete feature 2

### Acceptance Criteria
The Evaluator will verify:
- Can the user {specific action}?
- Does {specific element} display correctly?
- Does {specific interaction} work end-to-end?

### Dependencies
- Requires Sprint {N-1} (if any)
```

## Rules
- Focus on PRODUCT CONTEXT, not implementation details
- Keep sprints small: each should take 10-15 minutes to implement
- Acceptance criteria must be TESTABLE via browser interaction
- Front-load core functionality (sprint 1 = MVP skeleton)
- Later sprints add polish, edge cases, secondary features
- Do NOT write any implementation code
```

### Checkpoint

After the Planner finishes, display `spec.md` and `sprint-contracts.md` to the user.

**This is the ONLY human checkpoint before the autonomous loop.**

Ask: "Does this plan look good? Say 'go' to start building, or tell me what to change."

Wait for confirmation. If the user requests changes, update the files and re-confirm.

---

## Phase 2: Build Loop

```dot
digraph build_loop {
  rankdir=TB;
  node [shape=box];

  start [label="Read next sprint\nfrom sprint-contracts.md" shape=ellipse];
  generate [label="GENERATOR AGENT\nImplement sprint features\ngit commit changes"];
  server [label="Start dev server\nConfirm it responds"];
  evaluate [label="EVALUATOR AGENT\nBrowse live app\nScore all criteria"];
  decide [shape=diamond label="Avg score >= 7?"];
  keep [label="git merge to main\nLog 'keep' to experiments.jsonl"];
  discard [label="git reset --hard\nLog 'discard' to experiments.jsonl"];
  retry [shape=diamond label="Attempt < 3?"];
  besteff [label="Keep best attempt\nLog 'keep-best-effort'"];
  next [shape=diamond label="More sprints?"];
  done [label="Phase 3: Human Review" shape=ellipse];
  annot [shape=diamond label="--interactive flag\nand annotations pending?"];
  fixannot [label="Fix annotations\nResolve via agentation"];

  start -> generate;
  generate -> server;
  server -> evaluate;
  evaluate -> decide;
  decide -> keep [label="PASS"];
  decide -> discard [label="FAIL"];
  keep -> annot;
  annot -> fixannot [label="yes"];
  annot -> next [label="no"];
  fixannot -> next;
  discard -> retry;
  retry -> generate [label="yes\n(with feedback)"];
  retry -> besteff [label="no"];
  besteff -> next;
  next -> start [label="yes"];
  next -> done [label="no"];
}
```

**CRITICAL: Do NOT stop between sprints. Do NOT ask for permission. Continue until ALL sprints are complete or the user intervenes.**

### Generator Agent

Spawn for each sprint:

```
subagent_type: general-purpose
name: ganbuild-generator
mode: bypassPermissions
```

**Prompt:**

```
You are the GENERATOR in ganbuild. Implement this sprint.

## Context
- Sprint contract: {CURRENT_SPRINT from sprint-contracts.md}
- Full spec: [read spec.md]
- Evaluator feedback from last attempt (if retry): {FEEDBACK}
- Past experiments: [read experiments.jsonl for patterns of what failed]

## Rules
1. Implement ONLY what the sprint contract specifies
2. Write clean, working code — not stubs or placeholders
3. git commit your changes with message: "sprint {N}: {description}"
4. Ensure the dev server starts and the app loads without errors
5. Do NOT evaluate your own work — the Evaluator does that
6. If retrying after a FAIL, focus on the specific issues the Evaluator raised
7. Check experiments.jsonl — do NOT repeat approaches that were already discarded

## Dev Server
Start command: {DEV_SERVER_CMD}
Expected URL: {DEV_URL, usually http://localhost:5173 or http://localhost:3000}

After your changes compile and the server is running, say READY.
```

### Evaluator Agent

Spawn AFTER Generator says READY:

```
subagent_type: general-purpose
name: ganbuild-evaluator
mode: bypassPermissions
```

**Prompt:**

```
You are the EVALUATOR in ganbuild. You are SKEPTICAL by default. Your job is to find problems, not to praise.

## Context
- Sprint contract: {CURRENT_SPRINT}
- App URL: {DEV_URL}
- Browser tool: {BROWSER_TOOL}

## Process

1. Open the app at {DEV_URL} using {BROWSER_TOOL}
2. For EACH acceptance criterion in the sprint contract:
   - Attempt to complete the user action
   - Take a screenshot as evidence
   - Note if it works, partially works, or fails
3. Also check for issues NOT in the contract:
   - Console errors
   - Broken layouts
   - Non-functional buttons or links
   - Missing loading/error states

## Scoring (1-10 each)

| Criterion     | What 7+ means                                          |
|---------------|--------------------------------------------------------|
| Functionality | All acceptance criteria pass. User flows complete.     |
| Design        | Coherent visual identity. Not default template look.   |
| Craft         | Good spacing, typography, contrast. Responsive.        |
| Originality   | Custom design decisions. Not generic AI output.        |

## Output

Write to `evaluation-sprint{N}-attempt{A}.md`:

```markdown
## Sprint {N} Evaluation (Attempt {A})

### Scores
- Functionality: X/10 — {justification}
- Design: X/10 — {justification}
- Craft: X/10 — {justification}
- Originality: X/10 — {justification}
- **Average: X/10**

### Issues Found
1. {Issue with screenshot reference}
2. {Issue with screenshot reference}

### Verdict: PASS / FAIL

### Feedback for Generator (if FAIL)
- Fix: {specific actionable instruction}
- Fix: {specific actionable instruction}
```

## Grading Rules
- 7+ = genuinely good, not "it renders"
- If you CANNOT interact with a feature, Functionality ≤ 4
- If everything is default gray/white with no visual identity, Design ≤ 4
- If spacing is inconsistent or text is hard to read, Craft ≤ 5
- If it looks like every other AI-generated app, Originality ≤ 4
- Be HARSH. The Generator improves through honest feedback.
```

### Keep/Discard Logic

After each evaluation, the ORCHESTRATOR (main conversation, not a subagent) executes:

```
Read evaluation-sprint{N}-attempt{A}.md
Extract average score

IF avg >= 7 (PASS):
  git checkout main
  git merge sprint/{N} --no-ff -m "merge: sprint {N} - {description}"
  Append to experiments.jsonl:
    {"sprint":N, "attempt":A, "commit":"HASH", "scores":{...}, "avg":X,
     "status":"keep", "description":"...", "timestamp":"ISO8601"}

IF avg < 7 AND attempt < 3 (FAIL, retry):
  git reset --hard HEAD~{commits_in_sprint}
  Append to experiments.jsonl:
    {"sprint":N, "attempt":A, "commit":"HASH", "scores":{...}, "avg":X,
     "status":"discard", "feedback":"...", "timestamp":"ISO8601"}
  Go back to Generator with evaluator feedback

IF avg < 7 AND attempt = 3 (FAIL, max retries):
  Find attempt with highest avg score
  Merge that one to main
  Append to experiments.jsonl:
    {"sprint":N, "attempt":A, "scores":{...}, "avg":X,
     "status":"keep-best-effort", "known_issues":"...", "timestamp":"ISO8601"}
  Move to next sprint
```

### Dev Server Management

Between sprints:
- Check if dev server is still running (curl the URL)
- If crashed, restart it
- If port conflict, kill the old process first

---

## Phase 3: Human Review (agentation)

**Skip if `--no-review` flag was set.**

After all sprints complete:

1. Ensure the dev server is running
2. Open the app in the user's default browser: `open {DEV_URL}`
3. Tell the user:

> **Your app is ready for review.**
> Open it in your browser and use the Agentation toolbar to annotate anything you want changed.
> - Use "feedback" annotations for bugs or issues
> - Use "placement" annotations to move elements
> - Use "rearrange" annotations for layout changes
>
> When you're done reviewing, say **"done reviewing"** and I'll move to final polish.

4. Enter the annotation watch loop:

```
WHILE user has not said "done reviewing":

  Check agentation_get_all_pending

  IF pending annotations exist:
    Sort by severity: blocking → important → suggestion
    FOR each annotation:
      agentation_acknowledge(annotation.id)
      Read annotation details (intent, severity, element selector, comment)
      Implement the requested change
      git commit -m "review: {annotation summary}"
      agentation_resolve(annotation.id, "Fixed: {what was done}")

  IF no pending annotations:
    agentation_watch_annotations (blocks until new annotations arrive)
    Process newly arrived annotations
```

5. After user says "done reviewing":
   - git commit any remaining changes
   - Log review stats to experiments.jsonl:
     ```
     {"event":"human_review", "annotations_received":N,
      "annotations_resolved":N, "annotations_dismissed":N,
      "timestamp":"ISO8601"}
     ```

---

## Phase 4: Polish

Spawn a final **Evaluator Agent** with expanded scope:

```
subagent_type: general-purpose
name: ganbuild-polisher
mode: bypassPermissions
```

**Prompt:**

```
You are the POLISHER in ganbuild. This is the final quality pass before the app ships.

## App URL: {DEV_URL}
## Browser tool: {BROWSER_TOOL}

## Full Review Checklist

Use {BROWSER_TOOL} to test the ENTIRE app systematically:

### Functionality
- [ ] Every page loads without errors
- [ ] Every button/link does something
- [ ] Every form submits and validates
- [ ] Data persists across page refreshes (if applicable)
- [ ] Edge cases: empty states, long text, special characters

### Visual Consistency
- [ ] Consistent color palette throughout
- [ ] Consistent typography (no mixed font sizes/weights)
- [ ] Consistent spacing and alignment
- [ ] No orphaned elements or broken layouts

### Responsiveness
- [ ] Check at mobile width (375px)
- [ ] Check at tablet width (768px)
- [ ] Check at desktop width (1280px)

### Accessibility Basics
- [ ] Sufficient color contrast
- [ ] Focus states visible on interactive elements
- [ ] Images have alt text
- [ ] Headings in logical order

### Console
- [ ] No JavaScript errors in console
- [ ] No failed network requests

## For Each Issue Found
Fix it directly. You have full edit access.
Commit each fix separately: "polish: {what was fixed}"

## Output
After all fixes, write `build-report.md` summarizing:
- Total sprints completed
- Experiments tried / kept / discarded (read experiments.jsonl)
- Human annotations addressed (if Phase 3 ran)
- Issues found and fixed in polish
- Known limitations (anything you couldn't fix)
- Final feature inventory
```

---

## NEVER STOP Rules

These rules apply during Phase 2 (Build Loop) and Phase 4 (Polish):

1. **Do NOT ask for permission between sprints** — the plan was approved in Phase 1
2. **Do NOT stop because you're "unsure"** — try something and let the Evaluator judge
3. **Do NOT skip the Evaluator** — every sprint gets evaluated, no exceptions
4. **If a sprint crashes**, fix trivial issues; abandon fundamentally broken approaches after 2 crash attempts
5. **If the dev server dies**, restart it before continuing
6. **If you run out of ideas**, read experiments.jsonl for what hasn't been tried yet
7. **Continue until ALL sprints are complete** or the user explicitly stops you

---

## Experiment Ledger Format

`experiments.jsonl` — append-only, one JSON object per line:

```jsonl
{"event":"init","timestamp":"2025-01-15T10:00:00Z"}
{"sprint":1,"attempt":1,"commit":"a1b2c3d","scores":{"functionality":8,"design":5,"craft":5,"originality":4},"avg":5.5,"status":"discard","description":"basic grid layout, default styling","feedback":"No visual identity, generic template look","timestamp":"2025-01-15T10:15:00Z"}
{"sprint":1,"attempt":2,"commit":"e4f5g6h","scores":{"functionality":8,"design":8,"craft":7,"originality":7},"avg":7.5,"status":"keep","description":"retro CRT aesthetic with scanlines and pixel font","timestamp":"2025-01-15T10:32:00Z"}
{"event":"human_review","annotations_received":3,"annotations_resolved":3,"annotations_dismissed":0,"timestamp":"2025-01-15T11:45:00Z"}
{"event":"polish","issues_found":5,"issues_fixed":5,"timestamp":"2025-01-15T12:00:00Z"}
```

The Generator MUST read this file before each attempt to avoid repeating discarded approaches.

---

## Resume Support

When `--resume` flag is set:

1. Read `experiments.jsonl` to find the last completed sprint
2. Read `sprint-contracts.md` to find the next sprint
3. Verify the dev server starts with the current codebase
4. Continue from the next incomplete sprint
5. Do NOT re-run the Planner or re-confirm the plan
