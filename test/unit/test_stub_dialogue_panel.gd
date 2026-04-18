extends GutTest

const StubPanelScene := preload("res://scenes/panels/stub_dialogue.tscn")

func _make_fake_npc(name: String) -> Node:
	var npc := Node.new()
	npc.set("config", NpcConfig.new())
	npc.config.display_name = name
	return npc

func test_show_for_sets_npc_name_in_label():
	var panel: StubDialoguePanel = StubPanelScene.instantiate()
	add_child_autofree(panel)
	var npc := _make_fake_npc("Claudebot")
	add_child_autofree(npc)
	panel.show_for(npc)
	assert_string_contains(panel.get_label_text(), "Claudebot")
	assert_string_contains(panel.get_label_text(), "coming soon")

func test_close_emits_panel_closed_once():
	var panel: StubDialoguePanel = StubPanelScene.instantiate()
	add_child_autofree(panel)
	var counter := [0]
	panel.panel_closed.connect(func(): counter[0] += 1)
	panel.close()
	await wait_frames(2)
	assert_eq(counter[0], 1)
