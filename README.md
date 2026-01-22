# cc-kit

A collection of tools and utilities for Claude Code.

## cc-launcher

Multi-provider launcher for Claude Code. Switch between Anthropic and alternative backends.

- **Single file, zero dependencies** - one bash script, download and run, no package managers or build steps
- **Fully transparent** - ~400 lines of readable bash, see exactly what env vars get set before `exec claude`
- **Easily hackable** - change models or add providers by editing a few lines, no config schemas to learn
- **No trust required** - open source, auditable in 5 minutes, no external runtime dependencies

### Usage

```bash
cc-launcher [provider] [api_key] [--] [claude-args...]
```

### Providers

| Provider | Aliases | Env Variable |
|----------|---------|--------------|
| Anthropic Subscription | `sub` | - |
| Anthropic API | `api` | `ANTHROPIC_API_KEY` |
| DeepSeek | `deepseek` | `DEEPSEEK_API_KEY` |
| Zhipu AI | `zhipu`, `zai`, `glm` | `ZAI_API_KEY` |
| Moonshot | `moonshot`, `kimi` | `MOONSHOT_API_KEY` |
| MiniMax | `minimax` | `MINIMAX_API_KEY` |
| Local llama-server | `llama-server` | - |
| Custom URL | `https://...` | - |

### Examples

```bash
cc-launcher sub              # Claude subscription (default)
cc-launcher deepseek         # DeepSeek (prompts for key if not set)
cc-launcher glm              # Zhipu via alias
cc-launcher kimi             # Moonshot via alias
cc-launcher "https://..."    # Custom Anthropic-compatible URL
```

### Installation

```bash
curl -o ~/.local/bin/cc-launcher https://raw.githubusercontent.com/Gnnng/cc-kit/main/cc-launcher
chmod +x ~/.local/bin/cc-launcher
```
