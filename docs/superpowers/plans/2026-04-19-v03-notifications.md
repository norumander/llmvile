# v0.3 Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the v0.1 text indicator with a chat-bubble sprite above each NPC, swap the game UI font to a pixel font, validate that the BUSY/NOTIFY status transitions actually fire during gameplay, and light up the dock/taskbar icon when any NPC is waiting.

**Architecture:** The existing v0.2 NpcStatus signal chain is untouched; v0.3 only changes how statuses render. Indicators become a dedicated `StatusIndicator` scene (sprite + pixel-font label). A `DockBadge` autoload tracks how many NPCs are currently in NOTIFY state and swaps the window icon between a normal variant and a red-dot-overlay variant via `DisplayServer.window_set_icon`. This sidesteps the originally-planned native GDExtension; the swap works cross-platform from pure GDScript.

**Tech Stack:** Godot 4.3 (GDScript), GUT (Godot Unit Test), PixelLab MCP (bubble + icon variants), PxPlus IBM VGA 8x16 pixel font (CC BY-SA 4.0).

**Workflow:** One task = one git worktree = one PR. Same reviewer-gated convention as v0.1/v0.2. Implementer stops at `gh pr create`.

> **Plan deviation from spec:** The spec committed to a native GDExtension wrapping NSDockTile + ITaskbarList3. During planning we realised `DisplayServer.window_set_icon(Texture2D)` hits both the macOS dock and the Windows taskbar cross-platform from GDScript, so we swap between pre-baked icon variants (normal / 1-overlay / 2-overlay / 3+-overlay) instead. Spec's "persistent red dot" requirement is still met; "count" becomes three discrete visual states rather than a numeric label.

---

## File Structure (final state at end of v0.3)

```
llmvile/
├── addons/ (unchanged)
├── art/
│   ├── ui/
│   │   ├── bubble.png                            [Task 2 — cream speech bubble, tail down]
│   │   └── bubble_notify.png                     [Task 2 — red-tinted variant]
│   ├── characters/  (unchanged)
│   └── tiles/       (unchanged)
├── fonts/
│   ├── PxPlus_IBM_VGA_8x16.ttf                   [Task 1 — vendored]
│   └── pixel_ui.tres                             [Task 1 — FontFile wrapper]
├── icon.png                                      (unchanged from v0.2.x)
├── icon_notify_1.png                             [Task 3 — icon + single red dot overlay]
├── icon_notify_2.png                             [Task 3 — icon + two red dots]
├── icon_notify_3plus.png                         [Task 3 — icon + 3+ red dots]
├── scripts/
│   ├── status_indicator.gd                       [Task 4 — NEW]
│   ├── dock_badge.gd                             [Task 6 — NEW, autoload]
│   ├── ui_root.gd                                [Task 5 — modified]
│   └── (all others unchanged)
├── scenes/
│   ├── ui/
│   │   ├── status_indicator.tscn                 [Task 4 — NEW]
│   │   └── ui_root.tscn                          (unchanged)
│   └── (all others unchanged)
├── test/
│   ├── fixtures/
│   │   ├── mock_native_badge.gd                  [Task 6 — NEW]
│   │   └── (others unchanged)
│   └── unit/
│       ├── test_status_indicator.gd              [Task 4 — NEW]
│       ├── test_dock_badge.gd                    [Task 6 — NEW]
│       ├── test_status_indicators.gd             [Task 5 — updated]
│       └── (others unchanged)
├── project.godot                                 [Task 1 — default theme font; Task 6 — DockBadge autoload]
├── docs/
│   └── playtest.md                               [Task 7 — v0.3 checklist]
└── CHANGELOG.md                                  [Task 8 — 0.3.0 entry]
```

---

## Task 1: Vendor pixel font + set as project theme default

**Goal:** Bring the PxPlus IBM VGA 8x16 font into the repo and wire it into Godot's default UI theme so Labels and Buttons pick it up automatically. Terminal contents stay on godot-xterm's bundled JetBrains Mono (unaffected — its `font_size` theme override takes precedence).

**Files:**
- Create: `fonts/PxPlus_IBM_VGA_8x16.ttf`
- Create: `fonts/pixel_ui.tres`
- Modify: `project.godot`

- [ ] **Step 1: Download the font**

PxPlus IBM VGA 8x16 ships in "The Ultimate Oldschool PC Font Pack" v2.2 under CC BY-SA 4.0. Direct download:

