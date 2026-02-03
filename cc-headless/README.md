# cc-headless

Configuration for running Claude Code with API keys instead of the default subscription login.

![screenshot](screenshot.png)

## Features

- **Custom statusline** showing context usage, model, session count, directory, git info, and line changes
- **Model preset** set to Opus
- **No co-authored-by** in commits (`includeCoAuthoredBy: false`)
- **Telemetry disabled** via `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`
- **Onboarding bypassed** so Claude Code starts immediately

## Setup

Copy the configuration files to your home directory:

```bash
cp -r .claude ~/
cp .claude.json ~/
```

## Authentication

```bash
# Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-..."

# Or with custom endpoint
export ANTHROPIC_BASE_URL="https://api.example.com"
export ANTHROPIC_AUTH_TOKEN="your-token"
```

Then run `claude` as usual.

## Statusline

The custom statusline (`~/.claude/statusline.sh`) displays:

| Element | Description |
|---------|-------------|
| Context bar | Visual progress bar showing token usage with buffer zone |
| Model | Current model with color-coded tier (Opus/Sonnet/Haiku) |
| Session count | `position/total (historical)` - active sessions in directory |
| Directory | Working directory with deterministic background color |
| Git info | Branch, dirty indicator, ahead/behind, line changes |
| Session ID | Dimmed session identifier |

The statusline works on both Linux and macOS.
