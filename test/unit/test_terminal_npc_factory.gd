extends GutTest

const FactoryScript := preload("res://scripts/terminal_npc_factory.gd")
const TestFrames := preload("res://test/fixtures/test_sprite_frames.tres")
const TestPanelScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func _make_factory() -> Node:
	var parent := Node2D.new()
	add_child_autofree(parent)
	var f: Node = FactoryScript.new()
	var pool: Array[SpriteFrames] = [TestFrames]
	f.sprite_frames_pool = pool
	f.panel_scene_override = TestPanelScene
	parent.add_child(f)
	return f

func test_first_spawn_uses_first_desk():
	var f := _make_factory()
	var npc: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	assert_not_null(npc)
	assert_eq(npc.position, Vector2(144, 144))

func test_four_spawns_fill_all_desks():
	var f := _make_factory()
	var npcs: Array[Node] = []
	for i in range(4):
		var n: Node = f.spawn_at_free_desk()
		assert_not_null(n, "spawn %d should succeed" % i)
		npcs.append(n)
	await wait_frames(1)
	assert_eq(npcs[0].position, Vector2(144, 144))
	assert_eq(npcs[1].position, Vector2(368, 144))
	assert_eq(npcs[2].position, Vector2(144, 240))
	assert_eq(npcs[3].position, Vector2(368, 240))

func test_fifth_spawn_returns_null():
	var f := _make_factory()
	for i in range(4):
		f.spawn_at_free_desk()
	await wait_frames(1)
	var fifth: Node = f.spawn_at_free_desk()
	assert_null(fifth)

func test_freeing_npc_frees_its_desk():
	var f := _make_factory()
	var first: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	first.queue_free()
	await wait_frames(2)
	var second: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	assert_not_null(second)
	assert_eq(second.position, Vector2(144, 144))

func test_display_name_counter_increments():
	var f := _make_factory()
	var a: Node = f.spawn_at_free_desk()
	var b: Node = f.spawn_at_free_desk()
	await wait_frames(1)
	assert_ne(a.config.display_name, b.config.display_name)
