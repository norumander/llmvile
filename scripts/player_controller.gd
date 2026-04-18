extends CharacterBody2D
class_name PlayerController

@export var speed: float = 140.0

func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# 4-dir: collapse diagonals to cardinal
	if abs(input_dir.x) >= abs(input_dir.y):
		input_dir = Vector2(sign(input_dir.x), 0)
	else:
		input_dir = Vector2(0, sign(input_dir.y))
	_compute_velocity(input_dir)
	move_and_slide()

func _compute_velocity(dir: Vector2) -> void:
	if GameRoot.world_input_paused:
		velocity = Vector2.ZERO
		return
	velocity = dir * speed
