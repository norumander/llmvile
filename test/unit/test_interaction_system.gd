extends GutTest

const InteractionSystemScript := preload("res://scripts/interaction_system.gd")
const NpcScene := preload("res://scenes/npc.tscn")

func _make_npc(at: Vector2) -> Node:
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	cfg.sprite = preload("res://art/_missing.png")
	cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
	var npc = NpcScene.instantiate()
	npc.config = cfg
	npc.position = at
	return npc

func test_closest_npc_wins_when_multiple_in_zone():
	var sys: Node = InteractionSystemScript.new()
	add_child_autofree(sys)
	var a = _make_npc(Vector2(10, 0))
	var b = _make_npc(Vector2(100, 0))
	add_child_autofree(a); add_child_autofree(b)
	sys.notify_entered(a)
	sys.notify_entered(b)
	sys.recompute_target(Vector2.ZERO)
	assert_eq(sys.current_target, a)

func test_target_cleared_when_all_exit():
	var sys: Node = InteractionSystemScript.new()
	add_child_autofree(sys)
	var a = _make_npc(Vector2(10, 0))
	add_child_autofree(a)
	sys.notify_entered(a)
	sys.notify_exited(a)
	sys.recompute_target(Vector2.ZERO)
	assert_null(sys.current_target)
