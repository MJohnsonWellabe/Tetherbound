extends Node3D

## Cloudreach Cliffs' data-driven world shell.
##
## The chapter's macro layout lives in `data/config/cloudreach_world.json`.
## This node turns that authored region/route graph into solid, traversable
## cliff plates, ramps, suspended bridges and landmark silhouettes.  It is a
## deliberately separate world builder rather than another branch inside the
## Meadows' 1,700-line runtime composer.

const CONFIG_PATH := "res://data/config/cloudreach_world.json"
const VISUAL_CONFIG_PATH := "res://data/config/cloudreach_visual.json"
const REALM_ID := "cloudreach"
const REALM_GATE := preload("res://scripts/world/realm_gate.gd")
const GROUND_COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const BUILDING_PREFABS := preload("res://scripts/world/building_prefabs.gd")
const ROUTE_DETAIL_SCENES := {
	"bush": preload("res://assets/environment/stylized_nature/Bush_Common.gltf"),
	"flowers": preload("res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf"),
	"rock": preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	"rock_low": preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
	"paving": preload("res://assets/environment/stylized_nature/RockPath_Round_Wide.gltf"),
	"fence": preload("res://assets/buildings/quaternius_medieval/Prop_WoodenFence_Extension2.gltf"),
	"wagon": preload("res://assets/buildings/quaternius_medieval/Prop_Wagon.gltf"),
	"crate": preload("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"),
	"barrel": preload("res://assets/props/quaternius_fantasy/Barrel.gltf"),
}
const NATURE_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/CommonTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_3.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_4.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_5.gltf"),
]
const WIND_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/TwistedTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_4.gltf"),
]
const NATURE_ROCKS: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
const CLOUDREACH_LEAF_TEXTURE := preload(
	"res://assets/environment/stylized_nature/derived/Leaves_NormalTree_C_desat55_b100.png")

@onready var _player: CharacterBody3D = $Player
@onready var _camera_rig: Node3D = $CameraRig

var _config: Dictionary = {}
var _visual_config: Dictionary = {}
var _surfaces: Array[Dictionary] = []
var _cover_patches: Array[Dictionary] = []
var _materials: Dictionary = {}
var _tree_palette_materials: Dictionary = {}
var _region_count := 0
var _landmark_count := 0
var _progression_revision := -1
var _progression_gates: Array[Dictionary] = []
var _building_prefabs: RefCounted


func _ready() -> void:
	add_to_group("progression_restore")
	_config = _read_json(CONFIG_PATH)
	_visual_config = _read_json(VISUAL_CONFIG_PATH)
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
	_build_authored_route_details()
	_build_ground_cover()
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
		elif kind == "ellipse":
			var centre: Vector2 = surface.get("centre", Vector2.ZERO)
			var half: Vector2 = surface.get("half", Vector2.ONE)
			var local := Vector2(x - centre.x, z - centre.y).rotated(
				-float(surface.get("rotation", 0.0)))
			if half.x > 0.01 and half.y > 0.01 \
					and local.x * local.x / (half.x * half.x) \
					+ local.y * local.y / (half.y * half.y) <= 1.0:
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
	# Reuse the exact Meadows terrain family. World-space triplanar projection
	# keeps the texture scale coherent across cliff walls, caps and sloping
	# route ribbons without requiring UVs on every generated landform.
	var surface: Dictionary = _visual_config.get("surface", {})
	var cliff_surface: Dictionary = surface.get("cliff", {})
	_materials["cliff"] = _textured_material(_surface_tint(cliff_surface, "#c9865f"), Color("#c9865f"))
	_materials["cliff_high"] = _textured_material(_surface_tint(cliff_surface, "#e3ac79"), Color("#e3ac79"))
	_materials["cliff_mid"] = _textured_material(_surface_tint(cliff_surface, "#ad704f"), Color("#ad704f"))
	_materials["cliff_deep"] = _textured_material(_surface_tint(cliff_surface, "#82594a"), Color("#82594a"))
	_materials["cliff_shadow"] = _material(Color("#3f2b2a"), 1.0)
	_materials["upland"] = _textured_material(surface.get("upland", {}), Color("#e8dfbf"))
	_materials["upland_dry"] = _textured_material(surface.get("upland_dry", {}), Color("#e4d5aa"))
	_materials["path"] = _textured_material(surface.get("path", {}), Color("#caa77f"))
	_materials["stone"] = _textured_material(_surface_tint(cliff_surface, "#906955"), Color("#906955"))
	_materials["stone_light"] = _textured_material(_surface_tint(cliff_surface, "#cbae82"), Color("#cbae82"))
	_materials["wood"] = _material(Color("#432d24"), 1.0)
	_materials["rope"] = _material(Color("#8f7048"), 1.0)
	_materials["leaf"] = _material(Color("#4f623d"), 0.94)
	_materials["leaf_gold"] = _material(Color("#8f8744"), 0.94)
	_materials["tether"] = _material(Color("#651f2b"), 0.82)
	_materials["heart"] = _emissive_material(Color("#5ee0c2"), 1.35)
	_materials["wind_veil"] = _wind_veil_material()
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
	# The former stretched SphereMesh puffs read as dark/white floating debris
	# from several real gameplay angles. Keep the cloud sea and atmospheric fog;
	# authored sky banks return only with a proper soft-cloud material.


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
		var landmass: Dictionary = _visual_config.get("landmass", {})
		var size := Vector3(
			clampf((max_x - min_x) * float(landmass.get("region_width_factor", 0.30)),
				float(landmass.get("min_width_m", 260.0)), float(landmass.get("max_width_m", 560.0))),
			maxf(18.0, top - bottom),
			clampf((max_z - min_z) * float(landmass.get("region_depth_factor", 0.28)),
				float(landmass.get("min_depth_m", 220.0)), float(landmass.get("max_depth_m", 460.0))))
		var centre := Vector3(authored.x, (top + bottom) * 0.5, authored.z)
		var node := Node3D.new()
		node.name = _safe_name(str(spec.get("id", "Region")))
		root.add_child(node)
		var region_mass := _mesa(node, "CliffMass", centre, size, _materials["cliff"],
			_materials["upland_dry"] if int(spec.get("order", 0)) >= 5 else _materials["upland"], true,
			int(spec.get("order", 0)))
		_add_cliff_strata(node, centre, size, top)
		_add_satellite_crags(node, centre, size, top, int(spec.get("order", 0)))
		_add_wind_vegetation(node,
			Rect2(centre.x - size.x * 0.5, centre.z - size.z * 0.5, size.x, size.z),
			top, int(spec.get("order", 0)))
		_cover_patches.append({
			"kind": "ellipse", "centre": Vector3(centre.x, top, centre.z),
			# Conservative inside the rotated irregular crown; no grass can hang
			# in the air at the ellipse corners.
			"half": Vector2(size.x, size.z) * 0.34,
			"seed": int(spec.get("order", 0)) * 101,
			"dry": int(spec.get("order", 0)) >= 5,
		})
		# Match the real rotated irregular crown conservatively. The old enclosing
		# rectangle reported invisible corner air as ground, which could place a
		# loaded player or an evidence camera beside a floating island.
		_surfaces.append({"kind": "ellipse", "centre": Vector2(centre.x, centre.z),
			"half": Vector2(size.x, size.z) * 0.30,
			"rotation": region_mass.rotation.y, "height": top})
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
		_cover_patches.append({"kind": "ellipse", "centre": at, "half": Vector2(17.0, 17.0),
			"seed": int(absf(at.x + at.z)) + 501, "dry": false})


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
	# Keep companions lateral/back from each region's main south-to-north
	# approach. A former front-centre crag hid both Cliffhold and the Summit from
	# their authored roads, turning destination vistas into blank walls.
	const OFFSETS := [Vector2(-0.62, -0.12), Vector2(0.60, 0.36)]
	for i in OFFSETS.size():
		var offset: Vector2 = OFFSETS[(i + order) % OFFSETS.size()]
		var crag_top := top - 18.0 - float((i + order) % 3) * 14.0
		var crag_height := clampf(size.y * (0.34 + 0.07 * i), 22.0, 72.0)
		var at := Vector3(
			centre.x + offset.x * size.x,
			crag_top - crag_height * 0.5,
			centre.z + offset.y * size.z)
		_mesa(parent, "SatelliteCrag%d" % i, at,
			Vector3(size.x * (0.17 + i * 0.025), crag_height, size.z * (0.19 + i * 0.025)),
			_materials["cliff_mid"],
			_materials["upland_dry"] if order >= 5 else _materials["upland"],
			false, order * 7 + i)


