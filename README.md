# cc-kit

A toolkit for Claude Code — standalone scripts and config files installed via curl.

## Installation

```bash
# Install cc-launcher
curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-launcher

# Install cc-headless config
curl -fsSL https://raw.githubusercontent.com/Gnnng/cc-kit/main/install.sh | bash -s cc-headless
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
| [detect-auth](#detect-auth) | Utility script | Detect Claude Code credentials and export them as env vars |

---

## cc-launcher

Multi-provider launcher for Claude Code. Switch between Anthropic subscription, Anthropic API, third-party providers, and local servers.

### Features

- **Single file, zero dependencies** - one bash script, download and run
- **Multiple providers** - Anthropic, DeepSeek, Zhipu, Moonshot, MiniMax, and more
- **Local server support** - Ollama, LM Studio, Llama (llama.cpp)
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
| `llama` | localhost:8080 |

`llama` is the [Llama macOS app](https://github.com/ggml-org/Llama-macOS) (formerly LlamaBarn), the unified [`llama serve`](https://llama.app) CLI, or plain llama.cpp `llama-server` — all serve on port 8080. `llamabarn` and `llama-barn` still work as aliases (now pointing at 8080; pre-0.32 LlamaBarn on 2276 needs a custom URL).

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

## detect-auth

[`scripts/detect-auth.sh`](scripts/detect-auth.sh) detects your Claude Code credentials and outputs them as env vars — useful for passing auth into VMs or containers. Checks in priority order:

1. **OAuth token** (`CLAUDE_CODE_OAUTH_TOKEN`) — env var, then platform storage (macOS Keychain or `~/.claude/.credentials.json` on Linux)
2. **Enterprise token** (`ANTHROPIC_AUTH_TOKEN`) — env var
3. **API key** (`ANTHROPIC_API_KEY`) — env var

```bash
# Print detected credentials to stdout
./scripts/detect-auth.sh

# Write them to an env file
./scripts/detect-auth.sh --env-file .env
```

---

## License

MIT
