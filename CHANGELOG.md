# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- `.gitignore` now excludes `*.uid` so Godot 4.3's auto-generated UID files don't drift between local imports and CI.
- `docs/dev-setup.md` gained a "Local iterate loop" section documenting direct-launch playtest against a local Godot 4.3 install, including the one-time double-import step.

## [0.1.0] - 2026-04-18

### Added
- Repo scaffolding: issue templates, PR template, labels, milestones, CHANGELOG, CODEOWNERS, playtest checklist.
- `Import + GUT` CI workflow (Godot 4.3) hardened against silent parse errors.
- Branch protection on `main` (CI green, linear history, resolved conversations required).
- Godot 4.3 project skeleton with GUT test framework.
- `GameRoot` autoload singleton with panel stack and registration hooks.
- `NpcStatus` state machine (Idle / Busy / Waiting) and `NpcConfig` resource.
- `InteractionPanel` base class and `StubDialoguePanel` subclass.
- `NpcEntity` scene binding config to in-world presence.
- `PlayerController` with top-down WASD/arrow movement and collision body.
- `InteractionSystem` emitting `panel_requested` on `E` press within NPC zone.
- `UIRoot` scene managing the active panel layer.
- Per-NPC status indicators (floating labels above head).
- `world.tscn` assembling player, 4 NPCs, UIRoot, and the office tilemap.
- PixelLab-generated south-facing art: player (48x48) + 4 NPCs (48x48) + floor/wall/desk tiles (32x32).
- Hand-authored office tilemap (16x10), two-layer (floor + walls/desks), spawn + 4 desk positions.
- `NpcConfig` fixtures for Claude, Codex, Gemini, Spare wired to the stub panel.
- `export_presets.cfg` with macOS (universal, unsigned) and Windows Desktop (x86_64, unsigned) presets.
- `Build` workflow producing macOS `.app` and Windows `.exe` artifacts on tag push / manual dispatch.

### Fixed
- Player sprite referenced the missing-texture placeholder instead of the shipped PixelLab art.
- Player node rendered behind the tilemap because of sibling order in `world.tscn`.
- Desk tiles replaced the floor beneath them instead of layering over it.
- NPCs were placed on the desk tile itself instead of one tile south of the desk.
- macOS universal export required `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot`.

[Unreleased]: https://github.com/norumander/llmvile/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/norumander/llmvile/releases/tag/v0.1.0