func _add_wind_vegetation(parent: Node3D, rect: Rect2, top: float, order: int) -> void:
	var nature: Dictionary = _visual_config.get("nature", {})
	var centre := rect.get_center()
	var half := rect.size * 0.5
	var tree_count := maxi(12, int(nature.get("tree_count_base", 27))
		- order * int(nature.get("tree_count_order_falloff", 2)))
	for i in tree_count:
		# Golden-angle groups are biased into three groves, leaving authored open
		# sky between them instead of distributing one tree every N metres.
		var grove := i % 3
		var grove_angle := float(grove) * TAU / 3.0 + float(order) * 0.61
		var angle := grove_angle + sin(float(i * 17 + order * 5)) * 0.42
		var radius := 0.22 + 0.52 * sqrt(fmod(float(i) * 0.6180339 + float(order) * 0.17, 1.0))
		var at := Vector3(centre.x + cos(angle) * half.x * radius, top,
			centre.y + sin(angle) * half.y * radius)
		var tree_scene := WIND_TREES[order % WIND_TREES.size()] if i == 0 \
			else NATURE_TREES[(i + order) % NATURE_TREES.size()]
		var tree := tree_scene.instantiate() as Node3D
		tree.name = "WindTree%d" % i
		tree.position = at
		# Keep trunks planted and readable; wind character comes from clustered
		# crowns and the asset silhouettes, not from visibly uprooting whole trees.
		tree.rotation = Vector3(0.0, angle + 0.4,
			deg_to_rad(-0.5 - float((i + order) % 4) * 0.8))
		var scale_min := float(nature.get("tree_scale_min", 1.12))
		var scale_max := float(nature.get("tree_scale_max", 1.92))
		var scale_value := lerpf(scale_min, scale_max,
			float(posmod(i * 7 + order * 3, 11)) / 10.0)
		if i == 0:
			# Twisted trees are natively 16–19 m tall, versus 7–9 m for the
			# common canopy, so their final multiplier must be smaller.
			scale_value = 0.82 + float(order % 3) * 0.07
		tree.scale = Vector3.ONE * scale_value
		_apply_tree_palette(tree, i + order * 17)
		parent.add_child(tree)
		_set_geometry_visibility(tree, float(nature.get("tree_visibility_range_m", 1050.0)))
	for i in int(nature.get("rock_count", 16)):
		var angle := fmod(float(i) * 2.071 + float(order) * 0.39, TAU)
		var radius := 0.24 + 0.63 * sqrt(fmod(float(i) * 0.4142 + 0.13 * order, 1.0))
		var at := Vector3(centre.x + cos(angle) * half.x * radius, top - 0.18,
			centre.y + sin(angle) * half.y * radius)
		var rock := NATURE_ROCKS[(i * 2 + order) % NATURE_ROCKS.size()].instantiate() as Node3D
		rock.name = "BeddedRock%d" % i
		rock.position = at
		rock.rotation.y = angle
		rock.scale = Vector3.ONE * lerpf(float(nature.get("rock_scale_min", 0.85)),
			float(nature.get("rock_scale_max", 1.75)), float(posmod(i * 5 + order, 9)) / 8.0)
		parent.add_child(rock)
		_set_geometry_visibility(rock, float(nature.get("rock_visibility_range_m", 820.0)))


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
		var landmass: Dictionary = _visual_config.get("landmass", {})
		var collision_width := minf(width, float(landmass.get("path_collision_width_m", 7.0)))
		var visible_width := minf(collision_width - 0.8,
			float(landmass.get("path_visible_width_m", 4.2)))
		_build_route_shoulders(root, spec, points, width)
		var route_name_lower := str(spec.get("id", "")).to_lower()
		var landing_top: Material = _materials["upland_dry"] if (
			route_name_lower.contains("upper") or route_name_lower.contains("summit")
		) else _materials["upland"]
		for i in points.size():
			var pad := points[i]
			var landing_size := maxf(float(landmass.get("landing_size_m", 16.0)),
				collision_width * 2.25)
			_mesa(root, "%s_Ledge%d" % [_safe_name(str(spec.get("id", "Route"))), i],
				pad - Vector3.UP * 7.0, Vector3(landing_size, 14.0, landing_size),
				_materials["cliff"], landing_top, false,
				i * 19 + absi(str(spec.get("id", "Route")).hash()))
			# A shallow walkable cap bridges the several sloped path boxes meeting
			# here. The irregular cliff below carries the silhouette; this cap keeps
			# the joint from exposing a sky crack at player eye height.
			_box(root, "%s_LedgeCap%d" % [_safe_name(str(spec.get("id", "Route"))), i],
				pad - Vector3.UP * 0.42, Vector3(landing_size * 0.82, 0.84, landing_size * 0.82),
				landing_top, true)
			_add_landing_nature(root, points, i, pad, landing_size,
				i * 43 + absi(str(spec.get("id", "Route")).hash()))
			_surfaces.append({"kind": "rect", "centre": Vector2(pad.x, pad.z),
				"half": Vector2.ONE * landing_size * 0.44, "height": pad.y})
		for i in points.size() - 1:
			var route_label := "%s_%d" % [_safe_name(str(spec.get("id", "Route"))), i]
			var sections := _ground_sections_for_segment(str(spec.get("id", "")),
				points[i], points[i + 1])
			for section_index in sections.size():
				var section: Dictionary = sections[section_index]
				var section_a: Vector3 = section["a"]
				var section_b: Vector3 = section["b"]
				# Keep one forgiving collision ribbon for controller traversal, but
				# let the visible trail meander and breathe inside it. Bridge intervals
				# are omitted completely so the authored span and drop are real.
				_segment_box(root, "%sGround%d" % [route_label, section_index], section_a,
					section_b, collision_width, 0.72, landing_top, true)
				_path_ribbon(root, "%sTrail%d" % [route_label, section_index], section_a,
					section_b, visible_width,
					i * 97 + section_index * 31 + absi(str(spec.get("id", "Route")).hash()))
				_surfaces.append({"kind": "segment", "a": section_a, "b": section_b,
					"half_width": collision_width * 0.5, "height": section_a.y})


