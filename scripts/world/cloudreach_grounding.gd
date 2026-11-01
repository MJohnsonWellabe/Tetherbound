extends Node3D

## Cloudreach grounding pass (owner, 31 Oct 2026: "There are big cylinders in
## cloudreach that don't look like they touch the ground").
##
## Visual only, local presentation. After every Cloudreach builder and the
## look/settlement dressing has run, this walks the mounted world for upright
## CylinderMesh pieces whose base does not meet the walkable ground under its
## footprint, and seats each one: a flared skirt in the cylinder's own material
## runs from its base down past the lowest ground point under the rim, and big
## drums also get a ring of installed rocks banked against the foot. Nothing
## moves, shrinks or hides; no collider, route or surface is added or changed.
## No RPC, durable field or receipt: every peer rebuilds the same dressing.
##
## Flag-off: `data/config/cloudreach_grounding.json` "enabled" (false on main).
## A capture may preview it with --cloudreach-grounding-candidate, and
## --cloudreach-grounding-report prints every candidate it measured.

const CONFIG_PATH := "res://data/config/cloudreach_grounding.json"
const PREVIEW_ARG := "--cloudreach-grounding-candidate"
const REPORT_ARG := "--cloudreach-grounding-report"
const ROCKS: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]

var _cfg: Dictionary = {}
var _space: PhysicsDirectSpaceState3D
var _world: Node3D
var _seated: Array[Dictionary] = []
var _report := false


static func read_config() -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	return raw as Dictionary if raw is Dictionary else {}


static func enabled(cfg: Dictionary) -> bool:
	return bool(cfg.get("enabled", false)) or OS.get_cmdline_user_args().has(PREVIEW_ARG)


func seated() -> Array[Dictionary]:
	return _seated


func build(world: Node3D) -> void:
	_world = world
	_cfg = read_config()
	_report = OS.get_cmdline_user_args().has(REPORT_ARG)
	if not enabled(_cfg) and not _report:
		return
	var apply := enabled(_cfg)
	if world.get_world_3d() == null:
		return
	_space = world.get_world_3d().direct_space_state
	var candidates: Array = []
	_collect(world, candidates)
	for mesh_instance: MeshInstance3D in candidates:
		var result := _measure(mesh_instance)
		if result.is_empty():
			continue
		if _report:
			print("[cloudreach_grounding] ", mesh_instance.get_path(), " r=", snappedf(result.radius, 0.01),
				" h=", snappedf(result.height, 0.01), " base_y=", snappedf(result.base_y, 0.01),
				" max_gap=", snappedf(result.max_gap, 0.01), " void=", result.void_points,
				" at=", result.base.snapped(Vector3.ONE * 0.1), " action=", result.action)
		if apply and str(result.action) == "seat":
			_seat(mesh_instance, result)
	if bool(_cfg.get("ground_rock_drums", true)):
		var drums: Array = []
		_collect_drums(world, drums)
		for mass: MeshInstance3D in drums:
			_ground_drum(mass, apply)
	if _report:
		print("[cloudreach_grounding] seated=", _seated.size(), " applied=", apply)
		_prove()
		if OS.get_cmdline_user_args().has("--cloudreach-grounding-survey"):
			_survey_columns(world)


## The procedural rock drums (`cloudreach_world.gd::_mesa`): every shoulder,
## shelf and cliff mass ends in a flared, open bottom ring at a fixed depth.
## Where that depth sits above the ground below, the dark jagged rim hangs
## over the grass. Airborne islands (they carry IslandMist) are meant to float.
func _collect_drums(node: Node, out: Array) -> void:
	if node == self:
		return
	if node is MeshInstance3D and str(node.name) == "StratifiedCliffBody":
		var parent := node.get_parent()
		if parent != null and parent.get_node_or_null(^"IslandMist") == null:
			out.append(node)
	for child: Node in node.get_children():
		_collect_drums(child, out)


