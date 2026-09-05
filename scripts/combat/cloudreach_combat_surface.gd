extends Node

## Per-body ground source for production CreatureBody's existing injection slot.
## Cloudreach has stacked terrain; never seat a lower body on the highest XZ deck.
var world: Node
var body: Node3D
var reference_y := 0.0


func ground_height_at(x: float, z: float) -> float:
	if not is_instance_valid(world):
		return NAN
	var y := body.global_position.y if is_instance_valid(body) else reference_y
	if world.has_method("ground_height_near"):
		return float(world.call("ground_height_near", Vector3(x, y, z)))
	return float(world.call("ground_height_at", x, z)) if world.has_method("ground_height_at") else NAN
