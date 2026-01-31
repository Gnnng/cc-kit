# Development Guidelines

1. Run shellcheck on any shell script before committing
2. Use devcontainer to test the install script and other components
3. Don't install scripts locally - it may cause unforeseen issues
4. Use `$'...'` syntax for ANSI color codes (e.g., `C_RED=$'\033[31m'`)
