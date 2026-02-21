#!/bin/bash
# Test harness for cc-launcher
# Usage: bash tests/run_tests.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CC_LAUNCHER="$SCRIPT_DIR/../cc-launcher"
MOCK_CLAUDE="$SCRIPT_DIR/fixtures/mock_claude"

# Colors
if [[ -t 1 ]]; then
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
else
    C_RED=''
    C_GREEN=''
    C_RESET=''
    C_BOLD=''
fi

PASS_COUNT=0
FAIL_COUNT=0
FAILURES=()

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

assert_eq() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-assert_eq}"
    if [[ "$expected" != "$actual" ]]; then
        echo "  FAIL ($msg): expected '$expected', got '$actual'" >&2
        return 1
    fi
}

assert_match() {
    local pattern="$1"
    local actual="$2"
    local msg="${3:-assert_match}"
    if [[ ! "$actual" =~ $pattern ]]; then
        echo "  FAIL ($msg): '$actual' does not match /$pattern/" >&2
        return 1
    fi
}

assert_empty() {
    local actual="$1"
    local msg="${2:-assert_empty}"
    if [[ -n "$actual" ]]; then
        echo "  FAIL ($msg): expected empty, got '$actual'" >&2
        return 1
    fi
}

assert_not_set() {
    local var="$1"
    local msg="${2:-$var should be unset}"
    if captured_env_set "$var"; then
        echo "  FAIL ($msg): expected '$var' to be unset, got '$(captured_env "$var")'" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Capture helpers — read files written by mock_claude
# ---------------------------------------------------------------------------

captured_env() {
    grep "^${1}=" "$TEST_CAPTURE_DIR/env" 2>/dev/null | head -1 | cut -d= -f2-
}

captured_env_set() {
    grep -q "^${1}=" "$TEST_CAPTURE_DIR/env" 2>/dev/null
}

captured_args() {
    cat "$TEST_CAPTURE_DIR/args" 2>/dev/null || true
}

captured_arg() {
    sed -n "${1}p" "$TEST_CAPTURE_DIR/args" 2>/dev/null || true
}

captured_argc() {
    cat "$TEST_CAPTURE_DIR/argc" 2>/dev/null || echo ""
}

captured_stdout() {
    cat "$TEST_CAPTURE_DIR/stdout" 2>/dev/null || true
}

captured_stderr() {
    cat "$TEST_CAPTURE_DIR/stderr" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Setup / teardown
# ---------------------------------------------------------------------------

setup() {
    TEST_CAPTURE_DIR="$(mktemp -d)"
    export TEST_CAPTURE_DIR
    export CC_TEST_CAPTURE_DIR="$TEST_CAPTURE_DIR"

    # Prepend mock claude to PATH
    ORIG_PATH="$PATH"
    MOCK_BIN_DIR="$(mktemp -d)"
    cp "$MOCK_CLAUDE" "$MOCK_BIN_DIR/claude"
    chmod +x "$MOCK_BIN_DIR/claude"
    export PATH="$MOCK_BIN_DIR:$ORIG_PATH"

    # Unset all env vars that cc-launcher reads or sets
    unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY
    unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL
    unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC CLAUDE_CODE_OAUTH_TOKEN
    unset MOONSHOT_API_KEY DEEPSEEK_API_KEY ZAI_API_KEY ZHIPUAI_API_KEY MINIMAX_API_KEY
}

teardown() {
    export PATH="$ORIG_PATH"
    rm -rf "$TEST_CAPTURE_DIR" "$MOCK_BIN_DIR"
}

# ---------------------------------------------------------------------------
# Launcher runner — runs cc-launcher in a subshell so exec doesn't kill us
# ---------------------------------------------------------------------------

run_launcher() {
    (bash "$CC_LAUNCHER" "$@") >"$TEST_CAPTURE_DIR/stdout" 2>"$TEST_CAPTURE_DIR/stderr"
}

# ---------------------------------------------------------------------------
# Source test cases
# ---------------------------------------------------------------------------

# shellcheck source=tests/test_cc_launcher.sh
source "$SCRIPT_DIR/test_cc_launcher.sh"

# shellcheck source=tests/test_install.sh
source "$SCRIPT_DIR/test_install.sh"

# ---------------------------------------------------------------------------
# Discover and run tests
# ---------------------------------------------------------------------------

test_functions=()
while IFS= read -r line; do
    test_functions+=("$line")
done < <(declare -F | awk '{print $3}' | grep '^test_' | sort)

if [[ ${#test_functions[@]} -eq 0 ]]; then
    echo "No test functions found" >&2
    exit 1
fi

echo "${C_BOLD}Running ${#test_functions[@]} tests...${C_RESET}"
echo ""

for func in "${test_functions[@]}"; do
    setup
    output=$("$func" 2>&1) && status=0 || status=$?
    if [[ $status -eq 0 ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        echo "  ${C_GREEN}PASS${C_RESET}  $func"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILURES+=("$func")
        echo "  ${C_RED}FAIL${C_RESET}  $func"
        if [[ -n "$output" ]]; then
            while IFS= read -r line; do
                printf '        %s\n' "$line"
            done <<< "$output"
        fi
    fi
    teardown
done

echo ""
echo "${C_BOLD}Results: ${C_GREEN}${PASS_COUNT} passed${C_RESET}, ${C_RED}${FAIL_COUNT} failed${C_RESET}"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed tests:"
    for f in "${FAILURES[@]}"; do
        echo "  - $f"
    done
    exit 1
fi
