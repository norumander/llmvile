extends Node2D
class_name NpcEntity

signal interaction_started(panel: Node)
signal interaction_ended
signal status_changed(new_status: NpcStatus.Status)

const DEFAULT_PANEL_SCENE := preload("res://scenes/panels/terminal.tscn")

@export var config: NpcConfig
## Where the panel lives in the tree. Typically UIRoot.PanelHost.
## If unset (tests), the panel becomes a child of this NpcEntity.
var panel_host: Node
## For tests only — substitute a panel scene with a mock PTY.
var panel_scene_override: PackedScene

var status: NpcStatus.Status = NpcStatus.Status.IDLE :
	set(value):
		if status == value:
			return
		status = value
		status_changed.emit(value)

var _panel: Node

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
	var parent_for_panel: Node = panel_host if panel_host != null else self
	parent_for_panel.add_child(_panel)

	if _panel.has_signal("status_changed"):
		_panel.status_changed.connect(func(s): status = s)
	if _panel.has_signal("session_ended"):
		_panel.session_ended.connect(_on_session_ended)
	_panel.panel_closed.connect(_on_panel_closed)

	tree_exiting.connect(func():
		if is_instance_valid(_panel):
			_panel.queue_free())

func interact() -> Node:
	interaction_started.emit(_panel)
	return _panel

func _on_session_ended() -> void:
	if _panel != null and _panel.visible:
		_panel.close()
	queue_free()

func _on_panel_closed() -> void:
	interaction_ended.emit()