func _bottom_ring(mass: MeshInstance3D) -> Array[Vector3]:
	var mesh := mass.mesh
	var points: Array[Vector3] = []
	if mesh == null:
		return points
	var min_y := INF
	var vertices: Array[PackedVector3Array] = []
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		vertices.append(verts)
		for v: Vector3 in verts:
			min_y = minf(min_y, v.y)
	var bins := int(_cfg.get("drum_ring_bins", 64))
	var best: Array = []
	best.resize(bins)
	var centroid := Vector2.ZERO
	var count := 0
	for verts: PackedVector3Array in vertices:
		for v: Vector3 in verts:
			if v.y <= min_y + 0.05:
				centroid += Vector2(v.x, v.z)
				count += 1
	if count < 3:
		return points
	centroid /= float(count)
	for verts: PackedVector3Array in vertices:
		for v: Vector3 in verts:
			if v.y > min_y + 0.05:
				continue
			var d := Vector2(v.x, v.z) - centroid
			var bin := posmod(int(floor((atan2(d.y, d.x) + PI) / TAU * bins)), bins)
			if best[bin] == null or d.length() > (Vector2((best[bin] as Vector3).x, (best[bin] as Vector3).z) - centroid).length():
				best[bin] = v
	for entry: Variant in best:
		if entry != null:
			points.append(entry)
	return points


func _ground_drum(mass: MeshInstance3D, apply: bool) -> void:
	if not mass.is_visible_in_tree():
		return
	var ring := _bottom_ring(mass)
	if ring.size() < 8:
		return
	var xform := mass.global_transform
	var owner := mass.get_parent()
	var box := xform * mass.get_aabb()
	var base_y := (xform * ring[0]).y
	var centre_local := Vector3.ZERO
	for p: Vector3 in ring:
		centre_local += p
	centre_local /= float(ring.size())
	var max_probe := float(_cfg.get("drum_max_probe_m", 70.0))
	var lowest := INF
	var max_gap := -INF
	var min_gap := INF
	var voids := 0
	var probes: Array[Vector3] = [xform * centre_local]
	for p: Vector3 in ring:
		probes.append(xform * p)
	# The foot's own final outline (see `_foot_layer`), so the seat and the
	# proof probe the same ground.
	var outline_from := probes.size()
	for p: Vector3 in _foot_layer(ring, centre_local, ring[0].y, 1.0, _steps()):
		probes.append(xform * p)
	var outline_voids := 0
	var view_side := Vector3.INF
	var view_gap := INF
	for index in probes.size():
		var point: Vector3 = probes[index]
		var ground := _ground_y(point, box.end.y + 1.0, owner, max_probe)
		if not is_nan(ground) and index >= outline_from and point.y - ground > 0.3 and point.y - ground < view_gap:
			view_gap = point.y - ground
			view_side = point
		if is_nan(ground):
			voids += 1
			if index >= outline_from:
				outline_voids += 1
			continue
		lowest = minf(lowest, ground)
		max_gap = maxf(max_gap, point.y - ground)
		min_gap = minf(min_gap, point.y - ground)
	var action := "grounded"
	if not is_finite(max_gap):
		action = "void"
	elif max_gap > float(_cfg.get("gap_tolerance_m", 0.08)) * 4.0:
		# A drum with ground under enough of its outline is seated down to the
		# lowest ground found: the side over the grass meets the turf, the side
		# over a drop stays a cliff face. Mostly over open sky = a cliff ledge.
		var covered := 1.0 - float(outline_voids) / float(probes.size() - outline_from)
		action = "seat" if covered >= float(_cfg.get("drum_min_ground_fraction", 0.2)) else "overhang"
	var radius := 0.0
	for p: Vector3 in ring:
		radius = maxf(radius, Vector2(p.x - centre_local.x, p.z - centre_local.z).length())
	radius *= maxf(xform.basis.x.length(), xform.basis.z.length())
	var sink := float(_cfg.get("sink_m", 0.45))
	var depth := base_y - lowest + sink if is_finite(lowest) else 0.0
	if action == "seat" and _world.has_method("_shelf_in_route_headroom") \
			and bool(_world.call("_shelf_in_route_headroom", Vector3(probes[0].x, base_y, probes[0].z), radius, depth)):
		action = "route_below"
	if _report:
		var near := _nearest_route(probes[0])
		print("[cloudreach_grounding:drum] ", mass.get_parent().get_path(), " base_y=", snappedf(base_y, 0.1),
			" r=", snappedf(radius, 0.1), " max_gap=", snappedf(max_gap if is_finite(max_gap) else -1.0, 0.01),
			" void=", voids, "/", probes.size(), " at=", Vector2(probes[0].x, probes[0].z).snapped(Vector2.ONE * 0.1),
			" route=", near, " view=", _view_spot(probes[0], view_side, radius), " action=", action)
	if not apply or action != "seat":
		return
	_build_drum_foot(mass, ring, centre_local, lowest - sink, radius, base_y - max_probe, box.end.y + 1.0)


