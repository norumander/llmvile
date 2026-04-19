# v0.2 Terminal MVP — Design Spec

**Status:** Draft (2026-04-18)
**Owner:** Normid
**Milestone:** [v0.2 Terminal MVP](https://github.com/norumander/llmvile/milestone/2)

## Goal

Replace the v0.1 stub dialogue panel with a real, persistent terminal per NPC. Walking up to an NPC and pressing E opens a windowed terminal panel running `$SHELL` in a full PTY. The user can run anything — `claude`, `zsh` commands, `vim`, `htop` — and the session persists in the background while the panel is closed. Status indicators above the NPC's head signal "working" (BUSY) while the session streams output and "ready for you" (NOTIFY) when the session has been quiet for ≥1.5 seconds since last output.

NPCs are spawned dynamically. The game starts with one pre-spawned terminal NPC. A `+ new terminal` button in the HUD (keybind `N`) spawns a new NPC at the next free desk. Killing the shell (`exit`, Ctrl-D, process death) removes the NPC from the world.

## Non-goals

- **No LLM agent wiring.** NPCs are terminal hosts, not agent wrappers. If you want `claude`, you type `claude` in the terminal. Per-NPC default commands (e.g. NpcClaude auto-runs `claude`) are future work.
- **No session persistence across game launches.** Sessions die on game quit.
- **No multi-terminal panel layout.** Only one terminal panel visible at a time. Status indicators let you see which NPCs need attention.
- **No custom terminal emulator.** We use the [godot-xterm](https://github.com/lihop/godot-xterm) v4.0.3 addon (libvterm + platform PTY + a native Godot renderer). No GDExtension work in v0.2.
- **No polished spawn UI.** The HUD button is functional, not pretty. v0.3+ gets proper theming.
- **No auto-respawn.** When the shell dies, the NPC disappears. Re-spawn via the HUD button/hotkey.

## Foundation: godot-xterm addon (pre-validated)

Validated 2026-04-18 in a throwaway worktree (see `prototype/godot-xterm-eval`):

- **v4.0.3** ships pre-built macOS universal (arm64 + x86_64) and Windows x86_64 binaries — no local C++ compile.
- Godot 4.3 compatible.
- macOS gotcha: the shipped `.framework` is marked with `com.apple.quarantine` on first use. `xattr -dr com.apple.quarantine addons/godot_xterm` fixes it. Needed once per clone; the cleared attribute persists in git-tracked files (it's an xattr, not in-content).
- **`PTY.terminal_path` is required** for auto-wiring, OR the glue script must manually connect:
  - `Terminal.data_sent` → `PTY.write()`
  - `PTY.data_received` → `Terminal.write()`
  - `Terminal.resized` → `PTY.resize(get_cols(), get_rows())`
- Terminal requires `focus_mode = Control.FOCUS_ALL` + `grab_focus()` or it silently swallows keystrokes.
- Cursor does not blink — known [issue #139](https://github.com/lihop/godot-xterm/issues/139). Non-blocking.
- Font override: set `normal_font_size` to fit the 640×360 logical viewport. Eval used 10pt; production panel will use a size that fits the window chrome.

## Architecture

### File layout (delta from v0.1)

```
addons/godot_xterm/              NEW — vendored v4.0.3 release zip contents
scenes/panels/
  terminal.tscn                  NEW — TerminalPanel: frame + title bar + Terminal + PTY
  stub_dialogue.tscn             REMOVED (no longer used)
scenes/ui/
  hud.tscn                       NEW — "+ new terminal" button overlay
  ui_root.tscn                   MODIFY — add HUD child
scripts/
  terminal_panel.gd              NEW — extends InteractionPanel; status tracking + PTY lifecycle
  terminal_npc_factory.gd        NEW — spawns NpcEntity at free desks
  hud.gd                         NEW — + button + N hotkey
  world.gd                       MODIFY — instantiate factory, spawn one NPC on _ready
  npc_config.gd                  MODIFY — rename sprite_frames usage; no panel_scene (panel is per-NPC now)
  npc_entity.gd                  MODIFY — own a TerminalPanel instance from _ready, expose it via interact()
  stub_dialogue_panel.gd         REMOVED
  game_root.gd                   MODIFY — add "spawn_terminal" InputEvent binding
project.godot                    MODIFY — enable godot_xterm plugin, add spawn_terminal action
scenes/world.tscn                MODIFY — remove static NpcClaude/Codex/Gemini/Spare nodes
data/npcs/npc_*.tres             REMOVED — configs generated at spawn time by the factory
```

### Node tree (world scene)

```
World (Node2D)
├── TileMap                      (unchanged)
├── Desk1..4 (Sprite2D)           (unchanged — decorative)
├── Player                        (unchanged)
├── UIRoot (CanvasLayer)
│   ├── Prompt (Label)            (unchanged — "press E")
│   ├── IndicatorLayer (Node2D)   (unchanged — holds NPC status labels)
│   ├── PanelHost (Control)       (unchanged — where active panel reparents)
│   └── HUD (Control)             NEW
│       └── SpawnButton (Button)  NEW — label "+ new terminal"
├── [terminal NPCs spawned here by factory]
│   └── NpcEntity
│       ├── AnimatedSprite2D
│       ├── InteractionZone (Area2D + CollisionShape2D)
│       └── TerminalPanel (hidden, Control)   INSTANCED IN NpcEntity._ready
│           ├── Frame (Panel)                 — window chrome
│           │   ├── TitleBar (HBoxContainer)
│           │   │   ├── Title (Label)         — e.g. "NPC-3"
│           │   │   └── CloseButton (Button)  — "X"
│           │   └── Terminal (godot_xterm Terminal)
│           │       └── PTY (godot_xterm PTY)
│           └── (Timer, internal, for status polling)
└── TerminalNpcFactory (Node, sibling to Player/UIRoot)
```

### Interaction flow

Opening a panel:
1. Player enters InteractionZone → `InteractionSystem` sets `current_target = npc`.
2. Player presses `E` → `PlayerController.panel_requested.emit(panel, npc)` where `panel = npc.interact()`.
3. `NpcEntity.interact()` returns its pre-instantiated `TerminalPanel` (does NOT instantiate).
4. `UIRoot.show_panel_for(panel, npc)` reparents the panel from NpcEntity → `PanelHost`, calls `panel.show_for(npc)`, pushes it on `GameRoot.panel_stack` (pauses world input).
5. `TerminalPanel.show_for` does: `visible = true`, `grab_focus()` on its Terminal child, `_panel_opened = true`, trigger status recompute → IDLE.

Closing:
1. Esc or Close button → `TerminalPanel._close()` → emits `panel_closed`.
2. `UIRoot._on_panel_closed` reparents panel back to its NpcEntity, calls `GameRoot.pop_panel(panel)`.
3. `TerminalPanel._panel_opened = false`, `visible = false`, reset `_has_unread` flag to false (will flip true on next output).

Shell exit (the user types `exit` / Ctrl-D / process dies):
1. PTY emits `exited(exit_code, signum)`.
2. TerminalPanel re-emits on its own `session_ended` signal.
3. NpcEntity handler calls `queue_free()` on self. Factory observes `tree_exiting` → frees the desk slot.
4. If the panel was open when the shell died, the panel's `panel_closed` also fires so UIRoot unwinds state cleanly.

### Status tracking

Three states (reuse v0.1's `NpcStatus` enum: `IDLE` / `BUSY` / `NOTIFY`):

- **Panel open** → always IDLE. User is looking; no need to notify.
- **Panel closed** (checked each frame by a 0.1s Timer):
  - If `now - _last_activity_time < QUIET_THRESHOLD` (1.5s) AND `_has_unread`: **BUSY** (output is actively landing).
  - Else if `_has_unread`: **NOTIFY** (output stopped streaming, user hasn't seen it).
  - Else: **IDLE**.

`_has_unread` goes true when PTY produces output while panel is closed. Goes false on panel open.
`_last_activity_time` is updated on every `pty.data_received`.

The NpcEntity mirrors the panel's status via a connected signal, re-emitting `status_changed` so the existing `UIRoot.register_npc` wiring from v0.1 shows the indicator above the NPC's head.

### Spawn factory

`scripts/terminal_npc_factory.gd` — a `Node` instantiated as a child of `World`:

```gdscript
extends Node
class_name TerminalNpcFactory

const NPC_SCENE := preload("res://scenes/npc.tscn")
const DESK_POSITIONS: Array[Vector2] = [
    Vector2(144, 144), Vector2(368, 144),
    Vector2(144, 240), Vector2(368, 240),
]

var _occupied: Array[bool] = [false, false, false, false]

func spawn_at_free_desk() -> NpcEntity:
    var idx := _occupied.find(false)
    if idx == -1:
        return null
    _occupied[idx] = true
    var npc: NpcEntity = NPC_SCENE.instantiate()
    npc.position = DESK_POSITIONS[idx]
    npc.config = _default_config()
    npc.tree_exiting.connect(func(): _occupied[idx] = false)
    get_parent().add_child(npc)  # add as child of World (sibling of the factory)
    return npc
```

- `_default_config()` builds a fresh `NpcConfig` at runtime: pulls a `SpriteFrames` from a pool (for v0.2 MVP just re-use the v0.1 sprite resources, cycle through them), sets `display_name = "NPC-%d" % counter`, leaves `panel_scene` as the new `terminal.tscn` default.
- Factory emits `spawn_failed` when all desks are full. HUD displays a transient toast ("All desks full").

### NpcConfig changes

- Remove `panel_scene` field. Every NPC in v0.2 gets a terminal panel; `NpcEntity` constructs one from the canonical `terminal.tscn` in `_ready`.
- Keep `display_name`, `sprite_frames`. Drop `desk_position` (factory owns placement).
- Drop the `kind: StringName` field (one kind for v0.2; useful later when agent-specific NPCs land).

Updated resource:
```gdscript
extends Resource
class_name NpcConfig

@export var display_name: String = ""
@export var sprite_frames: SpriteFrames

func is_valid() -> bool:
    return display_name != "" and sprite_frames != null
```

### GameRoot input

Add a new `spawn_terminal` action bound to `N`. `HUD.gd` listens for both `button_down` on the `+` button and `ui_action_just_pressed("spawn_terminal")`. Pressed when a panel is open → ignored (world input paused).

## Error handling

| Failure | Behavior |
|---|---|
| `pty.fork()` returns non-OK | TerminalPanel renders a red-bordered "Session failed to start (code N)" message, no PTY. Panel still closes normally. NPC stays put (future: respawn via some action). |
| Shell exits with non-zero code | Treat like normal exit: NPC `queue_free`s. Exit code logged to console. |
| All desks full on spawn attempt | HUD shows "All desks full" label for ~2 seconds. No NPC created. |
| Panel reparenting fails (e.g. user tree_exiting mid-open) | Guard the reparent calls with `is_instance_valid` checks. Skip rather than crash. |
| Addon missing or incompatible Godot | Project fails to load in editor. Deliberate — user must install the addon. README documents. |

## Testing

### Unit (fast, runnable in CI)

Mock `PTY` as a GDScript stub exposing `fork()`, `write()`, signal `data_received`, signal `exited`. Replace godot-xterm nodes with plain Nodes in test scenes.

- `test_terminal_panel_status`:
  - Panel closed + no output → IDLE
  - Panel closed + data_received → BUSY immediately
  - Panel closed + data_received + 2s quiet → NOTIFY (advance time by `wait_frames` + simulated timer tick)
  - Panel open → IDLE regardless of data
- `test_terminal_npc_factory`:
  - First spawn → desk 0
  - Four spawns → all desks occupied
  - Fifth spawn → returns null
  - NPC freed → desk available again
- `test_npc_entity_terminal`:
  - NpcEntity instantiates one TerminalPanel on `_ready`
  - `interact()` returns the same TerminalPanel instance every call (not a new one)
  - `tree_exiting` frees the panel cleanly

### Integration (may be skipped in CI if no TTY)

- `test_terminal_real_shell`:
  - Instantiate `terminal.tscn`
  - `pty.fork("/bin/echo", ["hello"])` (non-interactive, fast)
  - Await `pty.exited`
  - Assert exit code 0 and at least one `data_received` with "hello"
  - Guard with `if OS.get_environment("CI") == "true": return` if GUT CI lacks a TTY (revisit — GitHub Actions runners usually do have one)

### Manual playtest (pre-tag)

Checklist lives in `docs/playtest.md`:

- [ ] Game launches with exactly one NPC visible at desk 1
- [ ] Press E on NPC → terminal panel opens, cursor focused
- [ ] Type `echo hi` → visible output
- [ ] Esc closes panel, WASD movement works again
- [ ] Inside terminal, run `sleep 3; echo done` → close panel immediately → status goes BUSY (..) during sleep, NOTIFY (!) after ~4.5s
- [ ] Open panel → indicator clears to IDLE
- [ ] Type `claude -p "2+2"` → expected output, status behaves correctly during claude streaming
- [ ] Type `exit` → NPC disappears from world, no error logs
- [ ] Press `N` or click `+ new terminal` → new NPC at next free desk
- [ ] Spawn 4 NPCs → 5th attempt shows "All desks full" toast
- [ ] Quit game, relaunch → starts with one NPC again (no persistence)

## Migration from v0.1

- Delete `data/npcs/npc_01..04.tres` and their fixture uses.
- Delete `scenes/panels/stub_dialogue.tscn` + `scripts/stub_dialogue_panel.gd`.
- Delete `test/unit/test_stub_dialogue_panel.gd`.
- Update `test/fixtures/valid_npc.tres` and `invalid_npc_no_panel.tres` to drop `panel_scene` (or delete them entirely — likely the latter, since NpcConfig is simpler now).
- Update `test/unit/test_npc_config.gd` to stop asserting on `panel_scene`.
- Update `test/unit/test_npc_entity.gd` to instantiate a mock PTY instead of a mock panel_scene.
- Update `test/unit/test_interaction_system.gd` and `test_status_indicators.gd` similarly (remove `panel_scene` from test configs).
- Update `scenes/world.tscn`: remove 4 static NPC instances + their ExtResources + the `Resource` ext_resources pointing at deleted tres files; add HUD + TerminalNpcFactory as children.

## Open questions

1. **Font rendering.** godot-xterm uses its bundled monospace at the size we override. Verify readability at 10-12pt in the centered-window panel size (~500×300 logical pixels). If too small, bump to 12. Settle during implementation.
2. **Panel dimensions.** "Centered window, ~80% of 640×360" = roughly 512×288 with padding. Title bar height ~16px. Actual Terminal area ~496×256. With 10pt font that's ~62 cols × 21 rows. Playtest to confirm these read well.
3. **NPC name scheme.** `NPC-1`, `NPC-2`, etc. by spawn order? Or sequential by desk index (Desk 1, Desk 2)? Lean toward spawn-order since v0.2.1 may drop the desk concept. Decide during implementation.
4. **SpriteFrames pool.** v0.1 has 4 distinct character sprites. If the player spawns 5+ NPCs, do we cycle? Color-tint? For MVP just cycle — visual collisions are acceptable.
5. **Close on shell exit + panel open.** Does the panel auto-close and show a brief "session ended" before the NPC disappears, or does the NPC+panel go away instantly? Lean instant for simplicity; playtest to confirm it doesn't feel jarring.

## Future work (NOT v0.2)

- **Dynamic per-NPC defaults.** Spawning a "Claude NPC" auto-runs `claude`; "Codex NPC" runs `codex`; etc. Requires per-NPC config in the spawn UI (e.g. a submenu from the `+` button).
- **Polished HUD.** Icon, tooltip, keyboard shortcut hint.
- **Session persistence across game launches.** Hard problem (process state + scrollback).
- **Multiple panels visible simultaneously.** Floating terminal windows the user can reposition.
- **Custom themes.** Terminal color schemes selected per NPC or globally.
- **"!" in title bar of the app.** OS-level notification when a background session goes NOTIFY.
- **Terminal search, copy-paste polish.** godot-xterm handles basics but edge cases remain.

## References

- [godot-xterm v4.0.3 release](https://github.com/lihop/godot-xterm/releases/tag/v4.0.3)
- [godot-xterm docs](https://docs.godot-xterm.nix.nz/)
- [v0.1 walkable overworld spec](2026-04-17-v01-walkable-overworld-design.md) — shared GameRoot / InteractionPanel / UIRoot contracts
