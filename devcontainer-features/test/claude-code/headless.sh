#!/bin/bash
set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "claude binary exists" bash -c "command -v claude"
check "dot-claude is symlink to /var/lib/claude" bash -c "readlink $HOME/.claude | grep -q /var/lib/claude"
check "settings.json exists" bash -c "test -f $HOME/.claude/settings.json"
check "bypass permissions enabled" bash -c "grep -q bypassPermissions $HOME/.claude/settings.json"

reportResults
