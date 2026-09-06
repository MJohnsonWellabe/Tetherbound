extends SceneTree

## Ground-truth collision audit for Cloudreach's walkable geology.
##
## OP-0905-24 "You can walk through too many spots and fall."
## OP-0905-25 "You walk like half way in the ground usually."
##
## Verified root causes (see docs/owner/OWNER_PLAYTEST_2026-09-05.md and the
## task brief that fixed them): the wide cliff-shoulder rock formation
## flanking every road had no collider at all while grass was planted on it;
## route landing pads and three landmark ledges rendered a large visible mesa
## with collision either disabled or shrunk to a much smaller flat cap/crown
## box; and every other mesa collided with a convex hull of its top and
## bottom rings, which floats above concave dips and sinks below bumps in an
## eroded or rugged crown.
##
## This smoke casts a physics ray straight down at a grid of real rendered
## points -- vertices actually on each feature's visible top mesh, so the
## expected height comes from the render itself, not a re-derived formula --
## across every route ribbon and its shoulders (out to the full rendered
## shoulder width, a superset of the required half_width*0.5), every landing
## pad, every visible landmark ledge, and every bridge deck. It asserts each
## ray hits a collider (no hole) and that the hit lands within 0.15 m of the
## rendered height (no float/sink). It also spot-checks a handful of named
## `_box()` platforms (traversal gates, the sky shrine dais, the summit
## stronghold courtyards) and reports total collider/triangle counts.

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const TOLERANCE_M := 0.15
const REAL_MASK := 1 # Default physics layer used by every StaticBody3D this file's builders create.

