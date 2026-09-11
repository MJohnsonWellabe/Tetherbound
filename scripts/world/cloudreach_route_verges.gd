extends Node3D

## CLOUDREACH-ROUTE-ECOLOGY-R1-0911. A collisionless, batched mid-distance
## layer for the long grounded journeys between Cloudreach landmarks. The
## world builder continues to own every route, shoulder, encounter and
## coordinate; this pass derives stations from those authored polylines and
## asks the existing route-support query for the final ground height.

const GRASS_WIDE := preload("res://assets/environment/stylized_nature/Grass_Wide_Tall.gltf")
const GRASS_WISPY := preload("res://assets/environment/stylized_nature/Grass_Wispy_Tall.gltf")
const BUSH := preload("res://assets/environment/stylized_nature/Bush_Common.gltf")
const FLOWERS := preload("res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf")
const SCREE: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/RockPath_Round_Small_1.gltf"),
	preload("res://assets/environment/stylized_nature/RockPath_Round_Small_2.gltf"),
]

var _route_count := 0
var _station_count := 0
var _plant_count := 0
var _stone_count := 0


## Pure authored-data plan used by the focused test. Long routes are sampled
## evenly down to max_stations_per_route rather than filled from one end, so
## the bounded budget reaches the whole journey and every grounded route.
static func route_verge_plan(routes: Array, cfg: Dictionary) -> Array[Dictionary]:
	if not bool(cfg.get("enabled", true)):
		return []
	var spacing := maxf(12.0, float(cfg.get("station_spacing_m", 48.0)))
	var margin := maxf(0.0, float(cfg.get("end_margin_m", 14.0)))
	var per_route_cap := maxi(1, int(cfg.get("max_stations_per_route", 16)))
	var plan: Array[Dictionary] = []
	for route_raw: Variant in routes:
		if not route_raw is Dictionary:
			continue
		var route := route_raw as Dictionary
		if str(route.get("traversal_mode", "ground")) != "ground":
			continue
		var points: Array = route.get("polyline", [])
		if points.size() < 2:
			continue
		var candidates: Array[Dictionary] = []
		for segment_index in points.size() - 1:
			var a := _vec3(points[segment_index])
			var b := _vec3(points[segment_index + 1])
			var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
			var length := flat.length()
			if length < 0.1:
				continue
			var usable := maxf(0.0, length - margin * 2.0)
			var count := maxi(1, int(ceilf(usable / spacing)))
			for sample_index in count:
				var along := length * 0.5
				if usable > 0.0:
					along = margin + usable * (float(sample_index) + 0.5) / float(count)
				var t := clampf(along / length, 0.0, 1.0)
				var forward := flat / length
				candidates.append({
					"route_id": str(route.get("id", "route")),
					"segment_index": segment_index,
					"centre": a.lerp(b, t),
					"forward": forward,
					"right": Vector3.UP.cross(forward).normalized(),
					"path_half_width": float(cfg.get("path_half_width_m", 2.1)),
				})
		if candidates.size() <= per_route_cap:
			plan.append_array(candidates)
			continue
		for selected_index in per_route_cap:
			var source_index := mini(candidates.size() - 1,
				int(floor((float(selected_index) + 0.5) * candidates.size() / per_route_cap)))
			plan.append(candidates[source_index])
	return plan


