#!/bin/bash

# Ralph loop script - runs AI agent with prompt until cancelled or iteration limit reached
# Usage: ralph.sh [opencode|codex|claude|gemini] [ITERATION_LIMIT]
# Default tool: codex
# Default iteration limit: 500
# Can be run from any directory. prd.json should be at the root of the directory where script is invoked.

# Get tool from command line argument or use default
TOOL=${1:-codex}

# Validate tool parameter
if [ "$TOOL" != "opencode" ] && [ "$TOOL" != "codex" ] && [ "$TOOL" != "claude" ] && [ "$TOOL" != "gemini" ]; then
    echo "Error: Invalid tool '$TOOL'. Must be 'opencode', 'codex', 'claude', or 'gemini'."
    echo "Usage: ralph.sh [opencode|codex|claude|gemini] [ITERATION_LIMIT]"
    exit 1
fi

# Get iteration limit from command line argument or use default
ITERATION_LIMIT=${2:-500}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="${SCRIPT_DIR}/prompt.md"
STOP_FILE="${SCRIPT_DIR}/STOP"
# Get the project root directory (where script is invoked from - prd.json lives here)
PROJECT_ROOT="$PWD"

# Check if prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: prompt file not found at $PROMPT_FILE"
    exit 1
fi

# Counter for iterations
ITERATION=0

# Flag for graceful shutdown
STOP_REQUESTED=0

# Trap Ctrl+C (SIGINT) for graceful shutdown
trap 'echo ""; echo "Ctrl+C detected. Stopping after current iteration..."; STOP_REQUESTED=1' INT

echo "Starting Ralph loop..."
echo "Tool: $TOOL"
echo "Iteration limit: $ITERATION_LIMIT"
echo "Prompt file: $PROMPT_FILE"
echo "Project root: $PROJECT_ROOT"
echo "Press Ctrl+C to cancel"
echo ""

# Change to project root directory (where prd.json should be)
cd "$PROJECT_ROOT" || {
    echo "Error: Failed to change to project root directory: $PROJECT_ROOT"
    exit 1
}

# Main loop
while [ $ITERATION -lt $ITERATION_LIMIT ]; do
    # Check if stop was requested via Ctrl+C
    if [ $STOP_REQUESTED -eq 1 ]; then
        echo "Stop requested by user. Exiting."
        exit 0
    fi

    # Check if STOP file exists
    if [ -f "$STOP_FILE" ]; then
        echo "STOP file detected at $STOP_FILE. Exiting."
        exit 0
    fi

    ITERATION=$((ITERATION + 1))
    echo "[Iteration $ITERATION/$ITERATION_LIMIT] Running $TOOL..."

    # Run the selected tool with the prompt from the project root (non-interactive, auto-exit)
    # Capture both stdout and stderr to check for rate limit errors
    OUTPUT_FILE=$(mktemp)

    if [ "$TOOL" = "opencode" ]; then
        # Run opencode with LM Studio models
        # OPENCODE_MODEL='ollama/qwen3:30b'
        # OPENCODE_MODEL='lmstudio/mistralai/devstral-2-2512'
        # OPENCODE_MODEL='lmstudio/qwen/qwen3-next-80b'
        OPENCODE_MODEL='lmstudio/zai-org/glm-4.7-flash'
        OPENCODE_CONFIG="${SCRIPT_DIR}/opencode.jsonc"
        # Generate title with format: ralph:YYMMDD:HHMM:iterationOFlimit
        TITLE="ralph:$(date +%y%m%d):$(date +%H%M):${ITERATION}of${ITERATION_LIMIT}"
        OPENCODE_CONFIG="$OPENCODE_CONFIG" opencode run -m "$OPENCODE_MODEL" --title "$TITLE" --print-logs --file "$PROMPT_FILE" --log-level "WARN" "Do the work requesteded in $PROMPT_FILE." 2>&1 | tee "$OUTPUT_FILE"
        # opencode run -m "ollama/$OLLAMA_MODEL" --title "$TITLE" --print-logs --file "$PROMPT_FILE" --log-level "WARN" "Do the work requesteded in $PROMPT_FILE." 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[0]}
    elif [ "$TOOL" = "claude" ]; then
        # Run claude code CLI in non-interactive mode
        CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN:-$(op read 'op://keys/env/CLAUDE_CODE_OAUTH_TOKEN')}"
        cat "$PROMPT_FILE" | CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" claude --dangerously-skip-permissions -p 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[1]}
    elif [ "$TOOL" = "gemini" ]; then
        # Run gemini CLI in yolo mode (auto-approve all actions)
        gemini --yolo "$(cat "$PROMPT_FILE")" 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[0]}
    else
        # Run codex (default)
        cat "$PROMPT_FILE" | codex exec --dangerously-bypass-approvals-and-sandbox 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[1]}
    fi

    # Check for OpenAI usage limit error (429)
    if grep -q "usage_limit_reached" "$OUTPUT_FILE"; then
        echo ""
        echo "OpenAI usage limit reached (429 error). Stopping."
        rm -f "$OUTPUT_FILE"
        exit 1
    fi

    # Check for Claude usage limit error
    if grep -qi "you've hit your limit" "$OUTPUT_FILE"; then
        echo ""
        echo "Claude usage limit reached. Stopping."
        rm -f "$OUTPUT_FILE"
        exit 1
    fi

    rm -f "$OUTPUT_FILE"

    # Check exit status
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Warning: $TOOL exited with code $EXIT_CODE on iteration $ITERATION"
    fi

    echo ""
done

echo "Reached iteration limit of $ITERATION_LIMIT. Stopping."
