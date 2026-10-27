extends RefCounted

## P2-038 preview candidate. Never changes terrain, physics or durable state.
## The feature stays OFF until its separate collision and native proofs close.
const CONFIG := "res://data/config/stormwood_destination_dressing.json"
const TERRAIN_HEIGHT := preload("res://scripts/world/terrain_height.gd")
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")


static func install(world: Node3D, budget: RefCounted) -> void:
	var cfg: Dictionary = _read(CONFIG).get("fallen_giant", {})
	var hero: Dictionary = cfg.get("hero", {})
	if bool(cfg.get("enabled", false)) and bool(hero.get("enabled", false)):
		# The grove's trees inside the log's footprint are cleared on every
		# shell (vegetation.gd clear_area, as the lantern pools do), so host
		# and client agree; only the client draws the log.
		var vegetation := world.get_node_or_null("Vegetation")
		for raw: Variant in hero.get("clear_circles", []):
			var circle: Array = raw
			if vegetation != null and vegetation.has_method("clear_area"):
				var y := float(world.call("ground_height_at", float(circle[0]), float(circle[1])))
				vegetation.call("clear_area", Vector3(float(circle[0]), y, float(circle[1])), float(circle[2]))
		_install_hero(world, hero, not bool(world.get("simulation_only")))
		return
	if bool(world.get("simulation_only")):
		return
	if not bool(cfg.get("enabled", false)):
		return
	var terrain := world.get_node_or_null("Terrain")
	var scene := load(str(cfg.asset)) as PackedScene
	if terrain == null or scene == null:
		push_warning("Fallen Giant candidate: terrain or installed tree unavailable")
		return
	var tree := scene.instantiate() as Node3D
	var samples := PackedVector3Array()
	_collect_samples(tree, Transform3D.IDENTITY, samples)
	var fit := await _fit(terrain, samples, cfg, budget)
	if fit.is_empty():
		tree.free()
		push_warning("Fallen Giant candidate: no supported, clear terrain seat")
		return
	tree.name = "FallenGiantCandidate"
	tree.transform = fit.transform
	tree.set_meta("terrain_fit", fit)
	tree.set_meta("collision_scope_pending", true)
	world.add_child(tree)


## r28 (GPU R verdict: the Fallen Giant stand is 4.6-4.7 with "no change";
## path item 3, a hero landmark): the Meshy fallen giant (tb/meshy-1024
## edd21e2f3, provenance beside the GLB) replaces the installed dead tree,
## lying along `yaw_deg` beside the road with its hollow root end toward the
## approach. Fitted along its long axis, seated on the lowest ground under its
## footprint. Its box collider (`collider_boxes`) is built on every shell;
## only a drawing shell (`draw`) loads the model.
static func _install_hero(world: Node3D, cfg: Dictionary, draw: bool) -> void:
	var holder := Node3D.new()
	holder.name = "FallenGiantHero"
	var at: Array = cfg.get("at_xz", [-150.0, 4478.0])
	var yaw := deg_to_rad(float(cfg.get("yaw_deg", 0.0)))
	holder.rotation.y = yaw
	# The footprint and collider come from config (measured once from the
	# GLB), so every shell, a headless host included, seats and blocks alike.
	var footprint: Array = cfg.get("footprint_half_m", [17.3, 27.5])
	var half := Vector2(float(footprint[0]), float(footprint[1]))
	var low := INF
	for u: float in [-1.0, 0.0, 1.0]:
		for v: float in [-1.0, 0.0, 1.0]:
			var offset := Vector3(half.x * u, 0.0, half.y * v).rotated(Vector3.UP, yaw)
			var y := float(world.call("ground_height_at", float(at[0]) + offset.x, float(at[1]) + offset.z))
			if is_finite(y):
				low = minf(low, y)
	holder.position = Vector3(float(at[0]), (low if is_finite(low) else 0.0) - float(cfg.get("sink_m", 1.5)), float(at[1]))
	var boxes: Array = cfg.get("collider_boxes", [])
	if not boxes.is_empty():
		var body := StaticBody3D.new()
		body.name = "FallenGiantBody"
		for raw: Variant in boxes:
			var box: Array = raw
			var shape := BoxShape3D.new()
			shape.size = Vector3(float(box[3]), float(box[4]), float(box[5]))
			var collider := CollisionShape3D.new()
			collider.shape = shape
			collider.position = Vector3(float(box[0]), float(box[1]), float(box[2]))
			body.add_child(collider)
		holder.add_child(body)
	else:
		holder.set_meta("collision_scope_pending", true)
	if draw:
		var model := HERO_PROP.load_model(str(cfg.get("model", "")))
		if model == null:
			push_warning("Fallen Giant hero: model unavailable")
		else:
			var bounds := HERO_PROP.BOUNDS.measure(model)
			var factor := float(cfg.get("length_m", 55.0)) / maxf(0.01, bounds.size.z)
			model.scale = Vector3.ONE * factor
			model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * factor
			_finish_bark(model, cfg.get("bark", {}))
			holder.add_child(model)
	world.add_child(holder)