func _add_landing_nature(parent: Node3D, points: Array[Vector3], index: int,
		pad: Vector3, landing_size: float, seed_value: int) -> void:
	if points.size() < 2 or posmod(seed_value, 4) == 0:
		return
	var previous := points[maxi(0, index - 1)]
	var following := points[mini(points.size() - 1, index + 1)]
	var flat := Vector3(following.x - previous.x, 0.0, following.z - previous.z)
	if flat.length_squared() < 0.01:
		return
	var right := Vector3.UP.cross(flat.normalized()).normalized()
	var side := -1.0 if posmod(seed_value, 2) == 0 else 1.0
	var tree := NATURE_TREES[posmod(seed_value, NATURE_TREES.size())].instantiate() as Node3D
	tree.name = "LandingTree%03d" % posmod(seed_value, 1000)
	tree.position = pad + right * side * landing_size * 0.46 - Vector3.UP * 0.32
	tree.rotation.y = float(posmod(seed_value * 17, 41)) / 41.0 * TAU
	tree.rotation.z = deg_to_rad(-0.8 - float(posmod(seed_value, 3)) * 0.6)
	tree.scale = Vector3.ONE * (1.32 + float(posmod(seed_value * 7, 7)) * 0.085)
	_apply_tree_palette(tree, seed_value)
	parent.add_child(tree)
	var nature: Dictionary = _visual_config.get("nature", {})
	_set_geometry_visibility(tree, float(nature.get("tree_visibility_range_m", 1050.0)))


func _build_route_shoulders(root: Node3D, spec: Dictionary, points: Array[Vector3], width: float) -> void:
	var route_name := _safe_name(str(spec.get("id", "Route")))
	var shoulder_root := Node3D.new()
	shoulder_root.name = "%sCliffShoulders" % route_name
	root.add_child(shoulder_root)
	var landmass: Dictionary = _visual_config.get("landmass", {})
	var serial := 0
	for segment_index in points.size() - 1:
		var original_a := points[segment_index]
		var original_b := points[segment_index + 1]
		var half_width := maxf(float(landmass.get("route_shoulder_min_half_width_m", 24.0)),
			width * float(landmass.get("route_shoulder_path_multiplier", 3.8)))
		var route_is_dry := route_name.to_lower().contains("upper") \
			or route_name.to_lower().contains("summit")
		var sections := _ground_sections_for_segment(str(spec.get("id", "")),
			original_a, original_b)
		for section: Dictionary in sections:
			var a: Vector3 = section["a"]
			var b: Vector3 = section["b"]
			_route_ridge(shoulder_root, "Ridge%03d" % serial, a, b, half_width,
				segment_index + int(spec.get("order", 0)) * 17 + serial,
				_materials["upland_dry"] if route_is_dry else _materials["upland"], landmass)
			_add_route_edge_nature(shoulder_root, a, b, half_width, serial)
			var cover_config: Dictionary = _visual_config.get("ground_cover", {})
			var cover_chunks := maxi(1, int(ceilf(a.distance_to(b)
				/ float(cover_config.get("route_cover_chunk_m", 120.0)))))
			for chunk in cover_chunks:
				var chunk_a := a.lerp(b, float(chunk) / float(cover_chunks))
				var chunk_b := a.lerp(b, float(chunk + 1) / float(cover_chunks))
				_cover_patches.append({
					"kind": "segment", "a": chunk_a, "b": chunk_b,
					# The ribbon's narrowest generated station is 0.58x. Sampling
					# inside 0.52x leaves margin even between different-width stations.
					"half_width": half_width * 0.52,
					"path_half_width": width * 0.5,
					"seed": serial * 3701 + chunk * 101 + absi(route_name.hash()),
					"surface_offset_y": -0.70,
					"dry": route_is_dry,
				})
			serial += 1


## Split an authored ground segment around every bridge assigned to its route.
## The first foundation pass placed bridge meshes over a continuous land ribbon,
## so no causeway actually exposed sky or danger. Keeping the cut here makes the
## same gap authoritative for cliff mass, trail visuals, cover, and collision.
func _ground_sections_for_segment(route_id: String, a: Vector3, b: Vector3) -> Array[Dictionary]:
	var delta := b - a
	var length_squared := delta.length_squared()
	if length_squared < 0.01:
		return []
	var cut_start := 1.0
	var cut_end := 0.0
	for raw: Variant in _config.get("bridges", []):
		if not raw is Dictionary:
			continue
		var bridge := raw as Dictionary
		if str(bridge.get("route_id", "")) != route_id:
			continue
		var endpoints: Variant = bridge.get("endpoints", [])
		if not endpoints is Array or (endpoints as Array).size() < 2:
			continue
		var p0 := _vec3((endpoints as Array)[0])
		var p1 := _vec3((endpoints as Array)[1])
		var t0 := (p0 - a).dot(delta) / length_squared
		var t1 := (p1 - a).dot(delta) / length_squared
		var distance0 := p0.distance_to(a + delta * clampf(t0, 0.0, 1.0))
		var distance1 := p1.distance_to(a + delta * clampf(t1, 0.0, 1.0))
		# A bridge can straddle a polyline joint, so each adjacent segment sees
		# the nearby portion while unrelated segments on the same route do not.
		if minf(distance0, distance1) > 145.0:
			continue
		var margin := 8.0 / maxf(delta.length(), 1.0)
		var local_start := clampf(minf(t0, t1) - margin, 0.0, 1.0)
		var local_end := clampf(maxf(t0, t1) + margin, 0.0, 1.0)
		if local_end <= 0.0 or local_start >= 1.0 or local_end - local_start < 0.015:
			continue
		cut_start = minf(cut_start, local_start)
		cut_end = maxf(cut_end, local_end)
	var result: Array[Dictionary] = []
	if cut_end <= cut_start:
		result.append({"a": a, "b": b})
		return result
	if cut_start > 0.035:
		result.append({"a": a, "b": a.lerp(b, cut_start)})
	if cut_end < 0.965:
		result.append({"a": a.lerp(b, cut_end), "b": b})
	return result


