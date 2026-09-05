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
const NATURE_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/CommonTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_3.gltf"),
]
const NATURE_ROCKS: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]

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
	# Darker than the raw swatches because the Compatibility renderer's sun and
	# sky contribution lift mid-values hard. These retain hue at noon instead
	# of bleaching every distant cliff into the same white slab.
	_materials["cliff"] = _material(Color("#754331"), 0.96)
	_materials["cliff_shadow"] = _material(Color("#3f2b2a"), 1.0)
	_materials["upland"] = _material(Color("#6f7448"), 0.94)
	_materials["upland_dry"] = _material(Color("#8c7c4a"), 0.95)
	_materials["path"] = _material(Color("#aa8150"), 0.96)
	_materials["stone"] = _material(Color("#595a58"), 1.0)
	_materials["stone_light"] = _material(Color("#898377"), 0.98)
	_materials["wood"] = _material(Color("#432d24"), 1.0)
	_materials["rope"] = _material(Color("#8f7048"), 1.0)
	_materials["leaf"] = _material(Color("#4f623d"), 0.94)
	_materials["leaf_gold"] = _material(Color("#8f8744"), 0.94)
	_materials["tether"] = _material(Color("#651f2b"), 0.82)
	_materials["heart"] = _emissive_material(Color("#5ee0c2"), 2.6)
	_materials["cloud"] = _cloud_material()
	_materials["cloud_bank"] = _emissive_material(Color("#d4e2e5"), 0.12)


func _build_cloud_sea() -> void:
	var realm: Dictionary = _config.get("realm", {})
	var bounds: Dictionary = realm.get("world_bounds", {})
	var width := maxf(900.0, float(bounds.get("max_x", 450.0)) - float(bounds.get("min_x", -450.0)) + 500.0)
	var depth := maxf(1200.0, float(bounds.get("max_z", 800.0)) - float(bounds.get("min_z", -200.0)) + 500.0)
	var y := float(bounds.get("min_y", -100.0)) + 18.0
	_box(self, "CloudSea", Vector3.ZERO + Vector3(0.0, y, 300.0), Vector3(width, 3.0, depth), _materials["cloud"], false)
	var banks := Node3D.new()
	banks.name = "CloudBanks"
	add_child(banks)
	const BANKS := [
		Vector3(-520.0, 75.0, 520.0), Vector3(470.0, 120.0, 980.0),
		Vector3(-820.0, 235.0, 1720.0), Vector3(690.0, 315.0, 2200.0),
		Vector3(760.0, 690.0, 3050.0), Vector3(-760.0, 610.0, 3750.0),
		Vector3(610.0, 810.0, 4570.0), Vector3(-560.0, 930.0, 5280.0),
	]
	for i in BANKS.size():
		var centre: Vector3 = BANKS[i]
		for puff in 3:
			var cloud := MeshInstance3D.new()
			cloud.name = "Cloud%02d_%d" % [i, puff]
			var mesh := SphereMesh.new()
			mesh.radius = 1.0
			mesh.height = 2.0
			mesh.radial_segments = 12
			mesh.rings = 6
			cloud.mesh = mesh
			cloud.position = centre + Vector3((puff - 1) * 54.0, float(puff % 2) * 7.0, (puff - 1) * 18.0)
			cloud.scale = Vector3(74.0 - puff * 9.0, 13.0 + puff * 2.0, 38.0 + puff * 8.0)
			cloud.material_override = _materials["cloud_bank"]
			banks.add_child(cloud)


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
		_mesa(node, "CliffMass", centre, size, _materials["cliff"],
			_materials["upland_dry"] if int(spec.get("order", 0)) >= 5 else _materials["upland"], true,
			int(spec.get("order", 0)))
		_add_cliff_strata(node, centre, size, top)
		_add_satellite_crags(node, centre, size, top, int(spec.get("order", 0)))
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
		_mesa(root, _safe_name(str((raw as Dictionary).get("id", "Transition"))),
			at - Vector3.UP * 8.0, Vector3(42.0, 16.0, 42.0), _materials["cliff"],
			_materials["upland"], true, int(absf(at.x + at.z)))
		_surfaces.append({"kind": "rect", "centre": Vector2(at.x, at.z), "half": Vector2(21.0, 21.0), "height": at.y})


func _add_cliff_strata(parent: Node3D, centre: Vector3, size: Vector3, top: float) -> void:
	for i in 3:
		var ledge_y := top - 7.0 - float(i) * 9.0
		if ledge_y <= centre.y - size.y * 0.5 + 2.0:
			continue
		_box(parent, "Stratum%d" % i,
			Vector3(centre.x, ledge_y, centre.z + size.z * 0.5 + 0.35),
			Vector3(size.x * (0.78 - i * 0.07), 0.65, 0.75), _materials["cliff_shadow"], false)


