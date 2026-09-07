extends SceneTree
## Mesh-only production CreatureBody fit and skin-correct render AABB probe.
## Rest geometry only: cannot establish an anatomical back or visual acceptance.
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const BODY := preload("res://scripts/creatures/wild_creature.gd")
const PREFAB := preload("res://scenes/creatures/creature.tscn")
const IDS := ["aquaryn", "mosshell", "sirenseal", "riverdrake", "cannonback"]
func _init() -> void:
	call_deferred("run")
func array_of(v: Vector3) -> Array:
	return [snappedf(v.x,0.001),snappedf(v.y,0.001),snappedf(v.z,0.001)]
func run() -> void:
	var result: Dictionary = {}
	for id: String in IDS:
		var body: Node3D = PREFAB.instantiate()
		body.set_script(BODY)
		root.add_child(body)
		body.set_physics_process(false)
		body.call("populate", "water_"+id, null)
		var model: Node3D = body.get_node("Model")
		var bounds := model.transform * BOUNDS.measure(model)
		var raw: Dictionary = SPECIES.table()["water_"+id]
		result["water_"+id] = {"aabb_position":array_of(bounds.position),"aabb_size":array_of(bounds.size),
			"collision_radius_m":body.call("body_radius"),"source_species":raw.water_placeholder.source_species,
			"model":raw.placeholder.model,"replacement_model":raw.water_placeholder.replacement_model,
			"replacement_binding":raw.water_placeholder.replacement_binding}
		body.free()
	var saddle: Node3D = load("res://assets/props/riding_saddle/riding_saddle.glb").instantiate()
	root.add_child(saddle)
	var box := BOUNDS.measure(saddle)
	result["saddle"]={"model":"res://assets/props/riding_saddle/riding_saddle.glb","aabb_position":array_of(box.position),"aabb_size":array_of(box.size)}
	saddle.free()
	var checks := 0
	var failures := 0
	if FileAccess.file_exists("res://data/config/water_mounts.json"):
		var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_mounts.json"))
		for id: String in IDS:
			var key := "water_" + id
			var row: Dictionary = config.mounts[key]
			var actual: Dictionary = result[key]
			var expected: Dictionary = row.measurement
			for axis in 3:
				checks += 1
				if absf(float(actual.aabb_size[axis])-float(expected.aabb_size[axis])) > 0.01:
					failures += 1
					print("FAIL changed fitted envelope: ",key," axis ",axis)
			checks += 3
			if float(row.mount_offset[1])+float(row.surface_origin_offset_m)-0.92 < 0.05:
				failures += 1
				print("FAIL rider origin below conservative sea clearance: ",key)
			if float(row.saddle_offset[1])+float(row.surface_origin_offset_m)+float(result.saddle.aabb_position[1])*float(row.saddle_scale) <= 0.0:
				failures += 1
				print("FAIL saddle rest envelope intersects sea: ",key)
			if float(row.dismount_distance) < float(actual.aabb_size[0])*0.5+0.65:
				failures += 1
				print("FAIL dismount offset lacks lateral envelope clearance: ",key)
		print("Water mount geometry: %d checks, %d failures" % [checks, failures])
	var file := FileAccess.open("user://water-mount-geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	print(JSON.stringify(result))
	quit(1 if failures else 0)


