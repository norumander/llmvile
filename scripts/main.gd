extends Control
## Root scene: hosts the game SubViewport (pixel-art, 640x360 logical)
## and the UI at native window resolution (terminal panels etc).

@onready var _world: Node = $GameViewportContainer/GameViewport/World
@onready var _ui: UIRootNode = $UIRoot

func _ready() -> void:
	_world.panel_requested.connect(_on_panel_requested)
	_world.target_changed.connect(_on_target_changed)
	_world.spawn_succeeded.connect(_on_spawn_succeeded)
	_world.spawn_failed.connect(_on_spawn_failed)
	_ui.spawn_requested.connect(_on_spawn_requested)
	_world.set_panel_host(_ui.get_panel_host())
	_world.spawn_at_free_desk()

func _on_spawn_requested() -> void:
	_world.spawn_at_free_desk()

func _on_spawn_succeeded(npc: NpcEntity) -> void:
	npc.add_to_group("npc")
	_ui.register_npc(npc)

func _on_spawn_failed(reason: String) -> void:
	_ui.show_toast(reason.capitalize())

func _on_panel_requested(panel: Node, npc: NpcEntity) -> void:
	_ui.show_panel_for(panel, npc)

func _on_target_changed(npc: NpcEntity) -> void:
	if npc == null:
		_ui.hide_prompt()
	else:
		_ui.show_prompt(npc.global_position)