func _add_satellite_crags(parent: Node3D, centre: Vector3, size: Vector3, top: float, order: int) -> void:
	# Three asymmetric companions stop each region reading as one isolated stamp
	# and give the long approach views overlapping silhouettes at different
	# depths. They are visual geology outside the walkable top, not secret paths.
	const OFFSETS := [Vector2(-0.58, -0.24), Vector2(0.51, 0.34), Vector2(0.12, -0.62)]
	for i in OFFSETS.size():
		var offset: Vector2 = OFFSETS[(i + order) % OFFSETS.size()]
		var crag_top := top - 18.0 - float((i + order) % 3) * 14.0
		var crag_height := clampf(size.y * (0.34 + 0.07 * i), 22.0, 72.0)
		var at := Vector3(
			centre.x + offset.x * size.x,
			crag_top - crag_height * 0.5,
			centre.z + offset.y * size.z)
		_mesa(parent, "SatelliteCrag%d" % i, at,
			Vector3(size.x * (0.22 + i * 0.035), crag_height, size.z * (0.25 + i * 0.03)),
			_materials["cliff_shadow"], _materials["stone"], false, order * 7 + i)


func _add_wind_vegetation(parent: Node3D, rect: Rect2, top: float, order: int) -> void:
	var centre := rect.get_center()
	var half := rect.size * 0.5
	var tree_count := maxi(6, 13 - order)
	for i in tree_count:
		var angle := fmod(float(i) * 2.399963 + float(order) * 0.71, TAU)
		var radius := 0.22 + 0.58 * sqrt(fmod(float(i) * 0.6180339 + float(order) * 0.17, 1.0))
		var at := Vector3(centre.x + cos(angle) * half.x * radius, top,
			centre.y + sin(angle) * half.y * radius)
		var tree := NATURE_TREES[(i + order) % NATURE_TREES.size()].instantiate() as Node3D
		tree.name = "WindTree%d" % i
		tree.position = at
		tree.rotation = Vector3(0.0, angle + 0.4, deg_to_rad(-5.0 - float((i + order) % 4) * 2.5))
		var scale_value := 0.54 + float((i * 7 + order) % 6) * 0.075
		tree.scale = Vector3.ONE * scale_value
		parent.add_child(tree)
	for i in 10:
		var angle := fmod(float(i) * 2.071 + float(order) * 0.39, TAU)
		var radius := 0.24 + 0.63 * sqrt(fmod(float(i) * 0.4142 + 0.13 * order, 1.0))
		var at := Vector3(centre.x + cos(angle) * half.x * radius, top - 0.18,
			centre.y + sin(angle) * half.y * radius)
		var rock := NATURE_ROCKS[(i * 2 + order) % NATURE_ROCKS.size()].instantiate() as Node3D
		rock.name = "BeddedRock%d" % i
		rock.position = at
		rock.rotation.y = angle
		rock.scale = Vector3.ONE * (0.65 + float((i + order) % 4) * 0.18)
		parent.add_child(rock)


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
		var width := float(spec.get("width_m", 7.5))
		_build_route_shoulders(root, spec, points, width)
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


