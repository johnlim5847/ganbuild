#!/bin/bash
# ganbuild installer — copies the skill to Claude Code's skill directory

set -e

SKILL_DIR="$HOME/.claude/skills/ganbuild"

echo "Installing ganbuild..."

# Create skills directory if it doesn't exist
mkdir -p "$SKILL_DIR"

# Copy skill file
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"

echo "Installed to $SKILL_DIR/SKILL.md"
echo ""
echo "Usage: In Claude Code, type:"
echo "  /ganbuild \"your app description here\""
echo ""
echo "Optional flags:"
echo "  --interactive    Check for human annotations between sprints"
echo "  --no-review      Skip human review phase"
echo "  --resume         Resume from last completed sprint"
echo ""
echo "Optional: For human review via browser annotations, install agentation-mcp:"
echo "  npm install -g agentation-mcp"
echo "  npx agentation-mcp init"
