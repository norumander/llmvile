# v0.2 Terminal MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the v0.1 stub dialogue panel with a persistent terminal per NPC via the godot-xterm addon. Ship one pre-spawned terminal NPC with a HUD button / `N` hotkey that spawns more, and status indicators that go BUSY while output streams and NOTIFY when the session is idle with unread output.

**Architecture:** Vendored `godot-xterm` v4.0.3 provides `Terminal` + `PTY` nodes. A `TerminalPanel` scene owns a `Terminal` + `PTY` and extends `InteractionPanel`. Each `NpcEntity` instantiates exactly one `TerminalPanel` on `_ready` and reparents it to `UIRoot.PanelHost` on interact (preserving session state across open/close). A `TerminalNpcFactory` node spawns NPCs at free desk slots, triggered on world start and on HUD button / hotkey. See [spec](../specs/2026-04-18-v02-terminal-mvp-design.md).

**Tech Stack:** Godot 4.3 (GDScript), GUT (Godot Unit Test), `godot-xterm` v4.0.3 addon (libvterm + platform PTY), GitHub Actions, `gh` CLI, Conventional Commits.

**Workflow:** One task = one GitHub issue = one git worktree = one PR (same convention as v0.1). Reviewers gate merges; implementer stops at `gh pr create`.

---

## File Structure (final state at end of v0.2)

```
llmvile/
├── addons/
│   └── godot_xterm/                              [Task 1 — vendored]
│
├── art/                                          (unchanged from v0.1.1)
│
├── scripts/
│   ├── game_root.gd                              (unchanged, see Task 6 for input map)
│   ├── npc_status.gd                             (unchanged)
│   ├── npc_config.gd                             [Task 2 — simplified]
│   ├── interaction_panel.gd                      (unchanged)
│   ├── terminal_panel.gd                         [Task 3 — NEW]
│   ├── npc_entity.gd                             [Task 4 — modified]
│   ├── player_controller.gd                      (unchanged from v0.1.1)
│   ├── interaction_system.gd                     (unchanged)
│   ├── ui_root.gd                                [Task 6 — adds HUD hook]
│   ├── terminal_npc_factory.gd                   [Task 5 — NEW]
│   ├── hud.gd                                    [Task 6 — NEW]
│   └── world.gd                                  [Task 7 — modified]
│
├── scenes/
│   ├── world.tscn                                [Task 7 — static NPCs removed, HUD + factory added]
│   ├── player.tscn                               (unchanged)
│   ├── npc.tscn                                  [Task 4 — no texture/frames pre-set anymore]
│   ├── panels/
│   │   └── terminal.tscn                         [Task 3 — NEW]
│   └── ui/
│       ├── ui_root.tscn                          [Task 6 — HUD added as child]
│       └── hud.tscn                              [Task 6 — NEW]
│
├── data/
│   └── characters/                               (unchanged from v0.1.1)
│
├── test/
│   ├── fixtures/
│   │   ├── valid_npc.tres                        [Task 2 — panel_scene dropped]
│   │   ├── invalid_npc_no_panel.tres             [Task 2 — deleted]
│   │   ├── test_sprite_frames.tres               (unchanged)
│   │   ├── mock_pty.gd                           [Task 3 — NEW]
│   │   ├── mock_terminal.gd                      [Task 3 — NEW]
│   │   └── test_terminal_panel.tscn              [Task 3 — NEW]
│   └── unit/
│       ├── test_game_root.gd                     (unchanged)
│       ├── test_npc_config.gd                    [Task 2 — panel_scene assertion dropped]
│       ├── test_stub_dialogue_panel.gd           [Task 8 — deleted]
│       ├── test_npc_entity.gd                    [Task 4 — uses mock PTY]
│       ├── test_player_controller.gd             (unchanged)
│       ├── test_interaction_system.gd            [Task 4 — uses mock PTY]
│       ├── test_ui_root.gd                       (unchanged)
│       ├── test_status_indicators.gd             [Task 4 — uses mock PTY]
│       ├── test_terminal_panel.gd                [Task 3 — NEW]
│       └── test_terminal_npc_factory.gd          [Task 5 — NEW]
│
├── project.godot                                 [Task 1 — enable plugin; Task 6 — add input action]
├── CHANGELOG.md                                  [Task 10 — 0.2.0 entry]
└── docs/
    ├── playtest.md                               [Task 9 — v0.2 checklist]
    └── superpowers/
        ├── specs/2026-04-18-v02-terminal-mvp-design.md
        └── plans/2026-04-18-v02-terminal-mvp.md  [this file]
```

---

## Conventions (same as v0.1)

- **Worktrees per task:** each task gets `../llmvile-issue-<N>`.
- **Implementer does NOT merge.** Controller runs spec + quality review, then merges.
- **Conventional Commits.**
- **TDD:** failing test first, minimal implementation, test passes, commit.
- **No placeholders.** If a test's expected output isn't concrete, that's a plan bug.

---

## Task 1: Vendor godot-xterm addon

**Goal:** Install `godot-xterm` v4.0.3 into `addons/godot_xterm/`, enable the plugin in `project.godot`, verify the editor loads and the Terminal/PTY node types resolve. Does not wire anything yet — just installation.

**Files:**
- Create: `addons/godot_xterm/...` (from release zip)
- Modify: `project.godot` — enable plugin
- Modify: `.gitignore` — ensure addon libs aren't accidentally ignored

**Why TDD doesn't apply here:** This task installs a dependency. Validation is "editor imports without errors" + "the Terminal type resolves in a scene."

- [ ] **Step 1: Download the release zip**

```bash
cd /tmp
curl --fail -sSL -o godot-xterm-v4.0.3.zip \
  "https://github.com/lihop/godot-xterm/releases/download/v4.0.3/godot-xterm-v4.0.3.zip"
unzip -q godot-xterm-v4.0.3.zip -d godot-xterm-v4.0.3
```

- [ ] **Step 2: Copy into the project**

```bash
cd <worktree-path>
cp -r /tmp/godot-xterm-v4.0.3/addons/godot_xterm addons/
```

- [ ] **Step 3: Clear macOS quarantine on the bundled binaries**

```bash
xattr -dr com.apple.quarantine addons/godot_xterm || true
```

(`|| true` because the attribute may not be present on non-macOS checkouts.)

- [ ] **Step 4: Enable the plugin in `project.godot`**

Locate the `[editor_plugins]` block and add `godot_xterm` to `enabled`:

```
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg", "res://addons/godot_xterm/plugin.cfg")
```

- [ ] **Step 5: Verify `.gitignore` does not exclude the vendored binaries**

Check `.gitignore`. If any rule would exclude `addons/godot_xterm/lib/**`, exempt it. The current `.gitignore` (post v0.1.1) does not include `addons/`, so this is a read-only sanity check.

