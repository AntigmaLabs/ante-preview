
[![Discord](https://img.shields.io/badge/Discord-Join%20Us-5865F2?logo=discord&logoColor=white)](https://discord.gg/CbAsUR434B)
[![Website](https://img.shields.io/badge/Website-antigma.ai-orange?logo=google-chrome&logoColor=white)](https://antigma.ai)
[![Twitter](https://img.shields.io/twitter/follow/antigma_labs?style=social)](https://twitter.com/antigma_labs)
[![🤗 Hugging Face](https://img.shields.io/badge/HuggingFace-Antigma-yellow?logo=huggingface&logoColor=white)](https://huggingface.co/Antigma)

# Ante Preview

> **⚠️ Alpha Preview For Evaluation**  
> This project is currently in alpha and provided as a research preview.
> Currently only support MacOs and Linux

Ante is a lightweight agent live in terminal built by Antigma Labs.
It was designed from ground up and built with native rust for security, performance and resistance to AI generated slop. 


## Quick Start

### Installation
Download the install.sh script and run
```sh
curl -fsSL https://ante.run/install.sh | bash -s -- anen.ai/install-manifest
```

### Run as headless

Positional prompt: `ante -p "your prompt"`

With overrides: `ante --model gpt-4o-mini --provider openai "your prompt"`

From stdin: echo `"your prompt" | ante "explain"`

### Run as Interactive TUI
`ante`

## Documentation Site
Documentation site is deployed at [docs.antigma.ai](https://docs.antigma.ai) and uses mintlify.

Check local change

in `docs/` folder run `npx mintlify dev`

## Github Page
Use Github Page to host static files in `gh-page` like installation script
