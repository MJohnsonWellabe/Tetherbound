extends Node3D

## Cloudreach Cliffs' data-driven world shell.
##
## The chapter's macro layout lives in `data/config/cloudreach_world.json`.
## This node turns that authored region/route graph into solid, traversable
## cliff plates, ramps, suspended bridges and landmark silhouettes.  It is a
## deliberately separate world builder rather than another branch inside the
## Meadows' 1,700-line runtime composer.

const CONFIG_PATH := "res://data/config/cloudreach_world.json"
const REALM_ID := "cloudreach"
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")

@onready var _player: CharacterBody3D = $Player
@onready var _camera_rig: Node3D = $CameraRig

var _config: Dictionary = {}
var _surfaces: Array[Dictionary] = []
var _materials: Dictionary = {}
var _region_count := 0
var _landmark_count := 0
var _progression_revision := -1
var _progression_gates: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("progression_restore")
	_config = _read_json(CONFIG_PATH)
	if _config.is_empty():
		push_error("Cloudreach world config missing or invalid: %s" % CONFIG_PATH)
		return
	_build_materials()
	_build_cloud_sea()
	_build_regions()
	_build_transition_ledges()
	_build_routes()
	_build_progression_gates()
	_build_bridges()
	_build_landmarks()
	_build_return_gate()
	_place_player()
	_capture_mouse_if_free()
	get_window().focus_entered.connect(_capture_mouse_if_free)
	_sync_progression_gates(_game())


func _process(_delta: float) -> void:
	var game := _game()
	var progression: Variant = game.get("progression") if game != null else null
	var revision := int((progression as RefCounted).get("revision")) if progression is RefCounted else -1
	if revision != _progression_revision:
		_sync_progression_gates(game)


func restore_progression_from_game(game: Node) -> void:
	_progression_revision = -1
	_sync_progression_gates(game)


func region_count() -> int:
	return _region_count


func landmark_count() -> int:
	return _landmark_count


func config_data() -> Dictionary:
	return _config.duplicate(true)


## The same terrain-independent contract authored objects use in the Meadows.
## Highest matching plate/route wins, which correctly resolves stacked cliffs.
func ground_height_at(x: float, z: float) -> float:
	var best := -INF
	for surface: Dictionary in _surfaces:
		var kind := str(surface.get("kind", "rect"))
		if kind == "rect":
			var centre: Vector2 = surface.get("centre", Vector2.ZERO)
			var half: Vector2 = surface.get("half", Vector2.ZERO)
			if absf(x - centre.x) <= half.x and absf(z - centre.y) <= half.y:
				best = maxf(best, float(surface.get("height", -INF)))
		elif kind == "segment":
			var a: Vector3 = surface.get("a", Vector3.ZERO)
			var b: Vector3 = surface.get("b", Vector3.ZERO)
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var length_sq := ab.length_squared()
			if length_sq <= 0.001:
				continue
			var point := Vector2(x - a.x, z - a.z)
			var t := clampf(point.dot(ab) / length_sq, 0.0, 1.0)
			var nearest := Vector2(a.x, a.z) + ab * t
			if nearest.distance_to(Vector2(x, z)) <= float(surface.get("half_width", 1.0)):
				best = maxf(best, lerpf(a.y, b.y, t))
	return NAN if best == -INF else best


func entry_anchor(anchor_id: String) -> Dictionary:
	var points: Variant = _config.get("transition_points", {})
	if not points is Dictionary:
		return {}
	for value: Variant in (points as Dictionary).values():
		if value is Dictionary and str((value as Dictionary).get("id", "")) == anchor_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _build_materials() -> void:
	_materials["cliff"] = _material(Color("#a65f43"), 0.92)
	_materials["cliff_shadow"] = _material(Color("#704135"), 0.98)
	_materials["path"] = _material(Color("#d7aa73"), 0.9)
	_materials["stone"] = _material(Color("#8e8276"), 0.96)
	_materials["stone_light"] = _material(Color("#c1b39b"), 0.92)
	_materials["wood"] = _material(Color("#60402d"), 1.0)
	_materials["rope"] = _material(Color("#b48d57"), 1.0)
	_materials["leaf"] = _material(Color("#667448"), 0.92)
	_materials["leaf_gold"] = _material(Color("#a99a50"), 0.9)
	_materials["tether"] = _material(Color("#651f2b"), 0.82)
	_materials["heart"] = _emissive_material(Color("#5ee0c2"), 2.6)
	_materials["cloud"] = _cloud_material()