## GPU SW10 (5 of 6 judges: the bark reads close to Team Tether's oxblood;
## red is reserved for them): a cool moss multiplier pulls the red-brown out of
## the GLB's bark, and a soft material rim lifts the log off the trunks behind
## it (r28/SW10 asks). Empty or disabled leaves the model as imported.
static func _finish_bark(model: Node3D, bark: Dictionary) -> void:
	if not bool(bark.get("enabled", false)):
		return
	for visual: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for surface in visual.mesh.get_surface_count():
			var source := visual.get_active_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var finished := source.duplicate() as BaseMaterial3D
			finished.albedo_color = Color(str(bark.get("tint", "#b4cbbd")))
			var rim := float(bark.get("rim", 0.0))
			if rim > 0.0:
				finished.rim_enabled = true
				finished.rim = rim
				finished.rim_tint = float(bark.get("rim_tint", 0.4))
			visual.set_surface_override_material(surface, finished)


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


## Samples include every original vertex, edge midpoint and face centre.
## These are actual installed geometry, not the old draft's bounding sphere.
static func _collect_samples(node: Node3D, parent: Transform3D,
		out: PackedVector3Array) -> void:
	var transform := parent * node.transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var faces := (node as MeshInstance3D).mesh.get_faces()
		var unique: Dictionary = {}
		for i in range(0, faces.size(), 3):
			var a := transform * faces[i]
			var b := transform * faces[i + 1]
			var c := transform * faces[i + 2]
			for point: Vector3 in [a, b, c, (a + b) * 0.5, (b + c) * 0.5,
					(c + a) * 0.5, (a + b + c) / 3.0]:
				if not unique.has(point):
					unique[point] = true
					out.append(point)
	for child in node.get_children():
		if child is Node3D:
			_collect_samples(child, transform, out)


