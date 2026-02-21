#!/bin/bash
set -e

# shellcheck source=/dev/null
source dev-container-features-test-lib

check "claude binary exists" bash -c "command -v claude"
check "cc-launcher exists" bash -c "command -v cc-launcher"
check "cc-launcher is executable" bash -c "test -x $HOME/.local/bin/cc-launcher"

reportResults