func _build_cloud_sea() -> void:
	var realm: Dictionary = _config.get("realm", {})
	var bounds: Dictionary = realm.get("world_bounds", {})
	var width := maxf(900.0, float(bounds.get("max_x", 450.0)) - float(bounds.get("min_x", -450.0)) + 500.0)
	var depth := maxf(1200.0, float(bounds.get("max_z", 800.0)) - float(bounds.get("min_z", -200.0)) + 500.0)
	var y := float(bounds.get("min_y", -100.0)) + 18.0
	_box(self, "CloudSea", Vector3.ZERO + Vector3(0.0, y, 300.0), Vector3(width, 3.0, depth), _materials["cloud"], false)


func _build_regions() -> void:
	var root := Node3D.new()
	root.name = "CliffRegions"
	add_child(root)
	for raw: Variant in _config.get("regions", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var bounds: Dictionary = spec.get("bounds", {})
		var min_x := float(bounds.get("min_x", 0.0))
		var max_x := float(bounds.get("max_x", min_x + 40.0))
		var min_z := float(bounds.get("min_z", 0.0))
		var max_z := float(bounds.get("max_z", min_z + 40.0))
		var authored := _vec3(spec.get("position", []))
		var top := authored.y
		var bottom := float(bounds.get("min_y", top - 36.0))
		# Bounds express the region's full navigation/visibility envelope, not a
		# single tabletop. A compact authored mesa at the region anchor plus the
		# route-ledges below produces separated vertical silhouettes instead of
		# six overlapping rectangular continents.
		var size := Vector3(
			clampf((max_x - min_x) * 0.18, 120.0, 300.0),
			maxf(18.0, top - bottom),
			clampf((max_z - min_z) * 0.16, 100.0, 250.0))
		var centre := Vector3(authored.x, (top + bottom) * 0.5, authored.z)
		var node := Node3D.new()
		node.name = _safe_name(str(spec.get("id", "Region")))
		root.add_child(node)
		_box(node, "CliffMass", centre, size, _materials["cliff"], true)
		_add_cliff_strata(node, centre, size, top)
		_add_wind_vegetation(node,
			Rect2(centre.x - size.x * 0.5, centre.z - size.z * 0.5, size.x, size.z),
			top, int(spec.get("order", 0)))
		_surfaces.append({"kind": "rect", "centre": Vector2(centre.x, centre.z), "half": Vector2(size.x, size.z) * 0.5, "height": top})
		_region_count += 1


func _build_transition_ledges() -> void:
	var root := Node3D.new()
	root.name = "RealmTransitionLedges"
	add_child(root)
	var points: Variant = _config.get("transition_points", {})
	if not points is Dictionary:
		return
	for raw: Variant in (points as Dictionary).values():
		if not raw is Dictionary:
			continue
		var at := _vec3((raw as Dictionary).get("position", []))
		_box(root, _safe_name(str((raw as Dictionary).get("id", "Transition"))),
			at - Vector3.UP * 8.0, Vector3(42.0, 16.0, 42.0), _materials["cliff"], true)
		_surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(21.0, 21.0), "height": at.y})


func _add_cliff_strata(parent: Node3D, centre: Vector3, size: Vector3, top: float) -> void:
	for i in 3:
		var ledge_y := top - 7.0 - float(i) * 9.0
		if ledge_y <= centre.y - size.y * 0.5 + 2.0:
			continue
		_box(parent, "Stratum%d" % i,
			Vector3(centre.x, ledge_y, centre.z + size.z * 0.5 + 0.35),
			Vector3(size.x * (0.94 - i * 0.06), 0.75, 0.7), _materials["cliff_shadow"], false)


