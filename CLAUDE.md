# Development Guidelines

1. Run shellcheck on any shell script before committing
2. Test with `bash tests/run_tests.sh`; container-based testing of the install script runs in CI or on a Docker-capable host
3. Don't install scripts locally - it may cause unforeseen issues
4. Use `$'...'` syntax for ANSI color codes (e.g., `C_RED=$'\033[31m'`)

## Devcontainer Commands

Note: requires a Docker-capable host.

```bash
# Start devcontainer (reuses existing if available)
devcontainer up --workspace-folder .

# Rebuild devcontainer (removes existing)
devcontainer up --workspace-folder . --remove-existing-container

# Force clean rebuild of image (no cache)
devcontainer build --workspace-folder . --no-cache

# Execute command inside devcontainer
devcontainer exec --workspace-folder . <command>

# Examples:
devcontainer exec --workspace-folder . tmux list-sessions
devcontainer exec --workspace-folder . claude
```
