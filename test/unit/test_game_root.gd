extends GutTest

var GameRootScript := preload("res://scripts/game_root.gd")

func test_defaults():
	var gr: Node = GameRootScript.new()
	assert_false(gr.world_input_paused, "input should not be paused on init")
	assert_eq(gr.panel_stack.size(), 0, "panel stack should be empty on init")
	gr.free()

func test_push_panel_pauses_input():
	var gr: Node = GameRootScript.new()
	var fake_panel := Node.new()
	gr.push_panel(fake_panel)
	assert_true(gr.world_input_paused)
	assert_eq(gr.panel_stack.size(), 1)
	gr.free()
	fake_panel.free()

func test_pop_panel_resumes_input_when_empty():
	var gr: Node = GameRootScript.new()
	var fake_panel := Node.new()
	gr.push_panel(fake_panel)
	gr.pop_panel(fake_panel)
	assert_false(gr.world_input_paused)
	assert_eq(gr.panel_stack.size(), 0)
	gr.free()
	fake_panel.free()

func test_pop_panel_keeps_pause_when_stack_nonempty():
	var gr: Node = GameRootScript.new()
	var p1 := Node.new()
	var p2 := Node.new()
	gr.push_panel(p1)
	gr.push_panel(p2)
	gr.pop_panel(p2)
	assert_true(gr.world_input_paused, "still paused with p1 on stack")
	gr.free(); p1.free(); p2.free()
