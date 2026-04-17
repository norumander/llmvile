# v0.1 — Walkable Overworld MVP

**Status:** Draft — pending user review
**Date:** 2026-04-17
**Parent project:** llmvile — top-down pixel-art chatroom wrapping CLI LLM agents as NPCs
**Next step:** implementation plan via `writing-plans` skill

## Purpose

Ship a playable pixel-art game shell **without** terminal integration. Establish the architectural seams (NPC config resource, pluggable interaction panel, status signal plumbing) that v0.2 will extend by swapping the stub panel for a real terminal backed by a GDExtension.

The goal is a walkable office room with 3–4 NPC desks. Pressing E on an NPC opens a stub "coming soon" dialogue. When v0.2 arrives, the dialogue is replaced by a live terminal panel with zero NPC-system rewrites.

## Scope

### In scope

- Godot 4.x 2D project
- 640×360 logical resolution, 32×32 tiles, integer-scaled to window
- One interior "cozy office" room (single scene)
- 4-directional top-down player movement
- 3–4 NPC desks, each with unique sprite and `NpcConfig.tres` resource
- Interaction system with proximity prompt and modal panel lifecycle
- `StubDialoguePanel` displaying "coming soon: claude code"
- Status signal wiring end-to-end (all NPCs `.idle` in v0.1)
- macOS + Windows export presets producing runnable artifacts
- GUT unit tests for `NpcConfig` / `InteractionSystem` / panel lifecycle
- Headless CI: import + export smoke test
- Manual playtest checklist

### Out of scope (deferred to later specs)

- Terminal GDExtension / PTY / libvterm integration (v0.2)
- Real dialogue trees, NPC personalities, or scripted conversations
- Notifications, OS-level alerts, audio cues (v0.3)
- Multiple rooms, outdoor areas, level transitions
- Save/load, settings menu, audio settings
- Accessibility (remappable keys, screen reader)
- Localization
- Linux build
- Steam / itch distribution
- Music / SFX (PixelLab MCP is image-only)

## Architecture

Godot 4.x 2D project. Single scene for v0.1 (the office room). Integer-scaled 640×360 logical framebuffer.

The core abstraction is **NPC = config + panel**:

- An `NpcEntity` loads an `NpcConfig` resource (`.tres`) declaring display name, sprite, desk position, and a `panel_scene: PackedScene` reference.
- On interaction, the entity instantiates `config.panel_scene` and hands it to `UIRoot`.
- v0.1 ships `StubDialoguePanel` as the panel. v0.2 adds `TerminalPanel` wrapping the GDExtension.
- **The NPC does not know which panel implementation runs.** v0.2 is a scene swap, not a code rewrite.

Status signals (`idle | busy | notify`) are plumbed end-to-end in v0.1 but never transition away from `.idle`. The signal contract, enum, and UI rendering code all ship now so v0.2's terminal panel simply writes `npc.status = .notify` and the existing indicator appears above the NPC's desk.

### Cross-cutting concerns

- **Input pausing** is centralized on `GameRoot.world_input_paused`. Panels set it true on open, false on close. `PlayerController` checks the flag.
- **Panel stack** lives on `GameRoot`. v0.1 only ever holds one panel, but the stack structure anticipates nested UI later (settings over a terminal, etc.).
- **Coordinate systems**: world coordinates for gameplay, `UIRoot` uses screen space via `CanvasLayer`, status indicators anchor to NPC world positions via `remote_transform`.

## Components

| Component | Type | Responsibility |
|---|---|---|
| `PlayerController` | `CharacterBody2D` | 4-directional movement, reads `GameRoot.world_input_paused` |
| `InteractionSystem` | `Area2D` (child of player) | Tracks overlapping `NpcEntity`, computes closest, routes E press to `npc.interact()` |
| `NpcEntity` | `Node2D` | Loads `NpcConfig`, renders sprite, owns collision `Area2D`, exposes `interact()`, holds `status` property, emits `status_changed`, `interaction_started`, `interaction_ended` |
| `NpcConfig` | `Resource` (`.tres`) | Fields: `display_name: String`, `sprite: Texture2D`, `desk_position: Vector2i`, `panel_scene: PackedScene`, `kind: StringName` |
| `InteractionPanel` | abstract `Control` | Virtual base. `show_for(npc: NpcEntity)`, `close()`, emits `panel_closed` |
| `StubDialoguePanel` | extends `InteractionPanel` | v0.1 impl. Renders a bubble with `"coming soon: claude code"` or NPC-specific stub text |
| `GameRoot` | autoload singleton | `world_input_paused: bool`, `panel_stack: Array[InteractionPanel]`, global pause hooks |
| `UIRoot` | `CanvasLayer` (in world scene) | Hosts active panel, "Press E" prompt, per-NPC status indicators |
| `World` | root scene | `TileMap` + NPC spawns + player + `UIRoot` + camera |

