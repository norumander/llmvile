extends GutTest

const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const StubPanelScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func test_show_prompt_sets_visible_and_positions():
	var ui: CanvasLayer = UIRootScene.instantiate()
	add_child_autofree(ui)
	ui.show_prompt(Vector2(100, 50))
	assert_true(ui.get_prompt_node().visible)

func test_hide_prompt_hides_node():
	var ui: CanvasLayer = UIRootScene.instantiate()
	add_child_autofree(ui)
	ui.show_prompt(Vector2.ZERO)
	ui.hide_prompt()
	assert_false(ui.get_prompt_node().visible)

func test_show_panel_pushes_to_gameroot_and_removes_on_close():
	var ui: CanvasLayer = UIRootScene.instantiate()
	add_child_autofree(ui)
	var panel: Node = StubPanelScene.instantiate()
	ui.show_panel_for(panel, null)
	assert_true(GameRoot.world_input_paused)
	panel.close()
	await wait_frames(2)
	assert_false(GameRoot.world_input_paused)
