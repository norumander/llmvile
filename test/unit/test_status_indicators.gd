extends GutTest

const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const NpcScene := preload("res://scenes/npc.tscn")

func _make_npc() -> NpcEntity:
	var cfg := NpcConfig.new()
	cfg.display_name = "T"
	cfg.sprite = preload("res://art/_missing.png")
	cfg.panel_scene = preload("res://scenes/panels/stub_dialogue.tscn")
	var npc: NpcEntity = NpcScene.instantiate()
	npc.config = cfg
	return npc

func test_notify_status_shows_bang():
	var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
	var npc := _make_npc(); add_child_autofree(npc)
	ui.register_npc(npc)
	npc.status = NpcStatus.Status.NOTIFY
	await wait_frames(1)
	assert_eq(ui.get_indicator_text_for(npc), "!")

func test_idle_hides_indicator():
	var ui: CanvasLayer = UIRootScene.instantiate(); add_child_autofree(ui)
	var npc := _make_npc(); add_child_autofree(npc)
	ui.register_npc(npc)
	npc.status = NpcStatus.Status.NOTIFY
	npc.status = NpcStatus.Status.IDLE
	await wait_frames(1)
	assert_false(ui.get_indicator_for(npc).visible)
