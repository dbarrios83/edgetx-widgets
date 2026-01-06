# AGENTS.md

Reusable Lua widgets for EdgeTX colour-screen radios (TX15, Jumper T15, TX16), covering telemetry dashboards, model info, and simulator utilities.

## Project Structure

```
edgetx-widgets/
├── widgets/           # Widget implementations
│   ├── BattWidget/
│   ├── common/        # Shared utilities (REQUIRED)
│   │   ├── utils.lua
│   │   └── icons/     # Shared icon assets
│   ├── Dashboard/
│   ├── GPSWidget/
│   ├── RXWidget/
│   ├── SimWidget/
│   └── TeleView/
├── tests/             # Test suite
│   ├── lua/          # Widget test files
│   └── utils/        # Testing utilities (telemetry simulator)
└── docs/             # Documentation
```

## Domain context

- Target platform: EdgeTX colour radios running Lua widgets in the main/view pages.
- Typical data sources: OpenTX/EdgeTX telemetry sensors (GPS, RSSI, battery, timers), model metadata, and companion simulators for offline testing.
- Interaction model: Widgets render via `lcd` APIs within a zone; options are set through EdgeTX widget settings and refreshed each frame.
- Constraints: Runs on embedded hardware with limited CPU/memory; avoid heavy allocations and prefer integer math where possible.
- Testing: Lua test harness and telemetry simulator under `tests/` mirror on-radio behaviour for CI-style checks.



## Agent conduct

- Verify assumptions before executing commands; call out uncertainties first.
- Ask for clarification when the request is ambiguous, destructive, or risky.
- Summarise intent before performing multi-step fixes so the user can redirect early.
- Cite the source when using documentation; quote exact lines instead of paraphrasing from memory.
- Break work into incremental steps and confirm each step with the smallest relevant check before moving on.