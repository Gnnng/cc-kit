## Usage

```json
"features": {
  "ghcr.io/Gnnng/cc-kit/claude-code:1": {}
}
```

### With cc-headless (bypass permissions + telemetry off)

```json
"features": {
  "ghcr.io/Gnnng/cc-kit/claude-code:1": {
    "headless": true
  }
}
```

### With cc-launcher (multi-provider support)

```json
"features": {
  "ghcr.io/Gnnng/cc-kit/claude-code:1": {
    "launcher": true
  }
}
```

## Persistence

A Docker volume is mounted at `/var/lib/claude` and symlinked to `~/.claude` and `~/.claude.json`. This persists auth tokens, session state, and configuration across container rebuilds.

## Authentication

Set your API key or OAuth token via environment variables in `devcontainer.json`:

```json
"remoteEnv": {
  "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
}
```