- [ ] **Step 6: Run Godot 4.3 headless import (expect no new errors)**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | tee /tmp/import.log
```

The known message `Parse Error: Could not find base class "Terminal"` in `editor_plugins/terminal/editor_terminal.gd` is expected under `--headless` (GDExtensions don't load) and is non-fatal. Other new errors MUST NOT appear.

- [ ] **Step 7: Verify the addon's sample Terminal type resolves in-editor**

Launch the editor once to let Godot cache the extension:

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --path . --editor --quit 2>&1 | tail -20
```

Expected: exits cleanly (exit code 0) without `Failed to load GDExtension` errors.

- [ ] **Step 8: Run GUT tests (expect all v0.1 tests still pass)**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1 | tail -20
```

Expected: `Passing 23, Failing 0`.

- [ ] **Step 9: Commit**

```bash
git add addons/godot_xterm project.godot
git commit -m "feat(deps): vendor godot-xterm v4.0.3 addon

Pre-built macOS universal + Windows binaries included. Enables
Terminal + PTY nodes for v0.2 work."
```

- [ ] **Step 10: Open PR, stop at `gh pr create`.**

---

## Task 2: Simplify `NpcConfig`

**Goal:** Remove `panel_scene`, `desk_position`, and `kind` fields from `NpcConfig`. The factory owns placement and panel_scene is no longer needed (every NPC uses `terminal.tscn`).

**Files:**
- Modify: `scripts/npc_config.gd`
- Modify: `test/unit/test_npc_config.gd`
- Modify: `test/fixtures/valid_npc.tres` — remove `panel_scene` + `desk_position` + `kind`
- Delete: `test/fixtures/invalid_npc_no_panel.tres`

**Preconditions:** Task 1 merged to `main`.

- [ ] **Step 1: Update the failing test first**

Edit `test/unit/test_npc_config.gd` to reflect the simplified shape:

```gdscript
extends GutTest

const NpcConfig := preload("res://scripts/npc_config.gd")

func test_valid_tres_loads_all_fields():
	var cfg: NpcConfig = load("res://test/fixtures/valid_npc.tres")
	assert_not_null(cfg)
	assert_eq(cfg.display_name, "Test NPC")
	assert_not_null(cfg.sprite_frames)

func test_default_new_instance_is_invalid():
	var cfg := NpcConfig.new()
	assert_false(cfg.is_valid(), "empty config must fail validation")

func test_missing_sprite_frames_fails_validation():
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	assert_false(cfg.is_valid())

func test_missing_display_name_fails_validation():
	var cfg := NpcConfig.new()
	cfg.sprite_frames = preload("res://test/fixtures/test_sprite_frames.tres")
	assert_false(cfg.is_valid())

func test_npc_status_enum_values():
	assert_eq(NpcStatus.Status.IDLE, 0)
	assert_eq(NpcStatus.Status.BUSY, 1)
	assert_eq(NpcStatus.Status.NOTIFY, 2)
```

- [ ] **Step 2: Run tests, confirm they fail**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gfile=res://test/unit/test_npc_config.gd -gexit
```

Expected: at least one failure (old fields still present / valid_npc.tres still has `panel_scene`).

- [ ] **Step 3: Write the new `NpcConfig`**

Replace `scripts/npc_config.gd` with:

```gdscript
extends Resource
class_name NpcConfig

@export var display_name: String = ""
@export var sprite_frames: SpriteFrames

func is_valid() -> bool:
	return display_name != "" and sprite_frames != null
```

- [ ] **Step 4: Update `test/fixtures/valid_npc.tres`**

```
[gd_resource type="Resource" script_class="NpcConfig" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/npc_config.gd" id="1_script"]
[ext_resource type="SpriteFrames" path="res://test/fixtures/test_sprite_frames.tres" id="2_frames"]

[resource]
script = ExtResource("1_script")
display_name = "Test NPC"
sprite_frames = ExtResource("2_frames")
```

- [ ] **Step 5: Delete `test/fixtures/invalid_npc_no_panel.tres`**

```bash
git rm test/fixtures/invalid_npc_no_panel.tres
```

- [ ] **Step 6: Run `test_npc_config.gd`, confirm pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gfile=res://test/unit/test_npc_config.gd -gexit
```

Expected: 5/5 pass.

- [ ] **Step 7: Commit**

```bash
git add scripts/npc_config.gd test/unit/test_npc_config.gd test/fixtures/valid_npc.tres
git commit -m "refactor(npc): simplify NpcConfig for v0.2

Remove panel_scene (every NPC uses terminal.tscn now), desk_position
(factory owns placement), kind (single kind in v0.2)."
```

- [ ] **Step 8: Note remaining test failures**

Other tests (`test_npc_entity.gd`, `test_interaction_system.gd`, `test_status_indicators.gd`) will fail at this point because they still set `cfg.panel_scene`. These fixes land in Task 4 — do NOT fix them here or the PR loses scope. Document in the PR body.

- [ ] **Step 9: Open PR, stop at `gh pr create`.**

---

## Task 3: `TerminalPanel` — scene + script + status tracking

**Goal:** Create `scenes/panels/terminal.tscn` and `scripts/terminal_panel.gd`. The panel owns a `Terminal` + `PTY` child, tracks session activity, and emits v0.1's `panel_closed` signal on close. Tests use a mock PTY (and a mock terminal stub) so GUT doesn't need a real shell.

**Files:**
- Create: `scripts/terminal_panel.gd`
- Create: `scenes/panels/terminal.tscn`
- Create: `test/fixtures/mock_pty.gd`
- Create: `test/fixtures/mock_terminal.gd`
- Create: `test/fixtures/test_terminal_panel.tscn`
- Create: `test/unit/test_terminal_panel.gd`

**Design contract (script):**

```gdscript
extends InteractionPanel
class_name TerminalPanel

signal session_ended
signal status_changed(new_status: NpcStatus.Status)

const QUIET_THRESHOLD_SEC := 1.5

var _panel_opened: bool = false
var _has_unread: bool = false
var _last_activity_time: float = 0.0
var _current_status: NpcStatus.Status = NpcStatus.Status.IDLE

@onready var _pty: Node = $PTY
@onready var _terminal: Control = $Frame/Terminal
@onready var _status_timer: Timer = $StatusTimer
@onready var _title_label: Label = $Frame/TitleBar/Title
@onready var _close_button: Button = $Frame/TitleBar/CloseButton
```

The script is duck-typed against `$PTY` — any node exposing `fork()`, `write(data)`, `resize(cols, rows)`, signals `data_received(PackedByteArray)` and `exited(int, int)` works. Same for `$Frame/Terminal` — any node exposing `grab_focus()`, `get_cols()`, `get_rows()`, `write(data)`, signals `data_sent(PackedByteArray)` and `resized()`.

**Preconditions:** Tasks 1 and 2 merged.

- [ ] **Step 1: Write the mock PTY helper**

Create `test/fixtures/mock_pty.gd`:

```gdscript
extends Node