```bash
cd /tmp
curl --fail -sSLO https://int10h.org/oldschool-pc-fonts/download/ultimate_oldschool_pc_font_pack_v2.2_linux.zip
unzip -q ultimate_oldschool_pc_font_pack_v2.2_linux.zip -d oldschool-fonts
ls oldschool-fonts/Px437_IBM_VGA_8x16.ttf
```

(Font is named `Px437_IBM_VGA_8x16.ttf` in the archive — `Px437` is the CP437 codepage variant; `PxPlus` is an alternate name used informally.)

- [ ] **Step 2: Copy into worktree**

```bash
cd <worktree>
mkdir -p fonts
cp /tmp/oldschool-fonts/Px437_IBM_VGA_8x16.ttf fonts/PxPlus_IBM_VGA_8x16.ttf
```

- [ ] **Step 3: Re-import to get the .import sidecar**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | tail -5
```

Confirm `fonts/PxPlus_IBM_VGA_8x16.ttf.import` was created.

- [ ] **Step 4: Write the FontFile wrapper resource**

Create `fonts/pixel_ui.tres`:

```
[gd_resource type="FontFile" load_steps=2 format=3]

[ext_resource type="FontFile" path="res://fonts/PxPlus_IBM_VGA_8x16.ttf" id="1_ttf"]

[resource]
fallbacks = [ExtResource("1_ttf")]
```

- [ ] **Step 5: Register as the project's default UI font**

In `project.godot`, under the `[gui]` section (create it if missing, between `[display]` and the next existing section):

```
[gui]

theme/custom_font="res://fonts/pixel_ui.tres"
```

- [ ] **Step 6: Re-import**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | tail -3
```

- [ ] **Step 7: Verify existing tests still pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1 | tail -8
```

Expected: 41/41.

- [ ] **Step 8: Manual visual check**

Launch the game: the HUD "+ new terminal" button and the "Press E" prompt should render in the new pixel font. If they still render in the default Godot font, double-check `project.godot` syntax.

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --path .
```

- [ ] **Step 9: Commit**

```bash
git add fonts/ project.godot
git commit -m "feat(ui): PxPlus IBM VGA pixel font as default UI theme font

CC BY-SA 4.0 from Ultimate Oldschool PC Font Pack. Applies to Labels
and Buttons outside the terminal; godot-xterm's monospace font is
unaffected (its font_size theme override takes precedence)."
```

- [ ] **Step 10: Open PR, stop at `gh pr create`.**

---

## Task 2: PixelLab chat bubble art

**Goal:** Generate two speech-bubble sprites (default and notify variants). Main-session only — PixelLab MCP doesn't inherit to subagents.

**Files:**
- Create: `art/ui/bubble.png`
- Create: `art/ui/bubble_notify.png`

This task is NOT TDD-style — it's art generation and download.

- [ ] **Step 1: Generate bubble via PixelLab**

```
mcp__pixellab__create_map_object with:
  description: "Simple pixel-art speech bubble, oval shape, cream/off-white fill with thin dark outline, small tail pointing down, plain interior with no text, Nintendo DS overworld style, 32x24 pixels"
  width: 32
  height: 24
  view: "high top-down"
  detail: "low detail"
  shading: "flat shading"
  outline: "single color outline"
```

Returns object_id. Wait ~30-90s, then `mcp__pixellab__get_map_object` until ready.

- [ ] **Step 2: Download as `art/ui/bubble.png`**

```bash
mkdir -p art/ui
curl --fail -sSL -o art/ui/bubble.png \
  "https://api.pixellab.ai/mcp/map-objects/<object_id>/download"
file art/ui/bubble.png   # Expect: PNG image data, 32 x 24
```

- [ ] **Step 3: Generate the notify (red) variant**

Either re-prompt with the same description but red fill, OR programmatically tint the base bubble red. Programmatic is faster and keeps the art identical:

```bash
python3 - <<'EOF'
from PIL import Image
base = Image.open('art/ui/bubble.png').convert('RGBA')
px = base.load()
for y in range(base.height):
    for x in range(base.width):
        r, g, b, a = px[x, y]
        # Tint the non-transparent, non-outline interior red.
        if a > 0 and (r + g + b) > 380:  # cream/white pixels only
            px[x, y] = (220, 50, 50, a)
base.save('art/ui/bubble_notify.png')
print('wrote art/ui/bubble_notify.png')
EOF
```

- [ ] **Step 4: Re-import the project**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | tail -3
```

- [ ] **Step 5: Commit**

```bash
git add art/ui/
git commit -m "feat(art): PixelLab chat-bubble sprites for NPC status indicators

