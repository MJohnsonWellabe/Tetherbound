extends SceneTree

## Standalone fixture for D111 (OP-0906-05): builds the Summit Stronghold
## aviary geometry on a bare Node3D with placeholder materials -- no
## Cloudreach world, no chapter runtime. Proves the throat/route clearance
## the hookup depends on is real (a shape-cast capsule, not a visual guess),
## that the oculus is genuinely open, and reports the counts/heights an
## agent doing the hookup or the visual judge would want without booting
## the world.

const AVIARY := preload("res://scripts/world/cloudreach_aviary.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _placeholder_materials() -> Dictionary:
	var materials: Dictionary = {}
	for key in ["masonry", "stone", "timber", "iron", "rope", "veil", "lantern"]:
		materials[key] = StandardMaterial3D.new()
	return materials


func _run() -> void:
	await process_frame
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	_check(spec is Dictionary and not spec.is_empty(), "cloudreach_aviary.json parses to a non-empty dictionary")

	var scene := Node3D.new()
	scene.name = "AviaryFixture"
	root.add_child(scene)
	current_scene = scene

	# A flat floor under the whole footprint so the oculus down-ray and the
	# capsule shape-casts have real ground to land on / walk over, exactly
	# as the landmark's own terrain would provide in the real world.
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80.0, 1.0, 80.0)
	floor_shape.shape = box
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	floor_body.add_child(floor_shape)
	scene.add_child(floor_body)

	var result: Dictionary = AVIARY.build(scene, _placeholder_materials(), spec)
	await physics_frame
	await physics_frame

	# ---- self-check math agrees with what was actually built ----
	_check(AVIARY.throat_clear(spec), "throat_clear(spec) self-check passes for the authored spec")

	# ---- node counts ----
	var ribs: Array = result.get("ribs", [])
	var rings: Array = result.get("latitude_rings", [])
	var perches: Array = result.get("perches", [])
	var nests: Array = result.get("nests", [])
	var lanterns: Array = result.get("lanterns", [])
	var arches: Array = result.get("arches", [])
	var ring_anchors: Array = result.get("ring_anchors", [])
	var colliders: Array = result.get("colliders", [])

	var dome_spec: Dictionary = spec.get("dome", {})
	var furniture_spec: Dictionary = spec.get("furniture", {})
	_check(ribs.size() == int(dome_spec.get("meridian_count", 16)),
		"rib count matches meridian_count (%d == %d)" % [ribs.size(), int(dome_spec.get("meridian_count", 16))])
	_check(rings.size() == int(dome_spec.get("latitude_ring_count", 5)),
		"latitude ring count matches config (%d == %d)" % [rings.size(), int(dome_spec.get("latitude_ring_count", 5))])
	_check(perches.size() == int(furniture_spec.get("perch_count", 10)),
		"perch count matches config (%d == %d)" % [perches.size(), int(furniture_spec.get("perch_count", 10))])
	_check(perches.size() >= 8 and perches.size() <= 12, "perch count is in the owner's 8-12 roost range")
	_check(nests.size() == (furniture_spec.get("nest_indices", []) as Array).size(),
		"nest count matches nest_indices (%d)" % nests.size())
	_check(lanterns.size() == int(furniture_spec.get("lantern_count", 4)),
		"lantern count matches config (%d == %d)" % [lanterns.size(), int(furniture_spec.get("lantern_count", 4))])
	_check(arches.size() == 4, "four arched openings exist (two throat + two side), found %d" % arches.size())
	_check(ring_anchors.size() == int(furniture_spec.get("ring_anchor_count", 6)),
		"ring anchor count matches config (%d)" % ring_anchors.size())
	_check(not colliders.is_empty(), "the drum has real colliders (%d bodies)" % colliders.size())

	var throat_arches := arches.filter(func(a: Dictionary) -> bool: return a["kind"] == "throat")
	_check(throat_arches.size() == 2, "exactly two arches are tagged as the throat")
	for arch: Dictionary in throat_arches:
		_check(arch["half_width_m"] >= 5.0, "throat arch half-width >= PORTAL_HALF_WIDTH (%.2fm)" % arch["half_width_m"])
		_check(arch["clear_height_m"] >= 8.0, "throat arch clear height >= PORTAL_CLEAR_HEIGHT (%.2fm)" % arch["clear_height_m"])

	# ---- real physics: shape-cast the throat axis at both portal_z bands ----
	var space := scene.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 1.8
	var walk_y := 1.0
	for z: float in [-1.5, 7.5]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.margin = 0.01
		query.collide_with_bodies = true
		var start := Vector3(-30.0, walk_y, z)
		var motion := Vector3(60.0, 0.0, 0.0)
		query.transform = Transform3D(Basis(), start)
		query.motion = motion
		var hits: Array = space.intersect_shape(query, 8)
		var motion_result: PackedFloat32Array = space.cast_motion(query)
		var safe: float = motion_result[0] if motion_result.size() > 0 else 0.0
		_check(hits.is_empty() and safe >= 0.999,
			"throat shape-cast at z=%.1f is clear x=-30..30 (safe=%.3f, overlaps=%d)" % [z, safe, hits.size()])

	# ---- oculus is genuinely open: a ray straight down from its centre hits the floor ----
	var oculus_height: float = result.get("oculus_height_m", 0.0)
	var oculus_start := Vector3(0.0, oculus_height + 1.0, 0.0)
	var ray := PhysicsRayQueryParameters3D.create(oculus_start, oculus_start + Vector3.DOWN * (oculus_height + 5.0))
	var ray_hit := space.intersect_ray(ray)
	_check(not ray_hit.is_empty() and (ray_hit.get("collider") as Node).name == "Floor",
		"a ray from the oculus centre straight down reaches the floor (open oculus)")

	# ---- apex height vs spec ----
	var expected_apex := float(spec.get("drum", {}).get("height_m", 9.0)) + float(dome_spec.get("radius_m", 23.0))
	var apex: float = result.get("apex_height_m", 0.0)
	_check(absf(apex - expected_apex) < 0.05, "apex height matches spec (%.2fm vs expected %.2fm)" % [apex, expected_apex])

	var drum_height: float = result.get("drum_height_m", 0.0)
	var trainer_height := 1.8
	print("CLOUDREACH AVIARY: drum_height=%.2fm (%.1fx trainer) apex_height=%.2fm (%.1fx trainer) oculus_height=%.2fm oculus_radius=%.2fm"
		% [drum_height, drum_height / trainer_height, apex, apex / trainer_height, oculus_height, result.get("oculus_radius_m", 0.0)])
	print("CLOUDREACH AVIARY counts: ribs=%d latitude_rings=%d perches=%d nests=%d lanterns=%d arches=%d ring_anchors=%d colliders=%d"
		% [ribs.size(), rings.size(), perches.size(), nests.size(), lanterns.size(), arches.size(), ring_anchors.size(), colliders.size()])

	scene.queue_free()
	await process_frame
	print("CLOUDREACH AVIARY FIXTURE %s" % ("PASS" if failures.is_empty() else "FAIL"))
	if not failures.is_empty():
		for message: String in failures:
			print("  - %s" % message)
	quit(0 if failures.is_empty() else 1)
