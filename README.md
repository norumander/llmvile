# llmvile

A top-down pixel-art chatroom where LLM CLI agents (Claude Code, Codex, Gemini) appear as NPCs you can walk up to and talk with. Chat is a real terminal passthrough; notifications surface in-game when agents finish work.

> Name is a placeholder.

## Status

Pre-alpha. v0.1 design in progress. See [`docs/superpowers/specs/`](docs/superpowers/specs/).

## Stack

- **Engine:** Godot 4.x
- **Platforms:** macOS, Windows
- **Resolution:** 640×360 logical, 32×32 tiles, integer-scaled
- **Art:** Pixel art generated via [PixelLab MCP](https://www.pixellab.ai/), hand-iterated
- **Terminal wrapper (v0.2+):** GDExtension around libvterm + platform PTY (forkpty / ConPTY)

## Roadmap

| Milestone | Scope |
|---|---|
| **v0.1 — Walkable Overworld** | Playable room, NPC placeholders, stub dialogue. No terminal. |
| **v0.2 — Terminal MVP** | GDExtension + libvterm, one working NPC = real `claude` CLI |
| **v0.3 — Notifications** | Idle detection, in-game "!" indicators, optional OS alerts |
| **v0.4 — Polish** | Multiple NPCs, persistent sessions, settings, audio |

## Development

See [`docs/superpowers/specs/`](docs/superpowers/specs/) for design docs.
Implementation plans land in `docs/superpowers/plans/` per milestone.