## Extrudes the drum's own bottom ring down to `bottom_y` (world) in the same
## cliff material, flaring and roughening slightly so it reads as the rock
## continuing into the ground. Visual only, no collider.
func _build_drum_foot(mass: MeshInstance3D, ring: Array[Vector3], centre: Vector3,
		bottom_y: float, radius_world: float, probe_floor_y: float, probe_top_y: float) -> void:
	var xform := mass.global_transform
	var inverse := xform.affine_inverse()
	var scale_y := maxf(xform.basis.y.length(), 0.0001)
	var top_y := ring[0].y + float(_cfg.get("drum_overlap_m", 0.6)) / scale_y
	var floor_local_y := (inverse * Vector3(xform.origin.x, bottom_y, xform.origin.z)).y
	var steps := _steps()
	var rings: Array = []
	for step in steps + 1:
		var t := float(step) / float(steps)
		rings.append(_foot_layer(ring, centre, lerpf(top_y, floor_local_y, t), t, step))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for step in steps:
		var upper: Array[Vector3] = rings[step]
		var lower: Array[Vector3] = rings[step + 1]
		for i in ring.size():
			var next := (i + 1) % ring.size()
			_tri(tool, upper[i], upper[next], lower[i])
			_tri(tool, lower[i], upper[next], lower[next])
	tool.generate_normals()
	var foot := MeshInstance3D.new()
	foot.name = "GroundingFoot_%s" % mass.get_parent().name
	foot.mesh = tool.commit()
	var material: Material = (_world.get("_materials") as Dictionary).get("cliff") if _world.get("_materials") is Dictionary else null
	foot.material_override = material if material != null else _material_of(mass)
	foot.visibility_range_end = mass.visibility_range_end
	foot.visibility_range_end_margin = mass.visibility_range_end_margin
	add_child(foot)
	foot.global_transform = xform
	var footing: Array[Vector3] = []
	for p: Vector3 in rings[steps]:
		footing.append(xform * p)
	_seated.append({"path": str(mass.get_parent().get_path()), "kind": "drum", "radius": radius_world,
		"skirt_height": (xform * Vector3(0, top_y, 0)).y - bottom_y, "footing": footing,
		"owner": mass.get_parent(), "probe_floor_y": probe_floor_y, "probe_top_y": probe_top_y})


## Report only: a ground-level camera stand on the drum's floating side,
## `x,z@heading` toward the drum, for before/after frames.
func _view_spot(centre: Vector3, side: Vector3, radius: float) -> String:
	if not side.is_finite():
		return "-"
	var out := Vector2(side.x - centre.x, side.z - centre.z).normalized()
	var stand := Vector2(side.x, side.z) + out * float(_cfg.get("report_view_back_m", 16.0))
	var heading := rad_to_deg(atan2(-out.x, -out.y))
	return "%.1f,%.1f@%.0f" % [stand.x, stand.y, heading]