func _add_wind_vegetation(parent: Node3D, rect: Rect2, top: float, order: int) -> void:
	const OFFSETS := [Vector2(0.14, 0.22), Vector2(0.81, 0.28), Vector2(0.31, 0.73), Vector2(0.69, 0.82), Vector2(0.52, 0.48)]
	for i in OFFSETS.size():
		var uv: Vector2 = OFFSETS[(i + order) % OFFSETS.size()]
		var at := Vector3(rect.position.x + rect.size.x * uv.x, top, rect.position.y + rect.size.y * uv.y)
		var tree := Node3D.new()
		tree.name = "WindTree%d" % i
		tree.position = at
		tree.rotation.z = deg_to_rad(-9.0 - float((i + order) % 3) * 4.0)
		parent.add_child(tree)
		_cylinder(tree, "Trunk", Vector3(0.0, 2.2, 0.0), 0.3, 4.4, _materials["wood"])
		var crown := SphereMesh.new()
		crown.radius = 1.35
		crown.height = 2.2
		var leaves := MeshInstance3D.new()
		leaves.name = "WindBentCrown"
		leaves.position = Vector3(0.8, 4.2, 0.0)
		leaves.scale = Vector3(1.65, 0.75, 0.85)
		leaves.mesh = crown
		leaves.material_override = _materials["leaf_gold"] if (i + order) % 3 == 0 else _materials["leaf"]
		tree.add_child(leaves)


