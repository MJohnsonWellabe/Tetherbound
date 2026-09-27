extends Node3D

## V-VIS-9 / F10#4: Team Tether's rod line as physical dressing beside the
## critical road (data/config/stormwood_rod_line.json). Presentation only: no
## colliders, no gameplay state; nothing is built on a simulation_only world.
## The pure layout (`layout`) is shared with its unit test.

const CONFIG_PATH := "res://data/config/stormwood_rod_line.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"
const ROAD_CURRENT := preload("res://scripts/world/stormwood_road_current.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
const PYLON_MATERIALS := preload("res://scripts/world/tether_pylon_materials.gd")

var game: Node
var _pylons: Array[Node3D] = []
var _beads: Array[MeshInstance3D] = []
var _aftermath_flag := ""
var _lit := true
var _revision := -1


static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH)) as Dictionary


## Every XZ point the rod line must stay clear of: each `at`/`position` in the
## exclusion sources (a 3-element position uses x and z), plus the junction of
## every spur route.
static func exclusions(cfg: Dictionary, routes: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for path: Variant in cfg.get("exclusion_sources", []):
		_collect(JSON.parse_string(FileAccess.get_file_as_string(str(path))), out)
	for route: Dictionary in routes:
		if str(route.get("kind", "")) == "spur":
			var first: Array = (route.points as Array)[0]
			out.append(Vector2(float(first[0]), float(first[1])))
	return out


static func _collect(value: Variant, out: Array[Vector2]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			var item: Variant = value[key]
			if (str(key) == "at" or str(key) == "position") and item is Array and (item as Array).size() >= 2:
				var a := item as Array
				out.append(Vector2(float(a[0]), float(a[2] if a.size() >= 3 else a[1])))
			else:
				_collect(item, out)
	elif value is Array:
		for item: Variant in value:
			_collect(item, out)


## The pylon stands in order along the rod line: [{at: Vector2, route: id,
## cable_from_previous: bool}].
static func layout(cfg: Dictionary, routes: Array) -> Array[Dictionary]:
	var by_id := {}
	for route: Dictionary in routes:
		by_id[str(route.id)] = route
	var current_cfg := ROAD_CURRENT.config()
	var avoid := exclusions(cfg, routes)
	var spacing := float(cfg.spacing_m)
	var offset := float(cfg.side_offset_m) * float(cfg.get("side_sign", 1))
	var radius := float(cfg.exclusion_radius_m)
	var lane_clear := float((JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH)) as Dictionary).route_half_width) \
		+ float(cfg.get("road_clear_m", 1.0))
	var lanes: Array[PackedVector2Array] = []
	for route: Dictionary in routes:
		if str(route.get("kind", "")) == "spur":
			continue
		var line := PackedVector2Array()
		for raw: Array in route.points:
			line.append(Vector2(float(raw[0]), float(raw[1])))
		lanes.append(line)
	var out: Array[Dictionary] = []
	var last := Vector2.INF
	for id: Variant in cfg.routes:
		if not by_id.has(str(id)):
			continue
		var points := ROAD_CURRENT.flow_points(by_id[str(id)], current_cfg)
		var total := 0.0
		for i in range(1, points.size()):
			total += points[i - 1].distance_to(points[i])
		var d := float(cfg.start_m)
		while d < total - spacing * 0.5:
			var at := _along(points, d)
			var dir := _direction(points, d)
			var side := Vector2(-dir.y, dir.x) * offset
			var stand := at + side
			var clear := true
			for p: Vector2 in avoid:
				if p.distance_to(stand) < radius:
					clear = false
					break
			if clear:
				clear = not _on_a_lane(stand, lanes, lane_clear)
			if clear:
				out.append({"at": stand, "route": str(id),
					"cable_from_previous": last != Vector2.INF and last.distance_to(stand) <= float(cfg.max_span_m)})
				last = stand
			else:
				last = Vector2.INF
			d += spacing
	return out


static func _on_a_lane(at: Vector2, lanes: Array[PackedVector2Array], clear_m: float) -> bool:
	for line: PackedVector2Array in lanes:
		for i in range(1, line.size()):
			if Geometry2D.get_closest_point_to_segment(at, line[i - 1], line[i]).distance_to(at) < clear_m:
				return true
	return false


static func _along(points: Array[Vector2], d: float) -> Vector2:
	var walked := 0.0
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if walked + seg >= d:
			return points[i - 1].lerp(points[i], (d - walked) / maxf(seg, 0.001))
		walked += seg
	return points[points.size() - 1]


