extends "res://scripts/combat/combat_manager.gd"

## Production combat with a realm-local, nearest-elevation placement seam.
## Damage, AI, catches, party ownership, switching, XP and resolution inherited.
var ground_world: Node


func _ground_height(x: float, z: float) -> float:
	if is_instance_valid(ground_world) and ground_world.has_method("ground_height_near"):
		var y := _player.global_position.y if is_instance_valid(_player) else _arena_centre.y
		return float(ground_world.call("ground_height_near", Vector3(x, y, z)))
	return super._ground_height(x, z)
