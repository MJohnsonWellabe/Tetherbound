extends SceneTree

## Real vendored Terrain3D and the complete baked Tidewake region set.
## Direct activation is an explicit mechanics fixture, not rollout/FPS proof.
const REGIONS := preload("res://scripts/world/water_collision_regions.gd")
var _checks := 0
var _failures := 0
var _ray_pairs := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		if _failures <= 10:
			print("FAIL: " + label)


func _run() -> void:
	if not ClassDB.class_exists("Terrain3D"):
		_check(false, "actual native Terrain3D DLL loaded")
		quit(1)
		return
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var terrain: Node3D = ClassDB.instantiate("Terrain3D")
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.current = true
	terrain.call("set_camera", camera)
	terrain.set("free_editor_textures", false)
	root.add_child(terrain)
	await process_frame
	terrain.set("region_size", int(config.terrain.region_size))
	terrain.set("vertex_spacing", float(config.terrain.vertex_spacing))
	terrain.set("data_directory", str(config.terrain.data_directory))
	terrain.set("collision_mode", 3)
	await physics_frame
	await physics_frame
	var collision: Object = terrain.get("collision")
	var original: RID = collision.call("get_rid")
	var data: Object = terrain.get("data")
	var locations: Array = data.call("get_region_locations")
	var count := PhysicsServer3D.body_get_shape_count(original)
	_check(not locations.is_empty() and count == locations.size(), "all actual baked regions have original native full collision")
	if locations.is_empty() or count != locations.size():
		terrain.queue_free()
		await process_frame
		quit(1)
		return
	var shapes: Array[Dictionary] = []
	var transforms: Array[Transform3D] = []
	for index in count:
		var shape := PhysicsServer3D.body_get_shape(original, index)
		shapes.append(PhysicsServer3D.shape_get_data(shape))
		transforms.append(PhysicsServer3D.body_get_shape_transform(original, index))
	var points: Array[Vector3] = []
	var expected: Array[Dictionary] = []
	var expected_normals: Array[Array] = []
	var state := terrain.get_world_3d().direct_space_state
	var size := int(config.terrain.region_size)
	var spacing := float(config.terrain.vertex_spacing)
	for location: Vector2i in locations:
		# Include both sides of all region borders and authored cell diagonals.
		for fraction: Vector2 in [Vector2(0.0, 0.0), Vector2(0.25, 0.63),
			Vector2(size * 0.5, size * 0.5), Vector2(size - 0.25, size - 0.63),
			Vector2(size - 0.01, 0.5), Vector2(0.5, size - 0.01)]:
			var xz := (Vector2(location) * size + fraction) * spacing
			var point := Vector3(xz.x, 1024.0, xz.y)
			points.append(point)
			expected.append(state.intersect_ray(PhysicsRayQueryParameters3D.create(point, point - Vector3(0, 2048, 0))))
			var normals: Array = []
			for dx in [-0.001, 0.0, 0.001]:
				for dz in [-0.001, 0.0, 0.001]:
					var adjacent := point + Vector3(dx, 0, dz)
					var old := state.intersect_ray(PhysicsRayQueryParameters3D.create(adjacent, adjacent - Vector3(0, 2048, 0)))
					if not old.is_empty():
						normals.append(old.normal)
			expected_normals.append(normals)
	var regions := REGIONS.new()
	terrain.add_child(regions)
	_check(await regions.install(terrain, 8.0), "production helper installs against actual vendored native terrain")
	_check(regions.installed and regions.region_count == count, "all original native full-region shapes retained")
	_check(int(terrain.get("collision_mode")) == 0, "native FULL disabled only after clone preparation")
	var bodies: Array[RID] = regions.get("_bodies")
	for index in bodies.size():
		var shape := PhysicsServer3D.body_get_shape(bodies[index], 0)
		_check(PhysicsServer3D.shape_get_data(shape) == shapes[index], "exact actual baked shape data %d" % index)
		_check(PhysicsServer3D.body_get_shape_transform(bodies[index], 0) == transforms[index], "exact actual baked transform %d" % index)
	await physics_frame
	await physics_frame
	for index in points.size():
		var point := points[index]
		var actual := state.intersect_ray(PhysicsRayQueryParameters3D.create(point, point - Vector3(0, 2048, 0)))
		var before := expected[index]
		_ray_pairs += 1
		_check(actual.is_empty() == before.is_empty(), "actual-region floor presence %s" % point)
		if not actual.is_empty() and not before.is_empty():
			_check(actual.position.distance_to(before.position) <= 0.0001, "actual floor within0.1mm %s" % point)
			var normal_matches := false
			for normal: Vector3 in expected_normals[index]:
				if actual.normal.distance_to(normal) <= 0.0001:
					normal_matches = true
			_check(normal_matches, "normal belongs to original actual-region triangles %s" % point)
			_check(actual.collider_id == before.collider_id, "actual Terrain3D collider identity %s" % point)
	terrain.queue_free()
	camera.queue_free()
	await process_frame
	print("Native baked Tidewake regional collider clone: %d regions, %d checks, %d ray pairs, %d failures" % [count, _checks, _ray_pairs, _failures])
	quit(0 if _failures == 0 and _ray_pairs == count * 6 else 1)
