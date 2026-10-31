extends Node3D

## F39 P2-011 candidate under the OFF Tidewake look gate: named destinations
## that read as bare slopes gain their reference-backed building
## (`landmark_models` in tidewake_look.json; Meshy assets with provenance
## beside each GLB). Each model is fitted to its authored height, grounded at
## the lowest point under its footprint and keeps an optional box collider
## inside that footprint. No interaction, route, encounter or durable state.

const RENDER_BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const GRASS_FIELD := preload("res://scripts/world/grass_field.gd")


func build(water_world: Node3D) -> void:
	if bool(water_world.get("simulation_only")):
		return
	var look := preload("res://scripts/world/tidewake_look_profile.gd").settings()
	if not bool(look.get("enabled", false)):
		return
	var landmarks := {}
	for raw: Variant in (water_world.get("config") as Dictionary).get("landmarks", []):
		landmarks[str((raw as Dictionary).get("id", ""))] = raw
	# `landmark_props_candidate` (judged, ON) and `veilfall_hero_candidate`
	# (unjudged, OFF in play) add props by absolute `position_xz_m` as well as
	# by landmark offset.
	var specs: Array = (look.get("landmark_models", []) as Array) + (look.get("landmark_props_candidate", []) as Array) \
		+ (look.get("veilfall_hero_candidate", []) as Array) + (look.get("veilfall_facade_candidate", []) as Array) \
		+ (look.get("veilfall_mountain_candidate", []) as Array) + (look.get("veilfall_buttress_candidate", []) as Array) \
		+ _destinations(look) + (look.get("lesson_clusters_candidate", []) as Array) \
		+ (look.get("beach_scene_candidate", []) as Array)
	_cladding(water_world, look.get("veilfall_cladding_candidate", {}))
	# `first_shore_declutter_candidate` (OFF in play) drops named props by id.
	var dropped: Array = ((look.get("first_shore_declutter_candidate", {}) as Dictionary).get("drop_landmark_props", []) as Array) \
		+ ((look.get("beach_declutter_candidate", {}) as Dictionary).get("drop_landmark_props", []) as Array)
	for raw: Variant in specs:
		var spec := raw as Dictionary
		if dropped.has(str(spec.get("id", ""))):
			continue
		var landmark: Dictionary = landmarks.get(str(spec.get("landmark_id", "")), {})
		var at_raw: Array = landmark.get("position", [])
		if spec.has("position_xz_m"):
			var placed: Array = spec.position_xz_m
			at_raw = [float(placed[0]), 0.0, float(placed[1])]
		if at_raw.size() < 3:
			push_warning("landmark model has no authored landmark: %s" % spec.get("landmark_id", ""))
			continue
		var offset: Array = spec.get("offset_xz_m", [0.0, 0.0])
		var at := Vector2(float(at_raw[0]) + float(offset[0]), float(at_raw[2]) + float(offset[1]))
		# A model-less entry is a clearing only: clean sand where the camera looks.
		if str(spec.get("model", "")).is_empty() and float(spec.get("grass_clear_m", 0.0)) > 0.0:
			var clearing := Node3D.new()
			clearing.name = "Clearing_%s" % str(spec.get("id", "site"))
			clearing.position = Vector3(at.x, 0.0, at.y)
			clearing.add_to_group("grass_clear")
			clearing.set_meta("grass_clear_radius", float(spec.grass_clear_m))
			add_child(clearing)
			GRASS_FIELD.clearings_dirty = true
			continue
		var model := _instantiate(str(spec.get("model", "")))
		if model == null:
			push_error("landmark model missing: %s" % spec.get("model", ""))
			continue
		_apply_surfaces(model, spec.get("surfaces", []))
		var bounds := RENDER_BOUNDS.measure(model)
		if bounds.size.y <= 0.001:
			model.free()
			continue
		var factor := float(spec.get("height_m", 5.0)) / bounds.size.y
		var holder := Node3D.new()
		holder.name = "Landmark_%s" % str(spec.get("landmark_id", spec.get("id", "prop")))
		# Optional `stretch_xz` widens a fitted model without changing its height
		# (close-1024: the generated Veilfall crown is narrower than the cone).
		var stretch: Array = spec.get("stretch_xz", [1.0, 1.0])
		var sx := float(stretch[0])
		var sz := float(stretch[1])
		model.scale = Vector3(factor * sx, factor, factor * sz)
		model.position = -Vector3(bounds.get_center().x * sx, bounds.position.y, bounds.get_center().z * sz) * factor
		holder.add_child(model)
		var yaw := deg_to_rad(float(spec.get("yaw_deg", 0.0)))
		var half := Vector2(bounds.size.x * sx, bounds.size.z * sz) * factor * 0.5
		holder.rotation.y = yaw
		# `lift_m` raises a piece set into a steep slope, where the lowest footprint
		# point would bury most of it (close-1024 vf2, the upper Veilfall tier).
		holder.position = Vector3(at.x, _floor(water_world, at, yaw, half) - float(spec.get("sink_m", 0.15))
			+ float(spec.get("lift_m", 0.0)), at.y)
		# `float_y_m` seats a moored boat on the sea surface instead of the seabed.
		if spec.has("float_y_m"):
			holder.position.y = float(spec.float_y_m)
		add_child(holder)
		# `grass_clear_m` (beach_scene_candidate): the field's grass and loose
		# stones step back from a placed building, so it stands on clean sand
		# instead of a pebble-and-tuft carpet (grass_field.gd CLEAR_GROUP).
		if float(spec.get("grass_clear_m", 0.0)) > 0.0:
			holder.add_to_group("grass_clear")
			holder.set_meta("grass_clear_radius", float(spec.grass_clear_m))
			GRASS_FIELD.clearings_dirty = true
		var box: Array = spec.get("collider_fraction", [])
		if box.size() == 3:
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var size := Vector3(half.x * 2.0 * float(box[0]), float(spec.get("height_m", 5.0)) * float(box[1]),
				half.y * 2.0 * float(box[2]))
			shape.shape = BoxShape3D.new()
			(shape.shape as BoxShape3D).size = size
			shape.position = Vector3(0.0, size.y * 0.5, 0.0)
			body.add_child(shape)
			holder.add_child(body)
		# `trimesh_collider`: collision that matches the drawn mesh, for pieces a
		# flyer or glider can reach (close-1024: the generated Veilfall crown).
		if bool(spec.get("trimesh_collider", false)):
			add_trimesh_collision(model)


