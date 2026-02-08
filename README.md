# cc-kit

A toolkit and plugin marketplace for Claude Code. Some components are installable plugins (via `claude plugin install`), others are standalone scripts or config files installed via curl.

## Plugin Marketplace

cc-kit doubles as a [Claude Code plugin marketplace](https://docs.anthropic.com/en/docs/claude-code/plugins). Plugins provide slash-command skills that run inside Claude Code. Not everything in cc-kit is a plugin — cc-launcher and cc-headless are standalone and installed separately.

```bash
# Add the marketplace
claude plugin marketplace add https://github.com/Gnnng/cc-kit

# Install a plugin
claude plugin install cc-devcontainer
```

### Available Plugins

| Plugin | Description |
|--------|-------------|
| `cc-devcontainer` | Devcontainer setup with Claude Code authentication for headless agents |

## Installation

### Standalone components (curl)

cc-launcher and cc-headless are not plugins — install them with the install script:

```bash
# Install cc-launcher
curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-launcher

# Install cc-headless config
curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-headless
```

### Plugins

Plugins can be installed via the marketplace (see above) or with the install script:

```bash
# Install cc-devcontainer plugin
curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-devcontainer
```

### Options

```bash
# Force overwrite existing files
curl -fsSL ... | bash -s cc-launcher -f

# Preview what will be installed
./install.sh cc-launcher --dry-run
```

### Manual Install

See component-specific sections below for manual installation steps.

---

## What's Included

| Component | Type | Description |
|-----------|------|-------------|
| [cc-launcher](#cc-launcher) | Standalone script | Multi-provider launcher - switch between Anthropic and alternative backends |
| [cc-headless](#cc-headless) | Config files | Configuration for headless/API-only Claude Code sessions |
| [cc-devcontainer](#cc-devcontainer) | Plugin | Devcontainer setup and troubleshooting with auth detection |

---

## cc-launcher

Multi-provider launcher for Claude Code. Switch between Anthropic subscription, Anthropic API, third-party providers, and local servers.

### Features

- **Single file, zero dependencies** - one bash script, download and run
- **Multiple providers** - Anthropic, DeepSeek, Zhipu, Moonshot, MiniMax, and more
- **Local server support** - Ollama, LM Studio, LlamaBarn, llama.cpp
- **Custom endpoints** - any Anthropic-compatible URL
- **Model tier mapping** - configure opus/sonnet/haiku models per provider
- **Fully transparent** - readable bash, see exactly what happens before `exec claude`

### Quick Start

```bash
# Download
curl -o ~/.local/bin/cc-launcher https://raw.githubusercontent.com/Gnnng/cc-kit/main/cc-launcher
chmod +x ~/.local/bin/cc-launcher

# Run
cc-launcher                      # Claude subscription (default)
cc-launcher anthropic            # Anthropic API
cc-launcher deepseek             # DeepSeek
cc-launcher ollama "qwen3:32b"   # Local Ollama with model
```

### Providers

| Provider | Aliases | URL | Env Variable |
|----------|---------|-----|--------------|
| Subscription | `sub` | - | `CLAUDE_CODE_OAUTH_TOKEN` |
| Anthropic API | `anthropic`, `api` | api.anthropic.com | `ANTHROPIC_API_KEY` |
| DeepSeek | `deepseek` | api.deepseek.com/anthropic | `DEEPSEEK_API_KEY` |
| Zhipu AI | `zhipu`, `zai` | api.z.ai/api/anthropic | `ZAI_API_KEY` |
| Moonshot | `moonshot`, `kimi` | api.moonshot.ai/anthropic | `MOONSHOT_API_KEY` |
| MiniMax | `minimax` | api.minimax.io/anthropic | `MINIMAX_API_KEY` |

### Local Servers

| Provider | Default URL |
|----------|-------------|
| `ollama` | localhost:11434 |
| `lmstudio` | localhost:1234 |
| `llama-server` | localhost:8080 |
| `llamabarn` | localhost:2276 |

```bash
cc-launcher ollama "gpt-oss"              # Single model for all tiers
cc-launcher ollama "big,small"            # opus+sonnet=big, haiku=small
cc-launcher ollama "huge,big,small"       # opus=huge, sonnet=big, haiku=small
```

### Custom URL

```bash
cc-launcher "https://api.example.com" "api-key" "model-name"
```

Run `cc-launcher --help` for full usage information.

---

## cc-headless

Configuration files for running Claude Code in headless/API-only mode without subscription login.

### Features

- **API key authentication** - use `ANTHROPIC_API_KEY` instead of subscription
- **Yolo mode** - bypass permission prompts for automated workflows
- **Custom endpoints** - configure alternative API URLs

### Setup

```bash
cd cc-headless
cp -r .claude ~/
cp .claude.json ~/
```

Then set your API key:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

See [cc-headless/README.md](cc-headless/README.md) for more details.

---

## cc-devcontainer

Plugin for initializing and troubleshooting devcontainers with Claude Code authentication. Provides two skills: `/devcontainer-init` and `/devcontainer-troubleshoot`.

### Authentication Detection

The plugin automatically detects your Claude Code credentials (in priority order):

1. **OAuth token** (`CLAUDE_CODE_OAUTH_TOKEN`) — env var, then platform storage (macOS Keychain or `~/.claude/.credentials.json` on Linux)
2. **Enterprise token** (`ANTHROPIC_AUTH_TOKEN`) — env var
3. **API key** (`ANTHROPIC_API_KEY`) — env var

Detected credentials are written to `.devcontainer/.env` and passed into the container automatically.

### Skills

**`/devcontainer-init`** — Scaffolds a `.devcontainer/` directory with Dockerfile, devcontainer.json, and an `.env` file containing your detected auth credentials. Optionally accepts `--name <container-name>`.

**`/devcontainer-troubleshoot`** — Diagnoses auth and container issues. Checks host credentials, `.env` configuration, container environment, and Claude CLI availability. Run with `auth`, `container`, or `all`.

See [cc-devcontainer/skills/devcontainer-init/SKILL.md](cc-devcontainer/skills/devcontainer-init/SKILL.md) and [cc-devcontainer/skills/devcontainer-troubleshoot/SKILL.md](cc-devcontainer/skills/devcontainer-troubleshoot/SKILL.md) for full details.

---

## License

MIT