func _build_ground_cover() -> void:
	var cover := GROUND_COVER.new()
	cover.name = "ProceduralGroundCover"
	add_child(cover)
	cover.call("build", _cover_patches, _visual_config.get("ground_cover", {}))


func _route_ridge(parent: Node3D, label: String, a: Vector3, b: Vector3,
		half_width: float, seed_value: int, top_material: Material, config: Dictionary) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var forward := flat.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	var spacing := float(config.get("route_station_spacing_m", 48.0))
	var station_count := clampi(int(ceilf(flat.length() / maxf(spacing, 8.0))) + 1, 3, 28)
	var left_top: Array[Vector3] = []
	var right_top: Array[Vector3] = []
	var left_upper: Array[Vector3] = []
	var right_upper: Array[Vector3] = []
	var left_lower: Array[Vector3] = []
	var right_lower: Array[Vector3] = []
	var left_bottom: Array[Vector3] = []
	var right_bottom: Array[Vector3] = []
	for i in station_count:
		var t := float(i) / float(station_count - 1)
		var centre := a.lerp(b, t) - Vector3.UP * 0.72
		var irregular := 0.84 + 0.18 * sin(float(i * 13 + seed_value * 7))
		irregular += 0.08 * cos(float(i * 5 + seed_value * 3))
		var width_here := half_width * irregular
		var left := centre - right * width_here
		var right_edge := centre + right * width_here
		var depth_mix := 0.5 + 0.5 * sin(float(i * 11 + seed_value * 17))
		var depth := lerpf(float(config.get("route_cliff_depth_min_m", 36.0)),
			float(config.get("route_cliff_depth_max_m", 92.0)), depth_mix)
		left_top.append(left)
		right_top.append(right_edge)
		var upper_push := 1.02 + 0.06 * sin(float(i * 7 + seed_value * 5))
		var lower_push := 0.84 + 0.05 * cos(float(i * 9 + seed_value * 3))
		left_upper.append(centre + (left - centre) * upper_push - Vector3.UP * depth * 0.28)
		right_upper.append(centre + (right_edge - centre) * upper_push - Vector3.UP * depth * 0.25)
		left_lower.append(centre + (left - centre) * lower_push - Vector3.UP * depth * 0.68)
		right_lower.append(centre + (right_edge - centre) * lower_push - Vector3.UP * depth * 0.64)
		left_bottom.append(centre + (left - centre) * 0.62 - Vector3.UP * depth)
		right_bottom.append(centre + (right_edge - centre) * 0.62 - Vector3.UP * (depth * 0.94))

	var mesh := ArrayMesh.new()
	var top_tool := SurfaceTool.new()
	top_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	top_tool.set_material(top_material)
	for i in station_count - 1:
		_add_surface_triangle(top_tool, left_top[i], left_top[i + 1], right_top[i])
		_add_surface_triangle(top_tool, right_top[i], left_top[i + 1], right_top[i + 1])
	top_tool.generate_normals()
	top_tool.commit(mesh)

	var upper_tool := SurfaceTool.new()
	upper_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper_tool.set_material(_materials["cliff_high"])
	for i in station_count - 1:
		_add_surface_triangle(upper_tool, left_top[i], left_upper[i], left_top[i + 1])
		_add_surface_triangle(upper_tool, left_upper[i], left_upper[i + 1], left_top[i + 1])
		_add_surface_triangle(upper_tool, right_top[i], right_top[i + 1], right_upper[i])
		_add_surface_triangle(upper_tool, right_upper[i], right_top[i + 1], right_upper[i + 1])
	upper_tool.generate_normals()
	upper_tool.commit(mesh)

	var middle_tool := SurfaceTool.new()
	middle_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	middle_tool.set_material(_materials["cliff_mid"])
	for i in station_count - 1:
		_add_surface_triangle(middle_tool, left_upper[i], left_lower[i], left_upper[i + 1])
		_add_surface_triangle(middle_tool, left_lower[i], left_lower[i + 1], left_upper[i + 1])
		_add_surface_triangle(middle_tool, right_upper[i], right_upper[i + 1], right_lower[i])
		_add_surface_triangle(middle_tool, right_lower[i], right_upper[i + 1], right_lower[i + 1])
	middle_tool.generate_normals()
	middle_tool.commit(mesh)

	var deep_tool := SurfaceTool.new()
	deep_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	deep_tool.set_material(_materials["cliff_deep"])
	for i in station_count - 1:
		_add_surface_triangle(deep_tool, left_lower[i], left_bottom[i], left_lower[i + 1])
		_add_surface_triangle(deep_tool, left_bottom[i], left_bottom[i + 1], left_lower[i + 1])
		_add_surface_triangle(deep_tool, right_lower[i], right_lower[i + 1], right_bottom[i])
		_add_surface_triangle(deep_tool, right_bottom[i], right_lower[i + 1], right_bottom[i + 1])
	# End faces prevent the ribbon's first/last station reading as a sliced box.
	_add_surface_triangle(deep_tool, left_top[0], right_top[0], left_bottom[0])
	_add_surface_triangle(deep_tool, left_bottom[0], right_top[0], right_bottom[0])
	var last := station_count - 1
	_add_surface_triangle(deep_tool, left_top[last], left_bottom[last], right_top[last])
	_add_surface_triangle(deep_tool, left_bottom[last], right_bottom[last], right_top[last])
	deep_tool.generate_normals()
	deep_tool.commit(mesh)

	var ridge := MeshInstance3D.new()
	ridge.name = label
	ridge.mesh = mesh
	ridge.visibility_range_end = 1900.0
	ridge.visibility_range_end_margin = 160.0
	parent.add_child(ridge)


func _add_surface_triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.set_uv(Vector2(a.x, a.z) * 0.04)
	tool.add_vertex(a)
	tool.set_uv(Vector2(b.x, b.z) * 0.04)
	tool.add_vertex(b)
	tool.set_uv(Vector2(c.x, c.z) * 0.04)
	tool.add_vertex(c)