var world: Node3D
var space: PhysicsDirectSpaceState3D
var checked := 0
var holes: Array[String] = []
var mismatches: Array[String] = []
var worst: Array[Dictionary] = [] # {label, gap}
var collider_count := 0
var trimesh_collider_count := 0
var trimesh_triangle_count := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := root.get_node(^"Game")
	game.current_realm = "cloudreach"
	world = SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in 6:
		await physics_frame
	space = world.get_world_3d().direct_space_state

	_count_geometry(world)
	_check_route_ribbons_and_shoulders()
	_check_landing_pads()
	_check_landmark_ledges()
	_check_bridges()
	_check_named_platforms()

	worst.sort_custom(func(a, b): return a["gap"] > b["gap"])
	print("CLOUDREACH GROUND TRUTH: colliders=%d trimesh_colliders=%d trimesh_triangles=%d"
		% [collider_count, trimesh_collider_count, trimesh_triangle_count])
	print("CLOUDREACH GROUND TRUTH: %d sample points checked, %d holes, %d height mismatches (>%.2fm)"
		% [checked, holes.size(), mismatches.size(), TOLERANCE_M])
	print("CLOUDREACH GROUND TRUTH: worst offenders (largest gap first):")
	for i in mini(10, worst.size()):
		var entry: Dictionary = worst[i]
		print("  %s gap=%.3fm" % [str(entry["label"]), float(entry["gap"])])
	for line: String in holes:
		printerr("HOLE: " + line)
	for line: String in mismatches:
		printerr("MISMATCH: " + line)
	var failures := holes.size() + mismatches.size()
	print("CLOUDREACH GROUND TRUTH: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)


## ---- geometry accounting (report item 6) --------------------------------

func _count_geometry(node: Node) -> void:
	if node is StaticBody3D:
		collider_count += 1
	if node is CollisionShape3D:
		var shape := (node as CollisionShape3D).shape
		if shape is ConcavePolygonShape3D:
			trimesh_collider_count += 1
			trimesh_triangle_count += (shape as ConcavePolygonShape3D).get_faces().size() / 3
	for child in node.get_children():
		_count_geometry(child)


## ---- shared sampling helpers ---------------------------------------------

## One expected world-space point per triangle on a mesh's own top surface
## (surface 0): the triangle's centroid, so the expectation comes from the
## render itself. A centroid is strictly interior to its triangle, unlike a
## shared vertex/edge -- probing exactly on a shared edge between two
## coplanar-ish triangles is a known watertight-raycast edge case that can
## report a false miss on an otherwise solid trimesh.
func _top_surface_points(mesh_instance: MeshInstance3D) -> Array[Vector3]:
	var points: Array[Vector3] = []
	var mesh := mesh_instance.mesh
	if mesh == null or mesh.get_surface_count() == 0:
		return points
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var xform := mesh_instance.global_transform
	var i := 0
	while i + 2 < verts.size():
		var centroid := (verts[i] + verts[i + 1] + verts[i + 2]) / 3.0
		points.append(xform * centroid)
		i += 3
	return points


## Casts straight down onto the real world collision (the layer every
## StaticBody3D in cloudreach_world.gd's builders uses) and records a hole or
## a height mismatch against `expected`. Skips past any dynamic body (an NPC
## or creature can be standing right at a sampled point) to find the real
## static ground underneath -- this world's NPCs share layer 1 with terrain,
## so a mask alone cannot tell them apart.
func _probe(label: String, expected: Vector3) -> void:
	checked += 1
	var from: Vector3 = expected + Vector3.UP * 5.0
	var to: Vector3 = expected + Vector3.DOWN * 5.0
	var hit: Dictionary = {}
	for _attempt in 8:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = REAL_MASK
		var result: Dictionary = space.intersect_ray(query)
		if result.is_empty():
			break
		if result["collider"] is StaticBody3D:
			hit = result
			break
		from = (result["position"] as Vector3) - Vector3.UP * 0.02
	if hit.is_empty():
		holes.append("%s: no static collider under rendered point %s" % [label, expected])
		worst.append({"label": label + " (HOLE)", "gap": 999.0})
		return
	var gap := absf((hit["position"] as Vector3).y - expected.y)
	worst.append({"label": label, "gap": gap})
	if gap > TOLERANCE_M:
		mismatches.append("%s: rendered y=%.3f, collider hit y=%.3f, gap=%.3fm at %s"
			% [label, expected.y, (hit["position"] as Vector3).y, gap, expected])


func _probe_mesh(label_prefix: String, mesh_instance: MeshInstance3D, stride: int = 1) -> void:
	var points := _top_surface_points(mesh_instance)
	for index in points.size():
		if index % stride == 0:
			var at := points[index]
			_probe("%s@(%.1f,%.1f)" % [label_prefix, at.x, at.z], at)


## ---- route ribbons and their grass-covered shoulders ---------------------

func _check_route_ribbons_and_shoulders() -> void:
	var routes_root := world.get_node_or_null(^"AuthoredRoutes")
	if routes_root == null:
		holes.append("AuthoredRoutes node missing entirely")
		return
	# All of a route's pieces (shoulders, ledges, ground ribbons, trails) are
	# direct children of AuthoredRoutes, named per-piece rather than grouped
	# under a per-route holder -- match by the same name fragments the
	# builders use.
	for node: Node in routes_root.get_children():
		var name := str(node.name)
		if name.ends_with("CliffShoulders"):
			# Shoulders: every MeshInstance3D named "Ridge###" here. Their top
			# surface spans from the outer rendered edge across the crest to
			# the opposite outer edge -- a superset of the required
			# half_width*0.5 out from the road.
			for ridge_node: Node in node.get_children():
				if ridge_node is MeshInstance3D and str(ridge_node.name).begins_with("Ridge"):
					_probe_mesh("Shoulder/%s" % ridge_node.name, ridge_node as MeshInstance3D, 3)
		elif name.contains("Ground") and node is Node3D:
			# Road ribbon: the narrow collision box already matches its own
			# (deliberately invisible) mesh by construction; confirm no gap.
			var mesh_child: MeshInstance3D = null
			for child in (node as Node3D).get_children():
				if child is MeshInstance3D:
					mesh_child = child
					break
			var box := mesh_child.mesh as BoxMesh if mesh_child != null else null
			if box != null:
				var xform := (node as Node3D).global_transform
				var top := xform.origin + xform.basis.y * (box.size.y * 0.5)
				_probe("Road/%s" % name, top)


## ---- route landing pads ---------------------------------------------------

func _check_landing_pads() -> void:
	var routes_root := world.get_node_or_null(^"AuthoredRoutes")
	if routes_root == null:
		return
	for route_node: Node in routes_root.get_children():
		if str(route_node.name).contains("_Ledge"):
			var body := (route_node as Node3D).find_child("StratifiedCliffBody", false, false) as MeshInstance3D
			if body != null:
				_probe_mesh("Pad/%s" % route_node.name, body, 2)


## ---- landmark ledges -------------------------------------------------------

func _check_landmark_ledges() -> void:
	var landmarks_root := world.get_node_or_null(^"Landmarks")
	if landmarks_root == null:
		holes.append("Landmarks node missing entirely")
		return
	for landmark_node: Node in landmarks_root.get_children():
		var ledge := (landmark_node as Node3D).find_child("LandmarkLedge", false, false)
		if ledge == null:
			continue
		var body := (ledge as Node3D).find_child("StratifiedCliffBody", false, false) as MeshInstance3D
		if body == null or not body.visible:
			continue # Hidden for settlements, which own a separate skirt/terrace.
		_probe_mesh("Landmark/%s" % landmark_node.name, body, 2)


## ---- bridge decks ----------------------------------------------------------

func _check_bridges() -> void:
	var config: Dictionary = world.call("config_data")
	var visual: Dictionary = _read_json("res://data/config/cloudreach_visual.json")
	var cap_half := float((visual.get("landmass", {}) as Dictionary).get("landing_size_m", 16.0)) * 0.41
	var bridges_root := world.get_node_or_null(^"SuspendedBridges")
	if bridges_root == null:
		return
	for spec: Dictionary in config.get("bridges", []):
		var stone_bridge := str(spec.get("type", "")).contains("stone")
		# Matches `_build_bridge_section`'s own visible-plank math: stone
		# paving sits 0.12m instance offset + half its 0.16m box above the
		# line; the rope/wood deck's thin floor modules sit ~0.045m proud.
		var visible_lift := 0.2 if stone_bridge else 0.045
		var points: Array = spec.get("deck_profile", spec.get("endpoints", []))
		var bridge_node := bridges_root.get_node_or_null(NodePath(_safe_name(str(spec.get("id", "Bridge")))))
		if bridge_node == null or points.size() < 2:
			continue
		for i in points.size() - 1:
			var a := _vec3(points[i])
			var b := _vec3(points[i + 1])
			# `_build_bridges()` joins the outer endpoints to the landing
			# pad's cap edge, not its centre, the same way route ribbons do.
			if i == 0:
				a = _landing_join(a, b, cap_half, 0.75)
			if i == points.size() - 2:
				b = _landing_join(b, a, cap_half, 0.75)
			if a.distance_to(b) < 0.01:
				continue
			# `_segment_basis`'s up axis, reconstructed locally.
			var forward := (b - a).normalized()
			var right := Vector3.UP.cross(forward).normalized()
			if right.length_squared() < 0.001:
				right = Vector3.RIGHT
			var up := forward.cross(right).normalized()
			for t in [0.1, 0.5, 0.9]:
				var line_point := a.lerp(b, t)
				_probe("Bridge/%s section%d t=%.1f" % [spec.get("id", ""), i, t],
					line_point + up * visible_lift)


static func _safe_name(raw: String) -> String:
	var words := raw.replace("-", "_").split("_", false)
	var result := ""
	for word: String in words:
		result += word.capitalize().replace(" ", "")
	return result if result != "" else "CloudreachNode"


static func _vec3(raw: Array) -> Vector3:
	return Vector3(float(raw[0]), float(raw[1]), float(raw[2])) if raw.size() == 3 else Vector3.ZERO


## Mirrors `cloudreach_world.gd::_landing_join` exactly.
static func _landing_join(pad: Vector3, toward: Vector3, cap_half: float, length_fraction: float = 0.2) -> Vector3:
	var flat := Vector3(toward.x - pad.x, 0, toward.z - pad.z)
	var length := flat.length()
	if length < 0.01:
		return pad
	var direction := flat / length
	var edge_distance := cap_half / maxf(absf(direction.x), absf(direction.z))
	return pad + direction * minf(edge_distance - 0.25, length * length_fraction)


static func _read_json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


## ---- spot checks: gate platforms, dais, courtyards (report item 5) --------

func _check_named_platforms() -> void:
	var gates_root := world.get_node_or_null(^"TraversalGates")
	if gates_root != null:
		var config: Dictionary = world.call("config_data")
		var ground_gate_ids: Dictionary = {}
		for spec: Dictionary in config.get("gates", []):
			if str(spec.get("required_traversal", "ground")) != "fly":
				ground_gate_ids[_safe_name(str(spec.get("id", "TraversalGate")))] = true
		for gate_node: Node3D in gates_root.get_children():
			# Fly-only gates are legitimately mid-air waypoints with no ground
			# beneath them -- only ground gates should ever find a collider.
			if ground_gate_ids.has(str(gate_node.name)):
				_probe("Gate/%s" % gate_node.name, gate_node.global_position)
	for label: String in ["Dais", "UpperKeep", "GateThreshold", "SettlementWalkableTerrace",
			"ObservatoryWalkableCrown", "OverlookWalkableCrown"]:
		var found := world.find_child(label, true, false)
		if found is Node3D:
			# `_box()` names the Node3D wrapper, not the MeshInstance3D child
			# it holds -- find that child to read the actual box height.
			var wrapper := found as Node3D
			var mesh_here: MeshInstance3D = null
			for child in wrapper.get_children():
				if child is MeshInstance3D:
					mesh_here = child
					break
			var top := wrapper.global_position
			if mesh_here != null and mesh_here.mesh is BoxMesh:
				top += wrapper.global_transform.basis.y * ((mesh_here.mesh as BoxMesh).size.y * 0.5)
			_probe("Platform/%s" % label, top)
