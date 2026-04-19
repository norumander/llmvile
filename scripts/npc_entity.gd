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

	if _panel.has_signal("status_changed"):
		_panel.status_changed.connect(func(s): status = s)
	if _panel.has_signal("session_ended"):
		_panel.session_ended.connect(_on_session_ended)
	_panel.panel_closed.connect(_on_panel_closed)

func interact() -> InteractionPanel:
	interaction_started.emit(_panel)
	return _panel

func _on_session_ended() -> void:
	if _panel != null and _panel.visible:
		_panel.close()
	queue_free()

func _on_panel_closed() -> void:
	interaction_ended.emit()