func _build_route_shoulders(root: Node3D, spec: Dictionary, points: Array[Vector3], width: float) -> void:
	var route_name := _safe_name(str(spec.get("id", "Route")))
	var shoulder_root := Node3D.new()
	shoulder_root.name = "%sCliffShoulders" % route_name
	root.add_child(shoulder_root)
	var serial := 0
	for segment_index in points.size() - 1:
		var a := points[segment_index]
		var b := points[segment_index + 1]
		var length := a.distance_to(b)
		var count := clampi(int(ceilf(length / 66.0)), 2, 12)
		var flat_forward := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
		var right := Vector3.UP.cross(flat_forward).normalized()
		for i in count:
			var jitter := sin(float(i * 19 + serial * 7 + segment_index * 13)) * 0.24
			var t := clampf((float(i) + 0.5 + jitter) / float(count), 0.08, 0.92)
			var p := a.lerp(b, t)
			var phase := float(posmod(serial * 17 + segment_index * 11, 9)) / 8.0
			var shoulder_width := maxf(width * 4.0, 30.0) * (0.72 + phase * 0.58)
			var shoulder_depth := shoulder_width * (0.68 + float(posmod(serial, 5)) * 0.095)
			var height := 48.0 + float(posmod(serial * 13, 9)) * 13.0
			var top := p.y - 0.65
			_mesa(shoulder_root, "Shelf%03d" % serial,
				Vector3(p.x, top - height * 0.5, p.z),
				Vector3(shoulder_width, height, shoulder_depth),
				_materials["cliff"], _materials["upland_dry"], false, serial + 70)

			# Sparse, clustered route-edge scale cues. Real Quaternius nature assets
			# make the shelf size readable without turning every ascent into woods.
			if serial % 3 == 0:
				var side := -1.0 if serial % 2 == 0 else 1.0
				var rock := NATURE_ROCKS[serial % NATURE_ROCKS.size()].instantiate() as Node3D
				rock.name = "RouteRock%03d" % serial
				rock.position = p + right * side * shoulder_width * 0.3 - Vector3.UP * 0.5
				rock.rotation.y = phase * TAU
				rock.scale = Vector3.ONE * (0.95 + phase * 0.8)
				shoulder_root.add_child(rock)
			if serial % 5 == 1:
				var side := -1.0 if serial % 2 == 0 else 1.0
				var tree := NATURE_TREES[(serial + segment_index) % NATURE_TREES.size()].instantiate() as Node3D
				tree.name = "RouteTree%03d" % serial
				tree.position = p + right * side * shoulder_width * 0.32
				tree.rotation = Vector3(0.0, phase * TAU, deg_to_rad(-7.0 - phase * 5.0))
				tree.scale = Vector3.ONE * (0.58 + phase * 0.22)
				shoulder_root.add_child(tree)
			serial += 1


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
		var count := clampi(int(ceilf(length / 4.5)), 8, 72)
		var bridge := Node3D.new()
		bridge.name = _safe_name(str(spec.get("id", "Bridge")))
		root.add_child(bridge)
		var bridge_type := str(spec.get("type", "rope_suspension"))
		var stone_bridge := bridge_type.contains("stone")
		_segment_box(bridge, "WalkableDeck", a, b, width, 0.42,
			_materials["stone"] if stone_bridge else _materials["wood"], true)
		var plank_mesh := BoxMesh.new()
		plank_mesh.size = Vector3(width, 0.16, length / float(count) * 0.86)
		plank_mesh.material = _materials["stone_light"] if stone_bridge else _materials["path"]
		var plank_instances := MultiMesh.new()
		plank_instances.transform_format = MultiMesh.TRANSFORM_3D
		plank_instances.mesh = plank_mesh
		plank_instances.instance_count = count
		var planks := MultiMeshInstance3D.new()
		planks.name = "BatchedDeckPlanks"
		planks.multimesh = plank_instances
		bridge.add_child(planks)
		var deck_basis := _segment_basis(a, b)
		for i in count:
			var t := (float(i) + 0.5) / float(count)
			var p := a.lerp(b, t)
			plank_instances.set_instance_transform(i, Transform3D(deck_basis, p + deck_basis.y * 0.12))
		if not stone_bridge:
			var rope_segments := clampi(int(ceilf(length / 18.0)), 8, 32)
			var tangent := (b - a).normalized()
			var right := Vector3.UP.cross(tangent).normalized()
			for i in rope_segments:
				var t := float(i) / float(rope_segments)
				var next_t := float(i + 1) / float(rope_segments)
				for side: float in [-1.0, 1.0]:
					var sag_a := a.lerp(b, t) + right * width * 0.62 * side + Vector3.UP * (1.75 - 0.85 * sin(PI * t))
					var q := a.lerp(b, next_t) + right * width * 0.62 * side + Vector3.UP * (1.75 - 0.85 * sin(PI * next_t))
					_cylinder_between(bridge, "Rope%02d" % i, sag_a, q, 0.055, _materials["rope"])
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
		_mesa(landmark, "LandmarkLedge", Vector3(0.0, -6.0, 0.0), Vector3(40.0, 12.0, 38.0),
			_materials["cliff"], _materials["upland_dry"], true, _landmark_count + 31)
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
	# A tall windwatch anchors the cluster at route-view distance; the houses
	# then read as an inhabited terrace instead of five same-sized boxes.
	_cylinder(root, "WindwatchTower", Vector3(-1.5, 9.0, -2.0), 3.6, 18.0, _materials["stone"])
	_box(root, "WindwatchCrown", Vector3(-1.5, 17.8, -2.0), Vector3(9.0, 1.3, 9.0), _materials["wood"], false)
	for side: float in [-1.0, 1.0]:
		_box(root, "WindBanner", Vector3(-1.5 + side * 4.6, 15.2, -2.0),
			Vector3(0.18, 4.2, 2.4), _materials["leaf_gold"], false)
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
	_box(root, "Dais", Vector3(0.0, 0.65, 0.0), Vector3(26.0, 1.3, 20.0), _materials["stone_light"], true)
	for x in [-9.5, 0.0, 9.5]:
		_box(root, "SkyPillar", Vector3(x, 10.0, 2.5), Vector3(2.2, 20.0, 2.2), _materials["stone"], true)
	_box(root, "SkyLintel", Vector3(0.0, 19.0, 2.5), Vector3(23.0, 2.0, 2.5), _materials["stone"], true)
	for x in [-9.5, 9.5]:
		_cylinder(root, "WindFinial", Vector3(x, 23.0, 2.5), 1.4, 7.0, _materials["stone_light"])
	var heart := MeshInstance3D.new()
	heart.name = "HeartSocketGlow"
	heart.position = Vector3(0.0, 8.5, 0.0)
	var crystal := SphereMesh.new()
	crystal.radius = 1.8
	crystal.height = 4.6
	heart.mesh = crystal
	heart.scale = Vector3(0.75, 1.25, 0.75)
	heart.material_override = _materials["heart"]
	root.add_child(heart)


