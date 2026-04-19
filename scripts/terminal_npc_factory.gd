extends Node
class_name TerminalNpcFactory

signal spawn_failed(reason: String)
signal spawn_succeeded(npc: NpcEntity)

const NPC_SCENE := preload("res://scenes/npc.tscn")
const DESK_POSITIONS: Array[Vector2] = [
	Vector2(144, 144),
	Vector2(368, 144),
	Vector2(144, 240),
	Vector2(368, 240),
]

## Populated by the world scene; cycled for each spawn.
@export var sprite_frames_pool: Array[SpriteFrames] = []

## Where each spawned NPC's panel should live in the tree (typically UIRoot.PanelHost).
## Configured by world.gd. Left null in unit tests.
var panel_host: Node

## For tests only — overrides the default terminal.tscn.
var panel_scene_override: PackedScene

var _occupied: Array[bool] = [false, false, false, false]
var _spawn_counter: int = 0

func spawn_at_free_desk() -> NpcEntity:
	var idx := _occupied.find(false)
	if idx == -1:
		spawn_failed.emit("all desks full")
		return null
	if sprite_frames_pool.is_empty():
		spawn_failed.emit("sprite pool empty")
		return null
	_occupied[idx] = true
	_spawn_counter += 1

	var cfg := NpcConfig.new()
	cfg.display_name = "NPC-%d" % _spawn_counter
	cfg.sprite_frames = sprite_frames_pool[(_spawn_counter - 1) % sprite_frames_pool.size()]

	var npc: NpcEntity = NPC_SCENE.instantiate()
	npc.config = cfg
	npc.position = DESK_POSITIONS[idx]
	if panel_scene_override != null:
		npc.panel_scene_override = panel_scene_override
	if panel_host != null:
		npc.panel_host = panel_host
	var captured_idx := idx
	npc.tree_exiting.connect(func(): _occupied[captured_idx] = false)
	get_parent().add_child(npc)
	spawn_succeeded.emit(npc)
	return npc