signal data_received(data: PackedByteArray)
signal exited(exit_code: int, signum: int)

var fork_calls: int = 0
var write_calls: Array[PackedByteArray] = []
var resize_calls: Array = []  # Array[Vector2i]

func fork(_file := "", _args := [], _cwd := "", _cols := 0, _rows := 0) -> int:
	fork_calls += 1
	return OK

func write(data) -> void:
	var bytes: PackedByteArray
	if data is PackedByteArray:
		bytes = data
	elif data is String:
		bytes = data.to_utf8_buffer()
	write_calls.append(bytes)

func resize(cols: int, rows: int) -> void:
	resize_calls.append(Vector2i(cols, rows))

func emit_output(text: String) -> void:
	data_received.emit(text.to_utf8_buffer())

func emit_exit(code: int = 0, sig: int = 0) -> void:
	exited.emit(code, sig)
```

- [ ] **Step 2: Write the mock terminal helper**

Create `test/fixtures/mock_terminal.gd`:

```gdscript
extends Control

signal data_sent(data: PackedByteArray)
# resized is already a Control signal — no redeclaration needed.

var cols: int = 80
var rows: int = 24
var written: Array[PackedByteArray] = []
var focused: bool = false

func get_cols() -> int:
	return cols

func get_rows() -> int:
	return rows

func write(data) -> void:
	var bytes: PackedByteArray
	if data is PackedByteArray:
		bytes = data
	elif data is String:
		bytes = data.to_utf8_buffer()
	written.append(bytes)

func grab_focus() -> void:
	focused = true
