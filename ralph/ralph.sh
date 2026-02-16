#!/bin/bash

# Ralph loop script - runs AI agent with prompt until cancelled or iteration limit reached.
# After each full pass of the configured CLI list, critic mode runs once to audit quality.
# Usage: ralph.sh [opencode|codex|claude|gemini][,opencode|codex|claude|gemini,...] [ITERATION_LIMIT]
# Default CLI list: codex
# Default iteration limit: 500
# Can be run from any directory. prd.json should be at the root of the directory where script is invoked.

# Get CLI list from command line argument or use default
CLIS_ARG=${1:-codex}

# Get iteration limit from command line argument or use default
ITERATION_LIMIT=${2:-500}

# Supported CLIs
VALID_CLIS=("opencode" "codex" "claude" "gemini")

# Trim helper for parsing comma-separated CLI input
trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

# Normalize and validate CLI list format
CLIS_ARG="$(trim "$CLIS_ARG")"
if [ -z "$CLIS_ARG" ] || [[ "$CLIS_ARG" == ,* ]] || [[ "$CLIS_ARG" == *, ]]; then
    echo "Error: Invalid CLI list '$CLIS_ARG'."
    echo "Usage: ralph.sh [opencode|codex|claude|gemini][,opencode|codex|claude|gemini,...] [ITERATION_LIMIT]"
    exit 1
fi

# Parse and validate each CLI in the list
IFS=',' read -r -a RAW_CLIS <<< "$CLIS_ARG"
CLIS=()
for RAW_CLI in "${RAW_CLIS[@]}"; do
    CLI="$(trim "$RAW_CLI")"

    if [ -z "$CLI" ]; then
        echo "Error: Invalid CLI list '$CLIS_ARG'. Empty CLI entries are not allowed."
        echo "Usage: ralph.sh [opencode|codex|claude|gemini][,opencode|codex|claude|gemini,...] [ITERATION_LIMIT]"
        exit 1
    fi

    IS_VALID=0
    for VALID_CLI in "${VALID_CLIS[@]}"; do
        if [ "$CLI" = "$VALID_CLI" ]; then
            IS_VALID=1
            break
        fi
    done

    if [ $IS_VALID -eq 0 ]; then
        echo "Error: Invalid CLI '$CLI'. Must be one of: opencode, codex, claude, gemini."
        echo "Usage: ralph.sh [opencode|codex|claude|gemini][,opencode|codex|claude|gemini,...] [ITERATION_LIMIT]"
        exit 1
    fi

    CLIS+=("$CLI")
done