## `veilfall_cladding_candidate` (OFF in play; Stormwood lane 26 Oct, after the
## vf3 judges named "giant stretched faceted terrain slabs" in the Veilfall
## gully): instead of one facade pasted mid-slab, many staggered facade pieces
## lie flat on every steep face in the gully, each aligned to the terrain
## normal, varied in size and roll from a fixed seed, kept off the hike and the
## cascade. One MultiMesh per facade surface; presentation only, no collider
## (only faces too steep to walk are clad).
func _cladding(world: Node3D, cfg: Dictionary) -> void:
	if cfg.is_empty():
		return
	var template := _instantiate(str(cfg.get("model", "")))
	if template == null:
		return
	var bounds := RENDER_BOUNDS.measure(template)
	if bounds.size.x <= 0.001:
		template.free()
		return
	var spine: Array[Vector2] = []
	for route: Dictionary in (world.get("config") as Dictionary).get("land_routes", []):
		if str(route.get("id", "")) == str(cfg.get("clear_route", "veilfall_exploration_spine")):
			for point: Array in route.get("polyline", []):
				spine.append(Vector2(float(point[0]), float(point[2])))
	var excludes: Array = cfg.get("exclude", [])
	var centre := Vector2(float(cfg.area_centre[0]), float(cfg.area_centre[1]))
	var radius := float(cfg.get("area_radius_m", 100.0))
	var cell := float(cfg.get("cell_m", 20.0))
	var size_range: Array = cfg.get("width_m", [22.0, 34.0])
	var max_up := float(cfg.get("max_normal_y", 0.7))
	var clear := float(cfg.get("route_clear_m", 12.0))
	var sink := float(cfg.get("sink_m", 1.5))
	var roll := deg_to_rad(float(cfg.get("roll_jitter_deg", 12.0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.get("seed", 39))
	# Seat on what is drawn and collides (coordinator, 26 Oct): the gully's
	# faceted slabs are collision-bearing pieces over the heightfield, so a
	# height-and-gradient seat left the cl1/cl2 pieces floating as shelves.
	# Wait for the physics space to see every static body first.
	var raycast := str(cfg.get("seat", "raycast")) == "raycast"
	var space: PhysicsDirectSpaceState3D = null
	if raycast:
		for _frame in 3:
			await get_tree().physics_frame
		if not is_inside_tree():
			template.free()
			return
		space = get_world_3d().direct_space_state
	var poses: Array[Transform3D] = []
	var steps := int(ceil(radius / cell))
	for gx in range(-steps, steps + 1):
		for gz in range(-steps, steps + 1):
			var at := centre + Vector2(gx, gz) * cell + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)) * cell
			var width := rng.randf_range(float(size_range[0]), float(size_range[1]))
			var twist := rng.randf_range(-roll, roll)
			if at.distance_to(centre) > radius:
				continue
			var blocked := false
			for index in spine.size() - 1:
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at, spine[index], spine[index + 1])) < clear:
					blocked = true
			for raw: Variant in excludes:
				var ex: Array = raw
				if at.distance_to(Vector2(float(ex[0]), float(ex[1]))) < float(ex[2]):
					blocked = true
			if blocked:
				continue
			var y := float(world.call("ground_height_at", at.x, at.y))
			if not is_finite(y):
				continue
			var normal := Vector3.UP
			if space != null:
				var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, y + float(cfg.get("ray_above_m", 200.0)), at.y),
					Vector3(at.x, y - 5.0, at.y))
				query.collide_with_areas = false
				var hit := space.intersect_ray(query)
				if hit.is_empty():
					continue
				y = (hit.position as Vector3).y
				normal = (hit.normal as Vector3).normalized()
			else:
				# The slope under the whole piece, not a 2 m sample: a local
				# normal left wide pieces floating off the face (cl1 preview).
				var d := maxf(2.0, width * float(cfg.get("normal_span", 0.35)))
				normal = Vector3(
					float(world.call("ground_height_at", at.x - d, at.y)) - float(world.call("ground_height_at", at.x + d, at.y)),
					2.0 * d,
					float(world.call("ground_height_at", at.x, at.y - d)) - float(world.call("ground_height_at", at.x, at.y + d))).normalized()
			if y < float(cfg.get("min_height_m", 4.0)) or not normal.is_finite() or normal.y > max_up:
				continue
			# The facade's front (+Z) faces out of the slope; its up runs up the face.
			var up := (Vector3.UP - normal * normal.dot(Vector3.UP)).normalized()
			var basis := Basis(up.cross(normal).normalized(), up, normal).rotated(normal, twist)
			# Only where the face is flat under the whole piece: at a crest a
			# flat piece follows one facet and overhangs the other (cl4).
			if space != null:
				var centre3 := Vector3(at.x, y, at.y)
				var half_w := width * 0.5
				var half_h := width * bounds.size.y / bounds.size.x * 0.5
				var flat := true
				for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
					var p := centre3 + basis.x * corner.x * half_w + basis.y * corner.y * half_h
					var probe := PhysicsRayQueryParameters3D.create(p + normal * 30.0, p - normal * 30.0)
					probe.collide_with_areas = false
					var touch := space.intersect_ray(probe)
					if touch.is_empty() or absf(((touch.position as Vector3) - centre3).dot(normal)) > float(cfg.get("flat_tolerance_m", 1.5)):
						flat = false
						break
				if not flat:
					continue
			# The facade is 35% as deep as it is wide: laid on a slope at full
			# depth a 20 m piece stood ~7 m proud as a shelf (cl1-cl3). Squash
			# its depth and sink most of what is left, so only the relief shows.
			var factor := width / bounds.size.x
			var squash := float(cfg.get("depth_scale", 0.4))
			var fit := Transform3D(Basis.from_scale(Vector3(factor, factor, factor * squash)),
				-Vector3(bounds.get_center().x * factor, bounds.get_center().y * factor, bounds.position.z * factor * squash))
			var proud := bounds.size.z * factor * squash
			poses.append(Transform3D(basis, Vector3(at.x, y, at.y) - normal * (sink + proud * float(cfg.get("sink_fraction", 0.6)))) * fit)
	if poses.is_empty():
		template.free()
		return
	var tint := Color(str(cfg.get("tint", "#ffffff")))
	var root := Node3D.new()
	root.name = "VeilfallCladding"
	add_child(root)
	for visual: MeshInstance3D in template.find_children("*", "MeshInstance3D", true, false):
		var mesh := visual.mesh.duplicate() as Mesh
		for surface in mesh.get_surface_count():
			var source := visual.get_active_material(surface) as BaseMaterial3D
			if source != null and tint != Color.WHITE:
				var tinted := source.duplicate() as BaseMaterial3D
				tinted.albedo_color = source.albedo_color * tint
				mesh.surface_set_material(surface, tinted)
		var local := Transform3D.IDENTITY
		var node: Node = visual
		while node != null and node != template:
			if node is Node3D:
				local = (node as Node3D).transform * local
			node = node.get_parent()
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh
		multi.instance_count = poses.size()
		for index in poses.size():
			multi.set_instance_transform(index, poses[index] * local)
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multi
		root.add_child(batch)
	template.free()


