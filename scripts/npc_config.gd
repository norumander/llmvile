extends Resource
class_name NpcConfig

@export var display_name: String = ""
@export var sprite_frames: SpriteFrames

func is_valid() -> bool:
	return display_name != "" and sprite_frames != null
