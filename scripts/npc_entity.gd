extends Node2D
class_name NpcEntity

signal interaction_started(panel: InteractionPanel)
signal interaction_ended
signal status_changed(new_status: NpcStatus.Status)

@export var config: NpcConfig

var status: NpcStatus.Status = NpcStatus.Status.IDLE :
	set(value):
		if status == value:
			return
		status = value
		status_changed.emit(value)

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

func interact() -> InteractionPanel:
	if config == null or config.panel_scene == null:
		push_error("Cannot interact: missing panel_scene")
		return null
	var panel := config.panel_scene.instantiate() as InteractionPanel
	if panel == null:
		push_error("panel_scene did not produce an InteractionPanel")
		return null
	panel.panel_closed.connect(_on_panel_closed)
	interaction_started.emit(panel)
	return panel

func _on_panel_closed() -> void:
	interaction_ended.emit()
