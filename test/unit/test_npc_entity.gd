extends GutTest

const NpcScene := preload("res://scenes/npc.tscn")
const TestFrames := preload("res://test/fixtures/test_sprite_frames.tres")
const TerminalPanelTestScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func _make_cfg() -> NpcConfig:
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	cfg.sprite_frames = TestFrames
	return cfg

func _instantiate_npc() -> Node:
	var npc: Node = NpcScene.instantiate()
	npc.config = _make_cfg()
	npc.panel_scene_override = TerminalPanelTestScene
	return npc

func test_applies_config_on_ready():
	var npc := _instantiate_npc()
	add_child_autofree(npc)
	await wait_frames(1)
	var sprite: AnimatedSprite2D = npc.get_node("AnimatedSprite2D")
	assert_eq(sprite.sprite_frames, npc.config.sprite_frames)
	assert_eq(sprite.animation, &"idle_south")

func test_npc_instantiates_terminal_panel_on_ready():
	var npc := _instantiate_npc()
	add_child_autofree(npc)
	await wait_frames(1)
	var panels := npc.find_children("TerminalPanel", "", true, false)
	assert_eq(panels.size(), 1)

func test_interact_returns_same_panel_each_call():
	var npc := _instantiate_npc()
	add_child_autofree(npc)
	await wait_frames(1)
	var started := [false]
	npc.interaction_started.connect(func(_p): started[0] = true)
	var first: InteractionPanel = npc.interact()
	var second: InteractionPanel = npc.interact()
	assert_same(first, second)
	assert_true(started[0])

func test_status_bubbles_up_from_panel():
	var npc := _instantiate_npc()
	add_child_autofree(npc)
	await wait_frames(1)
	var observed: Array = []
	npc.status_changed.connect(func(s): observed.append(s))
	var panel: Node = npc.interact()
	panel.get_node("PTY").emit_output("hi")
	panel._recompute_status()
	assert_true(observed.size() > 0)

func test_status_change_emits_exactly_once():
	var npc := _instantiate_npc()
	add_child_autofree(npc)
	await wait_frames(1)
	var count := [0]
	npc.status_changed.connect(func(_s): count[0] += 1)
	npc.status = NpcStatus.Status.NOTIFY
	npc.status = NpcStatus.Status.NOTIFY
	npc.status = NpcStatus.Status.IDLE
	assert_eq(count[0], 2)