func _path_ribbon(parent: Node3D, label: String, a: Vector3, b: Vector3,
		width: float, seed_value: int) -> void:
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var right := Vector3.UP.cross(flat.normalized()).normalized()
	var up := _segment_basis(a, b).y
	var stations := clampi(int(ceilf(flat.length() / 14.0)) + 1, 5, 42)
	var left: Array[Vector3] = []
	var right_edge: Array[Vector3] = []
	for i in stations:
		var t := float(i) / float(stations - 1)
		var envelope := sin(PI * t)
		var wander := sin(t * TAU * 1.35 + float(seed_value % 29)) * width * 0.24 * envelope
		wander += sin(t * TAU * 3.1 + float(seed_value % 11)) * width * 0.08 * envelope
		var half_here := width * (0.43 + 0.08 * sin(t * TAU * 2.4 + float(seed_value % 17)))
		var centre := a.lerp(b, t) + right * wander + up * 0.06
		left.append(centre - right * half_here)
		right_edge.append(centre + right * half_here)
	var mesh := ArrayMesh.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_material(_materials["path"])
	for i in stations - 1:
		_add_surface_triangle(tool, left[i], left[i + 1], right_edge[i])
		_add_surface_triangle(tool, right_edge[i], left[i + 1], right_edge[i + 1])
	tool.generate_normals()
	tool.commit(mesh)
	var trail := MeshInstance3D.new()
	trail.name = label
	trail.mesh = mesh
	trail.visibility_range_end = 1200.0
	trail.visibility_range_end_margin = 100.0
	parent.add_child(trail)


func _add_route_edge_nature(parent: Node3D, a: Vector3, b: Vector3,
		half_width: float, serial: int) -> void:
	var nature: Dictionary = _visual_config.get("nature", {})
	var flat := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if flat.length_squared() < 0.01:
		return
	var forward := flat.normalized()
	var right := Vector3.UP.cross(forward).normalized()
	# A route segment can be several hundred metres long. Populate it in
	# readable edge clusters rather than putting one tiny grove at its midpoint.
	var cluster_count := clampi(int(ceilf(flat.length() / 74.0)), 3, 9)
	for cluster in cluster_count:
		var t := float(cluster + 1) / float(cluster_count + 1)
		# The route ridge's walkable top sits below the authored spline. Keep all
		# imported nature rooted into that same generated surface.
		var anchor := a.lerp(b, t) - Vector3.UP * 0.72
		var side := -1.0 if (serial + cluster) % 2 == 0 else 1.0
		var rock := NATURE_ROCKS[(serial + cluster) % NATURE_ROCKS.size()].instantiate() as Node3D
		rock.name = "RouteRock%03d_%d" % [serial, cluster]
		rock.position = anchor + right * side * half_width * 0.70 - Vector3.UP * 0.32
		rock.rotation.y = float(posmod(serial * 17 + cluster * 11, 31)) / 31.0 * TAU
		rock.scale = Vector3.ONE * (1.0 + float(posmod(serial * 7 + cluster * 5, 9)) * 0.10)
		parent.add_child(rock)
		_set_geometry_visibility(rock, float(nature.get("rock_visibility_range_m", 820.0)))
		for grove_tree in 2:
			# Skip occasional trees to preserve windswept openings and sightlines.
			if posmod(serial * 3 + cluster * 5 + grove_tree, 7) == 0:
				continue
			var tree := NATURE_TREES[(serial + cluster + grove_tree) % NATURE_TREES.size()].instantiate() as Node3D
			tree.name = "RouteTree%03d_%d_%d" % [serial, cluster, grove_tree]
			tree.position = (
				anchor + right * side * half_width * (0.64 + grove_tree * 0.17)
				+ forward * (float(grove_tree) - 0.5) * 10.0
			)
			tree.rotation = Vector3(0.0,
				float(posmod(serial * 13 + cluster * 7 + grove_tree * 19, 37)) / 37.0 * TAU,
				deg_to_rad(-0.4 - float(grove_tree) * 1.1))
			tree.scale = Vector3.ONE * (1.28
				+ float(posmod(serial * 5 + cluster * 3 + grove_tree * 3, 8)) * 0.085)
			_apply_tree_palette(tree, serial * 31 + cluster * 7 + grove_tree)
			parent.add_child(tree)
			_set_geometry_visibility(tree, float(nature.get("tree_visibility_range_m", 1050.0)))


func _set_geometry_visibility(root_node: Node, distance: float) -> void:
	if root_node is GeometryInstance3D:
		var geometry := root_node as GeometryInstance3D
		geometry.visibility_range_end = distance
		geometry.visibility_range_end_margin = minf(120.0, distance * 0.14)
	for child: Node in root_node.get_children():
		_set_geometry_visibility(child, distance)


## Small, individually authored places along the road. Imported meshes retain
## their production materials; the shared prefab utility measures real bounds
## so barrels, wagons and shrubs agree with the 1.80 m trainer.
func _build_authored_route_details() -> void:
	var root := Node3D.new()
	root.name = "AuthoredRouteDetails"
	add_child(root)
	var detail: Dictionary = _visual_config.get("route_details", {})
	var bounds_tool := BUILDING_PREFABS.new()
	for raw: Dictionary in detail.get("pockets", []):
		var pocket := Node3D.new()
		pocket.name = str(raw.get("id", "Pocket"))
		root.add_child(pocket)
		var anchor := _vec3(raw.get("anchor", []))
		var forward := _vec3(raw.get("forward", [0.0, 0.0, 1.0])).normalized()
		forward.y = 0.0
		forward = forward.normalized()
		var right := Vector3.UP.cross(forward)
		for item: Dictionary in raw.get("items", []):
			var asset := str(item.get("asset", "rock"))
			var packed := ROUTE_DETAIL_SCENES.get(asset) as PackedScene
			if packed == null:
				continue
			var offset: Array = item.get("offset", [0.0, 0.0])
			var at := anchor + right * float(offset[0]) + forward * float(offset[1])
			var ground := _route_detail_ground(at)
			if is_nan(ground):
				push_warning("Cloudreach detail %s/%s has no supporting surface" % [pocket.name, asset])
				continue
			var model := packed.instantiate() as Node3D
			var bounds: AABB = bounds_tool.combined_aabb(model)
			var span := maxf(bounds.size.x, bounds.size.z) if item.has("width_m") else bounds.size.y
			var size_m := float(item.get("width_m", item.get("height_m", 1.0)))
			var scale_value := size_m / maxf(span, 0.01)
			var placement := Node3D.new()
			placement.name = "%s%02d" % [asset.capitalize(), pocket.get_child_count()]
			placement.position = Vector3(at.x, ground - float(item.get("bury_m", 0.04)), at.z)
			placement.rotation.y = atan2(forward.x, forward.z) + deg_to_rad(float(item.get("yaw_deg", 0.0)))
			pocket.add_child(placement)
			model.scale = Vector3.ONE * scale_value
			model.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
			placement.add_child(model)
			if asset == "bush" or asset == "flowers":
				_apply_tree_palette(model, pocket.get_child_count())
			_set_geometry_visibility(placement, float(detail.get("visibility_range_m", 320.0)))


