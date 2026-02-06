---
name: devcontainer-troubleshoot
description: Troubleshoot devcontainer and Claude Code authentication issues
argument-hint: [auth | container | all]
allowed-tools: Bash(devcontainer exec --workspace-folder . *), Bash(security find-generic-password -s "Claude Code-credentials" *), Bash(jq *), Read
---

# /devcontainer-troubleshoot

Diagnose and fix common devcontainer and Claude Code authentication issues.

## Handle: $ARGUMENTS

Parse the argument to determine what to troubleshoot:
- `auth` or no argument → Check authentication setup
- `container` → Check devcontainer status
- `all` → Run all checks

## Authentication Checks (`auth`)

### 1. Check host authentication

Detect which auth method is configured on the host:

**Check environment variables:**
```bash
[ -n "$CLAUDE_CODE_OAUTH_TOKEN" ] && echo "CLAUDE_CODE_OAUTH_TOKEN: set"
[ -n "$ANTHROPIC_AUTH_TOKEN" ] && echo "ANTHROPIC_AUTH_TOKEN: set"
[ -n "$ANTHROPIC_API_KEY" ] && echo "ANTHROPIC_API_KEY: set"
```

**Check platform storage:**

macOS:
```bash
security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r 'keys' 2>/dev/null
```

Linux:
```bash
[ -f ~/.claude/.credentials.json ] && jq -r 'keys' ~/.claude/.credentials.json
```

### 2. Check .devcontainer/.env file

```bash
[ -f .devcontainer/.env ] && cat .devcontainer/.env | sed 's/=.*/=<redacted>/'
```

Show which variables are configured (values redacted).

### 3. Check container environment

If container is running:
```bash
devcontainer exec --workspace-folder . env | grep -E '^(CLAUDE_CODE_OAUTH_TOKEN|ANTHROPIC_AUTH_TOKEN|ANTHROPIC_API_KEY|GH_TOKEN)=' | sed 's/=.*/=<redacted>/'
```

### 4. Test Claude CLI in container

```bash
devcontainer exec --workspace-folder . claude --version
devcontainer exec --workspace-folder . claude /cost 2>&1 | head -5
```

## Container Checks (`container`)

### 1. Check devcontainer configuration

```bash
[ -f .devcontainer/devcontainer.json ] && echo "devcontainer.json: exists"
[ -f .devcontainer/Dockerfile ] && echo "Dockerfile: exists"
[ -f .devcontainer/.env ] && echo ".env: exists"
```

### 2. Check container status

```bash
devcontainer exec --workspace-folder . echo "Container is running" 2>&1
```

### 3. Check required tools in container

```bash
devcontainer exec --workspace-folder . which tmux jq claude git gh
```

### 4. Check tmux session

```bash
devcontainer exec --workspace-folder . tmux list-sessions 2>&1
```

## Common Issues and Fixes

### Auth not passed to container
- **Symptom**: `claude` works on host but not in container
- **Fix**: Run `/devcontainer-init` to set up `.devcontainer/.env`

### Container not starting
- **Symptom**: `devcontainer up` fails
- **Fix**: Check Docker is running, try `devcontainer up --workspace-folder . --remove-existing-container`

### OAuth token expired
- **Symptom**: `claude` returns auth error
- **Fix**: Re-login on host with `claude /login`, then run `/devcontainer-init` again

### Missing tools in container
- **Symptom**: `tmux` or `jq` not found
- **Fix**: Rebuild container with `devcontainer up --workspace-folder . --remove-existing-container`

## Report

Summarize findings:
- Host auth status
- Container auth status
- Container health
- Any issues found with recommended fixes
