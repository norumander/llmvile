extends InteractionPanel
class_name StubDialoguePanel

@onready var _label: Label = $Panel/Label

func show_for(npc: Node) -> void:
	var display_name := "an NPC"
	if npc != null and npc.get("config") != null:
		display_name = npc.config.display_name
	_label.text = "%s: coming soon — claude code" % display_name
	visible = true

func get_label_text() -> String:
	return _label.text

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close()
