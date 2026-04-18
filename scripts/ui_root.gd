extends CanvasLayer
class_name UIRootNode
## Hosts the press-E prompt and whichever panel is currently open.

@onready var _prompt: Label = $Prompt
@onready var _panel_host: Control = $PanelHost

func show_prompt(world_pos: Vector2) -> void:
	_prompt.visible = true
	_prompt.global_position = world_pos + Vector2(-16, -32)

func hide_prompt() -> void:
	_prompt.visible = false

func get_prompt_node() -> Label:
	return _prompt

func show_panel_for(panel: InteractionPanel, npc: NpcEntity) -> void:
	_panel_host.add_child(panel)
	panel.panel_closed.connect(_on_panel_closed.bind(panel), CONNECT_ONE_SHOT)
	GameRoot.push_panel(panel)
	panel.show_for(npc)

func _on_panel_closed(panel: InteractionPanel) -> void:
	GameRoot.pop_panel(panel)