```

- [ ] **Step 3: Write the test scene**

Create `test/fixtures/test_terminal_panel.tscn`:

```
[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://scripts/terminal_panel.gd" id="1_script"]
[ext_resource type="Script" path="res://test/fixtures/mock_pty.gd" id="2_pty"]
[ext_resource type="Script" path="res://test/fixtures/mock_terminal.gd" id="3_term"]

[node name="TerminalPanel" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_script")

[node name="PTY" type="Node" parent="."]
script = ExtResource("2_pty")

[node name="Frame" type="Panel" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="TitleBar" type="HBoxContainer" parent="Frame"]

[node name="Title" type="Label" parent="Frame/TitleBar"]
text = "TEST"

[node name="CloseButton" type="Button" parent="Frame/TitleBar"]
text = "X"

[node name="Terminal" type="Control" parent="Frame"]
script = ExtResource("3_term")

[node name="StatusTimer" type="Timer" parent="."]
wait_time = 0.1
autostart = true
```

- [ ] **Step 4: Write the failing test**

Create `test/unit/test_terminal_panel.gd`:

```gdscript
extends GutTest

const TestScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func _make_panel() -> Node:
	var panel: Node = TestScene.instantiate()
	add_child_autofree(panel)
	return panel

func test_fork_called_on_ready():
	var panel := _make_panel()
	await wait_frames(1)
	assert_eq(panel.get_node("PTY").fork_calls, 1)

func test_show_for_sets_opened_and_grabs_focus():
	var panel := _make_panel()
	await wait_frames(1)
	panel.show_for(null)
	assert_true(panel.get_node("Frame/Terminal").focused)
	assert_eq(panel._current_status, NpcStatus.Status.IDLE)

func test_output_while_closed_sets_unread_and_busy():
	var panel := _make_panel()
	await wait_frames(1)
	# Panel defaults to not-opened.
	panel.get_node("PTY").emit_output("hello")
	await wait_frames(1)
	assert_true(panel._has_unread)
	assert_eq(panel._current_status, NpcStatus.Status.BUSY)

func test_output_then_quiet_transitions_to_notify():
	var panel := _make_panel()
	await wait_frames(1)
	panel.get_node("PTY").emit_output("hello")
	# Simulate QUIET_THRESHOLD passing by advancing _last_activity_time
	panel._last_activity_time -= 2.0
	panel._recompute_status()
	assert_eq(panel._current_status, NpcStatus.Status.NOTIFY)

func test_open_panel_clears_unread_and_status():
	var panel := _make_panel()
	await wait_frames(1)
	panel.get_node("PTY").emit_output("hello")
	panel.show_for(null)
	assert_false(panel._has_unread)
	assert_eq(panel._current_status, NpcStatus.Status.IDLE)

func test_close_reverts_and_leaves_unread_false_until_new_output():
	var panel := _make_panel()
	await wait_frames(1)
	panel.show_for(null)
	panel.close()
	assert_false(panel._has_unread)
	assert_eq(panel._current_status, NpcStatus.Status.IDLE)

func test_pty_exit_emits_session_ended():
	var panel := _make_panel()
	await wait_frames(1)
	var ended := [false]
	panel.session_ended.connect(func(): ended[0] = true)
	panel.get_node("PTY").emit_exit(0, 0)
	assert_true(ended[0])

func test_input_forwarded_terminal_to_pty():
	var panel := _make_panel()
	await wait_frames(1)
	var term: Node = panel.get_node("Frame/Terminal")
	term.data_sent.emit("abc".to_utf8_buffer())
	var writes: Array = panel.get_node("PTY").write_calls
	assert_eq(writes.size(), 1)
	assert_eq(writes[0], "abc".to_utf8_buffer())

func test_output_forwarded_pty_to_terminal():
	var panel := _make_panel()
	await wait_frames(1)
	panel.get_node("PTY").emit_output("xyz")
	var writes: Array = panel.get_node("Frame/Terminal").written
	assert_eq(writes.size(), 1)
	assert_eq(writes[0], "xyz".to_utf8_buffer())
```

- [ ] **Step 5: Run tests, confirm they fail (script does not exist yet)**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gfile=res://test/unit/test_terminal_panel.gd -gexit
```

Expected: all 9 fail with "script not found" or "method not found".

- [ ] **Step 6: Write `scripts/terminal_panel.gd`**

```gdscript
extends InteractionPanel
class_name TerminalPanel

signal session_ended
signal status_changed(new_status: NpcStatus.Status)

const QUIET_THRESHOLD_SEC := 1.5

var _panel_opened: bool = false
var _has_unread: bool = false
var _last_activity_time: float = 0.0
var _current_status: NpcStatus.Status = NpcStatus.Status.IDLE

@onready var _pty: Node = $PTY
@onready var _terminal: Control = $Frame/Terminal
@onready var _status_timer: Timer = $StatusTimer
@onready var _title_label: Label = $Frame/TitleBar/Title
@onready var _close_button: Button = $Frame/TitleBar/CloseButton

func _ready() -> void:
	# Wire signals (duck-typed).
	_terminal.data_sent.connect(_on_terminal_data_sent)
	_pty.data_received.connect(_on_pty_data_received)
	_pty.exited.connect(_on_pty_exited)
	_terminal.resized.connect(_on_terminal_resized)
	_close_button.pressed.connect(close)
	_status_timer.timeout.connect(_recompute_status)

	var err: int = _pty.fork()
	if err != OK:
		push_error("pty.fork failed: %s" % err)

func show_for(npc) -> void:
	super.show_for(npc)
	_panel_opened = true
	_has_unread = false
	visible = true
	_terminal.grab_focus()
	if npc != null and npc.config != null:
		_title_label.text = npc.config.display_name
	_set_status(NpcStatus.Status.IDLE)

func close() -> void:
	_panel_opened = false
	visible = false
	panel_closed.emit()

func _on_terminal_data_sent(data: PackedByteArray) -> void:
	_pty.write(data)

func _on_pty_data_received(data: PackedByteArray) -> void:
	_terminal.write(data)
	_last_activity_time = Time.get_ticks_msec() / 1000.0
	if not _panel_opened:
		_has_unread = true
	_recompute_status()

func _on_pty_exited(_code: int, _signum: int) -> void:
	session_ended.emit()

func _on_terminal_resized() -> void:
	_pty.resize(_terminal.get_cols(), _terminal.get_rows())

func _recompute_status() -> void:
	var next: NpcStatus.Status
	if _panel_opened:
		next = NpcStatus.Status.IDLE
	elif not _has_unread:
		next = NpcStatus.Status.IDLE
	else:
		var quiet: bool = (Time.get_ticks_msec() / 1000.0) - _last_activity_time >= QUIET_THRESHOLD_SEC
		next = NpcStatus.Status.NOTIFY if quiet else NpcStatus.Status.BUSY
	_set_status(next)

func _set_status(new_status: NpcStatus.Status) -> void:
	if new_status == _current_status:
		return
	_current_status = new_status
	status_changed.emit(new_status)
```

- [ ] **Step 7: Run tests, confirm they pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gfile=res://test/unit/test_terminal_panel.gd -gexit
```

Expected: 9/9 pass.

- [ ] **Step 8: Create the production scene**

Create `scenes/panels/terminal.tscn`. Panel dimensions ~512×288 centered in 640×360 viewport.

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/terminal_panel.gd" id="1_script"]

[node name="TerminalPanel" type="Control"]
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -256.0
offset_top = -144.0
offset_right = 256.0
offset_bottom = 144.0
mouse_filter = 0
script = ExtResource("1_script")

[node name="PTY" type="PTY" parent="."]

[node name="Frame" type="Panel" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="TitleBar" type="HBoxContainer" parent="Frame"]
anchors_preset = 10
anchor_right = 1.0
offset_bottom = 18.0

[node name="Title" type="Label" parent="Frame/TitleBar"]
size_flags_horizontal = 3
text = "NPC"

[node name="CloseButton" type="Button" parent="Frame/TitleBar"]
custom_minimum_size = Vector2(18, 18)
text = "X"

[node name="Terminal" type="Terminal" parent="Frame"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 20.0
offset_left = 4.0
offset_right = -4.0
offset_bottom = -4.0
focus_mode = 2

[node name="StatusTimer" type="Timer" parent="."]
wait_time = 0.1
autostart = true
```

- [ ] **Step 9: Re-import the project to pick up new scenes**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import
```

- [ ] **Step 10: Commit**

```bash
git add scripts/terminal_panel.gd scenes/panels/terminal.tscn test/fixtures/mock_pty.gd \
        test/fixtures/mock_terminal.gd test/fixtures/test_terminal_panel.tscn \
        test/unit/test_terminal_panel.gd
git commit -m "feat(terminal): TerminalPanel with PTY lifecycle + status tracking

Owns a Terminal + PTY; tracks activity for the BUSY/NOTIFY indicator.
Duck-typed against child nodes so mock PTY/Terminal work in unit tests."
```

- [ ] **Step 11: Open PR, stop at `gh pr create`.**

---

## Task 4: `NpcEntity` owns a `TerminalPanel`

**Goal:** Make `NpcEntity` instantiate a `TerminalPanel` on `_ready` and return that same instance from `interact()`. Update `scenes/npc.tscn` to remove texture pre-set. Update the other tests that still pass `panel_scene` through `NpcConfig`.

**Files:**
- Modify: `scripts/npc_entity.gd`
- Modify: `scenes/npc.tscn`
- Modify: `test/unit/test_npc_entity.gd`
- Modify: `test/unit/test_interaction_system.gd`
- Modify: `test/unit/test_status_indicators.gd`

**Preconditions:** Tasks 1, 2, 3 merged.

- [ ] **Step 1: Write the failing test for NpcEntity**

Replace `test/unit/test_npc_entity.gd`:

```gdscript
extends GutTest

const NpcScene := preload("res://scenes/npc.tscn")
const TestFrames := preload("res://test/fixtures/test_sprite_frames.tres")
# Use the TerminalPanel fixture with a mock PTY for test NPCs.
const TerminalPanelTestScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func _make_cfg() -> NpcConfig:
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	cfg.sprite_frames = TestFrames
	return cfg

func _instantiate_npc_with_mock_panel() -> Node:
	var npc: Node = NpcScene.instantiate()
	npc.config = _make_cfg()
	# Swap panel_scene_override so _ready uses the test panel with mock PTY.
	npc.panel_scene_override = TerminalPanelTestScene
	return npc

func test_npc_instantiates_terminal_panel_on_ready():
	var npc := _instantiate_npc_with_mock_panel()
	add_child_autofree(npc)
	await wait_frames(1)
	var panels := npc.find_children("TerminalPanel", "", true, false)
	assert_eq(panels.size(), 1)

func test_interact_returns_same_panel_each_call():
	var npc := _instantiate_npc_with_mock_panel()
	add_child_autofree(npc)
	await wait_frames(1)
	var first: InteractionPanel = npc.interact()
	var second: InteractionPanel = npc.interact()
	assert_same(first, second)

func test_status_bubbles_up_from_panel():
	var npc := _instantiate_npc_with_mock_panel()
	add_child_autofree(npc)
	await wait_frames(1)
	var observed: Array = []
	npc.status_changed.connect(func(s): observed.append(s))
	var panel: Node = npc.interact()  # same panel instance
	# Simulate output while panel closed: trigger PTY directly.
	panel.get_node("PTY").emit_output("hi")
	# _panel_opened defaults false since show_for wasn't called here.
	panel._recompute_status()
	assert_true(observed.size() > 0)
```

- [ ] **Step 2: Run test, confirm failure**

Expected: `panel_scene_override` not defined, `find_children` returns 0, status bubbling not wired.

- [ ] **Step 3: Modify `scripts/npc_entity.gd`**

```gdscript
extends Node2D
class_name NpcEntity

signal interaction_started(panel: InteractionPanel)
signal interaction_ended
signal status_changed(new_status: NpcStatus.Status)

const DEFAULT_PANEL_SCENE := preload("res://scenes/panels/terminal.tscn")

@export var config: NpcConfig
## For tests only — substitute a panel scene with a mock PTY.
var panel_scene_override: PackedScene

var status: NpcStatus.Status = NpcStatus.Status.IDLE :
	set(value):
		if status == value:
			return
		status = value
		status_changed.emit(value)

var _panel: InteractionPanel

func _ready() -> void:
	if config == null:
		push_warning("NpcEntity has no config assigned; skipping spawn")
		queue_free()
		return
	if not config.is_valid():
		push_warning("NpcConfig invalid for NPC at %s; skipping" % get_path())
		queue_free()
		return
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	sprite.sprite_frames = config.sprite_frames
	sprite.play("idle_south")

	var scene: PackedScene = panel_scene_override if panel_scene_override != null else DEFAULT_PANEL_SCENE
	_panel = scene.instantiate()
	_panel.visible = false
	add_child(_panel)

	# Bubble status from panel to UIRoot listeners.
	if _panel.has_signal("status_changed"):
		_panel.status_changed.connect(func(s): status = s)
	# Self-destruct when the shell exits.
	if _panel.has_signal("session_ended"):
		_panel.session_ended.connect(func():
			if _panel.visible:
				_panel.close()
			queue_free())

func interact() -> InteractionPanel:
	return _panel

func _on_panel_closed() -> void:
	interaction_ended.emit()
```

- [ ] **Step 4: Update `scenes/npc.tscn`**

Remove texture pre-wire (from v0.1.1 it's already using config.sprite_frames assigned at `_ready`). Verify current content uses `AnimatedSprite2D` and has no hardcoded texture. If any `autoplay` or pre-set animation remains, that's fine.

- [ ] **Step 5: Update `test/unit/test_interaction_system.gd`**

Replace:

```gdscript
cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
```

with: (delete the line — `NpcConfig` no longer has `panel_scene`). Set `npc.panel_scene_override = preload("res://test/fixtures/test_terminal_panel.tscn")` right after `var npc = NpcScene.instantiate()`.

The rest of the test (closest NPC wins, target cleared on exit) is unchanged.

- [ ] **Step 6: Update `test/unit/test_status_indicators.gd` similarly**

Drop `cfg.panel_scene = ...`. Add `npc.panel_scene_override = preload("res://test/fixtures/test_terminal_panel.tscn")` after instantiation.

- [ ] **Step 7: Run all unit tests, confirm pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

Expected: all tests (including `test_stub_dialogue_panel.gd` — still present until Task 8) pass, except possibly stub_dialogue tests which may break if their config path loaded the deleted `invalid_npc_no_panel.tres`. If stub_dialogue tests fail solely for that reason, **do not fix them here** — Task 8 removes them entirely.

- [ ] **Step 8: Commit**

```bash
git add scripts/npc_entity.gd scenes/npc.tscn test/unit/test_npc_entity.gd \
        test/unit/test_interaction_system.gd test/unit/test_status_indicators.gd
git commit -m "feat(npc): NpcEntity owns one TerminalPanel for its lifetime

Panel instantiated in _ready, reused across interactions.
Session end (shell exit) queue_frees the NPC."
```

- [ ] **Step 9: Open PR, stop at `gh pr create`.**

---

## Task 5: `TerminalNpcFactory`

**Goal:** A `Node` that allocates NPCs to 4 desk slots and frees slots when NPCs `tree_exiting`. Unit-testable without a real scene.

**Files:**
- Create: `scripts/terminal_npc_factory.gd`
- Create: `test/unit/test_terminal_npc_factory.gd`

**Preconditions:** Tasks 1–4 merged.

- [ ] **Step 1: Write the failing tests**

Create `test/unit/test_terminal_npc_factory.gd`:

```gdscript
extends GutTest

const FactoryScript := preload("res://scripts/terminal_npc_factory.gd")
const TestFrames := preload("res://test/fixtures/test_sprite_frames.tres")
const TestPanelScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func _make_factory() -> Node:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var f: Node = FactoryScript.new()
	f.sprite_frames_pool = [TestFrames]
	f.panel_scene_override = TestPanelScene
	parent.add_child(f)
	return f

func test_first_spawn_uses_first_desk():
	var f := _make_factory()
	var npc: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	assert_not_null(npc)
	assert_eq(npc.position, Vector2(144, 144))

func test_four_spawns_fill_all_desks():
	var f := _make_factory()
	var npcs: Array[Node] = []
	for i in range(4):
		var n: Node = f.spawn_at_free_desk()
		assert_not_null(n, "spawn %d should succeed" % i)
		npcs.append(n)
	await wait_frames(1)
	assert_eq(npcs[0].position, Vector2(144, 144))
	assert_eq(npcs[1].position, Vector2(368, 144))
	assert_eq(npcs[2].position, Vector2(144, 240))
	assert_eq(npcs[3].position, Vector2(368, 240))

func test_fifth_spawn_returns_null():
	var f := _make_factory()
	for i in range(4):
		f.spawn_at_free_desk()
	await wait_frames(1)
	var fifth: Node = f.spawn_at_free_desk()
	assert_null(fifth)

func test_freeing_npc_frees_its_desk():
	var f := _make_factory()
	var first: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	first.queue_free()
	await wait_frames(2)
	var second: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	assert_not_null(second)
	assert_eq(second.position, Vector2(144, 144))

func test_display_name_counter_increments():
	var f := _make_factory()
	var a: Node = f.spawn_at_free_desk()
	var b: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	assert_ne(a.config.display_name, b.config.display_name)
```

- [ ] **Step 2: Run tests, confirm failure**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gfile=res://test/unit/test_terminal_npc_factory.gd -gexit
```

Expected: all fail (script doesn't exist).

- [ ] **Step 3: Write `scripts/terminal_npc_factory.gd`**

```gdscript
extends Node
class_name TerminalNpcFactory

signal spawn_failed(reason: String)
signal spawn_succeeded(npc: NpcEntity)

const NPC_SCENE := preload("res://scenes/npc.tscn")
const DESK_POSITIONS: Array[Vector2] = [
	Vector2(144, 144),
	Vector2(368, 144),
	Vector2(144, 240),
	Vector2(368, 240),
]

## Populated by the world scene. Cycled for each spawn.
@export var sprite_frames_pool: Array[SpriteFrames] = []

## For tests only — overrides the default terminal.tscn.
var panel_scene_override: PackedScene

var _occupied: Array[bool] = [false, false, false, false]
var _spawn_counter: int = 0

func spawn_at_free_desk() -> NpcEntity:
	var idx := _occupied.find(false)
	if idx == -1:
		spawn_failed.emit("all desks full")
		return null
	if sprite_frames_pool.is_empty():
		spawn_failed.emit("sprite pool empty")
		return null
	_occupied[idx] = true
	_spawn_counter += 1

	var cfg := NpcConfig.new()
	cfg.display_name = "NPC-%d" % _spawn_counter
	cfg.sprite_frames = sprite_frames_pool[(_spawn_counter - 1) % sprite_frames_pool.size()]

	var npc: NpcEntity = NPC_SCENE.instantiate()
	npc.config = cfg
	npc.position = DESK_POSITIONS[idx]
	if panel_scene_override != null:
		npc.panel_scene_override = panel_scene_override
	npc.tree_exiting.connect(func(): _occupied[idx] = false)
	get_parent().add_child(npc)
	spawn_succeeded.emit(npc)
	return npc
```

- [ ] **Step 4: Run tests, confirm pass**

Expected: 5/5 pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/terminal_npc_factory.gd test/unit/test_terminal_npc_factory.gd
git commit -m "feat(world): TerminalNpcFactory with slot allocation"
```

- [ ] **Step 6: Open PR, stop at `gh pr create`.**

---

## Task 6: HUD + `spawn_terminal` input action

**Goal:** Add a HUD overlay with a "+ new terminal" button that fires `spawn_terminal` input. Wire keybind `N` to the same action. UIRoot hosts the HUD. A `spawn_requested` signal bubbles up from HUD to `world.gd` for wiring in Task 7.

**Files:**
- Create: `scenes/ui/hud.tscn`
- Create: `scripts/hud.gd`
- Modify: `scenes/ui/ui_root.tscn` (add HUD child)
- Modify: `scripts/ui_root.gd` (expose HUD's `spawn_requested` signal)
- Modify: `project.godot` (add `spawn_terminal` action bound to `N`)

**Preconditions:** Task 1 merged. Independent of Tasks 2–5.

- [ ] **Step 1: Add the input action**

Edit `project.godot`. In the `[input]` block, append:

```
spawn_terminal={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":78,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

`keycode: 78` is `N`.

- [ ] **Step 2: Write the HUD test**

Create `test/unit/test_hud.gd`:

```gdscript
extends GutTest

const HudScene := preload("res://scenes/ui/hud.tscn")

func test_button_press_emits_spawn_requested():
	var hud: Node = HudScene.instantiate()
	add_child_autofree(hud)
	var fired := [0]
	hud.spawn_requested.connect(func(): fired[0] += 1)
	var btn: Button = hud.get_node("SpawnButton")
	btn.pressed.emit()
	assert_eq(fired[0], 1)

func test_action_press_emits_spawn_requested():
	var hud: Node = HudScene.instantiate()
	add_child_autofree(hud)
	var fired := [0]
	hud.spawn_requested.connect(func(): fired[0] += 1)
	# Simulate action by calling the handler directly (GUT can't easily inject InputEvents here).
	hud._on_spawn_terminal_action()
	assert_eq(fired[0], 1)

func test_toast_label_shows_message():
	var hud: Node = HudScene.instantiate()
	add_child_autofree(hud)
	hud.show_toast("All desks full")
	var toast: Label = hud.get_node("Toast")
	assert_eq(toast.text, "All desks full")
	assert_true(toast.visible)
```

- [ ] **Step 3: Run test, expect failure**

Script + scene don't exist yet.

- [ ] **Step 4: Create `scripts/hud.gd`**

```gdscript
extends Control
class_name Hud

signal spawn_requested

const TOAST_SECONDS := 2.0

@onready var _spawn_button: Button = $SpawnButton
@onready var _toast: Label = $Toast
@onready var _toast_timer: Timer = $ToastTimer

func _ready() -> void:
	_spawn_button.pressed.connect(func(): spawn_requested.emit())
	_toast.visible = false
	_toast_timer.timeout.connect(func(): _toast.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_terminal"):
		_on_spawn_terminal_action()

func _on_spawn_terminal_action() -> void:
	if not GameRoot.world_input_paused:
		spawn_requested.emit()

func show_toast(msg: String) -> void:
	_toast.text = msg
	_toast.visible = true
	_toast_timer.start(TOAST_SECONDS)
```

- [ ] **Step 5: Create `scenes/ui/hud.tscn`**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1_script"]

[node name="Hud" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
script = ExtResource("1_script")

[node name="SpawnButton" type="Button" parent="."]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -120.0
offset_top = 4.0
offset_right = -4.0
offset_bottom = 24.0
text = "+ new terminal"

[node name="Toast" type="Label" parent="."]
anchors_preset = 7
anchor_left = 0.5
anchor_right = 0.5
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -100.0
offset_top = -32.0
offset_right = 100.0
offset_bottom = -8.0
horizontal_alignment = 1
visible = false

[node name="ToastTimer" type="Timer" parent="."]
one_shot = true
```

- [ ] **Step 6: Update `scenes/ui/ui_root.tscn`**

Add a `Hud` child instance (same level as `Prompt`, `IndicatorLayer`, `PanelHost`):

```
[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="NEW_hud"]

... existing nodes ...

[node name="Hud" parent="." instance=ExtResource("NEW_hud")]
```

- [ ] **Step 7: Expose HUD signal on `ui_root.gd`**

Add to `scripts/ui_root.gd`:

```gdscript
signal spawn_requested

@onready var _hud: Hud = $Hud

func _ready() -> void:
	# existing body unchanged
	_hud.spawn_requested.connect(func(): spawn_requested.emit())

func show_toast(msg: String) -> void:
	_hud.show_toast(msg)
```

(Keep existing `_ready` content; prepend/append the connect call without disturbing other setup.)

- [ ] **Step 8: Run tests**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gfile=res://test/unit/test_hud.gd -gexit
```

Expected: 3/3 pass.

- [ ] **Step 9: Run the full suite**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

Expected: no regressions.

- [ ] **Step 10: Commit**

```bash
git add project.godot scripts/hud.gd scenes/ui/hud.tscn scenes/ui/ui_root.tscn \
        scripts/ui_root.gd test/unit/test_hud.gd
git commit -m "feat(ui): HUD with + new terminal button and N hotkey"
```

- [ ] **Step 11: Open PR, stop at `gh pr create`.**

---

## Task 7: World scene integration

**Goal:** Update `world.tscn` to remove the four static `NpcClaude/Codex/Gemini/Spare` instances. Add a `TerminalNpcFactory` node as a child of World. Update `world.gd` to: spawn one NPC on `_ready`, listen to `UIRoot.spawn_requested` and `factory.spawn_failed` to wire the HUD flow.

**Files:**
- Modify: `scenes/world.tscn`
- Modify: `scripts/world.gd`

**Preconditions:** Tasks 1–6 merged.

- [ ] **Step 1: Read current `world.gd` and plan changes**

```bash
cat scripts/world.gd
```

Confirm current content (should be small from v0.1).

- [ ] **Step 2: Remove the four static NPC nodes from `world.tscn`**

Edit `scenes/world.tscn`. Delete nodes `NpcClaude`, `NpcCodex`, `NpcGemini`, `NpcSpare` and the four `ExtResource` entries pointing at `res://data/npcs/npc_*.tres`. Also delete the `ext_resource type="PackedScene" ... scenes/npc.tscn` ONLY IF no longer referenced. (It IS still referenced — the factory preloads it — so keep it in-memory only if the world scene had an instance, which it no longer does. Safe to delete this ExtResource from world.tscn specifically.)

- [ ] **Step 3: Add `TerminalNpcFactory` and register NPC group membership**

In `scenes/world.tscn`, add:

```
[ext_resource type="Script" path="res://scripts/terminal_npc_factory.gd" id="NEW_factory"]
[ext_resource type="SpriteFrames" path="res://data/characters/player.tres" id="NEW_pf1"]
[ext_resource type="SpriteFrames" path="res://data/characters/npc_claude.tres" id="NEW_pf2"]
[ext_resource type="SpriteFrames" path="res://data/characters/npc_codex.tres" id="NEW_pf3"]
[ext_resource type="SpriteFrames" path="res://data/characters/npc_gemini.tres" id="NEW_pf4"]
[ext_resource type="SpriteFrames" path="res://data/characters/npc_spare.tres" id="NEW_pf5"]

[node name="Factory" type="Node" parent="."]
script = ExtResource("NEW_factory")
sprite_frames_pool = [ExtResource("NEW_pf2"), ExtResource("NEW_pf3"), ExtResource("NEW_pf4"), ExtResource("NEW_pf5")]
```

(Player's SpriteFrames stays separate — player has its own in `player.tscn`.)

Spawned NPCs need to auto-join the `npc` group for `UIRoot.register_npc` to pick them up. Add in `terminal_npc_factory.gd` `spawn_at_free_desk` body after `get_parent().add_child(npc)`:

```gdscript
npc.add_to_group("npc")
UIRoot_register_helper(npc)  # if UIRoot exposes a registration helper; otherwise emit succeeded and let world.gd call it
```

Simpler: rely on `spawn_succeeded` signal and let `world.gd` do the registration.

- [ ] **Step 4: Update `scripts/world.gd`**

```gdscript
extends Node2D
class_name World

@onready var _factory: TerminalNpcFactory = $Factory
@onready var _ui: UIRootNode = $UIRoot

func _ready() -> void:
	_factory.spawn_succeeded.connect(_on_spawn_succeeded)
	_factory.spawn_failed.connect(_on_spawn_failed)
	_ui.spawn_requested.connect(_on_spawn_requested)
	# Initial NPC on game start.
	_factory.spawn_at_free_desk()

func _on_spawn_requested() -> void:
	_factory.spawn_at_free_desk()

func _on_spawn_succeeded(npc: NpcEntity) -> void:
	npc.add_to_group("npc")
	_ui.register_npc(npc)

func _on_spawn_failed(reason: String) -> void:
	_ui.show_toast(reason.capitalize())
```

- [ ] **Step 5: Re-import the project**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import
```

- [ ] **Step 6: Run the game manually for a smoke test**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --path .
```

Manual check: game launches. One NPC at the top-left desk. Press E → panel opens with a live shell. Run `echo hi` → output appears. Press Esc → panel closes. Press N → a second NPC appears at the next desk. Press N three more times → fourth NPC at last desk, fifth press shows "All desks full" toast. Type `exit` inside any NPC's terminal → that NPC disappears; pressing N creates a replacement.

- [ ] **Step 7: Run the full unit suite**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add scenes/world.tscn scripts/world.gd scripts/terminal_npc_factory.gd
git commit -m "feat(world): factory-driven spawn; removed static NPCs

Game starts with one terminal NPC; N / HUD button spawns more;
killed NPCs free their desk for respawn."
```

- [ ] **Step 9: Open PR, stop at `gh pr create`.**

---

## Task 8: Delete stub dialogue artifacts

**Goal:** Remove v0.1's stub dialogue scene + script + tests + the `data/npcs/npc_*.tres` configs that referenced it.

**Files:**
- Delete: `scenes/panels/stub_dialogue.tscn`
- Delete: `scripts/stub_dialogue_panel.gd`
- Delete: `test/unit/test_stub_dialogue_panel.gd`
- Delete: `data/npcs/npc_01.tres`, `npc_02.tres`, `npc_03.tres`, `npc_04.tres`

**Preconditions:** Task 7 merged. (World no longer references these files.)

- [ ] **Step 1: Verify nothing still references the files**

```bash
grep -rn "stub_dialogue\|data/npcs/npc_0" scenes/ scripts/ test/ project.godot
```

Expected: no matches. If any, fix before proceeding.

- [ ] **Step 2: Delete the files**

```bash
git rm scenes/panels/stub_dialogue.tscn scripts/stub_dialogue_panel.gd \
       test/unit/test_stub_dialogue_panel.gd \
       data/npcs/npc_01.tres data/npcs/npc_02.tres data/npcs/npc_03.tres data/npcs/npc_04.tres
```

- [ ] **Step 3: Remove the now-empty `data/npcs/` directory if it is empty**

```bash
rmdir data/npcs 2>/dev/null || true
```

- [ ] **Step 4: Re-import and run all tests**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

Expected: all pass, no missing-resource warnings.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove v0.1 stub dialogue panel and fixtures"
```

- [ ] **Step 6: Open PR, stop at `gh pr create`.**

---

## Task 9: Playtest checklist + macOS dev doc update

**Goal:** Add a v0.2-specific playtest checklist to `docs/playtest.md`. Update `docs/dev-setup.md` with the `xattr` note for the vendored addon.

**Files:**
- Create or modify: `docs/playtest.md`
- Modify: `docs/dev-setup.md`

**Preconditions:** Tasks 1–8 merged.

- [ ] **Step 1: Append a v0.2 checklist section**

Edit (or create) `docs/playtest.md`:

```markdown
## v0.2 Terminal MVP checklist

Run against the tagged build on macOS (primary) and Windows (spot-check).

1. [ ] Game launches, single NPC visible at top-left desk (tile col 4, row 4).
2. [ ] Approach NPC: "press E" prompt appears above head.
3. [ ] Press E: terminal panel opens centered; shell cursor focused; window chrome visible (title + X).
4. [ ] Type `echo hi` → output renders without artifacts.
5. [ ] Type `claude -p "2+2"` (if claude CLI installed) → expected reply renders.
6. [ ] Esc closes panel, WASD resumes.
7. [ ] Inside panel, run `sleep 3; echo done`; close panel immediately; indicator shows `..` during sleep, switches to `!` within ~1-2 seconds after "done" prints.
8. [ ] Re-open panel: indicator clears to none; scrollback shows the sleep/done lines.
9. [ ] Type `exit` in the panel; panel closes, NPC disappears, no errors in Output log.
10. [ ] Press `N`: new NPC appears at first free desk.
11. [ ] Click `+ new terminal` in the HUD: same behavior.
12. [ ] Spawn 4 NPCs; 5th attempt shows "All desks full" toast for ~2 seconds, nothing else.
13. [ ] Relaunch game: starts clean with one NPC again.
```

- [ ] **Step 2: Add the `xattr` note**

Append to `docs/dev-setup.md` under a new "Known gotchas" section:

```markdown
## Known gotchas

### macOS: godot-xterm dylib quarantine

On first checkout, macOS may quarantine the vendored `.framework` inside `addons/godot_xterm/lib/`, causing `pty.fork()` to fail silently with `posix_spawnp: Permission denied`. Clear it with:

\`\`\`bash
xattr -dr com.apple.quarantine addons/godot_xterm
\`\`\`

The cleared state persists in-place.
```

- [ ] **Step 3: Commit**

```bash
git add docs/playtest.md docs/dev-setup.md
git commit -m "docs: v0.2 playtest checklist and macOS xattr note"
```

- [ ] **Step 4: Open PR, stop at `gh pr create`.**

---

## Task 10: Release v0.2.0

**Goal:** CHANGELOG entry, version bump, tag, Build workflow, GitHub release with artifacts, close milestone.

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `project.godot` — `config/version="0.2.0"`

**Preconditions:** Tasks 1–9 merged. Local playtest per `docs/playtest.md#v0.2 Terminal MVP checklist` passes.

- [ ] **Step 1: Append `[0.2.0]` section to CHANGELOG**

Insert after `## [Unreleased]`:

```markdown
## [0.2.0] - <YYYY-MM-DD>

### Added
- Real persistent terminals per NPC via the vendored `godot-xterm` v4.0.3 addon. Each NPC runs `$SHELL` in a full PTY; the session survives panel open/close.
- `+ new terminal` HUD button and `N` hotkey to spawn new terminal NPCs at free desks. Game starts with one pre-spawned NPC.
- Status indicators now reflect session state: `..` while output is streaming (panel closed), `!` once the session has been quiet for ≥1.5 seconds with unread output.
- Shell exit (`exit` / Ctrl-D / process death) removes the NPC from the world.

### Changed
- `NpcConfig` simplified: dropped `panel_scene`, `desk_position`, and `kind`. Factory owns placement; every NPC uses the terminal panel.
- `scenes/npc.tscn` no longer pre-sets texture; the panel scene is picked by `NpcEntity._ready`.
- `world.tscn` no longer contains static NPC instances; `TerminalNpcFactory` spawns them at runtime.

### Removed
- `scenes/panels/stub_dialogue.tscn`, `scripts/stub_dialogue_panel.gd`, and all v0.1 `data/npcs/npc_*.tres` fixtures.
- `test/fixtures/invalid_npc_no_panel.tres`.
```

- [ ] **Step 2: Bump version**

In `project.godot`, `config/version="0.1.1"` → `config/version="0.2.0"`.

- [ ] **Step 3: Update CHANGELOG compare links**

```markdown
[Unreleased]: https://github.com/norumander/llmvile/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/norumander/llmvile/releases/tag/v0.2.0
[0.1.1]: https://github.com/norumander/llmvile/releases/tag/v0.1.1
[0.1.0]: https://github.com/norumander/llmvile/releases/tag/v0.1.0
```

- [ ] **Step 4: Commit + PR + merge (standard flow)**

- [ ] **Step 5: Tag and push**

```bash
git pull origin main --ff-only
git tag -a v0.2.0 -m "v0.2 Terminal MVP"
git push origin v0.2.0
```

- [ ] **Step 6: Wait for tagged Build workflow to succeed on both platforms**

Check `gh run list --workflow=build.yml -R norumander/llmvile --limit 1`. Wait until `conclusion` is `success`.

- [ ] **Step 7: Download artifacts and package zips**

```bash
mkdir -p /tmp/llmvile-v020-release && cd /tmp/llmvile-v020-release
gh run download <RUN_ID> -R norumander/llmvile
zip -rq llmvile-v0.2.0-macos.zip llmvile-macOS/llmvile.app
zip -jq llmvile-v0.2.0-windows.zip llmvile-Windows/llmvile.exe llmvile-Windows/llmvile.pck
```

- [ ] **Step 8: Create GitHub release**

```bash
gh release create v0.2.0 -R norumander/llmvile \
  --title "v0.2.0 — Terminal MVP" \
  --generate-notes \
  /tmp/llmvile-v020-release/llmvile-v0.2.0-macos.zip \
  /tmp/llmvile-v020-release/llmvile-v0.2.0-windows.zip
```

- [ ] **Step 9: Close the v0.2 milestone**

```bash
gh api -X PATCH /repos/norumander/llmvile/milestones/2 -f state=closed
```

- [ ] **Step 10: Update `docs/superpowers/PROGRESS.md`**

Record v0.2.0 shipped: tag + release URL + milestone closed. Direct push to `main`.

---

## Self-review notes

- **Spec coverage:** every spec section maps to a task. Tasks 1–10 cover: addon install, NpcConfig simplification, TerminalPanel, NpcEntity rewiring, factory, HUD, world wiring, v0.1 cleanup, docs, release.
- **Placeholder scan:** no TBDs. Every code block is complete. Every test has concrete assertions.
- **Type consistency:** `TerminalNpcFactory.spawn_at_free_desk()` returns `NpcEntity`; used in `world.gd._on_spawn_succeeded` receiving `npc: NpcEntity`. `NpcConfig` shape (two fields) is consistent across Tasks 2, 4, 5. `panel_scene_override` is defined in Task 4 and used in Tasks 4 + 5. Status enum values unchanged from v0.1.

## References

- [v0.2 design spec](../specs/2026-04-18-v02-terminal-mvp-design.md)
- [v0.1 plan](2026-04-17-v01-walkable-overworld.md) — conventions and workflow inherited
- [godot-xterm v4.0.3](https://github.com/lihop/godot-xterm/releases/tag/v4.0.3)
