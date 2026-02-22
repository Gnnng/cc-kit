## Getting Started

Start the devcontainer:

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

Use `remoteEnv` in `devcontainer.json` to forward host environment variables:

```json
"remoteEnv": {
  "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
}
```

Or with OAuth:

```json
"remoteEnv": {
  "CLAUDE_CODE_OAUTH_TOKEN": "${localEnv:CLAUDE_CODE_OAUTH_TOKEN}"
}
```

## Persistence

Claude Code state (`~/.claude` and `~/.claude.json`) is symlinked to `/var/lib/claude`. Mount a Docker volume at that path to persist auth tokens and session state across rebuilds.
