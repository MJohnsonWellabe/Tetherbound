extends SceneTree

## Synthetic installed-asset geometry diagnosis, not a world/route acceptance.
const BODY := preload("res://scripts/creatures/creature_body.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const DIRECTOR := preload("res://scripts/combat/cloudreach_encounter_director.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("Creature clearance diagnostic watchdog")
		quit(1))
	var rows: Array[Dictionary] = []
	for id in ["water_cragclaw", "water_mirejaw", "water_mangrove_monitor"]:
		var body: Node3D = SCENE.instantiate()
		body.set_script(BODY)
		root.add_child(body)
		body.set_physics_process(false)
		body.set_process(false)
		body.call("setup", id)
		var model: Node3D = body.get_node("Model")
		var box: AABB = model.transform * BOUNDS.measure(model)
		var radius := float(body.call("body_radius"))
		var height := float(body.call("body_height"))
		var capsule: CapsuleShape3D = body.get_node("Collision").shape
		if box.size.y <= 0 or capsule == null or radius <= 0:
			push_error("Missing actual rendered model/capsule: " + id)
			body.free()
			quit(1)
			return
		var row := {"species": id, "declared_height": height,
			"declared_radius": radius, "capsule_radius": capsule.radius,
			"capsule_height": capsule.height,
			"model_aabb_position": _v(box.position), "model_aabb_size": _v(box.size),
			"horizontal_extent_to_capsule_diameter": maxf(box.size.x, box.size.z) / (2.0 * radius),
			"same_species_admission_minimum": 2.0 * radius + 2.0 * DIRECTOR.WILD_FOOT_MARGIN,
			"rest_bounds_only": true, "aabb_is_conservative": true}
		rows.append(row)
		print("CREATURE_CLEARANCE ", JSON.stringify(row))
		body.free()
	var mixed_minimum: float = rows[0].declared_radius + rows[1].declared_radius + 2.0 * DIRECTOR.WILD_FOOT_MARGIN
	print("CREATURE_CLEARANCE_MIXED cragclaw_mirejaw_admission_minimum=", mixed_minimum)
	print("CREATURE_CLEARANCE_COMPLETE bodies=", rows.size())
	quit(0)

func _v(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
