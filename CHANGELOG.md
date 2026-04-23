# Changelog

## v0.preview.15 - 2026-04-23

- Enable vision for local GGUF models and refresh offline model catalog
- Fix yolo resume bug
- Support nested skill metadata
- Add read-only bash permission heuristic
- Align headless startup provider handling
- Move message ID generation into OpMsg/EventMsg constructors
- Consolidate llm_smoke around session-based tool-call path
- Split antix into its own catalog module
- Harden release workflow reproducibility and failure recovery
- Move thinking option labels into TUI
- Update connect and model command description

## v0.preview.14 - 2026-04-21

- Add escape example of Ante and fix config reload bug
- Fix shutdown bug for offline serve and headless
- Show changelog on update
- Support symlinked user skill roots
- Scope release concurrency by version

## v0.preview.13 - 2026-04-17

- Add initial Claude Code SDK (agent-sdk)
- Add offline mode support for headless, serve, and channel modes
- Add offline mode loading progress bar
- Promote Evt::UserInput to a protocol-level event
- Refactor agent-sdk so CLI owns session id
- Drop redundant search_incomplete field from GrepResult

## v0.preview.12 - 2026-04-14

- Add `--resume` CLI flag and exit resume hint
- Add Slack/Discord integration
- Add ali-coding-plan builtin support
- Update log analyzer to accept workflow URL as input
- Fix Gemini enum problem
- Improve grep tool: pagination, filtering, glob parsing, count totals, and session cwd resolution
- Clarify TUI connect command description
- Remove user group
- Fix smoke test format
- Dependency updates

## v0.preview.11 - 2026-04-07

- Experimental PTY tmux support
- Update init command description with contextual input
- Add Gemma4 model
- Update eval workflow with new harbor
- Improve offline mode log output
- Update Antix wirestyle to Anthropic and add Qwen models
- Adjust offline mode for new llamacpp version
- Add popular models from OpenRouter
- Implement explicit update command
- Dependency updates

## v0.preview.10 - 2026-04-01

- Update openrouter model name
- Fix git commit authors for GitHub Action

## v0.preview.9 - 2026-03-30

- Add dialog snapshot persistence for session restore
- Add event log persistence and TUI replay on resume

## v0.preview.8 - 2026-03-30

- Add guide subagent
- Add number key shortcuts to approval dialog
- Improve inactive model visibility in model selector
- Refactor TUI modal state handling
- Refactor default prompt assembly for agents
- Update ratatui to 0.30 and tui-input to 0.15
- Dependency updates

## v0.preview.7 - 2026-03-25

- Decouple scheduler from review decisions
- Fix quit bug
- Update eval workflow and scripts
- Make browser tool optional
- Eliminate per-delta buffer cloning in streaming output
- Deserialize tool results from &Value instead of cloning
- Sort model selector by current provider first
- Simplify TUI thinking selector handling

## v0.preview.6 - 2026-03-24

- Add queued message feature for multi-turn input
- Add browser tool
- Fix OpenAI codex backend
- Reduce tool input cloning
- Dependency updates

## v0.preview.5 - 2026-03-22

- Add /statusline command for configurable footer
- Add PR link status line item
- Add thinking level selector to model switcher
- Use theme.secondary for status line text to improve readability
- Refactor skill module into core/skill
- Reorganize agent specs
- Add websocket transport for serve mode
- Add release skill for tagged releases
- Fix assistant messages in OpenAI Responses API
- Dependency updates

## v0.preview.4 - 2026-03-14

- Add Criterion benchmarking for core fs and Bash tools
- Add release benchmark baseline reporting
- Fix update Antix's default URL to public domain
- Fix typos and spelling
- Update calculation for benchmarks
- Move bundled assets to top-level module
- Dependency updates

## v0.preview.3 - 2026-03-11

- Prioritize TUI input over protocol events
- Flatten llm catalog presets
- Move catalog into llm module
- Handle queued steers around approval pauses

## v0.preview.2 - 2026-03-09

- Fix command popup scrolling when selection moves past visible area
- Add Ante terminus
- Add standard OAuth support for Antix
- Fix OAuth callback server cancellation and bind errors
- Adjust OpenAI reasoning effort mapping
- Dependency updates

## v0.preview.1 - 2026-03-06

- Initial preview release