## `destination_landmarks_s3_candidate` (OFF in play) re-seats and adds to the
## lm2 destination pieces: its entries replace lm2's by landmark_id. The s4
## and s5 layers stack on it in that order.
static func _destinations(look: Dictionary) -> Array:
	var base: Array = look.get("destination_landmarks_candidate", [])
	var s3: Array = (look.get("destination_landmarks_s3_candidate", []) as Array) \
		+ (look.get("destination_landmarks_s4_candidate", []) as Array) \
		+ (look.get("destination_landmarks_s5_candidate", []) as Array)
	if s3.is_empty():
		return base
	var replaced: Array = []
	for raw: Variant in s3:
		replaced.append(str((raw as Dictionary).get("landmark_id", "")))
	var merged: Array = []
	for raw: Variant in base:
		if not replaced.has(str((raw as Dictionary).get("landmark_id", ""))):
			merged.append(raw)
	# A later entry with the same landmark_id (s4 over s3) wins.
	var last: Dictionary = {}
	for index in s3.size():
		var id := str((s3[index] as Dictionary).get("landmark_id", ""))
		if not id.is_empty():
			last[id] = index
	for index in s3.size():
		var id := str((s3[index] as Dictionary).get("landmark_id", ""))
		if id.is_empty() or int(last[id]) == index:
			merged.append(s3[index])
	return merged