## Report only: the nearest authored route point (x, z, deck height, distance).
func _nearest_route(at: Vector3) -> String:
	if not _world.has_method("_lines_near") or not _world.has_method("_line_point_xz"):
		return "-"
	if (_world.get("_all_route_lines") as Array).is_empty() and _world.has_method("_collect_all_route_lines"):
		_world.call("_collect_all_route_lines")
	var best := {}
	for line: Dictionary in _world.call("_lines_near", at.x - 60.0, at.x + 60.0, at.z - 60.0, at.z + 60.0):
		var hit: Dictionary = _world.call("_line_point_xz", line, at)
		if best.is_empty() or float(hit.distance) < float(best.distance):
			var a: Vector3 = line["a"]
			var b: Vector3 = line["b"]
			var flat := Vector2(b.x - a.x, b.z - a.z)
			var t := 0.0
			if flat.length_squared() > 0.0001:
				t = clampf(Vector2(at.x - a.x, at.z - a.z).dot(flat) / flat.length_squared(), 0.0, 1.0)
			best = hit
			best["point"] = (Vector2(a.x, a.z) + flat * t).snapped(Vector2.ONE * 0.1)
	if best.is_empty():
		return "-"
	return "%s,d=%.1f,h=%.1f" % [str(best.point), float(best.distance), float(best.height)]


func _steps() -> int:
	return maxi(1, int(_cfg.get("drum_steps", 3)))


## One ring of the foot at local height `y`: tucked just inside the drum's rim
## at the top (t = 0), flared and roughened toward the ground (t = 1).
func _foot_layer(ring: Array[Vector3], centre: Vector3, y: float, t: float, step: int) -> Array[Vector3]:
	var widen := lerpf(float(_cfg.get("drum_tuck", 0.985)), float(_cfg.get("drum_flare", 1.06)), t)
	var rough := float(_cfg.get("drum_roughness", 0.05))
	var layer: Array[Vector3] = []
	for i in ring.size():
		var p: Vector3 = ring[i]
		var jitter := 1.0 + (rough * sin(float(i) * 2.17 + float(step) * 1.31) if step > 0 else 0.0)
		layer.append(Vector3(centre.x + (p.x - centre.x) * widen * jitter, y,
			centre.z + (p.z - centre.z) * widen * jitter))
	return layer


