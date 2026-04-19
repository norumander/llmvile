# v0.3 Notifications — Design Spec

**Status:** Draft (2026-04-19)
**Owner:** Normid
**Milestone:** [v0.3 Notifications](https://github.com/norumander/llmvile/milestone/3)

## Goal

Make "an NPC is waiting for me" impossible to miss, in-world and out. v0.2 already emits the right NpcStatus signals; v0.3 polishes how they're surfaced:

1. **Chat-bubble indicator** above each NPC replaces v0.1's text label. `!` inside a red bubble for NOTIFY, `…` inside a neutral bubble for BUSY, hidden for IDLE.
2. **Pixel font** on all game UI (HUD "+ new terminal" button, "Press E" prompt, any toast). Terminal contents stay monospace via godot-xterm's own font.
3. **Validation pass** — confirm end-to-end that an NPC's indicator actually changes during a real session (`sleep 3; echo done`), because we haven't eyeballed this in the v0.2 playtest.
4. **Dock/taskbar badge** — persistent red dot with count when any NPC is in NOTIFY state, cleared when all go back to IDLE. macOS via NSDockTile.badgeLabel, Windows via ITaskbarList3.

## Non-goals

- No sound cues for status changes (v0.4 polish).
- No OS Notification Center / toast pop-ups (the bounced-dock version was considered and rejected; badge is the intended channel).
- No per-NPC custom bubble art (all NPCs share the same bubble style; glyph varies).
- No per-bubble animation beyond show/hide fade (no typing dots, no float-bounce).
- No badge history or persistence across game launches.

## Architecture

### File layout (delta from v0.2)

```
addons/
  native_badge/                           NEW — small GDExtension for dock/taskbar badges
    native_badge.gdextension
    src/
      native_badge.cpp                    stub + cross-platform dispatch
      native_badge_mac.mm                 NSDockTile wrapper (macOS)
      native_badge_win.cpp                ITaskbarList3 wrapper (Windows)
    lib/
      libnative_badge.macos.*.framework/
      libnative_badge.windows.*.dll
    SConstruct                            build script
art/
  ui/
    bubble.png                            NEW — PixelLab-generated chat bubble
    bubble_notify.png                     NEW — red-tinted variant for !
fonts/
  pixel_ui.ttf                            NEW — PxPlus IBM VGA 8x16 or equivalent
  pixel_ui.tres                           NEW — FontVariation wrapper with size defaults
scripts/
  status_indicator.gd                     NEW — single NPC's bubble Node2D (Sprite2D + Label)
  dock_badge.gd                           NEW — autoload wrapping the GDExtension; tracks count
  ui_root.gd                              MODIFY — replace Label-based indicator with StatusIndicator scene
scenes/
  ui/
    status_indicator.tscn                 NEW — matches scripts/status_indicator.gd
project.godot                             MODIFY — register DockBadge autoload; default theme font
```

### Components (what each owns)

**StatusIndicator** (`scenes/ui/status_indicator.tscn` + `scripts/status_indicator.gd`)
- Node2D holding a `Sprite2D` (bubble art) + `Label` (glyph, pixel font) child.
- Exposes `set_status(NpcStatus.Status)`:
  - IDLE → `visible = false`, emit `left_notify()` if previously NOTIFY.
  - BUSY → show bubble_default, label text = `…`.
  - NOTIFY → show bubble_notify (red), label text = `!`, emit `entered_notify()`.
- One instance per NPC. UIRoot parents them under `IndicatorLayer`.
- Position tracking logic from v0.2's `_process` stays (uses canvas transform).

**DockBadge** (`scripts/dock_badge.gd`, registered as autoload)
- Maintains an integer count of NPCs currently in NOTIFY state.
- API: `increment()` / `decrement()` / `reset()`.
- Setter applies count via `NativeBadge.set_badge(count)`; clears via `set_badge(0)`.
- Also caps below 99 — shows "99+" label for sanity, though realistic counts stay 1–4.

**NativeBadge** (GDExtension class, exposed to GDScript)
- Single static method: `set_badge(count: int) -> void`.
- Platform dispatch:
  - macOS: `[[NSApp dockTile] setBadgeLabel:@"3"]` (or `nil` for clear).
  - Windows: `ITaskbarList3::SetOverlayIcon` with a small red-circle numeric PNG baked into the extension.
- Fails silently on unsupported platforms (Linux, Web).

**Bubble assets** — PixelLab `create_map_object` with transparent bg:
- `bubble.png`: 32×24 or so, cream oval + dark outline + tail pointing down (south).
- `bubble_notify.png`: same shape, red fill.

**Font** — PxPlus IBM VGA 8x16 from "The Ultimate Oldschool PC Font Pack" (CC BY-SA 4.0). Wrapped in a `pixel_ui.tres` FontVariation; applied as project-level theme default via `project.godot → gui/theme/custom_font`.

### Data flow

**Per-NPC status change:**
1. `TerminalPanel.status_changed(s)` fires (existing v0.2 wiring).
2. `NpcEntity` re-emits `status_changed(s)`.
3. `UIRoot._on_npc_status_changed(s, npc)` resolves the StatusIndicator for that NPC and calls `indicator.set_status(s)`.
4. Indicator either shows the bubble (BUSY/NOTIFY) or hides it (IDLE).
5. If indicator transitions **into** NOTIFY: `DockBadge.increment()`. **Out of** NOTIFY: `DockBadge.decrement()`.
6. DockBadge autoload calls `NativeBadge.set_badge(count)`.

**NPC destroyed (shell exit):**
1. NPC `tree_exiting` fires.
2. If it was in NOTIFY state, UIRoot's handler calls `DockBadge.decrement()` before the indicator is freed.
3. StatusIndicator is freed along with the NPC.

### NativeBadge integration details

The GDExtension lives in `addons/native_badge/`. We build it ourselves (with SConstruct + godot-cpp) rather than shipping binaries only, since upstream doesn't have a canonical addon.

Build matrix: macOS universal (arm64 + x86_64), Windows x86_64. Linux + Web get a no-op stub.

The extension vendors godot-cpp as a submodule (pinned to `4.3` branch). CI builds it on each tag push; for local dev we commit the prebuilt binaries next to the source (like godot-xterm ships them).

First-time compile on macOS: `scons platform=macos target=template_release generate_bindings=yes`. Expected ~3 min.

## Error handling

| Failure | Behavior |
|---|---|
| GDExtension fails to load (corrupt build, wrong Godot version) | `DockBadge` logs `push_warning` and no-ops. Game runs normally; just no dock indicator. |
| Bubble PNG missing | Indicator falls back to the v0.1 Label renderer (keep a small fallback path). |
| Pixel font missing | Godot default theme font applies; game remains playable. |
| Badge count goes negative (bookkeeping bug) | Clamped to ≥ 0; push_warning in debug builds. |

## Testing

### Unit (GUT)

- `test_status_indicator.gd`
  - `set_status(IDLE)` → visible false
  - `set_status(BUSY)` → visible true, glyph is "…"
  - `set_status(NOTIFY)` → visible true, glyph is "!"
  - IDLE → NOTIFY → IDLE emits `entered_notify` then `left_notify` once each
- `test_dock_badge.gd`
  - `increment()` x3 → count = 3
  - `decrement()` x3 → count = 0
  - Reset via `reset()` → count = 0 after any state
  - `decrement()` below 0 → clamps to 0 + warning
  - Mock `NativeBadge` (GDScript class) captures set_badge calls; assert correct count values
- Existing `test_status_indicators.gd` updated: indicators are now StatusIndicator nodes, assertions look at the child label.

### Integration (manual)

Added to `docs/playtest.md#v0.3`:

1. Game launches with one NPC, no bubble visible (IDLE).
2. Press E → terminal opens; confirm no bubble while panel is open.
3. Type `sleep 3; echo done`; click the game window to auto-close.
4. Within 1s: bubble appears with `…` (BUSY). Dock icon shows no badge yet (indicator is BUSY not NOTIFY by design).
5. After `echo done` fires: within ~1.5s bubble flips to red-`!` (NOTIFY), dock badge shows "1".
6. Click game to re-focus; press E on the NPC. Panel opens; bubble disappears; dock badge clears.
7. Spawn a second NPC (N hotkey); run `sleep 2; echo hi` in it; close. Dock shows 1. Do same in a third. Dock shows 2.
8. Type `exit` in one NOTIFY-state NPC; dock badge decreases.
9. Quit and relaunch: dock badge cleared (no persistence across launches).

## Migration from v0.2

- v0.1's Label-based indicator is fully replaced. `UIRoot.get_indicator_text_for` / `get_indicator_for` test helpers update to return the StatusIndicator node.
- `test_status_indicators.gd` assertions change: `.text` becomes `.get_glyph()` or similar.
- The `IndicatorLayer` node stays, but its children become StatusIndicator instances instead of raw Labels.

## Open questions

1. **Bubble position offset.** v0.2 positions at NPC + (-4, -40). The new bubble sprite is ~32×24 instead of a tiny label; recenter the offset. Finalize during implementation.
2. **Pixel font scale.** The SubViewport is 640×360, stretched to window. HUD text renders at native resolution (since HUD lives outside the subviewport). PxPlus at 16pt native should read clearly; confirm during playtest.
3. **Windows badge fallback icon.** ITaskbarList3.SetOverlayIcon takes an HICON. Ship a small baked-in red circle PNG (with numbers 1-9, then "+" for 10+). 10 PNGs total at 16×16. Cheap.

## Future work (NOT v0.3)

- OS Notification Center / toast pop-ups when game is backgrounded and an NPC goes NOTIFY.
- Sound cue on status transitions (`res://audio/notify.ogg` style).
- Per-NPC bubble variations (different colors for different agent types).
- Persistent badge history / unread list across game launches.
- Linux dock badge support (systray icon change via DBus).

## References

- [v0.2 Terminal MVP spec](2026-04-18-v02-terminal-mvp-design.md) — NpcStatus flow inherited unchanged
- [Godot 4 GDExtension docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html)
- [Apple docs: NSDockTile](https://developer.apple.com/documentation/appkit/nsdocktile)
- [Microsoft docs: ITaskbarList3](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nn-shobjidl_core-itaskbarlist3)
- [Ultimate Oldschool PC Font Pack](https://int10h.org/oldschool-pc-fonts/) (CC BY-SA 4.0)
