extends Resource
class_name NpcConfig

@export var display_name: String = ""
@export var sprite: Texture2D
@export var desk_position: Vector2i = Vector2i.ZERO
@export var panel_scene: PackedScene
@export var kind: StringName = &"stub"

func is_valid() -> bool:
	return display_name != "" and sprite != null and panel_scene != null
