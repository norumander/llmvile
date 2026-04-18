extends GutTest

const PlayerScene := preload("res://scenes/player.tscn")

func test_velocity_zero_when_no_input():
	var p: CharacterBody2D = PlayerScene.instantiate()
	add_child_autofree(p)
	p._compute_velocity(Vector2.ZERO)
	assert_eq(p.velocity, Vector2.ZERO)

func test_velocity_cardinal_normalized_to_speed():
	var p: CharacterBody2D = PlayerScene.instantiate()
	add_child_autofree(p)
	p._compute_velocity(Vector2.RIGHT)
	assert_eq(p.velocity.x, p.speed)
	assert_eq(p.velocity.y, 0.0)

func test_paused_world_zeroes_velocity():
	var p: CharacterBody2D = PlayerScene.instantiate()
	add_child_autofree(p)
	GameRoot.world_input_paused = true
	p._compute_velocity(Vector2.RIGHT)
	assert_eq(p.velocity, Vector2.ZERO)
	GameRoot.world_input_paused = false
