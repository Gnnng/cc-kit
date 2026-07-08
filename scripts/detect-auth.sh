#!/bin/bash
# Detect Claude Code authentication method and output credentials
# Usage: ./detect-auth.sh [--env-file <path>]
#
# Priority order:
#   1. CLAUDE_CODE_OAUTH_TOKEN (subscription mode - most common)
#   2. ANTHROPIC_AUTH_TOKEN (enterprise)
#   3. ANTHROPIC_API_KEY (API key)
#
# For OAuth token, checks env var first, then platform storage:
#   - macOS: Keychain "Claude Code-credentials"
#   - Linux: ~/.claude/.credentials.json

set -e

ENV_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

AUTH_VAR=""
AUTH_VALUE=""

# 1. Check CLAUDE_CODE_OAUTH_TOKEN (subscription mode)
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    AUTH_VAR="CLAUDE_CODE_OAUTH_TOKEN"
    AUTH_VALUE="$CLAUDE_CODE_OAUTH_TOKEN"
else
    # Extract from platform storage
    if [ "$(uname)" = "Darwin" ]; then
        # macOS: read from Keychain
        AUTH_VALUE=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || true)
    else
        # Linux: read from credentials file
        AUTH_VALUE=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null || true)
    fi
    [ -n "$AUTH_VALUE" ] && AUTH_VAR="CLAUDE_CODE_OAUTH_TOKEN"
fi

# 2. Check ANTHROPIC_AUTH_TOKEN (enterprise)
if [ -z "$AUTH_VAR" ] && [ -n "$ANTHROPIC_AUTH_TOKEN" ]; then
    AUTH_VAR="ANTHROPIC_AUTH_TOKEN"
    AUTH_VALUE="$ANTHROPIC_AUTH_TOKEN"
fi

# 3. Check ANTHROPIC_API_KEY (API key)
if [ -z "$AUTH_VAR" ] && [ -n "$ANTHROPIC_API_KEY" ]; then
    AUTH_VAR="ANTHROPIC_API_KEY"
    AUTH_VALUE="$ANTHROPIC_API_KEY"
fi

# Output results
if [ -n "$AUTH_VAR" ]; then
    if [ -n "$ENV_FILE" ]; then
        # Write to env file
        echo "${AUTH_VAR}=${AUTH_VALUE}" > "$ENV_FILE"
        # Add GH_TOKEN if set
        [ -n "$GH_TOKEN" ] && echo "GH_TOKEN=${GH_TOKEN}" >> "$ENV_FILE"
        echo "AUTH_METHOD=${AUTH_VAR}"
    else
        # Output to stdout
        echo "AUTH_METHOD=${AUTH_VAR}"
        echo "${AUTH_VAR}=${AUTH_VALUE}"
        [ -n "$GH_TOKEN" ] && echo "GH_TOKEN=${GH_TOKEN}"
    fi
else
    echo "AUTH_METHOD=none"
    exit 1
fi