## Route shoulders are visual ground, while the controller collision ribbon is
## narrower. Use the same conservative shoulder samples as ground cover, and
## reject unrelated stacked plateaus rather than floating a prop across a gap.
func _route_detail_ground(at: Vector3) -> float:
	var ground := ground_height_at(at.x, at.z)
	if not is_nan(ground) and absf(ground - at.y) < 8.0:
		return ground
	for patch: Dictionary in _cover_patches:
		if str(patch.get("kind", "")) != "segment":
			continue
		var a: Vector3 = patch["a"]
		var b: Vector3 = patch["b"]
		var ab := Vector2(b.x - a.x, b.z - a.z)
		var t := Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01)
		if t < 0.0 or t > 1.0:
			continue
		var centre := a.lerp(b, t)
		if Vector2(at.x - centre.x, at.z - centre.z).length() > float(patch["half_width"]):
			continue
		var height := centre.y + float(patch.get("surface_offset_y", -0.72))
		if absf(height - at.y) < 8.0:
			return height
	return NAN


## Reuse the Meadows' desaturated green leaf sheet on the installed Quaternius
## trees. The source twisted-tree sheet is crimson and the raw common sheet is
## fluorescent; both break the project's one-nature-family palette. Surface
## overrides preserve the imported meshes, LOD chains, alpha mode and shadows.
func _apply_tree_palette(root_node: Node, seed_value: int) -> void:
	if root_node is MeshInstance3D:
		var instance := root_node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				var source := instance.mesh.surface_get_material(surface) as StandardMaterial3D
				if source == null:
					continue
				var key_name := source.resource_name.to_lower()
				if not key_name.contains("leaves") and not key_name.contains("bark"):
					continue
				var variant := posmod(seed_value, 3)
				var cache_key := "%s|%d" % [source.resource_path if source.resource_path != "" \
					else source.resource_name, variant]
				var material := _tree_palette_materials.get(cache_key) as StandardMaterial3D
				if material == null:
					material = source.duplicate(true) as StandardMaterial3D
					if key_name.contains("leaves"):
						material.albedo_texture = CLOUDREACH_LEAF_TEXTURE
						material.albedo_color = [Color("#eef1d5"), Color("#b9cbb5"),
							Color("#ded39a")][variant]
					else:
						material.albedo_color = [Color("#d4bc9e"), Color("#bda68f"),
							Color("#cbb08c")][variant]
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					_tree_palette_materials[cache_key] = material
				instance.set_surface_override_material(surface, material)
	for child: Node in root_node.get_children():
		_apply_tree_palette(child, seed_value)


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
		veil.material_override = _materials["wind_veil"]
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
		_cover_patches.append({"kind": "ellipse", "centre": at, "half": Vector2(16.5, 15.5),
			"inner_clear_fraction": 0.42, "seed": _landmark_count * 71 + 809,
			"dry": at.y >= 790.0})
		var landmark_id := str(spec.get("id", ""))
		var identity := (landmark_id + " " + str(spec.get("category", ""))).to_lower()
		if landmark_id == "realm_gate_crag":
			_build_realm_gate_crag(landmark)
		elif landmark_id == "three_bells_bridge":
			_build_three_bells(landmark)
		elif landmark_id == "broken_skyroad_arch":
			_build_broken_arch(landmark)
		elif landmark_id == "windscar_beacon":
			_build_windscar_beacon(landmark)
		elif landmark_id == "windscar_flight_aerie":
			_build_flight_aerie(landmark)
		elif landmark_id == "high_roost_perches":
			_build_high_perches(landmark)
		elif landmark_id == "old_wind_observatory":
			_build_observatory(landmark)
		elif landmark_id == "waterward_overlook":
			_build_waterward_overlook(landmark)
		elif identity.contains("settlement") or identity.contains("village"):
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
	if _building_prefabs == null:
		_building_prefabs = BUILDING_PREFABS.new()
		_building_prefabs.call("load_recipes")
	var settlement: Dictionary = _visual_config.get("settlement", {})
	for house: Dictionary in settlement.get("houses", []):
		var prefab := str(house["prefab"])
		var model := _building_prefabs.call("instantiate", prefab) as Node3D
		if model == null:
			continue
		model.name = "Terrace_%s_%d" % [prefab, root.get_child_count()]
		model.position = _vec3(house["position"])
		model.rotation.y = deg_to_rad(float(house.get("yaw_deg", 0.0)))
		root.add_child(model)
		# Reuse the prefab's authored wall boxes, including its open doorway.
		for collider: Dictionary in _building_prefabs.call("colliders", prefab):
			var body := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = _vec3(collider.get("size", [1.0, 1.0, 1.0]))
			shape.shape = box
			shape.position = _vec3(collider.get("at", [0.0, 0.0, 0.0]))
			body.add_child(shape)
			model.add_child(body)
		_set_geometry_visibility(model, float(settlement.get("visibility_range_m", 850.0)))


func _build_realm_gate_crag(root: Node3D) -> void:
	# The gate is deliberately above the arrival road; carry that elevation with
	# one readable cliff tower so the reveal is a grounded destination, not a
	# black frame apparently floating in empty sky.
	_mesa(root, "GateFoundationCrag", Vector3(0.0, -20.0, 2.0),
		Vector3(44.0, 40.0, 42.0), _materials["cliff"], _materials["upland"], false, 211)
	for side: float in [-1.0, 1.0]:
		_cylinder(root, "GateCrag", Vector3(side * 11.0, 12.0, 2.0), 4.2, 24.0, _materials["stone"])
		_cylinder(root, "GateNeedle", Vector3(side * 11.0, 27.0, 2.0), 1.8, 10.0, _materials["stone_light"])
	_box(root, "AncientGateLintel", Vector3(0.0, 22.0, 2.0), Vector3(24.0, 3.0, 4.0), _materials["stone_light"], false)
	_box(root, "RealmKeyGlow", Vector3(0.0, 26.0, 1.7), Vector3(7.0, 0.45, 0.35), _materials["heart"], false)


