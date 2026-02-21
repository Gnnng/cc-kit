#!/bin/bash
set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "claude binary exists" bash -c "command -v claude"
check "dot-claude is symlink to /var/lib/claude" bash -c "readlink $HOME/.claude | grep -q /var/lib/claude"
check "dot-claude.json is symlink" bash -c "readlink $HOME/.claude.json | grep -q /var/lib/claude/.claude.json"

reportResults
