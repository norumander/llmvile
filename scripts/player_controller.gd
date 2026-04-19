extends CharacterBody2D
class_name PlayerController

signal panel_requested(panel: InteractionPanel, npc: NpcEntity)

@export var speed: float = 140.0

var _facing: StringName = &"south"

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 4-dir: collapse diagonals to cardinal
	if abs(input_dir.x) >= abs(input_dir.y):
		input_dir = Vector2(sign(input_dir.x), 0)
	else:
		input_dir = Vector2(0, sign(input_dir.y))
	if GameRoot.world_input_paused:
		input_dir = Vector2.ZERO
	_compute_velocity(input_dir)
	move_and_slide()
	_update_animation(input_dir)
	$InteractionSystem.recompute_target(global_position)
	if not GameRoot.world_input_paused and Input.is_action_just_pressed("interact"):
		var panel: InteractionPanel = $InteractionSystem.try_interact()
		if panel != null:
			panel_requested.emit(panel, $InteractionSystem.current_target)

func _compute_velocity(dir: Vector2) -> void:
	if GameRoot.world_input_paused:
		velocity = Vector2.ZERO
		return
	velocity = dir * speed

func _update_animation(dir: Vector2) -> void:
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	if dir.x > 0:
		_facing = &"east"
	elif dir.x < 0:
		_facing = &"west"
	elif dir.y < 0:
		_facing = &"north"
	elif dir.y > 0:
		_facing = &"south"
	var prefix := &"walk_" if dir != Vector2.ZERO else &"idle_"
	var target := StringName(prefix + _facing)
	if sprite.animation != target:
		sprite.play(target)

func _on_interaction_zone_area_entered(area: Area2D) -> void:
	if area.owner is NpcEntity:
		$InteractionSystem.notify_entered(area.owner)

func _on_interaction_zone_area_exited(area: Area2D) -> void:
	if area.owner is NpcEntity:
		$InteractionSystem.notify_exited(area.owner)
