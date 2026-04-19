extends GutTest

const HudScene := preload("res://scenes/ui/hud.tscn")

func test_button_press_emits_spawn_requested():
	var hud: Node = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_frames(1)
	var fired := [0]
	hud.spawn_requested.connect(func(): fired[0] += 1)
	var btn: Button = hud.get_node("SpawnButton")
	btn.pressed.emit()
	assert_eq(fired[0], 1)

func test_action_handler_emits_spawn_requested():
	var hud: Node = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_frames(1)
	var fired := [0]
	hud.spawn_requested.connect(func(): fired[0] += 1)
	hud._on_spawn_terminal_action()
	assert_eq(fired[0], 1)

func test_toast_label_shows_message():
	var hud: Node = HudScene.instantiate()
	add_child_autofree(hud)
	await wait_frames(1)
	hud.show_toast("All desks full")
	var toast: Label = hud.get_node("Toast")
	assert_eq(toast.text, "All desks full")
	assert_true(toast.visible)