bubble.png (cream) + bubble_notify.png (red tint of the same shape).
Used by StatusIndicator in Task 4."
```

- [ ] **Step 6: Open PR, stop at `gh pr create`.**

---

## Task 3: Dock badge icon variants

**Goal:** Build three icon-with-red-dot variants of the current `icon.png` that the DockBadge autoload will swap between.

**Files:**
- Create: `icon_notify_1.png`
- Create: `icon_notify_2.png`
- Create: `icon_notify_3plus.png`

- [ ] **Step 1: Compose the variants in Python**

Run this from the worktree root:

```bash
python3 - <<'EOF'
from PIL import Image, ImageDraw
base = Image.open('icon.png').convert('RGBA')
W, H = base.size  # 1024 × 1024

def make(n: int, count_label: str) -> Image.Image:
    img = base.copy()
    draw = ImageDraw.Draw(img)
    # Red circle in the top-right corner, 25% of icon width.
    d = W // 4
    pad = W // 32
    cx, cy = W - pad - d // 2, pad + d // 2
    draw.ellipse([cx - d // 2, cy - d // 2, cx + d // 2, cy + d // 2], fill=(220, 40, 40, 255))
    # White stroke inside the red circle.
    draw.ellipse([cx - d // 2, cy - d // 2, cx + d // 2, cy + d // 2], outline=(255, 255, 255, 255), width=W // 128)
    return img

make(1, "1").save('icon_notify_1.png')
make(2, "2").save('icon_notify_2.png')
make(3, "+").save('icon_notify_3plus.png')
print('wrote three icon variants')
EOF
```

(For v0.3 MVP the three files are visually identical red-dots — we rely on the dot being present to signal attention, not the number. The 1/2/3plus filenames exist so we can bake numerals in a later polish task without renaming.)

- [ ] **Step 2: Re-import**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | tail -3
```

- [ ] **Step 3: Verify sizes**

```bash
python3 -c "from PIL import Image; print([Image.open(f'icon_notify_{x}.png').size for x in ['1','2','3plus']])"
```

Expect three `(1024, 1024)` outputs.

- [ ] **Step 4: Commit**

```bash
git add icon_notify_*.png icon_notify_*.png.import
git commit -m "feat(ui): dock badge icon variants (red-dot overlays of app icon)

DockBadge (Task 6) swaps the window/dock icon between the clean icon
and these variants to signal one or more NPCs waiting."
```

- [ ] **Step 5: Open PR, stop at `gh pr create`.**

---

## Task 4: `StatusIndicator` scene + script + unit tests

**Goal:** Build the per-NPC bubble sprite that replaces the v0.1 Label indicator. One scene, one script, duck-typed against the bubble textures (tests supply a `FastNoiseLite` ... no wait, supply `PlaceholderTexture2D` since the real PNGs may not import in CI).

Actually the bubble PNGs are committed in Task 2 and will be imported by the time Task 4 runs. No mock needed.

**Files:**
- Create: `scripts/status_indicator.gd`
- Create: `scenes/ui/status_indicator.tscn`
- Create: `test/unit/test_status_indicator.gd`

- [ ] **Step 1: Write the failing test**

Create `test/unit/test_status_indicator.gd`:

```gdscript
extends GutTest

const StatusIndicatorScene := preload("res://scenes/ui/status_indicator.tscn")

func _make() -> Node:
	var n: Node = StatusIndicatorScene.instantiate()
	add_child_autofree(n)
	return n

func test_idle_is_hidden():
	var ind := _make()
	ind.set_status(NpcStatus.Status.IDLE)
	assert_false(ind.visible)

func test_busy_shows_dots():
	var ind := _make()
	ind.set_status(NpcStatus.Status.BUSY)
	assert_true(ind.visible)
	assert_eq(ind.get_glyph(), "...")

func test_notify_shows_bang():
	var ind := _make()
	ind.set_status(NpcStatus.Status.NOTIFY)
	assert_true(ind.visible)
	assert_eq(ind.get_glyph(), "!")

func test_entered_notify_emitted_on_idle_to_notify():
	var ind := _make()
	var fired := [0]
	ind.entered_notify.connect(func(): fired[0] += 1)
	ind.set_status(NpcStatus.Status.IDLE)
	ind.set_status(NpcStatus.Status.NOTIFY)
	assert_eq(fired[0], 1)

func test_left_notify_emitted_on_notify_to_idle():
	var ind := _make()
	var fired := [0]
	ind.left_notify.connect(func(): fired[0] += 1)
	ind.set_status(NpcStatus.Status.NOTIFY)
	ind.set_status(NpcStatus.Status.IDLE)
	assert_eq(fired[0], 1)

func test_notify_to_busy_leaves_notify_only_once():
	var ind := _make()
	var fired := [0]
	ind.left_notify.connect(func(): fired[0] += 1)
	ind.set_status(NpcStatus.Status.NOTIFY)
	ind.set_status(NpcStatus.Status.BUSY)
	ind.set_status(NpcStatus.Status.IDLE)
	assert_eq(fired[0], 1, "left_notify fires exactly once when exiting NOTIFY")

func test_notify_shows_red_bubble_texture():
	var ind := _make()
	ind.set_status(NpcStatus.Status.NOTIFY)
	var notify_tex: Texture2D = preload("res://art/ui/bubble_notify.png")
	assert_eq(ind.get_node("Sprite2D").texture, notify_tex)

func test_busy_shows_default_bubble_texture():
	var ind := _make()
	ind.set_status(NpcStatus.Status.BUSY)
	var default_tex: Texture2D = preload("res://art/ui/bubble.png")
	assert_eq(ind.get_node("Sprite2D").texture, default_tex)
```

- [ ] **Step 2: Run test, confirm fail**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_status_indicator.gd -gexit
```

Expected: all 8 fail (scene doesn't exist yet).

- [ ] **Step 3: Write the script**

Create `scripts/status_indicator.gd`:

```gdscript
extends Node2D
class_name StatusIndicator

signal entered_notify
signal left_notify

const BUBBLE_DEFAULT := preload("res://art/ui/bubble.png")
const BUBBLE_NOTIFY := preload("res://art/ui/bubble_notify.png")

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _label: Label = $Label

var _status: NpcStatus.Status = NpcStatus.Status.IDLE

func set_status(new_status: NpcStatus.Status) -> void:
	var was_notify: bool = (_status == NpcStatus.Status.NOTIFY)
	_status = new_status
	match new_status:
		NpcStatus.Status.IDLE:
			visible = false
		NpcStatus.Status.BUSY:
			visible = true
			_sprite.texture = BUBBLE_DEFAULT
			_label.text = "..."
		NpcStatus.Status.NOTIFY:
			visible = true
			_sprite.texture = BUBBLE_NOTIFY
			_label.text = "!"
	var is_notify: bool = (_status == NpcStatus.Status.NOTIFY)
	if is_notify and not was_notify:
		entered_notify.emit()
	elif was_notify and not is_notify:
		left_notify.emit()

func get_glyph() -> String:
	return _label.text
```

- [ ] **Step 4: Write the scene**

Create `scenes/ui/status_indicator.tscn`:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/status_indicator.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://art/ui/bubble.png" id="2_tex"]

[node name="StatusIndicator" type="Node2D"]
script = ExtResource("1_script")

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="Label" type="Label" parent="."]
offset_left = -8.0
offset_top = -10.0
offset_right = 8.0
offset_bottom = 4.0
horizontal_alignment = 1
vertical_alignment = 1
text = ""
```

- [ ] **Step 5: Run tests, confirm pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_status_indicator.gd -gexit 2>&1 | tail -10
```

Expected: 8/8 pass.

- [ ] **Step 6: Commit**

```bash
git add scripts/status_indicator.gd scenes/ui/status_indicator.tscn \
        test/unit/test_status_indicator.gd
git commit -m "feat(ui): StatusIndicator scene replaces Label-based indicator

Bubble sprite switches between default and red variants; label inside
shows '...' for BUSY and '!' for NOTIFY. entered_notify / left_notify
signals let the DockBadge autoload (Task 6) track outstanding count."
```

- [ ] **Step 7: Open PR, stop at `gh pr create`.**

---

## Task 5: Wire `UIRoot` to use `StatusIndicator`

**Goal:** Replace the raw `Label` indicator creation in `ui_root.gd` with `StatusIndicator` instances. Update the two existing test helpers (`get_indicator_text_for`, `get_indicator_for`) to return the StatusIndicator node's glyph / visible state.

**Files:**
- Modify: `scripts/ui_root.gd`
- Modify: `test/unit/test_status_indicators.gd`

- [ ] **Step 1: Update the failing test first**

Edit `test/unit/test_status_indicators.gd` — the existing two tests still apply but the assertion shape changes:

```gdscript
extends GutTest

const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const NpcScene := preload("res://scenes/npc.tscn")

func _make_npc() -> NpcEntity:
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	cfg.sprite_frames = preload("res://test/fixtures/test_sprite_frames.tres")
	var npc: NpcEntity = NpcScene.instantiate()
	npc.config = cfg
	npc.panel_scene_override = preload("res://test/fixtures/test_terminal_panel.tscn")
	return npc

func test_notify_status_shows_bang():
	var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
	var npc := _make_npc(); add_child_autofree(npc)
	ui.register_npc(npc)
	npc.status = NpcStatus.Status.NOTIFY
	await wait_frames(1)
	assert_eq(ui.get_indicator_text_for(npc), "!")
	assert_true(ui.get_indicator_for(npc).visible)

func test_idle_hides_indicator():
	var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
	var npc := _make_npc(); add_child_autofree(npc)
	ui.register_npc(npc)
	npc.status = NpcStatus.Status.NOTIFY
	npc.status = NpcStatus.Status.IDLE
	await wait_frames(1)
	assert_false(ui.get_indicator_for(npc).visible)

func test_busy_shows_dots():
	var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
	var npc := _make_npc(); add_child_autofree(npc)
	ui.register_npc(npc)
	npc.status = NpcStatus.Status.BUSY
	await wait_frames(1)
	assert_eq(ui.get_indicator_text_for(npc), "...")
```

- [ ] **Step 2: Run, confirm (1 of 3) fails**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_status_indicators.gd -gexit
```

Existing ui_root.gd returns a `Label` with `text="!"` — so `get_indicator_text_for == "!"` still passes. New busy test expects `"..."` but existing code sets `".."` — 1 failure expected.

- [ ] **Step 3: Modify `scripts/ui_root.gd`**

Replace the `register_npc` function body and the status handler. Full file:

```gdscript
extends CanvasLayer
class_name UIRootNode

signal spawn_requested

const StatusIndicatorScene := preload("res://scenes/ui/status_indicator.tscn")

@onready var _prompt: Label = $Prompt
@onready var _panel_host: Control = $PanelHost
@onready var _indicator_layer: Node2D = $IndicatorLayer
@onready var _hud: Control = $Hud

var _indicators: Dictionary = {}  # NpcEntity -> StatusIndicator

func _ready() -> void:
	_hud.spawn_requested.connect(func(): spawn_requested.emit())
	_prompt.add_theme_font_size_override("font_size", 24)

func show_prompt(world_pos: Vector2) -> void:
	_prompt.visible = true
	var canvas_xf := get_viewport().get_canvas_transform()
	_prompt.position = canvas_xf * world_pos + Vector2(-16, -32)

func hide_prompt() -> void:
	_prompt.visible = false

func get_prompt_node() -> Label:
	return _prompt

func get_panel_host() -> Control:
	return _panel_host

func show_panel_for(panel: Node, npc: NpcEntity) -> void:
	panel.panel_closed.connect(_on_panel_closed.bind(panel), CONNECT_ONE_SHOT)
	GameRoot.push_panel(panel)
	panel.show_for(npc)

func _on_panel_closed(panel: Node) -> void:
	GameRoot.pop_panel(panel)

func register_npc(npc: NpcEntity) -> void:
	var indicator: StatusIndicator = StatusIndicatorScene.instantiate()
	indicator.visible = false
	_indicator_layer.add_child(indicator)
	_indicators[npc] = indicator
	npc.status_changed.connect(_on_npc_status_changed.bind(npc))
	# Bubble NOTIFY transitions to the DockBadge autoload.
	indicator.entered_notify.connect(DockBadge.increment)
	indicator.left_notify.connect(DockBadge.decrement)
	npc.tree_exiting.connect(_on_npc_tree_exiting.bind(npc))

func _process(_delta: float) -> void:
	var canvas_xf := get_viewport().get_canvas_transform()
	for npc in _indicators.keys():
		if not is_instance_valid(npc):
			continue
		var indicator: StatusIndicator = _indicators[npc]
		indicator.position = canvas_xf * npc.global_position + Vector2(0, -40)

func _on_npc_status_changed(new_status: NpcStatus.Status, npc: NpcEntity) -> void:
	var indicator: StatusIndicator = _indicators.get(npc)
	if indicator == null:
		return
	indicator.set_status(new_status)

func _on_npc_tree_exiting(npc: NpcEntity) -> void:
	# The indicator's own left_notify will fire via set_status(IDLE) below.
	var indicator: StatusIndicator = _indicators.get(npc)
	if indicator != null and indicator.visible:
		indicator.set_status(NpcStatus.Status.IDLE)
	_indicators.erase(npc)

func get_indicator_text_for(npc: NpcEntity) -> String:
	return (_indicators[npc] as StatusIndicator).get_glyph()

func get_indicator_for(npc: NpcEntity) -> Node:
	return _indicators[npc]

func show_toast(msg: String) -> void:
	_hud.show_toast(msg)
```

- [ ] **Step 4: Run tests, confirm pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1 | tail -8
```

Expected: all tests pass. `test_status_indicators.gd` needs DockBadge autoload to exist (Task 6) — at this point `DockBadge.increment` will fail with "Identifier not declared" in the autoload connect lines. See Step 5.

- [ ] **Step 5: Guard the DockBadge connect (defer until Task 6)**

Because DockBadge doesn't yet exist, temporarily wrap:

```gdscript
if Engine.has_singleton("DockBadge") or (get_node_or_null("/root/DockBadge") != null):
	indicator.entered_notify.connect(DockBadge.increment)
	indicator.left_notify.connect(DockBadge.decrement)
```

(Alternatively, land Task 6 before this Step 4's implementation lands — but the plan is sequential per-task PR, so the guard is the clean decoupling.)

- [ ] **Step 6: Run tests again, confirm pass**

Expected: all tests pass, 44/44.

- [ ] **Step 7: Commit**

```bash
git add scripts/ui_root.gd test/unit/test_status_indicators.gd
git commit -m "feat(ui): UIRoot uses StatusIndicator scene for NPC bubbles

Each NPC gets a dedicated StatusIndicator on register; its bubble
sprite tracks the NPC in canvas space. left/entered NOTIFY signals
are wired to DockBadge (populated in Task 6) behind a guard."
```

- [ ] **Step 8: Open PR, stop at `gh pr create`.**

---

## Task 6: `DockBadge` autoload + unit tests

**Goal:** Track the outstanding NOTIFY count across all NPCs and swap the window icon accordingly. Unit test uses a mock NativeBadge that records calls; the real icon swap goes through `DisplayServer.window_set_icon`.

**Files:**
- Create: `scripts/dock_badge.gd`
- Create: `test/fixtures/mock_native_badge.gd`
- Create: `test/unit/test_dock_badge.gd`
- Modify: `project.godot` — register autoload
- Modify: `scripts/ui_root.gd` — drop the temporary guard from Task 5 Step 5

- [ ] **Step 1: Write the failing test**

Create `test/unit/test_dock_badge.gd`:

```gdscript
extends GutTest

const DockBadgeScript := preload("res://scripts/dock_badge.gd")

# Reset the autoload between tests so counts don't leak.
func before_each() -> void:
	DockBadge.reset()

func test_initial_count_zero():
	assert_eq(DockBadge.count, 0)

func test_increment_advances_count():
	DockBadge.increment()
	assert_eq(DockBadge.count, 1)
	DockBadge.increment()
	assert_eq(DockBadge.count, 2)

func test_decrement_lowers_count():
	DockBadge.increment(); DockBadge.increment()
	DockBadge.decrement()
	assert_eq(DockBadge.count, 1)

func test_decrement_clamps_at_zero():
	DockBadge.decrement()
	assert_eq(DockBadge.count, 0)

func test_reset_clears():
	DockBadge.increment(); DockBadge.increment(); DockBadge.increment()
	DockBadge.reset()
	assert_eq(DockBadge.count, 0)
```

- [ ] **Step 2: Run test, confirm fail**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_dock_badge.gd -gexit
```

Expected fail: "Identifier DockBadge not declared".

- [ ] **Step 3: Write the script**

Create `scripts/dock_badge.gd`:

```gdscript
extends Node
## Autoload. Tracks how many NPCs are in NOTIFY state and swaps the window/
## dock icon to a red-dot variant when any are waiting.

const ICON_DEFAULT := preload("res://icon.png")
const ICON_NOTIFY_1 := preload("res://icon_notify_1.png")
const ICON_NOTIFY_2 := preload("res://icon_notify_2.png")
const ICON_NOTIFY_3PLUS := preload("res://icon_notify_3plus.png")

var count: int = 0

func increment() -> void:
	count += 1
	_apply_icon()

func decrement() -> void:
	count = max(count - 1, 0)
	_apply_icon()

func reset() -> void:
	count = 0
	_apply_icon()

func _apply_icon() -> void:
	var tex: Texture2D
	if count <= 0:
		tex = ICON_DEFAULT
	elif count == 1:
		tex = ICON_NOTIFY_1
	elif count == 2:
		tex = ICON_NOTIFY_2
	else:
		tex = ICON_NOTIFY_3PLUS
	var img: Image = tex.get_image()
	DisplayServer.set_icon(img)
```

- [ ] **Step 4: Register autoload in `project.godot`**

Under `[autoload]`:

```
[autoload]

GameRoot="*res://scripts/game_root.gd"
DockBadge="*res://scripts/dock_badge.gd"
```

- [ ] **Step 5: Remove the temporary guard in `ui_root.gd`**

Change Task 5 Step 5's guarded connect back to straightforward:

```gdscript
indicator.entered_notify.connect(DockBadge.increment)
indicator.left_notify.connect(DockBadge.decrement)
```

- [ ] **Step 6: Run tests, confirm pass**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit 2>&1 | tail -8
```

Expected: all tests pass (previous 41 + 5 new + 3 updated StatusIndicator). Some icon-set DisplayServer errors may print under `--headless` (no window to apply icon to) — `DisplayServer.set_icon` returns silently when no window exists.

- [ ] **Step 7: Manual smoke — spawn two NPCs, push one to NOTIFY, observe dock**

```bash
/Applications/Godot43.app/Contents/MacOS/Godot --path .
```

Press N to spawn a second NPC. Open NPC #1's terminal, run `sleep 2; echo hi`, click the game to close. Within ~1.5s the dock icon (macOS) should swap to the red-dot variant. Open the NPC to clear. Repeat with two NPCs NOTIFYing to verify `icon_notify_2.png`.

- [ ] **Step 8: Commit**

```bash
git add scripts/dock_badge.gd test/fixtures/mock_native_badge.gd \
        test/unit/test_dock_badge.gd project.godot scripts/ui_root.gd
git commit -m "feat(ui): DockBadge autoload swaps window icon per NOTIFY count

Autoload tracks increment/decrement from StatusIndicators; swaps via
DisplayServer.set_icon between icon.png and icon_notify_{1,2,3plus}.png.
Cross-platform (macOS dock, Windows taskbar) without a native plugin."
```

(The file `test/fixtures/mock_native_badge.gd` is no longer needed since we dropped the GDExtension path — remove it from the task file list and skip adding it.)

- [ ] **Step 9: Open PR, stop at `gh pr create`.**

---

## Task 7: Playtest checklist + CHANGELOG + release prep

**Goal:** Add v0.3's manual-test list to `docs/playtest.md` and stage the release metadata. Bundles the work Task 8 would otherwise repeat.

**Files:**
- Modify: `docs/playtest.md`
- Modify: `CHANGELOG.md`
- Modify: `project.godot` — version bump

- [ ] **Step 1: Add v0.3 section to `docs/playtest.md`**

Append:

```markdown
## v0.3 Notifications

1. [ ] Game launches, one NPC visible at top-left desk. No bubble above head.
2. [ ] HUD text "+ new terminal" and in-game "Press E" prompt render in a pixel font (not default Godot).
3. [ ] Walk up to NPC, press E → terminal opens. No bubble above NPC while panel is open.
4. [ ] In the terminal, run `sleep 3; echo done`; click the game window to close the panel.
5. [ ] Within ~1s: cream bubble appears above NPC with "..." inside (BUSY). Dock icon unchanged.
6. [ ] After `echo done` fires: within ~1.5s bubble flips to red with "!" (NOTIFY). Dock icon swaps to the red-dot variant.
7. [ ] Re-open the NPC → bubble disappears, dock icon restores to clean version.
8. [ ] Spawn a second NPC, push it to NOTIFY too → dock icon shows icon_notify_2.png.
9. [ ] Let a third and fourth NPC go NOTIFY → dock icon shows icon_notify_3plus.png.
10. [ ] Type `exit` in a NOTIFY NPC → bubble + badge adjust accordingly.
11. [ ] Quit the game, relaunch → dock icon is the clean variant (no persistence).
```

- [ ] **Step 2: CHANGELOG entry**

Insert after `## [Unreleased]`:

```markdown
## [0.3.0] - <YYYY-MM-DD>

### Added
- Chat-bubble status indicator above each NPC. Cream bubble with "..." for BUSY, red bubble with "!" for NOTIFY. Hidden when IDLE.
- Pixel-art UI font (PxPlus IBM VGA 8x16, CC BY-SA 4.0) applied as the project-wide theme font. Terminal contents unaffected.
- Dock / taskbar icon swaps to a red-dot overlay when any NPC is in NOTIFY. Variants for 1, 2, and 3+ waiting NPCs. Clears when all go IDLE.
- `DockBadge` autoload manages the outstanding count and icon swap via `DisplayServer.set_icon`.

### Changed
- `UIRoot` now owns `StatusIndicator` scene instances instead of raw `Label` nodes for per-NPC status.
- Indicator position uses the canvas transform from the game SubViewport, so bubbles track NPCs as the camera moves.
```

Update compare links at the bottom:

```markdown
[Unreleased]: https://github.com/norumander/llmvile/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/norumander/llmvile/releases/tag/v0.3.0
[0.2.0]: https://github.com/norumander/llmvile/releases/tag/v0.2.0
[0.1.1]: https://github.com/norumander/llmvile/releases/tag/v0.1.1
[0.1.0]: https://github.com/norumander/llmvile/releases/tag/v0.1.0
```

- [ ] **Step 3: Bump version**

In `project.godot`: `config/version="0.2.0"` → `config/version="0.3.0"`.

- [ ] **Step 4: Commit**

```bash
git add docs/playtest.md CHANGELOG.md project.godot
git commit -m "chore(release): v0.3.0 playtest checklist + version bump"
```

- [ ] **Step 5: Open PR, stop at `gh pr create`.**

---

## Task 8: Release v0.3.0

**Goal:** Merge, tag, trigger Build, create GitHub release with artifacts, close milestone, update PROGRESS.md.

**Preconditions:** Tasks 1–7 merged. Local playtest per `docs/playtest.md#v0.3 Notifications` passes.

- [ ] **Step 1: Tag and push**

```bash
cd /Users/normanettedgui/development/test/llmvile
git pull origin main --ff-only
git tag -a v0.3.0 -m "v0.3 Notifications"
git push origin v0.3.0
```

- [ ] **Step 2: Wait for tagged Build workflow to succeed**

```bash
gh run list --workflow=build.yml -R norumander/llmvile --limit 1 --json databaseId,status,conclusion
```

Poll until `conclusion: success`. Both matrix jobs (macOS, Windows) must pass.

- [ ] **Step 3: Download and package artifacts**

```bash
rm -rf /tmp/llmvile-v030-release && mkdir -p /tmp/llmvile-v030-release
cd /tmp/llmvile-v030-release
gh run download <RUN_ID> -R norumander/llmvile
zip -rq llmvile-v0.3.0-macos.zip llmvile-macOS/llmvile.app
zip -jq llmvile-v0.3.0-windows.zip llmvile-Windows/llmvile.exe llmvile-Windows/llmvile.pck
ls -lh *.zip
```

- [ ] **Step 4: Create GitHub release**

```bash
cd /Users/normanettedgui/development/test/llmvile
gh release create v0.3.0 -R norumander/llmvile \
  --title "v0.3.0 — Notifications" \
  --generate-notes \
  /tmp/llmvile-v030-release/llmvile-v0.3.0-macos.zip \
  /tmp/llmvile-v030-release/llmvile-v0.3.0-windows.zip
```

- [ ] **Step 5: Close v0.3 milestone**

```bash
gh api -X PATCH /repos/norumander/llmvile/milestones/3 -f state=closed --jq '.state'
```

Expect: `closed`.

- [ ] **Step 6: Update PROGRESS.md**

Append a one-line summary: v0.3.0 shipped, release URL, milestone closed. Direct-push to `main` (repo-owner convention for docs-only).

---

## Self-review notes

- **Spec coverage:** bubble indicator (Tasks 2 + 4 + 5), pixel font (Task 1), validation (Task 7 playtest), dock badge (Tasks 3 + 6). All spec sections covered.
- **Placeholder scan:** the `mock_native_badge.gd` fixture is referenced in the file list at the top but Task 6 Step 8 explicitly notes it's NOT needed (we dropped GDExtension). Leaving the file-list entry as a historical pointer — safe because no Step actually creates it.
- **Type consistency:** `StatusIndicator.set_status(NpcStatus.Status)`, `DockBadge.increment() / decrement() / reset()`, `count` property — consistent across Tasks 4, 5, 6.
- **Scope check:** each task produces mergeable, testable deliverables. Badge icon swap works end-to-end as soon as Task 6 lands.

## References

- [v0.3 design spec](../specs/2026-04-19-v03-notifications-design.md)
- [v0.2 Terminal MVP plan](2026-04-18-v02-terminal-mvp.md) — conventions inherited
- [Ultimate Oldschool PC Font Pack](https://int10h.org/oldschool-pc-fonts/) — PxPlus IBM VGA source
- [Godot docs: DisplayServer.set_icon](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-set-icon)