func build(world: Node3D, routes: Array, cfg: Dictionary) -> void:
	var plan := route_verge_plan(routes, cfg)
	if plan.is_empty():
		return
	var route_ids := {}
	var seed := int(cfg.get("seed", 20260911))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var buckets := {
		"GrassWide": [], "GrassWispy": [], "Bush": [], "Flowers": [],
		"ScreeA": [], "ScreeB": [],
	}
	var meshes := {
		"GrassWide": _prepared_mesh(world, GRASS_WIDE, false, seed),
		"GrassWispy": _prepared_mesh(world, GRASS_WISPY, false, seed + 1),
		"Bush": _prepared_mesh(world, BUSH, true, seed + 2),
		"Flowers": _prepared_mesh(world, FLOWERS, true, seed + 3),
		"ScreeA": _prepared_mesh(world, SCREE[0], false, seed + 4, true),
		"ScreeB": _prepared_mesh(world, SCREE[1], false, seed + 5, true),
	}
	var clearance := float(cfg.get("path_clearance_m", 1.2))
	var near_offset := float(cfg.get("near_offset_m", 2.1))
	var outer_offset := float(cfg.get("outer_offset_m", 4.7))
	var lateral_jitter := float(cfg.get("verge_jitter_m", 0.8))
	var grass_range := _float_range(cfg.get("grass_scale", [0.85, 1.25]), 0.85, 1.25)
	var bush_range := _float_range(cfg.get("bush_scale", [0.72, 1.08]), 0.72, 1.08)
	var flower_range := _float_range(cfg.get("flower_scale", [0.58, 0.88]), 0.58, 0.88)
	var stone_range := _float_range(cfg.get("stone_scale", [0.85, 1.45]), 0.85, 1.45)
	var embed_range := _float_range(cfg.get("stone_embed_m", [0.24, 0.48]), 0.24, 0.48)

	for station_index in plan.size():
		var station: Dictionary = plan[station_index]
		route_ids[station["route_id"]] = true
		var centre: Vector3 = station["centre"]
		var forward: Vector3 = station["forward"]
		var right: Vector3 = station["right"]
		var path_half := float(station["path_half_width"])
		var station_used := false
		for side_value: float in [-1.0, 1.0]:
			var side_seed := station_index * 2 + (0 if side_value < 0.0 else 1)
			var along_jitter := rng.randf_range(-3.2, 3.2)
			var near_distance := path_half + clearance + near_offset \
				+ rng.randf_range(-lateral_jitter, lateral_jitter)
			var near_guess := centre + forward * along_jitter + right * side_value * near_distance
			var near_ground := _supported_ground(world, near_guess)
			if not is_nan(near_ground):
				var near_at := Vector3(near_guess.x, near_ground + 0.03, near_guess.z)
				if not bool(world.call("_inside_settlement_clearance", near_at)):
					station_used = true
					for grass_index in 3:
						var grass_at := near_at + forward * (float(grass_index) - 1.0) * 1.55 \
							+ right * side_value * rng.randf_range(-0.65, 0.65)
						var grass_ground := _supported_ground(world, grass_at)
						if is_nan(grass_ground):
							continue
						grass_at.y = grass_ground + 0.025
						var grass_scale := rng.randf_range(grass_range.x, grass_range.y)
						var grass_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
							Vector3(grass_scale * 1.35, grass_scale, grass_scale * 1.35))
						var grass_key := "GrassWide" if (grass_index + side_seed) % 2 == 0 else "GrassWispy"
						(buckets[grass_key] as Array).append(Transform3D(grass_basis, grass_at))
						_plant_count += 1
					var accent_key := "Bush" if side_seed % 3 != 0 else "Flowers"
					var accent_scale_range := bush_range if accent_key == "Bush" else flower_range
					var accent_scale := rng.randf_range(accent_scale_range.x, accent_scale_range.y)
					var accent_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3.ONE * accent_scale)
					var accent_at := near_at + forward * rng.randf_range(-2.2, 2.2)
					var accent_ground := _supported_ground(world, accent_at)
					if not is_nan(accent_ground):
						accent_at.y = accent_ground + 0.02
						(buckets[accent_key] as Array).append(Transform3D(accent_basis, accent_at))
						_plant_count += 1

			var outer_distance := path_half + clearance + outer_offset \
				+ rng.randf_range(-lateral_jitter * 0.5, lateral_jitter * 0.5)
			var outer_guess := centre + forward * rng.randf_range(-4.0, 4.0) \
				+ right * side_value * outer_distance
			var outer_ground := _supported_ground(world, outer_guess)
			if not is_nan(outer_ground):
				var outer_at := Vector3(outer_guess.x,
					outer_ground - rng.randf_range(embed_range.x, embed_range.y), outer_guess.z)
				if not bool(world.call("_inside_settlement_clearance", outer_at)):
					station_used = true
					var stone_scale := rng.randf_range(stone_range.x, stone_range.y)
					var stone_basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(
						Vector3(stone_scale * 1.15, stone_scale * 0.72, stone_scale))
					var stone_key := "ScreeA" if side_seed % 2 == 0 else "ScreeB"
					(buckets[stone_key] as Array).append(Transform3D(stone_basis, outer_at))
					_stone_count += 1
		if station_used:
			_station_count += 1

	_route_count = route_ids.size()
	var plant_visibility := float(cfg.get("plant_visibility_m", 520.0))
	var stone_visibility := float(cfg.get("stone_visibility_m", 820.0))
	for key: String in buckets:
		var prepared: Dictionary = meshes[key]
		if prepared.is_empty():
			continue
		_commit_batch(key, buckets[key], prepared, stone_visibility if key.begins_with("Scree") \
			else plant_visibility)


