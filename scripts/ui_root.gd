extends CanvasLayer
class_name UIRootNode
## Hosts the press-E prompt and whichever panel is currently open.

signal spawn_requested

@onready var _prompt: Label = $Prompt
@onready var _panel_host: Control = $PanelHost
@onready var _indicator_layer: Node2D = $IndicatorLayer
@onready var _hud: Control = $Hud

var _indicators: Dictionary = {}  # NpcEntity -> Label
# Panel -> original parent (so we can reparent back on close)
var _panel_origins: Dictionary = {}

func _ready() -> void:
	_hud.spawn_requested.connect(func(): spawn_requested.emit())

func show_prompt(world_pos: Vector2) -> void:
	_prompt.visible = true
	_prompt.global_position = world_pos + Vector2(-16, -32)

func hide_prompt() -> void:
	_prompt.visible = false

func get_prompt_node() -> Label:
	return _prompt

func show_panel_for(panel: InteractionPanel, npc: NpcEntity) -> void:
	_panel_origins[panel] = panel.get_parent()
	panel.reparent(_panel_host)
	panel.panel_closed.connect(_on_panel_closed.bind(panel), CONNECT_ONE_SHOT)
	GameRoot.push_panel(panel)
	panel.show_for(npc)

func _on_panel_closed(panel: InteractionPanel) -> void:
	GameRoot.pop_panel(panel)
	var origin: Node = _panel_origins.get(panel)
	_panel_origins.erase(panel)
	if origin != null and is_instance_valid(origin) and is_instance_valid(panel):
		panel.reparent(origin)

func register_npc(npc: NpcEntity) -> void:
	var label := Label.new()
	label.text = ""
	label.visible = false
	_indicator_layer.add_child(label)
	_indicators[npc] = label
	npc.status_changed.connect(_on_npc_status_changed.bind(npc))
	label.set_meta("npc", npc)

func _process(_delta: float) -> void:
	for npc in _indicators.keys():
		if not is_instance_valid(npc):
			continue
		var label: Label = _indicators[npc]
		label.global_position = npc.global_position + Vector2(-4, -40)

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
