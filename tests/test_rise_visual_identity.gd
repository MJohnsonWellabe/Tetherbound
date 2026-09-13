extends "res://tests/test_case.gd"

## Focused contract for The Rise's production-visible hero composition.
## The destination used to be a terrain mound plus a fingerpost; these checks
## keep the authored tree-and-stone crown tied to the canonical region and out
## of both roads that meet at its foot.

const PROPS_PATH := "res://data/config/bands/band1_lower_meadows/props.json"
const VEGETATION_PATH := "res://data/config/bands/band1_lower_meadows/vegetation.json"
const LANDMARKS_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const CAPTURE_PATH := "res://tools/capture_the_rise_identity.gd"
const PROPS_SOURCE_PATH := "res://scripts/world/props.gd"
const PROPS_SCRIPT := preload("res://scripts/world/props.gd")
const BUILDING_PREFABS := preload("res://scripts/world/building_prefabs.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HERO_NAME := "the_rise_rock_crown"
const TRAIL_NAME := "the_rise_cairn_trail"
const OVERLOOK_NAME := "the_rise_overlook"
const COLLISION_CLEARANCE_MARGIN_M := 0.35


class RiseGroundStub:
	extends Node3D

	func ground_height_at(x: float, z: float) -> float:
		return x * 0.08 + z * 0.03


class RiseLowerJointCliffStub:
	extends Node3D

	func ground_height_at(x: float, z: float) -> float:
		# Reproduce the failure class: a sharp terrain drop inside the C-D-fork
		# interval. The installed terrace must remain continuous and floor-like.
		if Vector2(x, z).distance_to(Vector2(62.7, -60.2)) < 0.01:
			return -8.0
		if Vector2(x, z).distance_to(Vector2(66.2, -63.1)) < 0.01:
			return -7.5
		return 4.0


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _rise_region() -> Dictionary:
	for raw: Variant in _read_json(LANDMARKS_PATH).get("regions", []):
		var region := raw as Dictionary
		if str(region.get("id", "")) == "the_rise":
			return region
	return {}


func _hero_cluster() -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == HERO_NAME:
			return cluster
	return {}


func _trail_cluster() -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == TRAIL_NAME:
			return cluster
	return {}


func _trail_prop_named(prop_name: String) -> Dictionary:
	for raw: Variant in _trail_cluster().get("props", []):
		var prop := raw as Dictionary
		if str(prop.get("name", "")) == prop_name:
			return prop
	return {}


func _built_surface_endpoint(visual: MeshInstance3D, spec: Dictionary, at_end: bool,
		entry_clearance := 0.0) -> Vector3:
	var segment := spec.get("walkable_segment", {}) as Dictionary
	var from_raw := segment.get("from", []) as Array
	var to_raw := segment.get("to", []) as Array
	var horizontal := Vector2(float(from_raw[0]), float(from_raw[1])).distance_to(
		Vector2(float(to_raw[0]), float(to_raw[1])))
	var forward_xz := Vector2(visual.transform.basis.z.x, visual.transform.basis.z.z).length()
	var route_half := horizontal / maxf(forward_xz, 0.0001) * 0.5
	var overlap := float(segment.get("overlap_m", 0.45))
	var centre_shift := (overlap + entry_clearance) * 0.5
	var mesh := visual.mesh as BoxMesh
	return visual.transform * Vector3(0.0, mesh.size.y * 0.5,
		(route_half - centre_shift) if at_end else (-route_half - centre_shift))


func _built_box_edge(visual: MeshInstance3D, at_end: bool) -> Vector3:
	var mesh := visual.mesh as BoxMesh
	return visual.transform * Vector3(0.0, mesh.size.y * 0.5,
		mesh.size.z * (0.5 if at_end else -0.5))


func _overlook_cluster() -> Dictionary:
	for raw: Variant in _read_json(PROPS_PATH).get("clusters", []):
		var cluster := raw as Dictionary
		if str(cluster.get("name", "")) == OVERLOOK_NAME:
			return cluster
	return {}


func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _route_named(label: String, key: String = "routes") -> PackedVector2Array:
	var paths := _read_json(TERRAIN_PATH).get("paths", {}) as Dictionary
	for raw: Variant in paths.get(key, []):
		var route := raw as Dictionary
		if str(route.get("label", "")) != label:
			continue
		var result := PackedVector2Array()
		for point: Variant in route.get("points", []):
			result.append(Vector2(float(point[0]), float(point[1])))
		return result
	return PackedVector2Array()


func _distance_to_polyline(point: Vector2, line: PackedVector2Array) -> float:
	var nearest := INF
	for index in line.size() - 1:
		var a := line[index]
		var b := line[index + 1]
		var ab := b - a
		var t := clampf((point - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(a + ab * t))
	return nearest


## Resolve the same imported mesh bounds, non-uniform scale and yaw that
## props.gd uses to create its production BoxShape3D. A centre-only distance
## check is not evidence: these rocks have off-centre, multi-metre source
## AABBs and their generated collider follows that complete volume.
func _resolved_prop_collider(prop: Dictionary) -> Dictionary:
	var dir := str(prop.get("dir", "res://assets/props/quaternius_fantasy"))
	var path := "%s/%s.gltf" % [dir, str(prop.get("model", ""))]
	var packed := load(path) as PackedScene
	if packed == null:
		return {}
	var model := packed.instantiate() as Node3D
	if model == null:
		return {}
	var bounds: AABB = BUILDING_PREFABS.new().combined_aabb(model)
	model.free()
	var scale_raw := prop.get("scale_xyz", []) as Array
	if scale_raw.size() != 3 or bounds.size == Vector3.ZERO:
		return {}
	var scale_vec := Vector3(float(scale_raw[0]), float(scale_raw[1]), float(scale_raw[2]))
	var local_centre := bounds.position + bounds.size * 0.5
	local_centre *= scale_vec
	var yaw := deg_to_rad(float(prop.get("yaw_deg", 0.0)))
	var rotated := Basis(Vector3.UP, yaw) * local_centre
	var raw_at := prop.get("at", []) as Array
	var centre := Vector2(float(raw_at[0]) + rotated.x, float(raw_at[1]) + rotated.z)
	var half_x := bounds.size.x * scale_vec.x * 0.5
	var half_z := bounds.size.z * scale_vec.z * 0.5
	return {"centre": centre, "circumscribed_radius": sqrt(half_x * half_x + half_z * half_z)}


func _production_player_radius() -> float:
	var player := PLAYER_SCENE.instantiate() as CharacterBody3D
	if player == null:
		return INF
	var collision := player.get_node_or_null(^"Collision") as CollisionShape3D
	var capsule: CapsuleShape3D = null
	if collision != null:
		capsule = collision.shape as CapsuleShape3D
	var radius := capsule.radius if capsule != null else INF
	player.free()
	return radius


func test_the_rise_keeps_one_distinctive_authored_hero() -> void:
	var cluster := _hero_cluster()
	assert_false(cluster.is_empty(), "The Rise has no authored hero cluster")
	assert_eq(int(cluster.get("order", -1)), 1052, "The Rise hero keeps its band-reserved identity")
	var props := cluster.get("props", []) as Array
	assert_eq(props.size(), 4, "one hero tree and three asymmetrical crown stones")
	var hero_count := 0
	var rock_models := {}
	for raw: Variant in props:
		var prop := raw as Dictionary
		var dir := str(prop.get("dir", ""))
		var model := str(prop.get("model", ""))
		assert_true(ResourceLoader.exists("%s/%s.gltf" % [dir, model]), "%s is an installed production asset" % model)
		if str(prop.get("name", "")) == "RiseHeroTree":
			hero_count += 1
			assert_eq(model, "TwistedTree_3", "the hero keeps its wind-shaped silhouette")
			assert_true(float(prop.get("scale", 0.0)) >= 1.6, "the hero stays readable behind a trainer")
			var leaf := (prop.get("retint", {}) as Dictionary).get("Leaves_TwistedTree", {}) as Dictionary
			assert_eq(str(leaf.get("color", "")), "#e2e4ac", "the controlled warm modulation stays authored")
			assert_eq(str(leaf.get("texture", "")),
				"res://assets/environment/stylized_nature/Leaves_NormalTree_C.png",
				"crimson source leaves are swapped to the Meadows' green leaf sheet")
		elif model.begins_with("Rock_Medium_"):
			rock_models[model] = true
			assert_true(prop.has("scale_xyz"), "%s keeps a deliberately shaped stone fin" % model)
			var scale_raw := prop.get("scale_xyz", []) as Array
			assert_eq(scale_raw.size(), 3, "%s keeps a complete non-uniform scale" % model)
			if scale_raw.size() == 3:
				assert_true(float(scale_raw[0]) <= 1.3 and float(scale_raw[1]) <= 1.6 \
						and float(scale_raw[2]) <= 1.15,
					"%s has regrown into a road-end boulder wall" % model)
	assert_eq(hero_count, 1, "The Rise has one hero tree, not a grove")
	assert_eq(rock_models.size(), 3, "the crown uses three distinct rock silhouettes")


func test_crown_stones_frame_the_tree_instead_of_hiding_it_from_the_road_end() -> void:
	var props := _hero_cluster().get("props", []) as Array
	var hero_at := Vector2.INF
	var rock_positions := PackedVector2Array()
	for raw: Variant in props:
		var prop := raw as Dictionary
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		if str(prop.get("name", "")) == "RiseHeroTree":
			hero_at = at
		elif str(prop.get("model", "")).begins_with("Rock_Medium_"):
			rock_positions.append(at)
	assert_true(hero_at != Vector2.INF, "The Rise hero tree has no authored position")
	assert_eq(rock_positions.size(), 3, "the crown still uses exactly three framing stones")
	var road_end := Vector2(74.0, -41.0)
	for rock_at: Vector2 in rock_positions:
		assert_true(rock_at.distance_to(road_end) >= 23.0,
			"a crown stone has slipped back into the road-end foreground")
		assert_true(rock_at.distance_to(hero_at) <= 8.0,
			"a crown stone no longer reads as part of the tree composition")


func test_every_hero_piece_stays_inside_the_named_region_and_off_both_roads() -> void:
	var region := _rise_region()
	assert_false(region.is_empty(), "map_landmarks.json still publishes The Rise")
	assert_eq(str(region.get("display_name", "")), "The Rise", "player-visible naming stays canonical")
	var centre_raw := region.get("centre", []) as Array
	var centre := Vector2(float(centre_raw[0]), float(centre_raw[1]))
	var radius := float(region.get("radius", 0.0))
	var rise_road := _route_named("The Rise")
	var stronghold_road := _route_named("The Stronghold", "approaches")
	assert_true(rise_road.size() >= 2, "the authored The Rise road still exists")
	assert_true(stronghold_road.size() >= 2, "the Stronghold approach still leaves the same road end")
	for raw: Variant in (_hero_cluster().get("props", []) as Array):
		var prop := raw as Dictionary
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(at.distance_to(centre) < radius, "%s remains inside The Rise region" % str(prop.get("name", "prop")))
		assert_true(_distance_to_polyline(at, rise_road) >= 18.0, "%s stays out of the village road" % str(prop.get("name", "prop")))
		assert_true(_distance_to_polyline(at, stronghold_road) >= 18.0, "%s stays out of the Stronghold approach" % str(prop.get("name", "prop")))


func test_scatter_clearing_is_scoped_to_the_hero_composition() -> void:
	var found := false
	var sightline_found := false
	var crown_edge_found := false
	for raw: Variant in _read_json(VEGETATION_PATH).get("clearings", []):
		var clearing := raw as Dictionary
		if int(clearing.get("order", -1)) == 1922:
			crown_edge_found = true
			var edge_centre := Vector2(float(clearing.get("x", INF)),
				float(clearing.get("z", INF)))
			assert_true(edge_centre.distance_to(Vector2(111.0, -54.0)) <= 0.1,
				"the bounded lens left the intrusive right-edge canopy")
			assert_true(float(clearing.get("radius", 0.0)) <= 6.5,
				"the crown-edge repair expanded into a broad bald hillside")
		if int(clearing.get("order", -1)) == 1915:
			sightline_found = true
			var sightline_centre := Vector2(float(clearing.get("x", INF)),
				float(clearing.get("z", INF)))
			assert_true(sightline_centre.distance_to(Vector2(87.0, -48.0)) <= 0.1,
				"the road-end lens left the actual hero sightline")
			assert_true(float(clearing.get("radius", 0.0)) <= 8.5,
				"the road-end lens balds the broader Rise")
		if int(clearing.get("order", -1)) != 1911:
			continue
		found = true
		var centre := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
		assert_true(centre.distance_to(Vector2(99.0, -53.0)) <= 0.1, "the clearing follows the hero crown")
		assert_true(float(clearing.get("radius", 0.0)) <= 12.0, "the identity pass does not bald the broader hill")
	assert_true(found, "The Rise hero has no protection from random scatter overlap")
	assert_true(sightline_found, "The Rise road end is still screened from its hero crown")
	assert_true(crown_edge_found, "the crown view still admits the R7 right-edge canopy card")


func test_cairn_tread_connects_the_safe_road_end_to_the_crown_shelf() -> void:
	var cluster := _trail_cluster()
	assert_false(cluster.is_empty(), "The Rise has no authored climb/trail branch")
	assert_eq(int(cluster.get("order", -1)), 1055,
		"the climb remains a separate band-reserved production cluster")
	var props := cluster.get("props", []) as Array
	assert_eq(props.size(), 33,
		"eighteen grounded terrace segments, twelve low retaining stones and three bounded waylights")
	var tread_positions := PackedVector2Array()
	var terrace_segments: Array[Dictionary] = []
	var torch_positions := PackedVector2Array()
	var retaining_positions := PackedVector2Array()
	var torch_count := 0
	for raw: Variant in props:
		var prop := raw as Dictionary
		var model := str(prop.get("model", ""))
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		if prop.has("walkable_segment"):
			var segment := prop.get("walkable_segment", {}) as Dictionary
			var from_raw := segment.get("from", []) as Array
			var to_raw := segment.get("to", []) as Array
			assert_eq(from_raw.size(), 2, "a terrace segment lost its start endpoint")
			assert_eq(to_raw.size(), 2, "a terrace segment lost its end endpoint")
			if from_raw.size() != 2 or to_raw.size() != 2:
				continue
			var from := Vector2(float(from_raw[0]), float(from_raw[1]))
			var to := Vector2(float(to_raw[0]), float(to_raw[1]))
			if terrace_segments.is_empty():
				tread_positions.append(from)
			tread_positions.append(to)
			terrace_segments.append(segment)
			assert_true(float(segment.get("width_m", 5.4)) >= 5.4,
				"%s is no longer a player-scaled terrace" % str(prop.get("name", "terrace")))
			assert_true(float(segment.get("thickness_m", 0.32)) <= 0.35,
				"%s became another tall traversal-blocking slab" % str(prop.get("name", "terrace")))
		elif str(prop.get("name", "")).ends_with("Torch"):
			torch_count += 1
			torch_positions.append(at)
			assert_eq(model, "Torch_Metal", "the fork uses the established physical torch")
			assert_true(ResourceLoader.exists("res://assets/props/quaternius_fantasy/Torch_Metal.gltf"),
				"the waylight must use the installed fantasy-prop torch")
			assert_eq(str(prop.get("glow", "")), "campfire", "a waylight no longer casts light")
			assert_true(float(prop.get("glow_scale", 99.0)) <= 0.48,
				"a trail waylight became a hillside floodlight")
		elif str(prop.get("name", "")).begins_with("RiseRetaining"):
			retaining_positions.append(at)
			assert_true(model.begins_with("Rock_Medium_"),
				"the retaining edge left the Meadows nature family")
			assert_true(ResourceLoader.exists("%s/%s.gltf" % [str(prop.get("dir", "")), model]),
				"the retaining edge does not use an installed production asset")
			var scale_raw := prop.get("scale_xyz", []) as Array
			assert_eq(scale_raw.size(), 3, "a retaining stone lost its low, elongated profile")
			if scale_raw.size() == 3:
				assert_true(float(scale_raw[0]) >= 0.70 and float(scale_raw[1]) <= 0.7,
					"a retaining stone no longer reads as a low load-bearing edge")
	assert_eq(terrace_segments.size(), 18, "the continuous switchback surface survives")
	assert_eq(tread_positions.size(), 19, "eighteen terrace segments share nineteen route joints")
	assert_eq(retaining_positions.size(), 12, "the broad route loses its broken dry-stone retaining rhythm")
	assert_eq(torch_count, 3, "the trail keeps only its start-turn-arrival waylights")
	var player_radius := _production_player_radius()
	assert_true(player_radius < INF, "the production Player capsule radius cannot be resolved")
	for torch_at: Vector2 in torch_positions:
		var nearest_tread := INF
		for tread_at: Vector2 in tread_positions:
			nearest_tread = minf(nearest_tread, torch_at.distance_to(tread_at))
		assert_true(nearest_tread >= 2.5 and nearest_tread <= 4.5,
			"a waylight either blocks the walking line or has disconnected from it")
	var road_end := Vector2(74.0, -41.0)
	var hero := Vector2(99.5, -55.0)
	assert_true(tread_positions[0].distance_to(road_end) <= 3.0,
		"the first tread disconnected from the authored safe road end")
	assert_true(tread_positions[tread_positions.size() - 1].distance_to(hero) <= 6.0,
		"the last tread disconnected from the retained crown")
	for index in terrace_segments.size() - 1:
		var current_to := (terrace_segments[index].get("to", []) as Array)
		var next_from := (terrace_segments[index + 1].get("from", []) as Array)
		assert_true(Vector2(float(current_to[0]), float(current_to[1])).is_equal_approx(
			Vector2(float(next_from[0]), float(next_from[1]))),
			"the physical terrace opens a gap at joint %d" % index)
	for raw: Variant in props:
		var retaining := raw as Dictionary
		if not str(retaining.get("name", "")).begins_with("RiseRetaining"):
			continue
		var collider := _resolved_prop_collider(retaining)
		assert_false(collider.is_empty(), "a retaining stone's production collider bounds cannot be resolved")
		if collider.is_empty():
			continue
		var clearance := _distance_to_polyline(collider.centre, tread_positions) \
			- float(collider.circumscribed_radius)
		assert_true(clearance >= player_radius + COLLISION_CLEARANCE_MARGIN_M,
			"%s's complete scaled collider leaves only %.2fm from route centre" % [
				str(retaining.get("name", "retaining stone")), clearance])
		assert_true(_distance_to_polyline(collider.centre, tread_positions) <= 5.5,
			"a retaining stone disconnected visually from the switchback terrace")
	# A real switchback changes travel bearing at the lower terrace instead of
	# drawing one implausible line straight up the impassable west face.
	assert_true(tread_positions[11].y < tread_positions[5].y - 10.0,
		"the route no longer reaches the lower contour before turning uphill")
	assert_true(tread_positions[18].y > tread_positions[11].y + 15.0,
		"the switchback never returns from the lower contour to the crown")


func test_grounded_terrace_source_builds_one_matching_visible_and_collision_box() -> void:
	var source := _source(PROPS_SOURCE_PATH)
	assert_true(source.contains("func _place_walkable_segment")
		and source.contains("var from_ground := _ground_height")
		and source.contains("var to_ground := _ground_height"),
		"the terrace is not grounded from both production endpoints")
	assert_true(source.contains("_walkable_joint_heights")
		and source.contains("max_slope_deg")
		and source.contains("max_vertical_delta"),
		"R10 must carry installed joint heights and cap the actual ramp grade")
	assert_true(source.contains("has_incoming_segment")
		and source.contains("entry_clearance_m")
		and source.contains("physical_from")
		and source.contains("physical_to"),
		"R10 must keep the next segment's leading wall beyond the supported joint")
	assert_true(source.contains("var mesh := BoxMesh.new()")
		and source.contains("var box := BoxShape3D.new()")
		and source.contains("body.transform = mesh_instance.transform")
		and source.contains("box.size = box_size"),
		"visible terrace and honest collision no longer share exact geometry")
	assert_false(source.contains("emission_enabled"),
		"the grounded tread must not smuggle in emissive night lighting")


func test_grounded_terrace_instantiates_matching_geometry_at_both_ground_endpoints() -> void:
	var world := RiseGroundStub.new()
	var into := Node3D.new()
	world.add_child(into)
	var placer := PROPS_SCRIPT.new()
	world.add_child(placer)
	var spec := (_trail_cluster().get("props", []) as Array)[0] as Dictionary
	placer.place(into, spec)
	var visual := into.get_node_or_null(^"RiseTrailRoadEndTread") as MeshInstance3D
	var body := into.get_node_or_null(^"RiseTrailRoadEndTread_Collision") as StaticBody3D
	assert_true(visual != null and visual.mesh is BoxMesh,
		"the production placer did not build the authored terrace mesh")
	assert_true(body != null, "the authored terrace has no production StaticBody")
	var collision: CollisionShape3D = null
	if body != null:
		collision = body.get_child(0) as CollisionShape3D
	assert_true(collision != null and collision.shape is BoxShape3D,
		"the authored terrace has no matching BoxShape collision")
	if visual != null and body != null and collision != null:
		var mesh := visual.mesh as BoxMesh
		var box := collision.shape as BoxShape3D
		assert_eq(mesh.size, box.size, "visible and colliding terrace extents diverged")
		assert_eq(visual.transform, body.transform, "visible and colliding terrace transforms diverged")
		var segment := spec.get("walkable_segment", {}) as Dictionary
		var from_raw := segment.get("from", []) as Array
		var to_raw := segment.get("to", []) as Array
		var from_xz := Vector2(float(from_raw[0]), float(from_raw[1]))
		var to_xz := Vector2(float(to_raw[0]), float(to_raw[1]))
		var from_top := Vector3(from_xz.x, world.ground_height_at(from_xz.x, from_xz.y) + 0.10, from_xz.y)
		var to_top := Vector3(to_xz.x, world.ground_height_at(to_xz.x, to_xz.y) + 0.10, to_xz.y)
		# R10 shifts the shared box centre toward its exit so the overlap cannot put
		# the next segment's leading wall across this tread. Recover the authored
		# ground endpoints through the same physical interval instead of assuming a
		# pre-R10 centred box with no exit overlap.
		var built_from := _built_surface_endpoint(visual, spec, false, 0.0)
		var built_to := _built_surface_endpoint(visual, spec, true, 0.0)
		assert_true(built_from.distance_to(from_top) <= 0.001,
			"the road-end terrace does not meet production ground at its start")
		assert_true(built_to.distance_to(to_top) <= 0.001,
			"the road-end terrace does not meet production ground at its end")
	world.free()


func test_r10_lower_joint_uses_actual_matching_transforms_and_floor_grade() -> void:
	var world := RiseLowerJointCliffStub.new()
	var into := Node3D.new()
	world.add_child(into)
	var placer := PROPS_SCRIPT.new()
	world.add_child(placer)
	# C has an incoming segment in production. Install B first so the source uses
	# C's real entry clearance and carried joint height; starting directly at C
	# would correctly suppress that clearance and make the fixture's later math
	# describe a different transform than the one it instantiated.
	placer.place(into, _trail_prop_named("RiseTrailDescentTreadB"))
	var names := ["RiseTrailDescentTreadC", "RiseTrailDescentTreadD", "RiseTrailForkTread"]
	var prior_end := Vector3.ZERO
	var prior_box_end := Vector3.ZERO
	for index in names.size():
		var spec := _trail_prop_named(names[index])
		assert_false(spec.is_empty(), "%s remains authored" % names[index])
		placer.place(into, spec)
		var visual := into.get_node_or_null(NodePath(names[index])) as MeshInstance3D
		var body := into.get_node_or_null(NodePath("%s_Collision" % names[index])) as StaticBody3D
		assert_true(visual != null and body != null, "%s instantiates visible and collision geometry" % names[index])
		if visual == null or body == null:
			continue
		var collision := body.get_child(0) as CollisionShape3D
		assert_true(collision != null and collision.shape is BoxShape3D,
			"%s keeps a real box collider" % names[index])
		if collision == null or not collision.shape is BoxShape3D:
			continue
		assert_eq(visual.transform, body.transform,
			"%s collision no longer matches its visible terrace" % names[index])
		assert_eq((visual.mesh as BoxMesh).size, (collision.shape as BoxShape3D).size,
			"%s visible/collision extents diverged" % names[index])
		var actual_grade := rad_to_deg(asin(absf(visual.transform.basis.z.y)))
		assert_true(actual_grade <= 28.01,
			"%s actual installed slope %.2f exceeds player-safe grade" % [names[index], actual_grade])
		var segment := spec.get("walkable_segment", {}) as Dictionary
		var entry_clearance := float(segment.get("entry_clearance_m", 0.0))
		var built_start := _built_surface_endpoint(visual, spec, false, entry_clearance)
		var built_end := _built_surface_endpoint(visual, spec, true, entry_clearance)
		var box_start := _built_box_edge(visual, false)
		var box_end := _built_box_edge(visual, true)
		if index > 0:
			assert_true(built_start.distance_to(prior_end) <= 0.002,
				"lower Rise terrace opens a physical 3D joint before %s" % names[index])
			assert_true(box_start.distance_to(built_start) >= 0.40,
				"%s leading collision wall still reaches backward to the authored joint" % names[index])
			assert_true(prior_box_end.distance_to(prior_end) >= 0.84,
				"the incoming terrace no longer supports the leading-wall clearance")
		prior_end = built_end
		prior_box_end = box_end
	world.free()


func test_crown_arrival_has_a_real_outward_overlook_payoff() -> void:
	var cluster := _overlook_cluster()
	assert_false(cluster.is_empty(), "The Rise crown has no authored overlook payoff")
	assert_eq(int(cluster.get("order", -1)), 1056, "the overlook keeps its reserved band order")
	var props := cluster.get("props", []) as Array
	assert_eq(props.size(), 5, "the overlook remains one restrained five-piece pause")
	var names := {}
	for raw: Variant in props:
		var prop := raw as Dictionary
		names[str(prop.get("name", ""))] = true
		var at_raw := prop.get("at", []) as Array
		var at := Vector2(float(at_raw[0]), float(at_raw[1]))
		assert_true(at.distance_to(Vector2(99.5, -55.0)) <= 10.0,
			"%s disconnected from the retained crown" % str(prop.get("name", "prop")))
		assert_false(prop.has("glow"), "the summit payoff must not invent another beacon light")
	assert_true(names.has("RiseOverlookBench") and names.has("RiseOverlookCairnLeft") \
		and names.has("RiseOverlookCairnRight"),
		"the outward-facing bench and asymmetric vista frame must survive")
	var bench := props[0] as Dictionary
	assert_eq(str(bench.get("model", "")), "Bench", "the overlook loses its legible pause subject")
	assert_true(float(bench.get("yaw_deg", 0.0)) >= 45.0 and float(bench.get("yaw_deg", 0.0)) <= 70.0,
		"the bench has turned back into the slope instead of facing the village country")


func test_r11_all_uphill_joints_keep_the_leading_collision_wall_off_the_route() -> void:
	var names := ["RiseTrailShelfTreadA", "RiseTrailShelfTreadB",
		"RiseTrailShelfTreadC", "RiseTrailShelfTreadD", "RiseTrailShelfTreadE",
		"RiseTrailSwitchbackTread", "RiseTrailReturnTreadA",
		"RiseTrailReturnTreadB", "RiseTrailReturnTreadC",
		"RiseTrailReturnTreadD", "RiseTrailCrownTreadA", "RiseTrailCrownTread"]
	for name: String in names:
		var segment := _trail_prop_named(name).get("walkable_segment", {}) as Dictionary
		assert_true(float(segment.get("overlap_m", 0.0)) >= 1.0,
			"%s no longer supports the next uphill joint" % name)
		assert_true(float(segment.get("entry_clearance_m", 0.0)) >= 0.42,
			"%s put its leading collision wall back across the player route" % name)
		assert_true(float(segment.get("max_slope_deg", 99.0)) <= 28.0,
			"%s exceeds the player-safe installed grade" % name)


func test_r11_capture_proves_the_grounded_switchback_and_outward_overlook_without_injected_light() -> void:
	var source := _source(CAPTURE_PATH)
	assert_true(source.contains("THE-RISE-IDENTITY-R11")
		and source.contains("FRESH_OUTPUT.create_fresh")
		and source.contains("records.size() == VIEWS.size() * 2"),
		"R11 must write a fresh, complete day/night evidence set")
	for frame_name: String in ["01-road-climb-approach", "02-road-end-trailhead",
			"03-full-switchback-climb", "04-crown-overlook"]:
		assert_true(source.contains(frame_name), "R11 lost distinct composition %s" % frame_name)
	assert_true(source.contains("No scene content, light, material, pose or progression is injected")
		and source.contains("the_rise_cairn_trail/RiseTrailForkTorch")
		and source.contains("the_rise_overlook/RiseOverlookBench")
		and source.contains("target_xz\": [20.0, -5.0]")
		and source.contains("composition_role")
		and source.contains("day frame is not brighter than its matched night frame"),
		"the evidence must disclose and receipt production-only night readability")
	assert_true(source.contains("_prove_player_route")
		and source.contains("move_and_slide()")
		and source.contains("traversal_receipt")
		and source.contains("PLAYER_ROUTE")
		and source.contains("grounded_ratio")
		and source.contains("stalled before waypoint")
		and source.contains("if not bool(traversal_receipt.get(\"passed\", false))"),
		"R11 must fail closed unless one continuous real CharacterBody walk completes")
