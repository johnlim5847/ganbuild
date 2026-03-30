# ganbuild

GAN-inspired autonomous app builder for Claude Code.

Three agents — **Planner**, **Generator**, **Evaluator** — build applications from a short description. The Generator builds features sprint-by-sprint. A separate Evaluator agent critiques each sprint through live browser interaction. Failed approaches are discarded via git; successful ones are merged. Every experiment is logged.

Design direction is sourced from real award-winning reference sites, not generated from keyword catalogs. The Evaluator scores against those references with a strict 8/10 pass threshold.

Inspired by:
- [Anthropic's harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — separated Generator/Evaluator architecture
- [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) — experiment tracking, git-based keep/discard, autonomous loops

## Install

```bash
npx skills add johnlim5847/ganbuild
```

## Usage

In Claude Code:

```
/ganbuild "a retro arcade game collection with leaderboards"
```

### Skills

| Command | Description |
|---------|-------------|
| `/ganbuild "brief"` | Full build from a short description |
| `/ganbuild --interactive "brief"` | Build with human annotations between sprints |
| `/ganbuild --no-review "brief"` | Build without human review phase |
| `/ganbuild:resume` | Resume from the last completed sprint |
| `/ganbuild:review` | Launch human review on an existing build |

## How it works

```
Brief --> Planner --> spec.md + sprint-contracts.md
                          |
                     [User confirms]
                          |
              Design Research Agent
              Browses award-winning sites, screenshots them,
              extracts real CSS tokens (colors, fonts, layout)
              Writes design-system/MASTER.md
                          |
            +--- Build Loop (autonomous) ---+
            |                               |
            |  Generator -- implements sprint|
            |  Evaluator -- browses live app |
            |    + visits reference site     |
            |    + side-by-side comparison   |
            |    + scores blind (no attempt #)|
            |  Score >= 8 -- git merge (keep)|
            |  Score < 8 -- git reset (discard)|
            |  Max 3 retries per sprint     |
            |  All logged to experiments.jsonl|
            +-------------------------------+
                          |
            Human Review (agentation toolbar)
                          |
            Polish --> Feel Pass --> Humanizer
                          |
                     build-report.md
```

## Design Pipeline

The design system is not generated from keyword catalogs. Instead:

1. **Design Research Agent** browses curated design galleries for award-winning sites matching the product domain
2. Visits 3 reference sites live, screenshots heroes and inner sections
3. Extracts real colors, fonts, and layout patterns from computed CSS
4. Writes `design-system/MASTER.md` with concrete references and tokens
5. Reference screenshots saved to `design-system/references/`

The Planner writes product specs only (features, user flows, data model). It never specifies colors, fonts, or visual direction. Design comes from research, not imagination.

### Evaluator Rigor

- **Side-by-side comparison**: Evaluator visits a reference site during each evaluation and compares it to the app
- **Score anchoring**: Reference sites = 8-9 on the scale. The app is scored relative to them.
- **Blind evaluation**: The Evaluator never knows which attempt number it is, preventing score inflation on retries
- **Design research verification**: If `MASTER.md` or reference screenshots are missing, design scores are auto-capped at 4

## Optional: Human Review with Agentation

For the human review phase (Phase 3), install [agentation-mcp](https://www.agentation.com/mcp):

```bash
npm install -g agentation-mcp
npx agentation-mcp init
```

This lets you annotate the live app directly in your browser. The agent watches for annotations and fixes them in real-time.

## Requirements

- Any AI agent that supports the SKILL.md standard (Claude Code, Codex, Gemini CLI, Cursor, Windsurf, etc.)

## Experiment Tracking

Every build attempt is logged to `experiments.jsonl`:

```jsonl
{"sprint":1,"attempt":1,"scores":{"functionality":8,"design":5,"craft":5,"originality":4},"avg":5.5,"status":"discard","description":"basic grid layout"}
{"sprint":1,"attempt":2,"scores":{"functionality":9,"design":8,"craft":8,"originality":8},"avg":8.25,"status":"keep","description":"editorial layout with extracted design tokens"}
```

The Generator reads this before each attempt to avoid repeating failed approaches.

## License

MIT
