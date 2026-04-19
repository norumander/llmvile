extends Node2D

signal panel_requested(panel: InteractionPanel, npc: NpcEntity)
signal target_changed(npc: NpcEntity)
signal spawn_succeeded(npc: NpcEntity)
signal spawn_failed(reason: String)

@onready var _player: PlayerController = $Player
@onready var _factory: TerminalNpcFactory = $Factory

func _ready() -> void:
	_player.panel_requested.connect(func(p, n): panel_requested.emit(p, n))
	_player.get_node("InteractionSystem").target_changed.connect(
		func(npc): target_changed.emit(npc)
	)
	_factory.spawn_succeeded.connect(func(n): spawn_succeeded.emit(n))
	_factory.spawn_failed.connect(func(r): spawn_failed.emit(r))

func spawn_at_free_desk() -> void:
	_factory.spawn_at_free_desk()

func set_panel_host(host: Node) -> void:
	_factory.panel_host = host