### NPC Config schema

```
class_name NpcConfig extends Resource

@export var display_name: String = ""
@export var sprite: Texture2D
@export var desk_position: Vector2i = Vector2i.ZERO
@export var panel_scene: PackedScene
@export var kind: StringName = &"stub"
```

v0.1 uses `kind = &"stub"` for all NPCs. v0.2 adds `&"terminal"` with a different `panel_scene`.

### Status enum

```
class_name NpcStatus

enum Status { IDLE, BUSY, NOTIFY }
```

Defined as a top-level enum (or `NpcEntity.Status`, decided at implementation). v0.1 only uses `IDLE`.

### Panel interface

```
class_name InteractionPanel extends Control

signal panel_closed

func show_for(npc: NpcEntity) -> void:
    push_error("Subclass must override show_for")

func close() -> void:
    panel_closed.emit()
    queue_free()
```

## Data Flow

### Interaction lifecycle

```
Input (WASD / arrows)
  → PlayerController.move()        (skipped if world_input_paused)
  → CharacterBody2D.move_and_slide()

Player Area2D enters NpcEntity Area2D
  → InteractionSystem._on_area_entered(npc)
  → InteractionSystem tracks target (closest overlap wins)
  → UIRoot.show_prompt("Press E", above npc.desk_position)

Player Area2D exits NpcEntity Area2D
  → InteractionSystem._on_area_exited(npc)
  → recompute closest remaining target or clear
  → UIRoot updates/hides prompt

E pressed AND target present AND not world_input_paused
  → InteractionSystem calls npc.interact()
  → npc instantiates config.panel_scene
  → UIRoot adds panel to its tree, calls panel.show_for(npc)
  → GameRoot.world_input_paused = true
  → GameRoot.panel_stack.push(panel)
  → npc emits interaction_started

Panel receives close input (E or Esc)
  → panel.close() → emits panel_closed → queue_free
  → UIRoot removes panel
  → GameRoot.panel_stack.pop()
  → GameRoot.world_input_paused = false (if stack empty)
  → npc emits interaction_ended
```

### Status lifecycle (plumbed, stubbed in v0.1)

```
npc.status = NpcStatus.NOTIFY
  → status_changed.emit(NpcStatus.NOTIFY)
  → UIRoot._on_npc_status_changed(npc, new_status)
  → updates indicator sprite above npc.desk_position
     (NOTIFY = "!", BUSY = "..", IDLE = hide indicator)
```

In v0.1, no code path sets status away from `.idle`. The signal, enum, UI subscription, and indicator sprites all ship so v0.2's terminal panel can write `npc.status = .notify` and immediately see the UI respond.

## Error Handling

v0.1 philosophy: **log and degrade, never crash**.

| Failure | Response |
|---|---|
| `NpcConfig` missing required field (e.g. no `panel_scene`) | Log warning with NPC path, skip spawning that NPC; world loads without it |
| `panel_scene.instantiate()` fails | Log error; v0.1 has no meaningful fallback (stub is the only panel) — skip opening, stay in world. v0.2+ falls back to `StubDialoguePanel` |
| Sprite texture missing | Use magenta 32×32 placeholder sprite loaded from `res://art/_missing.png` |
| E pressed while panel already open | Ignored via `world_input_paused` gate |
| Player walks away with panel open | No-op; panel is modal, proximity irrelevant once open |
| Window resize / minimize | Delegated to Godot's stretch/aspect settings; verified by manual playtest |
| Multiple NPCs overlapped by player zone | `InteractionSystem` picks closest by world distance |

