extends Node
class_name InteractionSystem
## Tracks NpcEntities in proximity, picks closest as current target,
## routes the E action. Lives as a child of Player.

signal target_changed(npc)

var _in_range: Array[NpcEntity] = []
var current_target: NpcEntity = null

func notify_entered(npc: NpcEntity) -> void:
	if not _in_range.has(npc):
		_in_range.append(npc)

func notify_exited(npc: NpcEntity) -> void:
	_in_range.erase(npc)

func recompute_target(player_pos: Vector2) -> void:
	var closest: NpcEntity = null
	var best := INF
	for n in _in_range:
		if not is_instance_valid(n):
			continue
		var d := player_pos.distance_squared_to(n.global_position)
		if d < best:
			best = d
			closest = n
	if closest != current_target:
		current_target = closest
		target_changed.emit(current_target)

func try_interact() -> Node:
	if GameRoot.world_input_paused or current_target == null:
		return null
	return current_target.interact()
