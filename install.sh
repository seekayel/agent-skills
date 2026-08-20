#!/usr/bin/env bash
# Prints (or runs, with --run) the commands to install the unslop skill
# via the skills CLI (https://github.com/vercel-labs/skills).
set -euo pipefail

REPO="seekayel/agent-skills"
SKILL="unslop"

CLAUDE_CMD="npx skills add ${REPO} --skill ${SKILL} -a claude-code"
CODEX_CMD="npx skills add ${REPO} --skill ${SKILL} -a codex"

if [[ "${1:-}" == "--run" ]]; then
  echo "+ ${CLAUDE_CMD}"
  ${CLAUDE_CMD}
  echo "+ ${CODEX_CMD}"
  ${CODEX_CMD}
  exit 0
fi

cat <<EOF
Install the unslop skill with the skills CLI:

  # Claude Code
  ${CLAUDE_CMD}

  # Codex
  ${CODEX_CMD}

  # Or both at once
  npx skills add ${REPO} --skill ${SKILL} -a claude-code -a codex

Run this script with --run to execute the installs for Claude Code and Codex.
EOF