No telemetry, crash reporting, or analytics in v0.1.

## Testing

### Unit tests — GUT (Godot Unit Test) framework

- `NpcConfig` loading:
  - Valid `.tres` parses, all fields populated
  - Missing `panel_scene` → resource load logs warning, `NpcEntity` skips spawn
  - Missing sprite path → placeholder substituted
- `InteractionSystem`:
  - Enter zone → target set
  - Exit zone → target cleared
  - Two overlapping NPCs → closest wins, swapping as player moves
  - Target cleared when panel opens so rapid-fire E presses don't re-trigger
- Panel lifecycle:
  - Opening panel sets `world_input_paused=true`
  - `close()` emits `panel_closed` exactly once
  - `close()` releases `world_input_paused` only when stack empties
- Status signal:
  - Setting `npc.status = X` emits `status_changed(X)` exactly once per distinct change
  - Setting to same value does not re-emit

### Integration / smoke tests (headless, in CI)

- `godot --headless --import` exits 0 (project imports cleanly, no missing resources)
- `godot --headless --export-release "macOS" builds/llmvile.app` produces non-empty bundle
- `godot --headless --export-release "Windows Desktop" builds/llmvile.exe` produces non-empty binary

### Manual playtest checklist — `docs/playtest-checklist.md`

Run per PR touching gameplay. Items:

- [ ] Launch → office room renders at 640×360 scaled to window
- [ ] Player moves in all 4 directions, respects wall collisions
- [ ] Approaching each NPC shows "Press E" prompt above their head
- [ ] Leaving proximity hides the prompt
- [ ] E opens the stub panel with NPC-specific text
- [ ] E or Esc closes the panel; movement resumes
- [ ] All 3–4 NPCs visited in one session, no softlocks
- [ ] Window resize doesn't break layout (integer-scaled fallback acceptable)
- [ ] Mac `.app` and Windows `.exe` both launch from a fresh download

## Acceptance Criteria

v0.1 ships when **all** of these are true:

1. `main` branch builds clean macOS `.app` and Windows `.exe` via CI
2. Launching either artifact shows the office room at 640×360 scaled to the window
3. Player can reach every NPC desk without clipping through walls
4. Every NPC: proximity → prompt → E opens stub panel → E/Esc closes → movement resumes
5. All GUT unit tests pass headlessly in CI
6. Manual playtest checklist completes with no blockers on both platforms
7. This spec's behavior matches what ships; deviations are updated in-doc before close

## Development Lifecycle (project-wide, not just v0.1)

Set up once as part of v0.1 scaffolding; applies to every subsequent milestone.

- **Branch protection** on `main`: PR required, CI green required, linear history
- **Issue templates**: `feature.md`, `task.md`, `bug.md` under `.github/ISSUE_TEMPLATE/`
- **PR template** (`.github/pull_request_template.md`) with checklist: tests updated, screenshot if visual, linked issue, changelog entry
- **Labels**:
  - `type:feature`, `type:task`, `type:bug`, `type:chore`, `type:docs`
  - `area:engine`, `area:art`, `area:ui`, `area:build`, `area:ci`
  - `priority:p0`, `priority:p1`, `priority:p2`
  - `status:blocked`, `status:needs-design`
- **Milestones**: `v0.1 Walkable Overworld`, `v0.2 Terminal MVP`, `v0.3 Notifications`, `v0.4 Polish`
- **GitHub Project** (board): Backlog → Ready → In Progress → In Review → Done
- **CI (GH Actions)**: Godot headless import + export (mac+win) + GUT tests on every PR
- **Conventional commits**: `feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`
- **`CHANGELOG.md`**: keep-a-changelog format, updated per PR
- **Git worktrees per issue**: working directory isolation for parallel work

## Open Questions

None blocking v0.1 at time of writing. Deferred decisions:

- PixelLab MCP prompt conventions (emerges during art work, tracked in art-style issue)
- Specific NPC roster and CLI assignments (claude-code / codex / gemini / …) — v0.2 concern
- Exact notification UX: sound, OS notification, or in-game banner? — v0.3 concern
- Whether v0.2 ships with one working terminal NPC or all four at once — revisit at v0.2 brainstorm
