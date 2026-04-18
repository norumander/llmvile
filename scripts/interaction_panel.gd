extends Control
class_name InteractionPanel
## Abstract base for any panel that opens when interacting with an NPC.
## Subclasses MUST override show_for(). close() is typically fine as-is.

signal panel_closed

func show_for(_npc: Node) -> void:
	push_error("InteractionPanel.show_for must be overridden")

func close() -> void:
	panel_closed.emit()
	queue_free()
