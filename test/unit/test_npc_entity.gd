extends GutTest

const NpcScene := preload("res://scenes/npc.tscn")

func _make_cfg() -> NpcConfig:
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	cfg.sprite = preload("res://art/_missing.png")
	cfg.desk_position = Vector2i.ZERO
	cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
	cfg.kind = &"stub"
	return cfg

func test_applies_config_on_ready():
	var npc: Node = NpcScene.instantiate()
	npc.config = _make_cfg()
	add_child_autofree(npc)
	await wait_frames(1)
	assert_eq(npc.get_node("Sprite2D").texture, npc.config.sprite)

func test_interact_instantiates_panel_and_emits_signal():
	var npc: Node = NpcScene.instantiate()
	npc.config = _make_cfg()
	add_child_autofree(npc)
	await wait_frames(1)
	var started := [false]
	npc.interaction_started.connect(func(_panel): started[0] = true)
	var panel := npc.interact()
	assert_not_null(panel)
	assert_true(started[0])

func test_status_change_emits_exactly_once():
	var npc: Node = NpcScene.instantiate()
	npc.config = _make_cfg()
	add_child_autofree(npc)
	var count := [0]
	npc.status_changed.connect(func(_s): count[0] += 1)
	npc.status = NpcStatus.Status.NOTIFY
	npc.status = NpcStatus.Status.NOTIFY  # same value — no re-emit
	npc.status = NpcStatus.Status.IDLE
	assert_eq(count[0], 2)