func _build_summit_stronghold(root: Node3D) -> void:
	_box(root, "SummitKeep", Vector3(0.0, 15.0, 0.0), Vector3(42.0, 30.0, 34.0), _materials["stone"], true)
	_box(root, "UpperKeep", Vector3(0.0, 34.0, -2.0), Vector3(25.0, 11.0, 22.0), _materials["stone_light"], true)
	for corner in [Vector3(-24.0, 17.0, -20.0), Vector3(24.0, 17.0, -20.0), Vector3(-24.0, 17.0, 20.0), Vector3(24.0, 17.0, 20.0)]:
		_cylinder(root, "SummitTower", corner, 6.5, 34.0, _materials["stone"])
		_cylinder(root, "TowerCap", corner + Vector3.UP * 18.5, 8.0, 3.0, _materials["tether"])
	_cylinder(root, "TetherSpire", Vector3(0.0, 49.0, -2.0), 2.8, 20.0, _materials["tether"])
	_box(root, "TetherCrown", Vector3(0.0, 41.0, -2.0), Vector3(30.0, 2.2, 26.0), _materials["tether"], false)


func _build_wayfinder(root: Node3D) -> void:
	_cylinder(root, "AncientMarker", Vector3(0.0, 7.0, 0.0), 2.1, 14.0, _materials["stone_light"])
	_cylinder(root, "MarkerLight", Vector3(0.0, 15.0, 0.0), 0.8, 2.0, _materials["heart"])


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


func _mesa(
		parent: Node,
		label: String,
		centre: Vector3,
		size: Vector3,
		side_material: Material,
		top_material: Material,
		collision: bool,
		seed_value: int
	) -> Node3D:
	var root := Node3D.new()
	root.name = label
	root.position = centre
	root.rotation.y = deg_to_rad(float(posmod(seed_value * 23, 36)) - 18.0)
	parent.add_child(root)

	var sides := 9 + posmod(seed_value, 3)
	var mesa_mesh := CylinderMesh.new()
	mesa_mesh.top_radius = 1.0
	mesa_mesh.bottom_radius = 0.68
	mesa_mesh.height = size.y
	mesa_mesh.radial_segments = sides
	mesa_mesh.rings = 2
	var mass := MeshInstance3D.new()
	mass.name = "RockBody"
	mass.mesh = mesa_mesh
	mass.scale = Vector3(size.x * 0.5, 1.0, size.z * 0.5)
	mass.material_override = side_material
	root.add_child(mass)

	# A thin inset cap gives the plateau a distinct walkable value and hides the
	# cylinder's single-material top without adding another terrain system.
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 1.0
	cap_mesh.bottom_radius = 1.0
	cap_mesh.height = 0.55
	cap_mesh.radial_segments = sides
	var cap := MeshInstance3D.new()
	cap.name = "UplandCap"
	cap.position.y = size.y * 0.5 + 0.16
	cap.scale = Vector3(size.x * 0.47, 1.0, size.z * 0.47)
	cap.mesh = cap_mesh
	cap.material_override = top_material
	root.add_child(cap)

	if collision:
		var points := PackedVector3Array()
		for ring in 2:
			var y := size.y * (0.5 if ring == 0 else -0.5)
			var radius_scale := 0.47 if ring == 0 else 0.32
			for i in sides:
				var angle := TAU * float(i) / float(sides)
				points.append(Vector3(cos(angle) * size.x * radius_scale, y,
					sin(angle) * size.z * radius_scale))
		var body := StaticBody3D.new()
		body.name = "Collision"
		var shape_node := CollisionShape3D.new()
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
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
	var material := _emissive_material(Color(0.67, 0.77, 0.82, 1.0), 0.18)
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
