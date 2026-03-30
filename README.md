# ganbuild

Every AI builder ships the same look. Coral gradients, centered text, emoji everywhere. You've seen it. Your users have definitely seen it.

The problem is simple: one agent builds the thing and decides it's good. ganbuild splits those jobs. The Generator writes code. A different Evaluator opens the app in a real browser, pulls up an award-winning site next to it, and compares the two. Below 8/10? Code gets thrown out, Generator tries again. The Evaluator doesn't know which attempt it's seeing, so it can't go easy on round three.

You write a few sentences about what you want. ganbuild plans it, finds real sites to pull design direction from, builds it in sprints, and checks each one in a live browser. Hover states, copy tone, the works. You approve the plan once. After that, it runs on its own.

Inspired by:
- [Anthropic's harness design for long-running apps](https://www.anthropic.com/engineering/harness-design-long-running-apps) — separated Generator/Evaluator architecture
- [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) — experiment tracking, git-based keep/discard, autonomous loops

## Quick start

1. Install ganbuild (see below)
2. Run `/ganbuild "a personal portfolio site"` — describe what you're building
3. Approve the plan when prompted
4. Watch it build, evaluate, and polish autonomously
5. Run `/ganbuild:review` to annotate and refine

Stop there. You'll know if this is for you.

## Install

```bash
npx skills add johnlim5847/ganbuild
```

ganbuild works on any agent that supports the [SKILL.md standard](https://agentskills.io/specification) (Claude Code, Codex, Gemini CLI, Cursor, Windsurf, etc.). Skills are discovered automatically.

## Works well with [gstack](https://github.com/garrytan/gstack)

ganbuild uses a browser tool for design research and evaluation. If you have [gstack](https://github.com/garrytan/gstack) installed, ganbuild will automatically use its `/browse` skill (~100ms per command, persistent sessions). Otherwise it falls back to chrome MCP tools or Playwright.

gstack also provides complementary skills you can run on your ganbuild output:
- `/qa` — find and fix bugs with real browser testing
- `/design-review` — visual QA with before/after screenshots
- `/review` — pre-landing code review
- `/ship` — create a PR with changelog

## Usage

```
/ganbuild "a retro arcade game collection with leaderboards"
```

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

For the human review phase, install [agentation-mcp](https://www.agentation.com/mcp):

```bash
npm install -g agentation-mcp
npx agentation-mcp init
```

This lets you annotate the live app directly in your browser. The agent watches for annotations and fixes them in real-time.

## Experiment Tracking

Every build attempt is logged to `experiments.jsonl`:

```jsonl
{"sprint":1,"attempt":1,"scores":{"functionality":8,"design":5,"craft":5,"originality":4},"avg":5.5,"status":"discard","description":"basic grid layout"}
{"sprint":1,"attempt":2,"scores":{"functionality":9,"design":8,"craft":8,"originality":8},"avg":8.25,"status":"keep","description":"editorial layout with extracted design tokens"}
```

The Generator reads this before each attempt to avoid repeating failed approaches.

## License

MIT