static func _fit(terrain: Node, samples: PackedVector3Array, cfg: Dictionary,
		budget: RefCounted) -> Dictionary:
	if samples.is_empty():
		return {}
	var origin := Vector3(float(cfg.root_xz[0]), 0.0, float(cfg.root_xz[1]))
	var best: Dictionary = {}
	var best_score := INF
	# Coarse roll/seat solve followed by a bounded local pitch refinement.
	for pass_index in 2:
		if pass_index == 1 and best.is_empty():
			return {}
		var step := float(cfg.pitch_step_deg) if pass_index == 0 else float(cfg.pitch_refine_step_deg)
		var start_pitch := float(cfg.pitch_min_deg) if pass_index == 0 else maxf(float(cfg.pitch_min_deg), float(best.pitch_deg) - float(cfg.pitch_refine_half_range_deg))
		var end_pitch := float(cfg.pitch_max_deg) if pass_index == 0 else minf(float(cfg.pitch_max_deg), float(best.pitch_deg) + float(cfg.pitch_refine_half_range_deg))
		var count := int(round((end_pitch - start_pitch) / step)) + 1
		for index in count:
			await budget.call("breathe")
			var pitch := start_pitch + float(index) * step
			var basis := Basis(Vector3.UP, deg_to_rad(float(cfg.yaw_deg))) \
				* Basis(Vector3.BACK, deg_to_rad(-90.0 + pitch)) \
				* Basis(Vector3.UP, deg_to_rad(float(cfg.roll_deg)))
			basis = basis.scaled(Vector3.ONE * float(cfg.uniform_scale))
			var transformed := PackedVector3Array()
			var lift := -INF
			var root_lift := -INF
			var crown_lift := -INF
			for sample in samples:
				var point := basis * sample + origin
				var height := TERRAIN_HEIGHT.height_at(terrain, point.x, point.z)
				if not is_finite(height):
					return {}
				var demand := height - point.y
				lift = maxf(lift, demand)
				if sample.y >= float(cfg.root_support_source_y[0]) and sample.y <= float(cfg.root_support_source_y[1]):
					root_lift = maxf(root_lift, demand)
				if sample.y >= float(cfg.crown_support_source_y[0]) and sample.y <= float(cfg.crown_support_source_y[1]):
					crown_lift = maxf(crown_lift, demand)
				transformed.append(point)
			lift += float(cfg.surface_clearance_m)
			var support_gap := maxf(lift - root_lift, lift - crown_lift)
			if support_gap >= best_score:
				continue
			var bounds := AABB(transformed[0], Vector3.ZERO)
			for point in transformed:
				bounds = bounds.expand(point)
			if not _clear_footprint(bounds, cfg):
				continue
			best_score = support_gap
			bounds.position.y += lift
			best = {"transform": Transform3D(basis, origin + Vector3.UP * lift),
				"pitch_deg": pitch, "bounds": bounds, "sample_count": samples.size(),
				"root_support_gap_m": lift - root_lift, "crown_support_gap_m": lift - crown_lift,
				"minimum_sample_clearance_m": float(cfg.surface_clearance_m)}
	if best_score > float(cfg.maximum_support_gap_m):
		return {}
	return best


## The enclosing rectangle contains the complete transformed mesh footprint.
## Rectangle distances are conservative: even the empty space between branches
## must clear routes and actor seats. No centre-only radius approximation.
static func _clear_footprint(bounds: AABB, cfg: Dictionary) -> bool:
	var footprint := Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z))
	var world := _read("res://data/config/stormwood_world.json")
	if (world.get("routes", []) as Array).is_empty():
		return false
	for route: Dictionary in world.get("routes", []):
		var points: Array = route.points
		for i in points.size() - 1:
			if _segment_distance(footprint, Vector2(points[i][0], points[i][1]), Vector2(points[i + 1][0], points[i + 1][1])) < float(cfg.road_clearance_m):
				return false
	for path: String in ["stormwood_npcs", "stormwood_trainers", "stormwood_encounters"]:
		var actors := _read("res://data/config/%s.json" % path)
		if actors.is_empty() or _contains_seat(actors, footprint, float(cfg.actor_clearance_m)):
			return false
	return true


static func _contains_seat(value: Variant, box: Rect2, clearance: float) -> bool:
	if value is Dictionary:
		var position: Variant = value.get("position", null)
		if position is Array and position.size() == 3:
			var at := Vector2(float(position[0]), float(position[2]))
			if at.distance_to(at.clamp(box.position, box.end)) < clearance:
				return true
		for child: Variant in value.values():
			if _contains_seat(child, box, clearance):
				return true
	elif value is Array:
		for child: Variant in value:
			if _contains_seat(child, box, clearance):
				return true
	return false


static func _segment_distance(box: Rect2, a: Vector2, b: Vector2) -> float:
	if box.has_point(a) or box.has_point(b):
		return 0.0
	var corners: Array[Vector2] = [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	var distance := INF
	for i in 4:
		var c := corners[i]
		var d := corners[(i + 1) % 4]
		if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
			return 0.0
		distance = minf(distance, c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)))
		distance = minf(distance, a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)))
		distance = minf(distance, b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d)))
	return distance
