## Getting Started

After applying this template, create a `.devcontainer/.env` file with your credentials:

```bash
# Option 1: API key
ANTHROPIC_API_KEY=sk-ant-...

# Option 2: OAuth token
CLAUDE_CODE_OAUTH_TOKEN=oat-...
```

Then start the devcontainer:

```bash
devcontainer up --workspace-folder .
```

## What's Included

- **Claude Code CLI** — installed and ready to use
- **cc-headless** — bypass-permissions mode for autonomous agents (enabled by default)
- **cc-launcher** — multi-provider launcher (enabled by default)
- **tmux** — with mouse support pre-configured
- **GitHub CLI** — for repository operations

## Authentication

The `.env` file is passed into the container via `--env-file`. Add `.devcontainer/.env` to your `.gitignore` to avoid committing secrets.

Alternatively, use `remoteEnv` in `devcontainer.json` to forward host environment variables:

```json
"remoteEnv": {
  "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
}
```

## Persistence

Claude Code state (`~/.claude` and `~/.claude.json`) is symlinked to `/var/lib/claude`. Mount a Docker volume at that path to persist auth tokens and session state across rebuilds.
