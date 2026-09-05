extends "res://scripts/world/interactable.gd"

## Relays are struck by the piloted creature, whose collider can be much wider
## than the human. Exclude only that actor, never walls or other world bodies.
var controlled_body: Callable


func _has_line_of_sight(from: Vector3) -> bool:
	var world := get_world_3d()
	if world == null:
		return true
	var eye := from + Vector3.UP*SIGHT_EYE_HEIGHT
	var span := global_position.distance_to(eye)
	if span <= SIGHT_SELF_CLEARANCE+SIGHT_TRAINER_CLEARANCE:
		return true
	var direction := global_position.direction_to(eye)
	var query := PhysicsRayQueryParameters3D.create(global_position+direction*SIGHT_SELF_CLEARANCE,
		global_position+direction*(span-SIGHT_TRAINER_CLEARANCE))
	query.collide_with_areas=false
	if controlled_body.is_valid():
		var actor: CharacterBody3D = controlled_body.call()
		if is_instance_valid(actor):
			query.exclude=[actor.get_rid()]
	return world.direct_space_state.intersect_ray(query).is_empty()