func _tri(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	# Same winding as cloudreach_world.gd::_add_surface_triangle (clockwise front).
	tool.add_vertex(a)
	tool.add_vertex(c)
	tool.add_vertex(b)


## Proof: for every seated piece, its new lowest points meet or sink into the
## ground under them (probed again, independently of the seating maths).
func _prove() -> void:
	var failures := 0
	for entry: Dictionary in _seated:
		var footing: Array = entry.get("footing", [])
		var owner: Node = entry.get("owner")
		var worst := -INF
		var probed := 0
		for point: Vector3 in footing:
			# Ground is what lies within the same probe depth the seat used;
			# anything deeper is a drop, which the seat left as a cliff face.
			var ground := _ground_y(point, float(entry.get("probe_top_y", point.y + 20.0)),
				owner if owner != null else self, maxf(point.y - float(entry.get("probe_floor_y", point.y - 80.0)), 0.5))
			if is_nan(ground):
				continue
			probed += 1
			worst = maxf(worst, point.y - ground)
		var ok := probed > 0 and worst <= float(_cfg.get("gap_tolerance_m", 0.08))
		if not ok:
			failures += 1
		print("[cloudreach_grounding:proof] ", entry.path, " lowest_minus_ground=", snappedf(worst, 0.01),
			" probed=", probed, "/", footing.size(), " ", "PASS" if ok else "FAIL")
	print("[cloudreach_grounding:proof] seated=", _seated.size(), " failures=", failures)


## Report only: every large, upright, roughly round mesh of any kind (imported
## spires, drums, towers), with the gap from its lowest vertex to the ground.
func _survey_columns(world: Node3D) -> void:
	var meshes: Array = []
	_collect_all(world, meshes)
	var min_h := float(_cfg.get("survey_min_height_m", 5.0))
	var min_w := float(_cfg.get("survey_min_width_m", 2.0))
	for mesh_instance: MeshInstance3D in meshes:
		if not mesh_instance.is_visible_in_tree() or mesh_instance.mesh == null:
			continue
		var box := mesh_instance.global_transform * mesh_instance.get_aabb()
		var width := minf(box.size.x, box.size.z)
		if box.size.y < min_h or width < min_w or maxf(box.size.x, box.size.z) > width * 2.2:
			continue
		if box.size.y < width * 0.8:
			continue # slabs and crowns, not columns
		var centre := box.get_center()
		var bottom := box.position.y
		var gaps: Array[float] = []
		var voids := 0
		for offset: Vector2 in [Vector2.ZERO, Vector2(0.35, 0), Vector2(-0.35, 0), Vector2(0, 0.35), Vector2(0, -0.35)]:
			var at := Vector3(centre.x + offset.x * box.size.x, bottom, centre.z + offset.y * box.size.z)
			var ground := _ground_y(at, box.end.y + 1.0, mesh_instance, 40.0)
			if is_nan(ground):
				voids += 1
			else:
				gaps.append(bottom - ground)
		var max_gap := -1.0
		for g: float in gaps:
			max_gap = maxf(max_gap, g)
		print("[cloudreach_grounding:survey] ", mesh_instance.get_path(), " size=", box.size.snapped(Vector3.ONE * 0.1),
			" bottom=", snappedf(bottom, 0.1), " at=", centre.snapped(Vector3.ONE * 0.1),
			" max_gap=", snappedf(max_gap, 0.01), " void=", voids)


## The walkable ground under `point`: the first collider a ray meets coming
## down from `top_y` (above the piece, so rock that buries the foot counts as
## ground even though its one-sided mesh is invisible from inside), skipping
## the piece's own colliders. NAN when nothing lies within `max_probe` below.
func _ground_y(point: Vector3, top_y: float, owner: Node, max_probe: float) -> float:
	var exclude: Array[RID] = []
	var from := Vector3(point.x, top_y, point.z)
	var to := Vector3(point.x, point.y - max_probe, point.z)
	for attempt in 8:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = exclude
		var hit := _space.intersect_ray(query)
		if hit.is_empty():
			return NAN
		var collider := hit.get("collider") as Node
		if collider != null and _is_own_collider(collider, owner):
			exclude.append(hit.rid)
			continue
		return float((hit.position as Vector3).y)
	return NAN


func _is_own_collider(collider: Node, owner: Node) -> bool:
	if owner.is_ancestor_of(collider):
		return true
	if str(collider.name).begins_with(str(owner.name)):
		return true # `_castle_piece_collision`: "<label>Collision" sibling
	var parent := owner.get_parent()
	# `_box`/`_disc` pattern: a label root holding one mesh and its "Collision".
	if parent != null and collider.get_parent() == parent and str(collider.name) == "Collision":
		var meshes := 0
		for child: Node in parent.get_children():
			if child is MeshInstance3D:
				meshes += 1
		return meshes == 1
	return false


func _collect_all(node: Node, out: Array) -> void:
	if node == self:
		return
	if node is MeshInstance3D:
		out.append(node)
	for child: Node in node.get_children():
		_collect_all(child, out)


func _collect(node: Node, out: Array) -> void:
	if node == self:
		return
	if node is MeshInstance3D and (node as MeshInstance3D).mesh is CylinderMesh:
		out.append(node)
	for child: Node in node.get_children():
		_collect(child, out)


func _excluded_name(mesh_instance: MeshInstance3D) -> bool:
	var path := str(mesh_instance.get_path()).to_lower()
	for token: String in _cfg.get("exclude_name_tokens", []):
		if path.contains(token.to_lower()):
			return true
	return false


func _measure(mesh_instance: MeshInstance3D) -> Dictionary:
	if not mesh_instance.is_visible_in_tree() or _excluded_name(mesh_instance):
		return {}
	var cylinder := mesh_instance.mesh as CylinderMesh
	var xform := mesh_instance.global_transform
	var up := xform.basis.y
	var scale_y := up.length()
	if scale_y < 0.0001 or up.normalized().dot(Vector3.UP) < cos(deg_to_rad(float(_cfg.get("max_tilt_deg", 12.0)))):
		return {}
	var scale_xz := maxf(xform.basis.x.length(), xform.basis.z.length())
	var radius := maxf(cylinder.bottom_radius, cylinder.top_radius) * scale_xz
	var bottom_radius := cylinder.bottom_radius * scale_xz
	var height := cylinder.height * scale_y
	if radius < float(_cfg.get("min_radius_m", 0.8)) and height < float(_cfg.get("min_height_m", 6.0)):
		return {}
	if height < float(_cfg.get("min_thickness_m", 0.3)):
		return {} # floor decals and swept circles are paint, not drums
	if bottom_radius < float(_cfg.get("min_bottom_radius_m", 0.25)):
		return {} # cones and spikes have no footprint to seat
	var base := xform * Vector3(0.0, -cylinder.height * 0.5, 0.0)
	var samples := int(_cfg.get("rim_samples", 16))
	var max_probe := float(_cfg.get("max_probe_m", 14.0))
	var max_gap := -INF
	var min_gap := INF
	var lowest := INF
	var void_points := 0
	var points: Array[Vector3] = [base]
	for i in samples:
		var angle := TAU * float(i) / float(samples)
		points.append(base + Vector3(cos(angle), 0.0, sin(angle)) * bottom_radius * 0.97)
	# Probe from above the piece (see `_ground_y`), so ground that rises
	# above the base reads as a sunk foot rather than as void under it.
	var top_y := base.y + height + 1.0
	for point: Vector3 in points:
		var hit_y := _ground_y(point, top_y, mesh_instance, max_probe)
		if is_nan(hit_y):
			void_points += 1
			continue
		var gap := point.y - hit_y
		max_gap = maxf(max_gap, gap)
		min_gap = minf(min_gap, gap)
		lowest = minf(lowest, hit_y)
	var result := {"radius": radius, "bottom_radius": bottom_radius, "height": height,
		"base": base, "base_y": base.y, "max_gap": max_gap if is_finite(max_gap) else -1.0,
		"min_gap": min_gap, "lowest": lowest, "void_points": void_points, "action": "none"}
	if not is_finite(max_gap):
		result.action = "void"
		return result
	var tolerance := float(_cfg.get("gap_tolerance_m", 0.08))
	if max_gap <= tolerance:
		result.action = "grounded"
		return result
	# A piece whose whole base hangs far above the ground is a mounted part
	# (a spire on a dome, a clapper in a bell), never a floating foot.
	if min_gap > float(_cfg.get("max_seat_gap_m", 6.0)):
		result.action = "mounted"
		return result
	result.action = "seat" if void_points == 0 else "overhang"
	return result


func _material_of(mesh_instance: MeshInstance3D) -> Material:
	if mesh_instance.material_override != null:
		return mesh_instance.material_override
	return mesh_instance.get_active_material(0)


func _seat(mesh_instance: MeshInstance3D, result: Dictionary) -> void:
	var bottom_radius := float(result.bottom_radius)
	var base: Vector3 = result.base
	var sink := float(_cfg.get("sink_m", 0.45))
	var overlap := float(_cfg.get("overlap_m", 0.06))
	var top_y := base.y + overlap
	var bottom_y := float(result.lowest) - sink
	var height := top_y - bottom_y
	if height <= 0.02:
		return
	var flare := float(_cfg.get("flare", 1.18))
	if bottom_radius >= float(_cfg.get("big_radius_m", 2.5)):
		flare = float(_cfg.get("big_flare", 1.1))
	var skirt := MeshInstance3D.new()
	skirt.name = "GroundingSkirt_%s" % mesh_instance.name
	var mesh := CylinderMesh.new()
	mesh.top_radius = bottom_radius * 1.005
	# The flare grows with the drop so a tall footing reads as a battered plinth
	# rather than a straight pipe continuing into the turf.
	mesh.bottom_radius = bottom_radius * (flare + minf(height * float(_cfg.get("flare_per_m", 0.02)), 0.25))
	mesh.height = height
	mesh.radial_segments = maxi(16, int(bottom_radius * 10.0))
	mesh.rings = 1
	skirt.mesh = mesh
	skirt.material_override = _material_of(mesh_instance)
	skirt.cast_shadow = mesh_instance.cast_shadow
	skirt.visibility_range_end = mesh_instance.visibility_range_end
	add_child(skirt)
	skirt.global_position = Vector3(base.x, bottom_y + height * 0.5, base.z)
	var footing: Array[Vector3] = []
	for i in 16:
		var angle := TAU * float(i) / 16.0
		footing.append(Vector3(base.x, bottom_y, base.z) + Vector3(cos(angle), 0.0, sin(angle)) * mesh.bottom_radius * 0.97)
	var entry := {"path": str(mesh_instance.get_path()), "kind": "cylinder", "gap": float(result.max_gap),
		"radius": bottom_radius, "skirt_height": height, "rocks": 0, "footing": footing,
		"owner": mesh_instance, "probe_floor_y": base.y - float(_cfg.get("max_probe_m", 14.0)),
		"probe_top_y": base.y + float(result.height) + 1.0}
	if bottom_radius >= float(_cfg.get("rock_ring_min_radius_m", 1.6)):
		entry.rocks = _rock_ring(base, bottom_radius * mesh.bottom_radius / maxf(mesh.top_radius, 0.01),
			float(result.lowest), mesh_instance.name.hash())
	_seated.append(entry)


func _rock_ring(base: Vector3, foot_radius: float, ground_y: float, seed_value: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := clampi(int(foot_radius * float(_cfg.get("rocks_per_radius_m", 1.6))),
		int(_cfg.get("rocks_min", 4)), int(_cfg.get("rocks_max", 14)))
	var scale_range: Array = _cfg.get("rock_scale", [0.55, 1.1])
	var placed := 0
	for i in count:
		var angle := TAU * (float(i) + rng.randf_range(-0.3, 0.3)) / float(count)
		var at := base + Vector3(cos(angle), 0.0, sin(angle)) * foot_radius * rng.randf_range(0.92, 1.08)
		var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, base.y + 0.5, at.z),
			Vector3(at.x, ground_y - 3.0, at.z))
		var hit := _space.intersect_ray(query)
		if hit.is_empty():
			continue
		var ground: Vector3 = hit.position
		var size := rng.randf_range(float(scale_range[0]), float(scale_range[1])) * clampf(foot_radius / 3.0, 0.7, 1.6)
		var rock := ROCKS[(i + absi(seed_value)) % ROCKS.size()].instantiate() as Node3D
		rock.name = "GroundingRock%d" % i
		if _world.has_method("apply_stone_palette"):
			_world.call("apply_stone_palette", rock)
		add_child(rock)
		rock.global_position = ground - Vector3.UP * size * float(_cfg.get("rock_embed", 0.55))
		rock.rotation.y = rng.randf_range(0.0, TAU)
		rock.scale = Vector3.ONE * size
		for geometry: GeometryInstance3D in rock.find_children("*", "GeometryInstance3D", true, false):
			geometry.visibility_range_end = 420.0
		placed += 1
	return placed