func _build_routes() -> void:
	var root := Node3D.new()
	root.name = "AuthoredRoutes"
	add_child(root)
	for raw: Variant in _config.get("routes", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		if str(spec.get("traversal_mode", "ground")) != "ground":
			continue
		var points: Array[Vector3] = []
		for point: Variant in spec.get("polyline", []):
			points.append(_vec3(point))
		var width := float(spec.get("width_m", 5.5))
		for i in points.size():
			var pad := points[i]
			_box(root, "%s_Ledge%d" % [_safe_name(str(spec.get("id", "Route"))), i],
				pad - Vector3.UP * 7.0, Vector3(maxf(14.0, width * 2.5), 14.0, maxf(14.0, width * 2.5)),
				_materials["cliff"], true)
			_surfaces.append({"kind": "rect", "centre": Vector2(pad.x, pad.z),
				"half": Vector2(maxf(7.0, width * 1.25), maxf(7.0, width * 1.25)), "height": pad.y})
		for i in points.size() - 1:
			_segment_box(root, "%s_%d" % [_safe_name(str(spec.get("id", "Route"))), i], points[i], points[i + 1], width, 0.8, _materials["path"], true)
			_surfaces.append({"kind": "segment", "a": points[i], "b": points[i + 1], "half_width": width * 0.5, "height": points[i].y})


func _build_bridges() -> void:
	var root := Node3D.new()
	root.name = "SuspendedBridges"
	add_child(root)
	for raw: Variant in _config.get("bridges", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var endpoints: Variant = spec.get("endpoints", [])
		if not endpoints is Array or (endpoints as Array).size() < 2:
			continue
		var a := _vec3((endpoints as Array)[0])
		var b := _vec3((endpoints as Array)[1])
		var width := float(spec.get("width_m", 3.2))
		var length := a.distance_to(b)
		var count := maxi(4, int(ceilf(length / 1.7)))
		var bridge := Node3D.new()
		bridge.name = _safe_name(str(spec.get("id", "Bridge")))
		root.add_child(bridge)
		_segment_box(bridge, "WalkableDeck", a, b, width, 0.35, _materials["wood"], true)
		for i in count:
			var t := (float(i) + 0.5) / float(count)
			var p := a.lerp(b, t)
			var tangent := (b - a).normalized()
			var right := Vector3.UP.cross(tangent).normalized()
			_box(bridge, "Plank%02d" % i, p + Vector3.UP * 0.22, Vector3(width, 0.16, length / count * 0.9), _materials["path"], false, _segment_basis(a, b))
			if i < count - 1:
				var next_t := (float(i) + 1.5) / float(count)
				for side: float in [-1.0, 1.0]:
					var sag_a := p + right * width * 0.62 * side + Vector3.UP * (1.6 - 0.7 * sin(PI * t))
					var q := a.lerp(b, next_t) + right * width * 0.62 * side + Vector3.UP * (1.6 - 0.7 * sin(PI * next_t))
					_cylinder_between(bridge, "Rope", sag_a, q, 0.045, _materials["rope"])
		for endpoint: Vector3 in [a, b]:
			var tangent := (b - a).normalized()
			var right := Vector3.UP.cross(tangent).normalized()
			for side: float in [-1.0, 1.0]:
				_cylinder(bridge, "Post", endpoint + right * width * 0.62 * side + Vector3.UP * 1.15, 0.16, 2.3, _materials["wood"])
		_surfaces.append({"kind": "segment", "a": a, "b": b, "half_width": width * 0.5, "height": a.y})


func _build_progression_gates() -> void:
	var root := Node3D.new()
	root.name = "TraversalGates"
	add_child(root)
	for raw: Variant in _config.get("gates", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at := _vec3(spec.get("position", []))
		var required := str(spec.get("requires_unlock", ""))
		var flight := str(spec.get("required_traversal", "ground")) == "fly"
		var gate := Node3D.new()
		gate.name = _safe_name(str(spec.get("id", "TraversalGate")))
		gate.position = at
		gate.rotation.y = _gate_yaw_for(required, at)
		root.add_child(gate)
		var opening_width := 22.0 if flight else 16.0
		var opening_height := 18.0 if flight else 7.5
		_box(gate, "LeftPier", Vector3(-opening_width * 0.58, opening_height * 0.5, 0.0),
			Vector3(2.0, opening_height + 3.0, 2.2), _materials["stone"], true)
		_box(gate, "RightPier", Vector3(opening_width * 0.58, opening_height * 0.5, 0.0),
			Vector3(2.0, opening_height + 3.0, 2.2), _materials["stone"], true)
		_box(gate, "Counterweight", Vector3(0.0, opening_height + 1.1, 0.0),
			Vector3(opening_width + 4.0, 2.2, 2.2), _materials["stone_light"], true)
		var barrier := StaticBody3D.new()
		barrier.name = "LockedTraversalBarrier"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(opening_width, opening_height, 1.2)
		shape_node.shape = shape
		shape_node.position.y = opening_height * 0.5
		barrier.add_child(shape_node)
		gate.add_child(barrier)
		var veil := MeshInstance3D.new()
		veil.name = "LockedWindVeil"
		var veil_mesh := BoxMesh.new()
		veil_mesh.size = Vector3(opening_width, opening_height, 0.12)
		veil.mesh = veil_mesh
		veil.position.y = opening_height * 0.5
		veil.material_override = _materials["heart"]
		gate.add_child(veil)
		_progression_gates.append({"flag": required, "shape": shape_node, "veil": veil})


func _gate_yaw_for(required_flag: String, at: Vector3) -> float:
	for raw: Variant in _config.get("routes", []):
		if not raw is Dictionary or str((raw as Dictionary).get("requires_unlock", "")) != required_flag:
			continue
		var line: Variant = (raw as Dictionary).get("polyline", [])
		if not line is Array or (line as Array).size() < 2:
			continue
		var a := _vec3((line as Array)[0])
		var b := _vec3((line as Array)[1])
		if a.distance_to(at) < 30.0:
			return atan2(b.x - a.x, b.z - a.z)
	return 0.0


func _sync_progression_gates(game: Node) -> void:
	var progression: Variant = game.get("progression") if game != null else null
	_progression_revision = int((progression as RefCounted).get("revision")) if progression is RefCounted else -1
	for record: Dictionary in _progression_gates:
		var flag := str(record.get("flag", ""))
		var opened := flag == "" or (progression is RefCounted and bool((progression as RefCounted).call("has", flag)))
		var shape := record.get("shape") as CollisionShape3D
		var veil := record.get("veil") as Node3D
		if shape != null:
			shape.set_deferred("disabled", opened)
		if veil != null:
			veil.visible = not opened


func _build_landmarks() -> void:
	var root := Node3D.new()
	root.name = "Landmarks"
	add_child(root)
	for raw: Variant in _config.get("landmarks", []):
		if not raw is Dictionary:
			continue
		var spec := raw as Dictionary
		var at := _vec3(spec.get("position", []))
		var landmark := Node3D.new()
		landmark.name = _safe_name(str(spec.get("id", "Landmark")))
		landmark.position = at
		root.add_child(landmark)
		_box(landmark, "LandmarkLedge", Vector3(0.0, -6.0, 0.0), Vector3(34.0, 12.0, 34.0), _materials["cliff"], true)
		_surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(17.0, 17.0), "height": at.y})
		var identity := (str(spec.get("id", "")) + " " + str(spec.get("category", ""))).to_lower()
		if identity.contains("settlement") or identity.contains("village"):
			_build_cliff_settlement(landmark)
		elif identity.contains("shrine") or identity.contains("roost"):
			_build_sky_shrine(landmark)
		elif identity.contains("stronghold") or identity.contains("summit"):
			_build_summit_stronghold(landmark)
		else:
			_build_wayfinder(landmark)
		_landmark_count += 1


func _build_return_gate() -> void:
	var points: Dictionary = _config.get("transition_points", {})
	var raw: Variant = points.get("meadows_return", {})
	if not raw is Dictionary:
		return
	var spec := raw as Dictionary
	var gate: Node3D = REALM_GATE.new()
	gate.name = "MeadowsReturnRealmGate"
	gate.position = _vec3(spec.get("position", []))
	gate.rotation.y = deg_to_rad(float(spec.get("facing_yaw_deg", 180.0)))
	gate.call("setup", "meadows", str(spec.get("peer_anchor_id", "meadows_cloudreach_gate_return")),
		"The Meadows", "realm_key_cloudreach", "realm_gate_cloudreach_unlocked")
	add_child(gate)


func _build_cliff_settlement(root: Node3D) -> void:
	for i in 5:
		var row := i / 3
		var col := i % 3
		var p := Vector3((col - 1) * 9.0 + row * 3.0, row * 2.5, (row - 0.5) * 10.0)
		_box(root, "House%d" % i, p + Vector3.UP * 3.1, Vector3(6.2, 6.2, 5.2), _materials["stone_light"], true)
		var roof := PrismMesh.new()
		roof.size = Vector3(7.2, 2.4, 6.2)
		var mesh := MeshInstance3D.new()
		mesh.name = "Roof%d" % i
		mesh.position = p + Vector3.UP * 7.3
		mesh.mesh = roof
		mesh.material_override = _materials["wood"]
		root.add_child(mesh)


func _build_sky_shrine(root: Node3D) -> void:
	_box(root, "Dais", Vector3(0.0, 0.65, 0.0), Vector3(15.0, 1.3, 13.0), _materials["stone_light"], true)
	for x in [-5.2, 5.2]:
		_box(root, "Pillar", Vector3(x, 5.0, 1.8), Vector3(1.5, 10.0, 1.5), _materials["stone"], true)
	_box(root, "Lintel", Vector3(0.0, 9.3, 1.8), Vector3(12.0, 1.5, 1.8), _materials["stone"], true)
	var heart := MeshInstance3D.new()
	heart.name = "HeartSocketGlow"
	heart.position = Vector3(0.0, 3.0, 0.0)
	var crystal := SphereMesh.new()
	crystal.radius = 0.8
	crystal.height = 1.8
	heart.mesh = crystal
	heart.scale = Vector3(0.75, 1.25, 0.75)
	heart.material_override = _materials["heart"]
	root.add_child(heart)


func _build_summit_stronghold(root: Node3D) -> void:
	_box(root, "SummitKeep", Vector3(0.0, 8.0, 0.0), Vector3(24.0, 16.0, 22.0), _materials["stone"], true)
	for corner in [Vector3(-13.0, 9.0, -12.0), Vector3(13.0, 9.0, -12.0), Vector3(-13.0, 9.0, 12.0), Vector3(13.0, 9.0, 12.0)]:
		_cylinder(root, "SummitTower", corner, 4.0, 18.0, _materials["stone"])
	_box(root, "TetherCrown", Vector3(0.0, 18.5, 0.0), Vector3(18.0, 2.0, 18.0), _materials["tether"], false)


func _build_wayfinder(root: Node3D) -> void:
	_cylinder(root, "AncientMarker", Vector3(0.0, 4.5, 0.0), 1.5, 9.0, _materials["stone_light"])
	_cylinder(root, "MarkerLight", Vector3(0.0, 9.6, 0.0), 0.55, 1.4, _materials["heart"])


func _place_player() -> void:
	var game := get_node_or_null(^"/root/Game")
	var pending := str(game.call("pending_entry_for", REALM_ID)) if game != null and game.has_method("pending_entry_for") else ""
	if pending == "" and game != null and game.has_method("apply_loaded_player_pose") and bool(game.call("apply_loaded_player_pose")):
		return
	var anchor := entry_anchor(pending)
	if anchor.is_empty():
		var points: Dictionary = _config.get("transition_points", {})
		var fallback: Variant = points.get("meadows_entry", {})
		anchor = (fallback as Dictionary).duplicate(true) if fallback is Dictionary else {}
	var spot := _vec3(anchor.get("position", [0.0, 5.0, 0.0]))
	var floor_y := ground_height_at(spot.x, spot.z)
	if not is_nan(floor_y):
		spot.y = floor_y + 0.15
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var yaw := deg_to_rad(float(anchor.get("facing_yaw_deg", 0.0)))
	var model := _player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.rotation.y = yaw
	if _camera_rig != null:
		_camera_rig.set("yaw", yaw)
	if pending != "" and game != null and game.has_method("complete_realm_entry"):
		_settle_realm_arrival.call_deferred(game)


func _settle_realm_arrival(game: Node) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	if is_instance_valid(game):
		game.call("complete_realm_entry", REALM_ID)


func _capture_mouse_if_free() -> void:
	var game := _game()
	if game != null and game.has_method("menu"):
		var menu: Object = game.call("menu")
		if menu != null and bool(menu.call("is_open")):
			return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _game() -> Node:
	return get_node_or_null(^"/root/Game")


func _segment_box(parent: Node, label: String, a: Vector3, b: Vector3, width: float, thickness: float, material: Material, collision: bool) -> Node3D:
	var length := a.distance_to(b)
	return _box(parent, label, a.lerp(b, 0.5) - _segment_basis(a, b).y * thickness * 0.5,
		Vector3(width, thickness, length), material, collision, _segment_basis(a, b))


func _segment_basis(a: Vector3, b: Vector3) -> Basis:
	var forward := (b - a).normalized()
	var right := Vector3.UP.cross(forward).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var up := forward.cross(right).normalized()
	return Basis(right, up, forward)


func _box(parent: Node, label: String, centre: Vector3, size: Vector3, material: Material, collision: bool, basis: Basis = Basis.IDENTITY) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = centre
	root.basis = basis
	parent.add_child(root)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	root.add_child(mesh)
	if collision:
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
		root.add_child(body)
	return root


func _cylinder(parent: Node, label: String, centre: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.position = centre
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 1.08
	cylinder.height = height
	mesh.mesh = cylinder
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh


func _cylinder_between(parent: Node, label: String, a: Vector3, b: Vector3, radius: float, material: Material) -> void:
	var delta := b - a
	if delta.length_squared() < 0.001:
		return
	var node := _cylinder(parent, label, a.lerp(b, 0.5), radius, delta.length(), material)
	var up := delta.normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var forward := right.cross(up).normalized()
	node.basis = Basis(right, up, forward)


func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


func _emissive_material(colour: Color, energy: float) -> StandardMaterial3D:
	var material := _material(colour, 0.48)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	return material


func _cloud_material() -> StandardMaterial3D:
	var material := _emissive_material(Color(0.84, 0.9, 0.96, 0.78), 0.45)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func _safe_name(raw: String) -> String:
	var words := raw.replace("-", "_").split("_", false)
	var result := ""
	for word: String in words:
		result += word.capitalize().replace(" ", "")
	return result if result != "" else "CloudreachNode"