CLI_COUNT=${#CLIS[@]}
CLIS_DISPLAY=$(IFS=,; echo "${CLIS[*]}")

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_FILE="${SCRIPT_DIR}/prompt.md"
CRITIC_PROMPT_FILE="${SCRIPT_DIR}/critic-verify-prompt.md"
# Get the project root directory (where script is invoked from - prd.json lives here)
PROJECT_ROOT="$PWD"
STOP_FILE="${PROJECT_ROOT}/.ralph/STOP"
CRITIC_CLI="${CLIS[0]}"

# Check if prompt file exists
if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: prompt file not found at $PROMPT_FILE"
    exit 1
fi

# Check if critic prompt file exists
if [ ! -f "$CRITIC_PROMPT_FILE" ]; then
    echo "Error: critic prompt file not found at $CRITIC_PROMPT_FILE"
    exit 1
fi

# Counter for iterations
ITERATION=0

# Flag for graceful shutdown
STOP_REQUESTED=0

# Trap Ctrl+C (SIGINT) for graceful shutdown
trap 'echo ""; echo "Ctrl+C detected. Stopping after current iteration..."; STOP_REQUESTED=1' INT

echo "Starting Ralph loop..."
echo "CLI sequence: $CLIS_DISPLAY"
echo "Iteration limit: $ITERATION_LIMIT"
echo "Prompt file: $PROMPT_FILE"
echo "Critic prompt file: $CRITIC_PROMPT_FILE"
echo "Critic mode: enabled (runs with $CRITIC_CLI after each full CLI cycle)"
echo "Project root: $PROJECT_ROOT"
echo "Press Ctrl+C to cancel"
echo ""

# Change to project root directory (where prd.json should be)
cd "$PROJECT_ROOT" || {
    echo "Error: Failed to change to project root directory: $PROJECT_ROOT"
    exit 1
}

# Run a single CLI pass with a given prompt file.
run_cli_with_prompt() {
    local SELECTED_CLI="$1"
    local SELECTED_PROMPT_FILE="$2"
    local RUN_LABEL="$3"
    local OUTPUT_FILE
    local EXIT_CODE

    OUTPUT_FILE=$(mktemp)

    if [ "$SELECTED_CLI" = "opencode" ]; then
        # Run opencode with LM Studio models
        # OPENCODE_MODEL='ollama/qwen3:30b'
        # OPENCODE_MODEL='lmstudio/mistralai/devstral-2-2512'
        # OPENCODE_MODEL='lmstudio/qwen/qwen3-next-80b'
        local OPENCODE_MODEL
        local OPENCODE_CONFIG
        local TITLE

        OPENCODE_MODEL='lmstudio/zai-org/glm-4.7-flash'
        OPENCODE_CONFIG="${SCRIPT_DIR}/opencode.jsonc"
        # Generate title with format: ralph:YYMMDD:HHMM:runLabel:iterationOFlimit
        TITLE="ralph:$(date +%y%m%d):$(date +%H%M):${RUN_LABEL}:${ITERATION}of${ITERATION_LIMIT}"
        OPENCODE_CONFIG="$OPENCODE_CONFIG" opencode run -m "$OPENCODE_MODEL" --title "$TITLE" --print-logs --file "$SELECTED_PROMPT_FILE" --log-level "WARN" "Do the work requested in $SELECTED_PROMPT_FILE." 2>&1 | tee "$OUTPUT_FILE"
        # opencode run -m "ollama/$OLLAMA_MODEL" --title "$TITLE" --print-logs --file "$SELECTED_PROMPT_FILE" --log-level "WARN" "Do the work requested in $SELECTED_PROMPT_FILE." 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[0]}
    elif [ "$SELECTED_CLI" = "claude" ]; then
        # Run claude code CLI in non-interactive mode
        local CLAUDE_TOKEN
        CLAUDE_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN:-$(op read 'op://keys/env/CLAUDE_CODE_OAUTH_TOKEN')}"
        cat "$SELECTED_PROMPT_FILE" | CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_TOKEN" claude --dangerously-skip-permissions -p 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[1]}
    elif [ "$SELECTED_CLI" = "gemini" ]; then
        # Run gemini CLI in yolo mode (auto-approve all actions)
        gemini --yolo -p "$(cat "$SELECTED_PROMPT_FILE")" 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[0]}
    else
        # Run codex (default)
        cat "$SELECTED_PROMPT_FILE" | codex exec --dangerously-bypass-approvals-and-sandbox 2>&1 | tee "$OUTPUT_FILE"
        EXIT_CODE=${PIPESTATUS[1]}

        # If codex default model hits usage limit, retry once with codex-5.2.
        if grep -qi "you've hit your usage limit" "$OUTPUT_FILE"; then
            echo ""
            echo "Codex usage limit detected. Retrying with model codex-5.2..."

            local RETRY_OUTPUT_FILE
            RETRY_OUTPUT_FILE=$(mktemp)
            cat "$SELECTED_PROMPT_FILE" | codex exec --model codex-5.2 --dangerously-bypass-approvals-and-sandbox 2>&1 | tee "$RETRY_OUTPUT_FILE"
            EXIT_CODE=${PIPESTATUS[1]}

            mv "$RETRY_OUTPUT_FILE" "$OUTPUT_FILE"

            if grep -qi "you've hit your usage limit" "$OUTPUT_FILE"; then
                echo ""
                echo "Codex usage limit reached on fallback model codex-5.2. Stopping."
                rm -f "$OUTPUT_FILE"
                exit 1
            fi
        fi
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
    return "$EXIT_CODE"
}

# Main loop
while [ $ITERATION -lt $ITERATION_LIMIT ]; do
    # Check if stop was requested via Ctrl+C
    if [ $STOP_REQUESTED -eq 1 ]; then
        echo "Stop requested by user. Exiting."
        exit 0
    fi

    # Check if stop file exists in project .ralph directory
    if [ -f "$STOP_FILE" ]; then
        echo "STOP file detected at $STOP_FILE. Removing and stopping iterations."
        rm -f "$STOP_FILE"
        exit 0
    fi

    ITERATION=$((ITERATION + 1))
    CLI_INDEX=$(((ITERATION - 1) % CLI_COUNT))
    CURRENT_CLI="${CLIS[$CLI_INDEX]}"
    echo "[Iteration $ITERATION/$ITERATION_LIMIT] Running $CURRENT_CLI..."

    run_cli_with_prompt "$CURRENT_CLI" "$PROMPT_FILE" "main"
    EXIT_CODE=$?

    # Check exit status
    if [ $EXIT_CODE -ne 0 ]; then
        echo "Warning: $CURRENT_CLI exited with code $EXIT_CODE on iteration $ITERATION"
    fi

    # Run critic mode once after each full pass of the configured CLI list.
    if [ $((ITERATION % CLI_COUNT)) -eq 0 ]; then
        if [ $STOP_REQUESTED -eq 1 ]; then
            echo "Stop requested by user. Exiting."
            exit 0
        fi

        if [ -f "$STOP_FILE" ]; then
            echo "STOP file detected at $STOP_FILE. Removing and stopping iterations."
            rm -f "$STOP_FILE"
            exit 0
        fi

        echo "[Critic] Running $CRITIC_CLI after full CLI cycle..."
        run_cli_with_prompt "$CRITIC_CLI" "$CRITIC_PROMPT_FILE" "critic"
        CRITIC_EXIT_CODE=$?

        if [ $CRITIC_EXIT_CODE -ne 0 ]; then
            echo "Warning: critic mode ($CRITIC_CLI) exited with code $CRITIC_EXIT_CODE after iteration $ITERATION"
        fi

        echo ""
    fi

    echo ""
done

echo "Reached iteration limit of $ITERATION_LIMIT. Stopping."
