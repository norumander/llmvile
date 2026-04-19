extends CanvasLayer
class_name UIRootNode
## Hosts the press-E prompt and whichever panel is currently open.

signal spawn_requested

@onready var _prompt: Label = $Prompt
@onready var _panel_host: Control = $PanelHost
@onready var _indicator_layer: Node2D = $IndicatorLayer
@onready var _hud: Control = $Hud

var _indicators: Dictionary = {}  # NpcEntity -> Label

func _ready() -> void:
	# Scale the whole UI layer 2x to match the game's pixel-art upscale.
	scale = Vector2(2, 2)
	_hud.spawn_requested.connect(func(): spawn_requested.emit())

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

func show_panel_for(panel: InteractionPanel, npc: NpcEntity) -> void:
	panel.panel_closed.connect(_on_panel_closed.bind(panel), CONNECT_ONE_SHOT)
	GameRoot.push_panel(panel)
	panel.show_for(npc)

func _on_panel_closed(panel: InteractionPanel) -> void:
	GameRoot.pop_panel(panel)

func register_npc(npc: NpcEntity) -> void:
	var label := Label.new()
	label.text = ""
	label.visible = false
	_indicator_layer.add_child(label)
	_indicators[npc] = label
	npc.status_changed.connect(_on_npc_status_changed.bind(npc))
	label.set_meta("npc", npc)

func _process(_delta: float) -> void:
	var canvas_xf := get_viewport().get_canvas_transform()
	for npc in _indicators.keys():
		if not is_instance_valid(npc):
			continue
		var label: Label = _indicators[npc]
		# Convert npc world-space position to screen/canvas-space so the
		# CanvasLayer-hosted label tracks the camera.
		label.position = canvas_xf * npc.global_position + Vector2(-4, -40)

func _on_npc_status_changed(new_status: NpcStatus.Status, npc: NpcEntity) -> void:
	var label: Label = _indicators.get(npc)
	if label == null:
		return
	match new_status:
		NpcStatus.Status.IDLE:
			label.text = ""; label.visible = false
		NpcStatus.Status.BUSY:
			label.text = ".."; label.visible = true
		NpcStatus.Status.NOTIFY:
			label.text = "!"; label.visible = true

func get_indicator_text_for(npc: NpcEntity) -> String:
	return (_indicators[npc] as Label).text

func get_indicator_for(npc: NpcEntity) -> Label:
	return _indicators[npc]

func show_toast(msg: String) -> void:
	_hud.show_toast(msg)
