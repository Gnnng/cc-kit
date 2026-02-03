# Development Guidelines

1. Run shellcheck on any shell script before committing
2. Use devcontainer to test the install script and other components
3. Don't install scripts locally - it may cause unforeseen issues
4. Use `$'...'` syntax for ANSI color codes (e.g., `C_RED=$'\033[31m'`)

## Devcontainer Commands

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
