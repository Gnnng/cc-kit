#!/bin/bash
# Test cases for cc-launcher
# This file is sourced by run_tests.sh which provides:
#   run_launcher, assert_eq, assert_match, assert_empty, assert_not_set,
#   captured_env, captured_env_set, captured_arg, captured_argc,
#   captured_stdout, captured_stderr, TEST_CAPTURE_DIR

# shellcheck disable=SC2154  # Variables provided by test harness

# ===========================================================================
# Subscription path
# ===========================================================================

test_sub_default_no_args() {
    run_launcher || return 1
    assert_eq "0" "$(captured_argc)" "no args to claude" || return 1
    assert_not_set ANTHROPIC_API_KEY || return 1
    assert_not_set ANTHROPIC_BASE_URL || return 1
}

test_sub_explicit() {
    run_launcher sub || return 1
    assert_eq "0" "$(captured_argc)" || return 1
    assert_not_set ANTHROPIC_API_KEY || return 1
}

test_sub_subscription_keyword() {
    run_launcher subscription || return 1
    assert_eq "0" "$(captured_argc)" || return 1
    assert_not_set ANTHROPIC_API_KEY || return 1
}

test_sub_unsets_api_key() {
    export ANTHROPIC_API_KEY="should-be-removed"
    run_launcher sub || return 1
    assert_not_set ANTHROPIC_API_KEY "api key removed in sub mode" || return 1
}

test_sub_passthrough_separator() {
    run_launcher sub -- --verbose --print || return 1
    assert_eq "2" "$(captured_argc)" || return 1
    assert_eq "--verbose" "$(captured_arg 1)" || return 1
    assert_eq "--print" "$(captured_arg 2)" || return 1
}

# ===========================================================================
# Custom URL path
# ===========================================================================

test_custom_url_basic() {
    run_launcher "https://example.com/v1" "test-key" || return 1
    assert_eq "https://example.com/v1" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "test-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
    assert_eq "1" "$(captured_env CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)" || return 1
    assert_eq "0" "$(captured_argc)" "no extra args" || return 1
}

