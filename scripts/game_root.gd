extends Node
## Autoload singleton. Tracks input pause state and panel stack.

signal world_input_paused_changed(paused: bool)

var world_input_paused: bool = false :
	set(value):
		if world_input_paused == value:
			return
		world_input_paused = value
		world_input_paused_changed.emit(value)

var panel_stack: Array[Node] = []

func push_panel(panel: Node) -> void:
	panel_stack.append(panel)
	world_input_paused = true

func pop_panel(panel: Node) -> void:
	panel_stack.erase(panel)
	if panel_stack.is_empty():
		world_input_paused = false