func _supported_ground(world: Node3D, at: Vector3) -> float:
	return float(world.call("_route_detail_ground", at))


func _prepared_mesh(world: Node3D, scene: PackedScene, foliage: bool, palette_seed: int,
		stone: bool = false) -> Dictionary:
	var temp := scene.instantiate() as Node3D
	if foliage:
		world.call("_apply_tree_palette", temp, palette_seed)
	elif stone:
		world.call("apply_stone_palette", temp)
	var mesh_instance: MeshInstance3D = null
	for found: Node in temp.find_children("*", "MeshInstance3D", true, false):
		var candidate := found as MeshInstance3D
		if candidate != null and candidate.mesh != null:
			mesh_instance = candidate
			break
	if mesh_instance == null:
		temp.free()
		return {}
	var mesh_copy := mesh_instance.mesh.duplicate(true) as Mesh
	for surface_index in mesh_copy.get_surface_count():
		var active := mesh_instance.get_active_material(surface_index)
		if active != null:
			mesh_copy.surface_set_material(surface_index, active)
	# Imported scene roots are intentionally never attached to the live world.
	# `global_transform` is invalid before a Node3D enters the SceneTree and was
	# emitting one engine error per prepared asset. Accumulate the imported
	# hierarchy's local transforms instead; this produces the mesh transform
	# relative to `temp` without mutating or mounting the temporary scene.
	var local_transform := mesh_instance.transform
	var cursor := mesh_instance.get_parent()
	while cursor != null and cursor != temp:
		if cursor is Node3D:
			local_transform = (cursor as Node3D).transform * local_transform
		cursor = cursor.get_parent()
	temp.free()
	return {"mesh": mesh_copy, "local_transform": local_transform}


func _commit_batch(label: String, transforms: Array, prepared: Dictionary,
		visibility_range: float) -> void:
	if transforms.is_empty():
		return
	var local_transform: Transform3D = prepared.get("local_transform", Transform3D.IDENTITY)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = prepared["mesh"] as Mesh
	multimesh.instance_count = transforms.size()
	for transform_index in transforms.size():
		multimesh.set_instance_transform(transform_index,
			(transforms[transform_index] as Transform3D) * local_transform)
	var instances := MultiMeshInstance3D.new()
	instances.name = "RouteVerge%s" % label
	instances.multimesh = multimesh
	instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instances.visibility_range_end = visibility_range
	instances.visibility_range_end_margin = minf(80.0, visibility_range * 0.15)
	instances.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	instances.set_meta("cloudreach_route_ecology", true)
	add_child(instances)


static func _float_range(raw: Variant, fallback_min: float, fallback_max: float) -> Vector2:
	if raw is Array and (raw as Array).size() >= 2:
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2(fallback_min, fallback_max)


static func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func route_count() -> int:
	return _route_count


func station_count() -> int:
	return _station_count


func plant_count() -> int:
	return _plant_count


func stone_count() -> int:
	return _stone_count
