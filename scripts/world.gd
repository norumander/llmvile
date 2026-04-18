extends Node2D

@onready var _player: PlayerController = $Player
@onready var _ui: UIRootNode = $UIRoot

func _ready() -> void:
	_player.panel_requested.connect(_on_panel_requested)
	_player.get_node("InteractionSystem").target_changed.connect(_on_target_changed)
	for npc in get_tree().get_nodes_in_group("npc"):
		_ui.register_npc(npc)

func _on_panel_requested(panel: InteractionPanel, npc: NpcEntity) -> void:
	_ui.show_panel_for(panel, npc)

func _on_target_changed(npc: NpcEntity) -> void:
	if npc == null:
		_ui.hide_prompt()
	else:
		_ui.show_prompt(npc.global_position)
