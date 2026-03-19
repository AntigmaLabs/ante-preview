
[![Discord](https://img.shields.io/badge/Discord-Join%20Us-5865F2?logo=discord&logoColor=white)](https://discord.gg/CbAsUR434B)
[![Docs](https://img.shields.io/badge/Docs-docs.antigma.ai-orange?logo=safari&logoColor=white)](https://docs.antigma.ai)
[![X](https://img.shields.io/badge/X-@antigma__labs-black?logo=x&logoColor=white)](https://twitter.com/antigma_labs)
[![Hugging Face](https://img.shields.io/badge/HuggingFace-Antigma-yellow?logo=huggingface&logoColor=white)](https://huggingface.co/Antigma)

# Ante

> **⚠️ Alpha Preview**
> Ante is currently in alpha and provided as a research preview. Expect breaking changes and incomplete functionality. macOS and Linux only.

Ante is an AI-native, cloud-native, local-first agent runtime built by [Antigma Labs](https://antigma.ai). A single ~15MB Rust binary with zero runtime dependencies — designed from the ground up for security, performance, and resistance to AI-generated slop.

## Key Features

- **Lightweight agent core** — ~15MB binary, zero dependencies. Built for minimal overhead and maximum throughput.
- **Native local models** — Built-in local inference integration. No API keys, no internet, no data leaving your device.
- **Zero vendor lock-in** — Bring your own API key or local model. Switch between 12+ providers freely. No account required.
- **Client-daemon architecture** — Run as an interactive TUI, headless CLI, or long-lived server (`ante serve`).
- **Multi-agent orchestration** — Spawn sub-agents, coordinate complex tasks across independent, decentralized, or centralized architectures.
- **Extensible** — Custom skills, sub-agents, and persistent memory across sessions.
- **Benchmark proven** — Topped the Terminal Bench 1.0 and 2.0 leaderboards. Public, reproducible evals.

## Performance

Ante is built for scale. Its lightweight Rust core uses a fraction of the memory and disk I/O of comparable agents, completing the same coding tasks with dramatically lower overhead — making it practical to run hundreds of parallel agents on a single machine.

Docker resource usage across 20 parallel tasks (Ante vs Claude Code vs Opencode):

![Resource Usage Comparison](docs/assets/compare_animated.gif)

Across 20 parallel tasks, Ante uses **~7× less peak memory**, **~9× less average CPU**, and generates **~5× less total disk I/O** than Claude Code — while completing the same workload. That efficiency is what makes it practical to run hundreds of agents in parallel at scale. See the [full comparison table](docs/assets/compare_table.md) for detailed CPU, memory, disk, and I/O metrics.

## Quick Start

### Installation

Ante is distributed as a single, self-contained binary with no external dependencies — just download and run.

```sh
curl -fsSL https://ante.run/install.sh | bash
```

### Interactive TUI

```sh
ante
```

### Headless Mode

```sh
# Fix a bug
ante -p "find and fix the failing test in src/auth"

# Review a diff
git diff | ante -p "review this for security issues"

# Use a different provider
ante --provider openai --model gpt-5.4 -p "refactor the database module"

# Run fully offline with a local model
ante --provider local -p "add error handling to src/main.rs"
```

### Server Mode

```sh
ante serve
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Clients                             │
│                                                             │
│   ┌───────────┐    ┌───────────┐    ┌────────────────────┐  │
│   │    TUI    │    │ Headless  │    │    ante serve      │  │
│   │  (ante)   │    │ (ante -p) │    │  (stdio / ws)      │  │
│   └─────┬─────┘    └─────┬─────┘    └─────────┬──────────┘  │
└─────────┼────────────────┼─────────────────────┼────────────┘
          │     Op         │                     │
          ▼                ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                         Daemon                              │
│                                                             │
│   Session ──▶ Turn ──▶ Step                                 │
│                                                             │
│   ┌──────────┐  ┌──────────────┐  ┌───────────────────┐    │
│   │  Tools   │  │  Permission  │  │  Skills / Agents  │    │
│   └──────────┘  └──────────────┘  └───────────────────┘    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     LLM Providers                           │
│                                                             │
│   Anthropic · OpenAI · Gemini · Grok · Open Router · Local  │
└─────────────────────────────────────────────────────────────┘
```

## Supported Providers

Ante works with 12+ providers out of the box:

| Provider | Example Models |
|----------|---------------|
| Anthropic | Claude Sonnet 4.5, Opus 4.6 |
| OpenAI | GPT-5 family |
| Google Gemini | Gemini 3 family |
| Grok (xAI) | Grok 4 |
| Open Router | Multiple providers |
| Local (GGUF) | Any GGUF model via built-in llama.cpp |
| ...and more | Vertex AI, Zai, Antix, OpenAI-compatible |

Configure providers via environment variables (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, etc.) or OAuth. Add custom providers in `~/.ante/catalog.json`.

## FAQ

### Does Ante require an account or login?

No. Ante has zero vendor lock-in — you can use it with just an API key from any supported provider, or run fully offline with local models. No Antigma account is needed.

### Does Ante support Windows?

Not yet. Ante currently supports macOS and Linux only. Windows support may come in the future.

### Can I run Ante completely offline?

Yes. Ante has a built-in llama.cpp engine that runs GGUF models locally. It handles engine installation, model discovery, and memory management automatically. No API keys or internet connection required.


### Can I use my own custom models or providers?

Yes. Create a `~/.ante/catalog.json` file to add or override providers and models with custom endpoints, API keys, and configurations. Any OpenAI-compatible API works.

### What is the `ante serve` mode for?

Server mode runs Ante as a long-lived daemon that communicates over a structured JSONL protocol. It's ideal for building editor plugins, web UIs, and custom integrations on top of Ante.

### How does Ante compare to other AI coding agents?

Ante is built from scratch in native Rust — not a wrapper around an SDK or framework. Key differentiators: ~15MB self-contained binary, client-daemon architecture, native local model support, zero vendor lock-in, and multi-agent orchestration. It's designed for the "cellular-native" thesis — agents lightweight enough to run thousands of replicas at scale.

See the [resource usage comparison](docs/assets/compare_table.md) across 20 parallel tasks for concrete numbers.

### How do I configure Ante?

Settings live in `~/.ante/settings.json`. You can set your default model, provider, theme, and permission policy. CLI flags override settings for individual sessions. See the [configuration docs](https://docs.antigma.ai/configuration/preference) for details.

### Can I extend Ante with custom skills or sub-agents?

Yes. Drop skill files in `~/.ante/skills/` (user-level) or `.ante/skills/` (project-level) using the Open Agent Skills format. Custom sub-agents go in `~/.ante/agents/` with their own prompts, tool sets, and model overrides.

## Documentation

Full documentation is available at [docs.antigma.ai](https://docs.antigma.ai).

To preview docs locally, run `npx mintlify dev` from the `docs/` directory.
