extends GutTest

const TestScene := preload("res://test/fixtures/test_terminal_panel.tscn")

func _make_panel() -> Node:
	var panel: Node = TestScene.instantiate()
	add_child_autofree(panel)
	return panel

func test_fork_called_on_ready():
	var panel := _make_panel()
	await wait_frames(1)
	assert_eq(panel.get_node("PTY").fork_calls, 1)

func test_show_for_sets_opened():
	var panel := _make_panel()
	await wait_frames(1)
	panel.show_for(null)
	assert_true(panel._panel_opened)
	assert_true(panel.visible)
	assert_eq(panel._current_status, NpcStatus.Status.IDLE)

func test_output_while_closed_sets_unread_and_busy():
	var panel := _make_panel()
	await wait_frames(1)
	# Status tracking only starts after the first open.
	panel.show_for(null)
	panel.close()
	panel.get_node("PTY").emit_output("hello")
	await wait_frames(1)
	assert_true(panel._has_unread)
	assert_eq(panel._current_status, NpcStatus.Status.BUSY)

func test_output_then_quiet_transitions_to_notify():
	var panel := _make_panel()
	await wait_frames(1)
	panel.show_for(null)
	panel.close()
	panel.get_node("PTY").emit_output("hello")
	panel._last_activity_time -= 2.0
	panel._recompute_status()
	assert_eq(panel._current_status, NpcStatus.Status.NOTIFY)

func test_open_panel_clears_unread_and_status():
	var panel := _make_panel()
	await wait_frames(1)
	panel.get_node("PTY").emit_output("hello")
	panel.show_for(null)
	assert_false(panel._has_unread)
	assert_eq(panel._current_status, NpcStatus.Status.IDLE)

func test_close_reverts_and_leaves_unread_false_until_new_output():
	var panel := _make_panel()
	await wait_frames(1)
	panel.show_for(null)
	panel.close()
	assert_false(panel._has_unread)
	assert_eq(panel._current_status, NpcStatus.Status.IDLE)

func test_pty_exit_emits_session_ended():
	var panel := _make_panel()
	await wait_frames(1)
	var ended := [false]
	panel.session_ended.connect(func(): ended[0] = true)
	panel.get_node("PTY").emit_exit(0, 0)
	assert_true(ended[0])

func test_input_forwarded_terminal_to_pty():
	var panel := _make_panel()
	await wait_frames(1)
	var term: Node = panel.get_node("Terminal")
	term.data_sent.emit("abc".to_utf8_buffer())
	var writes: Array = panel.get_node("PTY").write_calls
	assert_eq(writes.size(), 1)
	assert_eq(writes[0], "abc".to_utf8_buffer())

func test_output_forwarded_pty_to_terminal():
	var panel := _make_panel()
	await wait_frames(1)
	panel.get_node("PTY").emit_output("xyz")
	var writes: Array = panel.get_node("Terminal").written
	assert_eq(writes.size(), 1)
	assert_eq(writes[0], "xyz".to_utf8_buffer())