## Optional per-surface materials, by surface index (the installed castle kit's
## .obj meshes import as flat grey): {texture, tint, uv_scale} as a triplanar
## world-scaled material, so a fitted model keeps its grain at any height.
func _apply_surfaces(node: Node, surfaces: Array) -> void:
	if surfaces.is_empty():
		return
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := node as MeshInstance3D
		for index in mesh.mesh.get_surface_count():
			var cfg: Dictionary = surfaces[mini(index, surfaces.size() - 1)]
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(str(cfg.get("tint", "#ffffff")))
			material.roughness = float(cfg.get("roughness", 0.9))
			var texture_path := str(cfg.get("texture", ""))
			if not texture_path.is_empty():
				material.albedo_texture = load(texture_path)
				material.uv1_triplanar = true
				material.uv1_world_triplanar = true
				material.uv1_scale = Vector3.ONE * float(cfg.get("uv_scale", 0.5))
			mesh.set_surface_override_material(index, material)
	for child in node.get_children():
		_apply_surfaces(child, surfaces)


## A scene, or a bare mesh (the installed castle kit ships .obj meshes).
func _instantiate(path: String) -> Node3D:
	var resource := load(path)
	if resource is PackedScene:
		return (resource as PackedScene).instantiate() as Node3D
	if resource is Mesh:
		var instance := MeshInstance3D.new()
		instance.mesh = resource
		return instance
	return null


## Lowest terrain under the rotated footprint, so no corner floats.
func _floor(world: Node3D, centre: Vector2, yaw: float, half: Vector2) -> float:
	var right := Vector2(cos(yaw), -sin(yaw))
	var back := Vector2(sin(yaw), cos(yaw))
	var low := INF
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var p := centre + right * half.x * u + back * half.y * v
			var y := float(world.call("ground_height_at", p.x, p.y))
			if is_finite(y):
				low = minf(low, y)
	return low if is_finite(low) else 0.0


## One static trimesh body per drawn mesh, in the mesh's own transform, so the
## collision follows exactly what is rendered. Returns the bodies it added.
static func add_trimesh_collision(root: Node) -> Array:
	var bodies: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
			var shape := (node as MeshInstance3D).mesh.create_trimesh_shape()
			if shape == null:
				continue
			var body := StaticBody3D.new()
			body.name = "TrimeshCollision"
			var collider := CollisionShape3D.new()
			collider.shape = shape
			body.add_child(collider)
			node.add_child(body)
			bodies.append(body)
	return bodies
