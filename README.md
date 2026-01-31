# cc-kit

A collection of tools and utilities for Claude Code.

## Installation

### Quick Install (recommended)

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

| Tool | Description |
|------|-------------|
| [cc-launcher](#cc-launcher) | Multi-provider launcher - switch between Anthropic and alternative backends |
| [cc-headless](#cc-headless) | Configuration for headless/API-only Claude Code sessions |

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

## License

MIT
