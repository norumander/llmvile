# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-04-19

### Added
- Real persistent terminals per NPC via the vendored `godot-xterm` v4.0.3 addon. Each NPC spawns a native OS subwindow running `$SHELL` in a full PTY. Windows open at 85% of the game window, centered, with semi-transparent background.
- `TerminalNpcFactory` dynamically spawns terminal NPCs. Game starts with one pre-placed NPC; a `+ new terminal` HUD button and `N` hotkey spawn more at the next free desk. Fifth spawn attempt toasts "All desks full".
- Status indicators now reflect session state: `..` while output is streaming (panel closed), `!` once the session has been quiet for ≥1.5 seconds with unread output.
- Shell exit (`exit` / Ctrl-D / process death) removes the NPC from the world.
- In-panel X close button + click-outside dismiss (terminal auto-closes when the game window receives focus).
- SubViewport-based architecture: game renders at 640×360 pixel-art, stretched to fill the window; terminal panels render at native OS resolution with real cell sizes and transparency.

### Changed
- `NpcConfig` simplified to `display_name` + `sprite_frames` only. Factory owns placement and panel assignment.
- `scenes/npc.tscn` no longer pre-sets textures; NpcEntity owns a TerminalPanel instance from `_ready`.
- `scenes/world.tscn` no longer contains static NPC instances; content wrapped in a `SubViewport` under `Main`. UIRoot sits outside the subviewport so UI renders crisply at native resolution.
- `PlayerController`: walk animation now freezes when input is paused (matching velocity behavior); interact key ignored while a panel is open.
- Project now uses `window/stretch/mode="disabled"` with a SubViewportContainer providing the pixel-art upscale. `embed_subwindows=false` and `per_pixel_transparency/allowed=true` enable native windows.

### Removed
- `scenes/panels/stub_dialogue.tscn`, `scripts/stub_dialogue_panel.gd`, and all v0.1 `data/npcs/npc_*.tres` fixtures.
- `test/fixtures/invalid_npc_no_panel.tres`.

### Fixed
- Panel reparenting across NpcEntity → UIRoot tripped the PTY's shell (process died on tree exit). Panels now live under `UIRoot.PanelHost` from spawn; no reparenting on interact.
- NPC status indicator labels use the canvas transform so they track NPCs across the SubViewport boundary as the camera moves.

## [0.1.1] - 2026-04-18

### Added
- Gen 4-ish DS-style chibi art pass: regenerated player + 4 NPCs with 4-directional sprites + walking-4-frames animations. Idle uses the static rotation image per direction (truer to DS overworld style than a bobbing loop).
- New cream-wall + warm-wood-floor office tileset matching the chibi palette.
- 64×64 desk sprites (decorative, no collision) rendered behind NPCs so each NPC appears to sit at their station.
- `SpriteFrames` resources under `data/characters/` for all 5 characters with `idle_<dir>` + `walk_<dir>` animations.

### Changed
- `NpcConfig.sprite: Texture2D` → `NpcConfig.sprite_frames: SpriteFrames`. Fixtures and tests updated to match.
- `scenes/player.tscn` and `scenes/npc.tscn` now use `AnimatedSprite2D` instead of `Sprite2D`.
- `PlayerController` tracks facing direction and switches between `walk_<dir>` and `idle_<dir>` animations based on velocity.
- `data/tilesets/office.tres` points at the new `floor.png` and no longer registers desk as a tile (desks are world-scene sprites now).
- `.gitignore` now excludes `*.uid` so Godot 4.3's auto-generated UID files don't drift between local imports and CI.
- `docs/dev-setup.md` gained a "Local iterate loop" section documenting direct-launch playtest against a local Godot 4.3 install, including the one-time double-import step.

### Removed
- Old placeholder art: `art/player.png`, `art/npc_01..04.png`, `art/tiles/floor_wood.png`.

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

[Unreleased]: https://github.com/norumander/llmvile/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/norumander/llmvile/releases/tag/v0.2.0
[0.1.1]: https://github.com/norumander/llmvile/releases/tag/v0.1.1
[0.1.0]: https://github.com/norumander/llmvile/releases/tag/v0.1.0