test_custom_url_with_model() {
    run_launcher "https://example.com" "key" "mymodel" || return 1
    assert_eq "https://example.com" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
    assert_eq "mymodel" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "mymodel" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "mymodel" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_custom_url_comma_2_models() {
    run_launcher "https://example.com" "key" "big,small" || return 1
    assert_eq "big" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "big" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "small" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_custom_url_comma_3_models() {
    run_launcher "https://example.com" "key" "huge,mid,tiny" || return 1
    assert_eq "huge" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "mid" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "tiny" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_custom_url_separator() {
    run_launcher "https://example.com" "key" -- --verbose || return 1
    assert_eq "https://example.com" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "1" "$(captured_argc)" || return 1
    assert_eq "--verbose" "$(captured_arg 1)" || return 1
}

test_custom_url_model_and_separator() {
    run_launcher "https://example.com" "key" "mymodel" -- --print || return 1
    assert_eq "mymodel" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "1" "$(captured_argc)" || return 1
    assert_eq "--print" "$(captured_arg 1)" || return 1
}

test_custom_url_flag_not_model() {
    run_launcher "https://example.com" "key" --verbose || return 1
    assert_not_set ANTHROPIC_DEFAULT_OPUS_MODEL "flag not consumed as model" || return 1
    assert_eq "1" "$(captured_argc)" || return 1
    assert_eq "--verbose" "$(captured_arg 1)" || return 1
}

test_custom_url_http_scheme() {
    run_launcher "http://localhost:8080" "key" || return 1
    assert_eq "http://localhost:8080" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

# ===========================================================================
# Local server path
# ===========================================================================

test_local_ollama() {
    run_launcher ollama || return 1
    assert_eq "http://localhost:11434" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "local" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
    assert_eq "1" "$(captured_env CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)" || return 1
}

test_local_llama_server() {
    run_launcher llama-server || return 1
    assert_eq "http://localhost:8080" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "local" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_local_lmstudio() {
    run_launcher lmstudio || return 1
    assert_eq "http://localhost:1234" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
}

test_local_lm_studio_alias() {
    run_launcher lm-studio || return 1
    assert_eq "http://localhost:1234" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
}

test_local_llamabarn() {
    run_launcher llamabarn || return 1
    assert_eq "http://localhost:2276" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
}

test_local_llama_barn_alias() {
    run_launcher llama-barn || return 1
    assert_eq "http://localhost:2276" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
}

test_local_with_model() {
    run_launcher ollama "qwen3" || return 1
    assert_eq "http://localhost:11434" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "qwen3" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "qwen3" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "qwen3" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_local_preserves_auth_token() {
    export ANTHROPIC_AUTH_TOKEN="my-real-token"
    run_launcher ollama || return 1
    assert_eq "my-real-token" "$(captured_env ANTHROPIC_AUTH_TOKEN)" "existing token preserved" || return 1
}

test_local_preserves_api_key() {
    export ANTHROPIC_API_KEY="my-api-key"
    run_launcher ollama || return 1
    # When ANTHROPIC_API_KEY is set, ANTHROPIC_AUTH_TOKEN should NOT be overwritten to "local"
    assert_not_set ANTHROPIC_AUTH_TOKEN "no auth token when api key present" || return 1
    assert_eq "my-api-key" "$(captured_env ANTHROPIC_API_KEY)" || return 1
}

test_local_separator() {
    run_launcher ollama -- --verbose || return 1
    assert_eq "http://localhost:11434" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "1" "$(captured_argc)" || return 1
    assert_eq "--verbose" "$(captured_arg 1)" || return 1
}

test_local_flag_not_model() {
    run_launcher ollama --verbose || return 1
    assert_not_set ANTHROPIC_DEFAULT_OPUS_MODEL "flag not consumed as model" || return 1
    assert_eq "1" "$(captured_argc)" || return 1
    assert_eq "--verbose" "$(captured_arg 1)" || return 1
}

# ===========================================================================
# Named provider path
# ===========================================================================

# --- Moonshot ---

test_provider_moonshot_inline_key() {
    run_launcher moonshot "sk-moon-123" || return 1
    assert_eq "https://api.moonshot.ai/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-moon-123" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
    assert_eq "1" "$(captured_env CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)" || return 1
}

test_provider_moonshot_env_key() {
    export MOONSHOT_API_KEY="env-moon-key"
    run_launcher moonshot || return 1
    assert_eq "env-moon-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_kimi_alias() {
    run_launcher kimi "sk-kimi" || return 1
    assert_eq "https://api.moonshot.ai/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-kimi" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_moonshot_model_tiers() {
    run_launcher moonshot "key" || return 1
    assert_eq "kimi-k2.5" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "kimi-k2-turbo-preview" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "kimi-k2-turbo-preview" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

# --- Deepseek ---

test_provider_deepseek_inline_key() {
    run_launcher deepseek "sk-deep-123" || return 1
    assert_eq "https://api.deepseek.com/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-deep-123" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_deepseek_env_key() {
    export DEEPSEEK_API_KEY="env-deep-key"
    run_launcher deepseek || return 1
    assert_eq "env-deep-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_deepseek_model_tiers() {
    run_launcher deepseek "key" || return 1
    assert_eq "deepseek-chat" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "deepseek-chat" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "deepseek-chat" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

# --- Zhipu ---

test_provider_zhipu_inline_key() {
    run_launcher zhipu "sk-zhipu-123" || return 1
    assert_eq "https://api.z.ai/api/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-zhipu-123" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_zai_alias() {
    run_launcher zai "sk-zai" || return 1
    assert_eq "https://api.z.ai/api/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-zai" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_glm_alias() {
    run_launcher glm "sk-glm" || return 1
    assert_eq "https://api.z.ai/api/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-glm" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_zhipu_env_zai() {
    export ZAI_API_KEY="env-zai-key"
    run_launcher zhipu || return 1
    assert_eq "env-zai-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_zhipu_env_zhipuai() {
    export ZHIPUAI_API_KEY="env-zhipuai-key"
    run_launcher zhipu || return 1
    assert_eq "env-zhipuai-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_zhipu_model_tiers() {
    run_launcher zhipu "key" || return 1
    assert_eq "glm-5" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "glm-5" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "GLM-4.7-Flash" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

# --- Minimax ---

test_provider_minimax_inline_key() {
    run_launcher minimax "sk-mini-123" || return 1
    assert_eq "https://api.minimax.io/anthropic" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-mini-123" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_minimax_env_key() {
    export MINIMAX_API_KEY="env-mini-key"
    run_launcher minimax || return 1
    assert_eq "env-mini-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_minimax_model_tiers() {
    run_launcher minimax "key" || return 1
    assert_eq "MiniMax-M2.5" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "MiniMax-M2.5" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "MiniMax-M2.5-highspeed" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

# --- Anthropic (API mode) ---

test_provider_anthropic_inline_key() {
    run_launcher anthropic "sk-ant-123" || return 1
    assert_eq "https://api.anthropic.com" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-ant-123" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
    # Anthropic provider unsets model tiers (lets claude use defaults)
    assert_not_set ANTHROPIC_DEFAULT_OPUS_MODEL || return 1
    assert_not_set ANTHROPIC_DEFAULT_SONNET_MODEL || return 1
    assert_not_set ANTHROPIC_DEFAULT_HAIKU_MODEL || return 1
}

test_provider_anthropic_env_key() {
    export ANTHROPIC_API_KEY="env-ant-key"
    run_launcher anthropic || return 1
    assert_eq "env-ant-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_anthropic_unsets_oauth() {
    export CLAUDE_CODE_OAUTH_TOKEN="test-oauth-token"
    run_launcher anthropic "mykey" || return 1
    assert_not_set CLAUDE_CODE_OAUTH_TOKEN "oauth unset in api mode" || return 1
    assert_eq "mykey" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

test_provider_api_alias() {
    run_launcher api "sk-api" || return 1
    assert_eq "https://api.anthropic.com" "$(captured_env ANTHROPIC_BASE_URL)" || return 1
    assert_eq "sk-api" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
}

# --- Cross-provider: flag not consumed as key ---

test_provider_flag_not_key() {
    export MOONSHOT_API_KEY="env-key"
    run_launcher moonshot --verbose || return 1
    assert_eq "env-key" "$(captured_env ANTHROPIC_AUTH_TOKEN)" "used env key, not flag" || return 1
    assert_eq "1" "$(captured_argc)" || return 1
    assert_eq "--verbose" "$(captured_arg 1)" || return 1
}

# --- Cross-provider: -- separator ---

test_provider_separator() {
    run_launcher moonshot "mykey" -- --print --verbose || return 1
    assert_eq "mykey" "$(captured_env ANTHROPIC_AUTH_TOKEN)" || return 1
    assert_eq "2" "$(captured_argc)" || return 1
    assert_eq "--print" "$(captured_arg 1)" || return 1
    assert_eq "--verbose" "$(captured_arg 2)" || return 1
}

# ===========================================================================
# set_model_tiers (tested through local server path)
# ===========================================================================

test_model_tiers_single() {
    run_launcher ollama "single-model" || return 1
    assert_eq "single-model" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "single-model" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "single-model" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_model_tiers_two() {
    run_launcher ollama "big,small" || return 1
    assert_eq "big" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "big" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "small" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_model_tiers_three() {
    run_launcher ollama "huge,mid,tiny" || return 1
    assert_eq "huge" "$(captured_env ANTHROPIC_DEFAULT_OPUS_MODEL)" || return 1
    assert_eq "mid" "$(captured_env ANTHROPIC_DEFAULT_SONNET_MODEL)" || return 1
    assert_eq "tiny" "$(captured_env ANTHROPIC_DEFAULT_HAIKU_MODEL)" || return 1
}

test_model_tiers_four_errors() {
    if run_launcher ollama "a,b,c,d"; then
        echo "  FAIL: expected non-zero exit for 4 models" >&2
        return 1
    fi
    assert_match "1-3" "$(captured_stderr)" "error mentions 1-3" || return 1
}

# ===========================================================================
# Edge cases
# ===========================================================================

test_help_flag() {
    run_launcher --help || return 1
    # Mock should not have been called
    assert_eq "" "$(captured_argc)" "mock not called" || return 1
    assert_match "USAGE" "$(captured_stdout)" "shows usage" || return 1
}

test_h_flag() {
    run_launcher -h || return 1
    assert_eq "" "$(captured_argc)" "mock not called" || return 1
    assert_match "USAGE" "$(captured_stdout)" "shows usage" || return 1
}

test_unknown_provider_error() {
    if run_launcher foobar; then
        echo "  FAIL: expected non-zero exit for unknown provider" >&2
        return 1
    fi
    assert_match "Unknown provider" "$(captured_stderr)" || return 1
}

test_args_with_spaces() {
    run_launcher sub -- "--message" "hello world" "--flag=value with spaces" || return 1
    assert_eq "3" "$(captured_argc)" || return 1
    assert_eq "--message" "$(captured_arg 1)" || return 1
    assert_eq "hello world" "$(captured_arg 2)" || return 1
    assert_eq "--flag=value with spaces" "$(captured_arg 3)" || return 1
}
