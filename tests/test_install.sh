#!/bin/bash
# Test cases for install.sh
# This file is sourced by run_tests.sh which provides:
#   assert_eq, assert_match, TEST_CAPTURE_DIR

# shellcheck disable=SC2154  # Variables provided by test harness

INSTALL_SH="$SCRIPT_DIR/../install.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Create a fake HOME with cc-headless source files for local-mode installs
setup_install_env() {
    FAKE_HOME="$(mktemp -d)"
    export HOME="$FAKE_HOME"

    # Create local cc-headless source files so install.sh runs in "local" mode
    FAKE_REPO="$(mktemp -d)"
    cp "$INSTALL_SH" "$FAKE_REPO/install.sh"

    # cc-launcher (stub)
    echo '#!/bin/bash' > "$FAKE_REPO/cc-launcher"
    chmod +x "$FAKE_REPO/cc-launcher"

    # cc-headless files
    mkdir -p "$FAKE_REPO/cc-headless/.claude"
    echo '{"hasCompletedOnboarding": true}' > "$FAKE_REPO/cc-headless/.claude.json"
    echo '{"model": "opus", "permissions": {}, "env": {}}' > "$FAKE_REPO/cc-headless/.claude/settings.json"
    echo '#!/bin/bash' > "$FAKE_REPO/cc-headless/.claude/statusline.sh"
}

teardown_install_env() {
    rm -rf "$FAKE_HOME" "$FAKE_REPO"
}

run_install() {
    (cd "$FAKE_REPO" && bash install.sh "$@") >"$TEST_CAPTURE_DIR/stdout" 2>"$TEST_CAPTURE_DIR/stderr"
}

# ---------------------------------------------------------------------------
# cc-headless: basic install
# ---------------------------------------------------------------------------

test_headless_install_creates_files() {
    setup_install_env
    run_install cc-headless || { teardown_install_env; return 1; }

    assert_eq "true" "$([ -f "$FAKE_HOME/.claude.json" ] && echo true || echo false)" \
        ".claude.json created" || { teardown_install_env; return 1; }
    assert_eq "true" "$([ -f "$FAKE_HOME/.claude/settings.json" ] && echo true || echo false)" \
        "settings.json created" || { teardown_install_env; return 1; }
    assert_eq "true" "$([ -f "$FAKE_HOME/.claude/statusline.sh" ] && echo true || echo false)" \
        "statusline.sh created" || { teardown_install_env; return 1; }

    teardown_install_env
}

# ---------------------------------------------------------------------------
# cc-headless: --force overwrites existing files
# ---------------------------------------------------------------------------

test_headless_force_overwrites() {
    setup_install_env
    echo '{"old": true}' > "$FAKE_HOME/.claude.json"
    mkdir -p "$FAKE_HOME/.claude"
    echo '{"old": true}' > "$FAKE_HOME/.claude/settings.json"

    run_install cc-headless --force || { teardown_install_env; return 1; }

    local content
    content=$(cat "$FAKE_HOME/.claude.json")
    assert_match "hasCompletedOnboarding" "$content" "force overwrote .claude.json" || { teardown_install_env; return 1; }

    teardown_install_env
}

# ---------------------------------------------------------------------------
# cc-headless: --merge preserves symlinks
# ---------------------------------------------------------------------------

test_headless_merge_preserves_symlinks() {
    setup_install_env

    # Create a directory to simulate a volume
    local volume_dir
    volume_dir="$(mktemp -d)"

    # Put existing config in the volume
    echo '{"existing": true}' > "$volume_dir/.claude.json"
    mkdir -p "$volume_dir/.claude"
    echo '{"model": "sonnet", "permissions": {}, "env": {}}' > "$volume_dir/.claude/settings.json"

    # Symlink HOME files to the volume (like our devcontainer feature does)
    mkdir -p "$FAKE_HOME/.claude"
    ln -sf "$volume_dir/.claude.json" "$FAKE_HOME/.claude.json"
    ln -sf "$volume_dir/.claude/settings.json" "$FAKE_HOME/.claude/settings.json"

    run_install cc-headless --merge || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    # Symlinks should still be symlinks
    assert_eq "true" "$([ -L "$FAKE_HOME/.claude.json" ] && echo true || echo false)" \
        ".claude.json is still a symlink" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }
    assert_eq "true" "$([ -L "$FAKE_HOME/.claude/settings.json" ] && echo true || echo false)" \
        "settings.json is still a symlink" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    # Content should be merged (both existing and new keys)
    local json_content
    json_content=$(cat "$FAKE_HOME/.claude.json")
    assert_match "existing" "$json_content" "existing key preserved" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }
    assert_match "hasCompletedOnboarding" "$json_content" "new key merged" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    # Volume file should have the merged content (written through symlink)
    local volume_content
    volume_content=$(cat "$volume_dir/.claude.json")
    assert_match "existing" "$volume_content" "volume has merged content" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    rm -rf "$volume_dir"
    teardown_install_env
}

# ---------------------------------------------------------------------------
# cc-headless: --yolo preserves symlinks
# ---------------------------------------------------------------------------

test_headless_yolo_preserves_symlinks() {
    setup_install_env

    local volume_dir
    volume_dir="$(mktemp -d)"

    # Symlink settings.json to a volume
    mkdir -p "$FAKE_HOME/.claude" "$volume_dir"
    echo '{"model": "opus", "permissions": {}, "env": {}}' > "$volume_dir/settings.json"
    ln -sf "$volume_dir/settings.json" "$FAKE_HOME/.claude/settings.json"

    run_install cc-headless --force --yolo || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    # Symlink should still be a symlink
    assert_eq "true" "$([ -L "$FAKE_HOME/.claude/settings.json" ] && echo true || echo false)" \
        "settings.json is still a symlink after --yolo" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    # Should have bypassPermissions
    local content
    content=$(cat "$FAKE_HOME/.claude/settings.json")
    assert_match "bypassPermissions" "$content" "bypass permissions set" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    # Volume file should have it too
    local volume_content
    volume_content=$(cat "$volume_dir/settings.json")
    assert_match "bypassPermissions" "$volume_content" "volume has bypass permissions" || { rm -rf "$volume_dir"; teardown_install_env; return 1; }

    rm -rf "$volume_dir"
    teardown_install_env
}

# ---------------------------------------------------------------------------
# cc-headless: fails on existing files without --force or --merge
# ---------------------------------------------------------------------------

test_headless_fails_on_existing_files() {
    setup_install_env
    echo '{"old": true}' > "$FAKE_HOME/.claude.json"

    run_install cc-headless && { teardown_install_env; return 1; }  # should fail

    teardown_install_env
}

# ---------------------------------------------------------------------------
# cc-launcher: installs to ~/.local/bin/
# ---------------------------------------------------------------------------

test_launcher_installs() {
    setup_install_env
    run_install cc-launcher || { teardown_install_env; return 1; }

    assert_eq "true" "$([ -x "$FAKE_HOME/.local/bin/cc-launcher" ] && echo true || echo false)" \
        "cc-launcher is executable" || { teardown_install_env; return 1; }

    teardown_install_env
}