func _build_three_bells(root: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		_box(root, "BellPier", Vector3(side * 12.0, 8.0, 0.0), Vector3(3.2, 16.0, 4.0), _materials["stone"], false)
	_box(root, "BellBeam", Vector3(0.0, 16.0, 0.0), Vector3(28.0, 2.4, 3.0), _materials["wood"], false)
	for i in 3:
		var x := (float(i) - 1.0) * 7.0
		_cylinder(root, "BellRope%d" % i, Vector3(x, 12.5, 0.0), 0.10, 6.0, _materials["rope"])
		var bell := MeshInstance3D.new()
		bell.name = "SkyBell%d" % i
		bell.position = Vector3(x, 9.0, 0.0)
		var bell_mesh := SphereMesh.new()
		bell_mesh.radius = 1.25
		bell_mesh.height = 2.2
		bell.mesh = bell_mesh
		bell.scale = Vector3(1.0, 0.85, 1.0)
		bell.material_override = _materials["leaf_gold"]
		root.add_child(bell)


func _build_broken_arch(root: Node3D) -> void:
	_box(root, "WestArchPier", Vector3(-10.0, 10.0, 0.0), Vector3(5.0, 20.0, 6.0), _materials["stone"], false)
	_box(root, "EastArchPier", Vector3(10.0, 7.0, 0.0), Vector3(5.0, 14.0, 6.0), _materials["stone"], false)
	_box(root, "WestArchCrown", Vector3(-4.0, 20.0, 0.0), Vector3(10.0, 3.0, 6.0), _materials["stone_light"], false,
		Basis(Vector3.FORWARD, deg_to_rad(-8.0)))
	_box(root, "FallenArchCrown", Vector3(8.0, 2.0, 8.0), Vector3(12.0, 3.0, 5.0), _materials["stone_light"], false,
		Basis(Vector3.FORWARD, deg_to_rad(17.0)))


func _build_windscar_beacon(root: Node3D) -> void:
	_cylinder(root, "BeaconPlinth", Vector3(0.0, 2.0, 0.0), 8.0, 4.0, _materials["stone"])
	_cylinder(root, "BeaconTower", Vector3(0.0, 15.0, 0.0), 3.8, 26.0, _materials["stone_light"])
	_box(root, "BeaconCrossarm", Vector3(0.0, 25.0, 0.0), Vector3(18.0, 1.0, 1.4), _materials["wood"], false)
	_cylinder(root, "BeaconFire", Vector3(0.0, 30.0, 0.0), 1.8, 7.0, _materials["heart"])


func _build_flight_aerie(root: Node3D) -> void:
	_cylinder(root, "AerieDais", Vector3(0.0, 1.2, 0.0), 15.0, 2.4, _materials["stone_light"])
	for i in 5:
		var angle := TAU * float(i) / 5.0 + 0.35
		var height := 12.0 + float(i % 3) * 4.0
		_cylinder(root, "AeriePerch%d" % i,
			Vector3(cos(angle) * 11.0, height * 0.5 + 2.0, sin(angle) * 8.0),
			0.65, height, _materials["wood"])
	_box(root, "LaunchStone", Vector3(0.0, 2.3, -13.0), Vector3(12.0, 1.0, 12.0), _materials["path"], false)


func _build_high_perches(root: Node3D) -> void:
	for i in 6:
		var angle := TAU * float(i) / 6.0 + 0.2
		var height := 16.0 + float(posmod(i * 7, 5)) * 5.0
		_cylinder(root, "RoostNeedle%d" % i,
			Vector3(cos(angle) * (8.0 + float(i % 2) * 5.0), height * 0.5,
				sin(angle) * (7.0 + float((i + 1) % 2) * 5.0)),
			1.8 + float(i % 2), height, _materials["stone"])
		_box(root, "PerchCap%d" % i,
			Vector3(cos(angle) * (8.0 + float(i % 2) * 5.0), height,
				sin(angle) * (7.0 + float((i + 1) % 2) * 5.0)),
			Vector3(8.0, 0.8, 4.0), _materials["wood"], false,
			Basis(Vector3.UP, angle))


func _build_observatory(root: Node3D) -> void:
	_cylinder(root, "ObservatoryTower", Vector3(0.0, 10.0, 0.0), 8.5, 20.0, _materials["stone"])
	var dome := MeshInstance3D.new()
	dome.name = "WindDome"
	dome.position = Vector3(0.0, 21.0, 0.0)
	var sphere := SphereMesh.new()
	sphere.radius = 8.8
	sphere.height = 10.0
	dome.mesh = sphere
	dome.scale = Vector3(1.0, 0.58, 1.0)
	dome.material_override = _materials["stone_light"]
	root.add_child(dome)
	_cylinder(root, "WeatherSpire", Vector3(0.0, 32.0, 0.0), 0.75, 16.0, _materials["tether"])
	_box(root, "WindVane", Vector3(0.0, 38.0, 0.0), Vector3(12.0, 0.6, 1.2), _materials["leaf_gold"], false)


func _build_waterward_overlook(root: Node3D) -> void:
	_box(root, "OverlookDeck", Vector3(0.0, 1.0, -6.0), Vector3(30.0, 2.0, 18.0), _materials["stone_light"], false)
	for side: float in [-1.0, 1.0]:
		_box(root, "WaterwardPillar", Vector3(side * 10.0, 10.0, 1.0), Vector3(3.0, 20.0, 3.0), _materials["stone"], false)
	_box(root, "WaterwardLintel", Vector3(0.0, 19.0, 1.0), Vector3(23.0, 2.5, 3.5), _materials["stone"], false)
	_box(root, "WaterwardGlow", Vector3(0.0, 16.0, 0.7), Vector3(8.0, 0.4, 0.3), _materials["heart"], false)


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
	# Two articulated wings and a high gate bridge replace the solid cuboid that
	# filled the whole final-approach frame. The open central throat is readable
	# from the road and gives the eventual pre-boss route a physical entrance.
	for side: float in [-1.0, 1.0]:
		_box(root, "SummitWing", Vector3(side * 13.5, 13.0, 0.0),
			Vector3(15.0, 26.0, 34.0), _materials["stone"], true)
		_box(root, "WingButtress", Vector3(side * 22.0, 7.5, 8.0),
			Vector3(4.0, 15.0, 10.0), _materials["cliff_mid"], true)
	_box(root, "GateBridge", Vector3(0.0, 25.0, 0.0),
		Vector3(14.0, 7.0, 34.0), _materials["stone_light"], true)
	_box(root, "UpperKeep", Vector3(0.0, 36.0, -3.0),
		Vector3(24.0, 15.0, 22.0), _materials["stone_light"], true)
	_box(root, "GateThreshold", Vector3(0.0, 0.6, -19.0),
		Vector3(9.0, 1.2, 12.0), _materials["path"], true)
	for corner in [Vector3(-24.0, 17.0, -20.0), Vector3(24.0, 17.0, -20.0), Vector3(-24.0, 17.0, 20.0), Vector3(24.0, 17.0, 20.0)]:
		_cylinder(root, "SummitTower", corner, 6.5, 34.0, _materials["stone"])
		_cylinder(root, "TowerCap", corner + Vector3.UP * 18.5, 8.0, 3.0, _materials["tether"])
	for x in [-10.0, -3.3, 3.3, 10.0]:
		_box(root, "Crenellation", Vector3(x, 45.0, -3.0),
			Vector3(3.5, 3.5, 24.0), _materials["stone"], false)
	for side: float in [-1.0, 1.0]:
		_box(root, "TetherBanner", Vector3(side * 8.5, 22.0, -17.3),
			Vector3(3.8, 11.0, 0.28), _materials["tether"], false)
	_cylinder(root, "TetherSpire", Vector3(0.0, 55.0, -3.0), 2.3, 22.0, _materials["tether"])
	_box(root, "TetherCrown", Vector3(0.0, 47.0, -3.0),
		Vector3(29.0, 2.2, 24.0), _materials["tether"], false)


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

	# An irregular three-ring cliff profile replaces the early CylinderMesh
	# placeholder. The top retains a broad playable crown; the wall overhangs,
	# pinches and tapers independently so a long route reads as geology rather
	# than a row of identical hanging prisms.
	var sides := 14 + posmod(seed_value, 4)
	var top_ring: Array[Vector3] = []
	var upper_ring: Array[Vector3] = []
	var lower_ring: Array[Vector3] = []
	var bottom_ring: Array[Vector3] = []
	for i in sides:
		var angle := TAU * float(i) / float(sides)
		var irregular := 0.91 + 0.075 * sin(float(i * 7 + seed_value * 11))
		irregular += 0.035 * cos(float(i * 13 + seed_value * 3))
		var top_point := Vector3(cos(angle) * size.x * 0.47 * irregular,
			size.y * 0.5, sin(angle) * size.z * 0.47 * irregular)
		var upper_push := 1.02 + 0.10 * sin(float(i * 5 + seed_value * 19))
		var lower_push := 0.84 + 0.08 * cos(float(i * 9 + seed_value * 7))
		# A constant Y per ring made every kilometre-scale face read as a clean
		# geological cutaway. Offset the strata independently around the perimeter
		# so the material transitions follow an eroded, rising/falling shelf line.
		# The playable crown stays level; only the visual wall profile changes.
		var upper_jitter := sin(float(i * 11 + seed_value * 5)) * size.y * 0.045
		upper_jitter += cos(float(i * 5 + seed_value * 13)) * size.y * 0.018
		var lower_jitter := sin(float(i * 7 + seed_value * 17)) * size.y * 0.038
		lower_jitter += cos(float(i * 13 + seed_value * 3)) * size.y * 0.014
		top_ring.append(top_point)
		upper_ring.append(Vector3(top_point.x * upper_push, size.y * 0.20 + upper_jitter,
			top_point.z * upper_push))
		lower_ring.append(Vector3(top_point.x * lower_push, -size.y * 0.20 + lower_jitter,
			top_point.z * lower_push))
		bottom_ring.append(Vector3(top_point.x * (0.66 + 0.06 * sin(float(i * 3 + seed_value))),
			-size.y * 0.5, top_point.z * (0.66 + 0.05 * cos(float(i * 5 - seed_value)))))

	var mesh := ArrayMesh.new()
	var top_tool := SurfaceTool.new()
	top_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	top_tool.set_material(top_material)
	var crown := Vector3(0.0, size.y * 0.5 + 0.03, 0.0)
	for i in sides:
		var next := (i + 1) % sides
		_add_surface_triangle(top_tool, crown, top_ring[next] + Vector3.UP * 0.03,
			top_ring[i] + Vector3.UP * 0.03)
	top_tool.generate_normals()
	top_tool.commit(mesh)

	var upper_tool := SurfaceTool.new()
	upper_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	upper_tool.set_material(_materials["cliff_high"] if side_material != _materials["cliff_shadow"] else side_material)
	for i in sides:
		var next := (i + 1) % sides
		_add_surface_triangle(upper_tool, top_ring[i], upper_ring[i], top_ring[next])
		_add_surface_triangle(upper_tool, upper_ring[i], upper_ring[next], top_ring[next])
	upper_tool.generate_normals()
	upper_tool.commit(mesh)

	var middle_tool := SurfaceTool.new()
	middle_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	middle_tool.set_material(_materials["cliff_mid"] if side_material != _materials["cliff_shadow"] else side_material)
	for i in sides:
		var next := (i + 1) % sides
		_add_surface_triangle(middle_tool, upper_ring[i], lower_ring[i], upper_ring[next])
		_add_surface_triangle(middle_tool, lower_ring[i], lower_ring[next], upper_ring[next])
	middle_tool.generate_normals()
	middle_tool.commit(mesh)

	var lower_tool := SurfaceTool.new()
	lower_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	lower_tool.set_material(_materials["cliff_deep"] if side_material != _materials["cliff_shadow"] else side_material)
	for i in sides:
		var next := (i + 1) % sides
		_add_surface_triangle(lower_tool, lower_ring[i], bottom_ring[i], lower_ring[next])
		_add_surface_triangle(lower_tool, bottom_ring[i], bottom_ring[next], lower_ring[next])
	lower_tool.generate_normals()
	lower_tool.commit(mesh)

	var mass := MeshInstance3D.new()
	mass.name = "StratifiedCliffBody"
	mass.mesh = mesh
	mass.visibility_range_end = 2600.0
	mass.visibility_range_end_margin = 220.0
	root.add_child(mass)

	if collision:
		var points := PackedVector3Array()
		for point: Vector3 in top_ring:
			points.append(point)
		for point: Vector3 in bottom_ring:
			points.append(point)
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


func _textured_material(raw: Variant, fallback_tint: Color) -> StandardMaterial3D:
	var spec: Dictionary = raw as Dictionary if raw is Dictionary else {}
	var material := _material(Color(str(spec.get("tint", fallback_tint.to_html()))), 0.96)
	var albedo_path := str(spec.get("albedo", ""))
	var normal_path := str(spec.get("normal", ""))
	var albedo := load(albedo_path) as Texture2D if albedo_path != "" else null
	var normal := load(normal_path) as Texture2D if normal_path != "" else null
	if albedo != null:
		material.albedo_texture = albedo
	if normal != null:
		material.normal_enabled = true
		material.normal_texture = normal
		material.normal_scale = float(spec.get("normal_depth", 0.3))
	var uv_scale := float(spec.get("uv_scale", 0.2))
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 6.0
	material.uv1_scale = Vector3.ONE * uv_scale
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return material


func _surface_tint(raw: Dictionary, tint: String) -> Dictionary:
	var result := raw.duplicate(true)
	result["tint"] = tint
	return result


func _emissive_material(colour: Color, energy: float) -> StandardMaterial3D:
	var material := _material(colour, 0.48)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	return material


func _wind_veil_material() -> StandardMaterial3D:
	var material := _emissive_material(Color(0.33, 0.78, 0.84, 0.24), 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color.a = 0.24
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
