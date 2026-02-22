---
name: devcontainer-init
description: Initialize devcontainer with Claude Code authentication for headless agents
argument-hint: [--name <container-name>]
allowed-tools: Bash(git *), Bash(mkdir *), Bash(bash *), Bash(chmod *), Read, Write, Edit
---

# /devcontainer-init

Initialize a devcontainer configuration with automatic Claude Code authentication detection.

## Handle: $ARGUMENTS

Parse optional arguments:
- `--name <name>`: Custom container name (default: "claude-devcontainer")

## Steps

### 1. Check if this is a git repository (on host)

```bash
git rev-parse --git-dir
```

If not a git repo, initialize it:
```bash
git init
```

Note: Git init runs on HOST because typically the docker host is local and the directory
is mounted into the devcontainer.

### 2. Check if .devcontainer already exists

If `.devcontainer/` exists, ask user if they want to:
- Overwrite existing configuration
- Skip and keep existing
- Merge (keep existing, add missing files)

### 3. Detect Claude authentication

Run the auth detection script from [../../scripts/detect-auth.sh](../../scripts/detect-auth.sh):

```bash
bash <script-path>/detect-auth.sh
```

The script checks (in priority order):
1. `CLAUDE_CODE_OAUTH_TOKEN` - env var, then platform storage:
   - macOS: Keychain "Claude Code-credentials"
   - Linux: `~/.claude/.credentials.json`
2. `ANTHROPIC_AUTH_TOKEN` - env var only (enterprise)
3. `ANTHROPIC_API_KEY` - env var only (API key)

If no auth detected, warn user they'll need to configure manually.

### 4. Create .devcontainer directory

```bash
mkdir -p .devcontainer
```

### 5. Copy template files

Read and write the template:
- [templates/devcontainer.json](templates/devcontainer.json) → `.devcontainer/devcontainer.json`

If `--name` was provided, update the `"name"` field in devcontainer.json.

### 6. Inject authentication into devcontainer.json

Based on the auth method detected in step 3, add a `remoteEnv` block to the generated `devcontainer.json`:

- OAuth: `"remoteEnv": { "CLAUDE_CODE_OAUTH_TOKEN": "${localEnv:CLAUDE_CODE_OAUTH_TOKEN}" }`
- Enterprise: `"remoteEnv": { "ANTHROPIC_AUTH_TOKEN": "${localEnv:ANTHROPIC_AUTH_TOKEN}" }`
- API key: `"remoteEnv": { "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}" }`

If no auth detected, skip this step.

### 7. Report success

Show:
- Auth method detected (or "none - manual setup required")
- Files created
- Next steps:
  - `devcontainer up --workspace-folder .` to start
  - Use Claude Code inside the container

## Template Files

- [templates/devcontainer.json](templates/devcontainer.json) - Devcontainer config with claude-code feature and headless/launcher setup