static func _direction(points: Array[Vector2], d: float) -> Vector2:
	var walked := 0.0
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if walked + seg >= d:
			return (points[i] - points[i - 1]).normalized()
		walked += seg
	return (points[points.size() - 1] - points[points.size() - 2]).normalized()


func build(world: Node3D) -> void:
	if bool(world.get("simulation_only")):
		return
	game = get_node_or_null("/root/Game")
	var cfg := config()
	_aftermath_flag = str(cfg.get("aftermath_flag", ""))
	var routes: Array = (JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH)) as Dictionary).routes
	var scene := load(str(cfg.pylon_model)) as PackedScene
	if scene == null:
		push_error("StormwoodRodLine: missing pylon model %s" % str(cfg.pylon_model))
		return
	var cable_mat := StandardMaterial3D.new()
	cable_mat.albedo_color = Color(str(cfg.cable_colour))
	cable_mat.metallic = float(cfg.cable_metallic)
	cable_mat.roughness = float(cfg.cable_roughness)
	var bead_mat := StandardMaterial3D.new()
	bead_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bead_mat.albedo_color = Color(str(cfg.bead_colour))
	bead_mat.emission_enabled = true
	bead_mat.emission = Color(str(cfg.bead_colour))
	bead_mat.emission_energy_multiplier = float(cfg.bead_energy)
	var range_end := float(cfg.visibility_range_m)
	var attach := float(cfg.cable_attach_m)
	var previous_top := Vector3.INF
	for stand: Dictionary in layout(cfg, routes):
		var at: Vector2 = stand.at
		var ground := float(world.call("ground_height_at", at.x, at.y))
		var pylon := scene.instantiate() as Node3D
		var bounds := BOUNDS.measure(pylon)
		var s := float(cfg.pylon_height_m) / maxf(0.1, bounds.size.y)
		pylon.scale = Vector3.ONE * s
		pylon.name = "RodPylon%d" % _pylons.size()
		add_child(pylon)
		pylon.position = Vector3(at.x, ground - float(cfg.sink_m) - bounds.position.y * s, at.y)
		_set_range(pylon, range_end)
		_pylons.append(pylon)
		var top := Vector3(at.x, ground + attach, at.y)
		var bead := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = float(cfg.bead_radius_m)
		sphere.height = sphere.radius * 2.0
		bead.mesh = sphere
		bead.material_override = bead_mat
		bead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bead.visibility_range_end = range_end
		add_child(bead)
		bead.position = top
		_beads.append(bead)
		if bool(stand.cable_from_previous) and previous_top != Vector3.INF:
			_cable(previous_top, top, cfg, cable_mat, range_end)
		previous_top = top
	add_to_group("progression_restore")
	restore_progression_from_game(game)


func _cable(a: Vector3, b: Vector3, cfg: Dictionary, material: Material, range_end: float) -> void:
	var segments := int(cfg.cable_segments)
	var sag := float(cfg.cable_sag_m)
	var radius := float(cfg.cable_radius_m)
	var prev := a
	for i in range(1, segments + 1):
		var t := float(i) / float(segments)
		var p := a.lerp(b, t)
		p.y -= sag * 4.0 * t * (1.0 - t)
		var length := prev.distance_to(p)
		var piece := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = length
		cyl.radial_segments = 6
		cyl.rings = 1
		piece.mesh = cyl
		piece.material_override = material
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.visibility_range_end = range_end
		add_child(piece)
		piece.position = (prev + p) * 0.5
		var up := (p - prev).normalized()
		var basis := Basis()
		basis.y = up
		basis.x = up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT).normalized()
		basis.z = basis.x.cross(up).normalized()
		piece.basis = basis
		prev = p


static func _set_range(node: Node, range_end: float) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).visibility_range_end = range_end
	for child: Node in node.get_children():
		_set_range(child, range_end)


func restore_progression_from_game(_game: Node) -> void:
	var lit := true
	if game != null and not _aftermath_flag.is_empty():
		lit = not bool((game.get("progression") as RefCounted).call("has", _aftermath_flag))
	_lit = lit
	for pylon: Node3D in _pylons:
		PYLON_MATERIALS.apply(pylon, lit)
	for bead: MeshInstance3D in _beads:
		bead.visible = lit


## The Long Storm can end while this scene is live (dynamo:release): follow
## the progression store's revision, as stormwood_rod_stations.gd does.
func _process(_delta: float) -> void:
	if game == null or _pylons.is_empty():
		return
	var flags: RefCounted = game.get("progression")
	var revision := int(flags.get("revision"))
	if revision == _revision:
		return
	_revision = revision
	var lit := not bool(flags.call("has", _aftermath_flag))
	if lit != _lit:
		restore_progression_from_game(game)


func pylon_count() -> int:
	return _pylons.size()
