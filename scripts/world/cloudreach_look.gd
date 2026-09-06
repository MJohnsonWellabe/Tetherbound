extends Node3D

## CLOUDREACH-LOOK-0906. Post-build dressing pass over the already-authored
## Cloudreach world (`cloudreach_world.gd`), driven by the owner's
## 2026-09-06 playtest addendum: grass reads as a mown lawn almost
## everywhere, floating islands read as flat grey slabs with no ropes,
## cliff rock is an undifferentiated grey mass, cliffside cottages are the
## Meadows village verbatim, and the horizon/frame reads thin and empty.
##
## Deliberately a SEPARATE node mounted after the world finishes building
## (`cloudreach_world_runtime.gd::mount()`), never a change to
## `cloudreach_world.gd` itself -- that file is being edited by another
## agent in the same pass. Everything here reads the built world through its
## public surface (`config_data()`, `_materials`, `ground_height_at()`,
## `_inside_settlement_clearance()`, `_inside_landmark_vista()`, the physics
## space) and adds new sibling geometry.
##
## Every tunable lives in `data/config/cloudreach_look.json` per CLAUDE.md's
## "tunables in data/config" rule -- nothing here is a magic number.

const LOOK_CONFIG_PATH := "res://data/config/cloudreach_look.json"
const ATMOSPHERE_CONFIG_PATH := "res://data/config/cloudreach_atmosphere.json"
const GRASS_FIELD_SCRIPT := preload("res://scripts/world/grass_field.gd")
const COVER_SHADER := preload("res://shaders/cloudreach_ground_cover.gdshader")

const LOOK_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/CommonTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_3.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_4.gltf"),
	preload("res://assets/environment/stylized_nature/CommonTree_5.gltf"),
]
const LOOK_TWISTED_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/TwistedTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_3.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_4.gltf"),
	preload("res://assets/environment/stylized_nature/TwistedTree_5.gltf"),
]
const LOOK_DEAD_TREES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/DeadTree_1.gltf"),
	preload("res://assets/environment/stylized_nature/DeadTree_2.gltf"),
	preload("res://assets/environment/stylized_nature/DeadTree_3.gltf"),
]
const LOOK_STONES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Rock_Medium_1.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_2.gltf"),
	preload("res://assets/environment/stylized_nature/Rock_Medium_3.gltf"),
]
const ALPINE_GRASS := preload("res://assets/environment/stylized_nature/Grass_Wispy_Tall.gltf")
const ALPINE_PEBBLES: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/Pebble_Round_1.gltf"),
	preload("res://assets/environment/stylized_nature/Pebble_Round_2.gltf"),
	preload("res://assets/environment/stylized_nature/Pebble_Round_3.gltf"),
]
const ALPINE_SCREE: Array[PackedScene] = [
	preload("res://assets/environment/stylized_nature/RockPath_Round_Small_1.gltf"),
	preload("res://assets/environment/stylized_nature/RockPath_Round_Small_2.gltf"),
]

var _world: Node3D
var _cfg: Dictionary = {}
var _materials: Dictionary = {}
var _exclusions: Array = []
var _routes: Array = []
var _space_state: PhysicsDirectSpaceState3D

# Fog persistent post-scale, applied every frame after WorldLook writes the
# base environment values (see the "fog" section below for why this lives
# here rather than in a JSON already owned by the concurrent world pass).
var _fog_env: Environment
var _fog_density_scale := 1.0
var _fog_aerial_scale := 1.0

# Counts reported to tests/smoke_cloudreach_look.gd and the operator.
var _bridge_rope_sides: Dictionary = {} # "<bridge>/<section>" -> {left:int,right:int}
var _bridge_post_count := 0
var _mooring_lines: Dictionary = {} # island label -> int lines
var _cover_main_count := 0
var _cover_far_count := 0
var _cover_alpine_count := 0
var _cover_by_patch: Dictionary = {} # patch label -> tuft count (this pass only)
var _tree_count := 0
var _stone_count := 0
var _settlement_material_overrides := 0
var _settlement_guy_ropes := 0
var _roof_colour := Color.WHITE
var _cover_patch_centres: Array[Vector3] = []
var _cover_counts_by_index: Array[int] = []
var _ellipse_patches_cache: Array = []
var _tree_positions: Array[Vector3] = []


func dress(world: Node3D) -> void:
	_world = world
	_cfg = _read_json(LOOK_CONFIG_PATH)
	_materials = world.get("_materials") as Dictionary
	if _materials == null:
		_materials = {}
	_ensure_materials()
	var exclusions_raw: Variant = world.get("_cover_exclusions")
	_exclusions = exclusions_raw if exclusions_raw is Array else []
	var config_data: Dictionary = world.call("config_data")
	_routes = config_data.get("routes", [])
	_space_state = world.get_world_3d().direct_space_state if world.get_world_3d() != null else null

	_dress_bridge_rails()
	_dress_moorings(config_data)
	_dress_ground_cover_finish()
	_dress_trees_and_stones(config_data)
	_dress_settlement_materials()
	_dress_fog()


func _ensure_materials() -> void:
	if not _materials.has("rope"):
		_materials["rope"] = _flat_material(Color("#8f7048"), 1.0)
	if not _materials.has("masonry"):
		_materials["masonry"] = _flat_material(Color("#b4b1a6"), 0.9)
	if not _materials.has("wood"):
		_materials["wood"] = _flat_material(Color("#9b8b71"), 0.85)
	if not _materials.has("bronze"):
		_materials["bronze"] = _flat_material(Color("#81704b"), 0.72)
	_materials["look_rope_tar"] = _flat_material(Color(str(_look_get("mooring", "tar_rope_colour", "#2c261f"))), 1.0)
	_materials["look_iron_ring"] = _flat_material(Color("#3a3a3d"), 0.4)


func _flat_material(colour: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = roughness
	return material


# ---------------------------------------------------------------------------
# Small shared geometry helpers (deliberately reimplemented rather than
# calling into cloudreach_world.gd's private helpers, which another agent is
# editing concurrently in this same pass).
# ---------------------------------------------------------------------------

func _add_cylinder_between(parent: Node, label: String, a: Vector3, b: Vector3,
		radius: float, material: Material) -> void:
	var delta := b - a
	if delta.length_squared() < 0.0001:
		return
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = delta.length()
	mesh.mesh = cyl
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	mesh.global_position = a.lerp(b, 0.5)
	var up := delta.normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.length_squared() < 0.001:
		right = Vector3.RIGHT
	var forward := right.cross(up).normalized()
	mesh.global_basis = Basis(right, up, forward)


func _add_catenary(parent: Node, label: String, a: Vector3, b: Vector3, sag: float,
		segments: int, radius: float, material: Material) -> void:
	var last := a
	for i in range(1, segments + 1):
		var t := float(i) / float(segments)
		var p := a.lerp(b, t)
		p.y -= sag * sin(PI * t)
		_add_cylinder_between(parent, "%s%02d" % [label, i], last, p, radius, material)
		last = p


func _add_box(parent: Node, label: String, centre: Vector3, size: Vector3,
		material: Material, basis: Basis = Basis.IDENTITY) -> Node3D:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	mesh.global_position = centre
	mesh.global_basis = basis
	return mesh


func _raycast_down(xz: Vector2, top_hint: float, above: float = 140.0, below: float = 320.0) -> Dictionary:
	if _space_state == null:
		return {}
	var from := Vector3(xz.x, top_hint + above, xz.y)
	var to := Vector3(xz.x, top_hint - below, xz.y)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	return _space_state.intersect_ray(query)


## Every `_mesa()` call that passes `collision:true` uses a turf top_material
## (upland/upland_dry) -- region crowns, landmark ledges, transition/route
## landing pads, rooted shelves, vegetated geological shelves -- and their
## dynamically-named "Collision" body's collision shape is generated only
## from that same crown top, so it is never anything but walkable ground.
## `_box()`'s hidden flat walkable-crown overrides (observatory/summit/
## overlook/settlement terrace) share the same "Collision" name and are
## likewise real turf. The two families this world actually builds that are
## NOT turf and reuse the same "Collision" name -- a bridge's `WalkableDeck`
## and a settlement building's `ContinuousStoneFloor` -- are the only ones
## worth naming explicitly; everything else through this exact body name is
## a walkable crown.
func _is_turf_top(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var collider: Object = hit.get("collider")
	if collider == null or not (collider is StaticBody3D):
		return false
	if str(collider.name) != "Collision":
		return false
	var parent: Node = collider.get_parent()
	if parent == null:
		return false
	var pname := str(parent.name).to_lower()
	return not (pname.contains("deck") or pname.contains("floor"))


func _excluded(at: Vector3) -> bool:
	for raw: Variant in _exclusions:
		if not raw is Dictionary:
			continue
		var exclusion: Dictionary = raw
		if str(exclusion.get("kind", "")) == "segment":
			var a: Vector3 = exclusion.get("a", Vector3.ZERO)
			var b: Vector3 = exclusion.get("b", Vector3.ZERO)
			var ab := Vector2(b.x - a.x, b.z - a.z)
			var t := clampf(Vector2(at.x - a.x, at.z - a.z).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
			var nearest := Vector2(a.x, a.z) + ab * t
			if absf((a.y + (b.y - a.y) * t) - at.y) < 3.0 \
					and nearest.distance_to(Vector2(at.x, at.z)) < float(exclusion.get("half_width", 1.0)):
				return true
			continue
		var centre: Vector3 = exclusion.get("centre", Vector3.ZERO)
		if absf(at.y - centre.y) > 4.0:
			continue
		var half: Vector2 = exclusion.get("half", Vector2.ONE)
		var local := Vector2(at.x - centre.x, at.z - centre.z).rotated(-float(exclusion.get("rotation", 0.0)))
		if str(exclusion.get("kind", "")) == "ellipse":
			if (local / half).length_squared() <= 1.0:
				return true
		elif absf(local.x) <= half.x and absf(local.y) <= half.y:
			return true
	return false


func _near_route(at: Vector3, extra_m: float) -> bool:
	for raw: Variant in _routes:
		if not raw is Dictionary:
			continue
		var route: Dictionary = raw
		var polyline: Array = route.get("polyline", [])
		if polyline.size() < 2:
			continue
		var half_width := float(route.get("width_m", 7.5)) * 0.5 + extra_m
		var prev: Vector3 = _vec3(polyline[0])
		if prev.distance_to(at) > 260.0 and Vector3(polyline[polyline.size() - 1][0], 0, polyline[polyline.size() - 1][2]).distance_to(at) > 260.0:
			# Cheap reject: neither endpoint is anywhere near this point and
			# Cloudreach routes are short local hops, not cross-map lines.
			pass
		for i in range(1, polyline.size()):
			var cur: Vector3 = _vec3(polyline[i])
			var ab := Vector2(cur.x - prev.x, cur.z - prev.z)
			var length_sq := ab.length_squared()
			if length_sq > 0.01:
				var t := clampf(Vector2(at.x - prev.x, at.z - prev.z).dot(ab) / length_sq, 0.0, 1.0)
				var nearest := Vector2(prev.x, prev.z) + ab * t
				if nearest.distance_to(Vector2(at.x, at.z)) < half_width \
						and absf(lerpf(prev.y, cur.y, t) - at.y) < 10.0:
					return true
			prev = cur
	return false


func _vec3(raw: Variant) -> Vector3:
	if raw is Array and (raw as Array).size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	return Vector3.ZERO


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _look_get(section: String, key: String, default: Variant) -> Variant:
	return (_cfg.get(section, {}) as Dictionary).get(key, default)


func _first_mesh(scene: PackedScene) -> Mesh:
	var temp := scene.instantiate() as Node3D
	var found: Mesh = null
	for mi: MeshInstance3D in temp.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh != null:
			found = mi.mesh
			break
	temp.free()
	return found


func _safe_name(raw: String) -> String:
	var words := raw.replace("-", "_").split("_", false)
	var result := ""
	for word: String in words:
		result += word.capitalize().replace(" ", "")
	return result if result != "" else "CloudreachNode"


# ---------------------------------------------------------------------------
# 1. Bridge rope rails. Stone-family decks (`broken_stone`/`ancient_stone`)
# have no rope at all; rope-family decks (`rope_suspension`/`rope_chain`)
# already carry exactly one sagging rope per edge from
# `cloudreach_world.gd::_build_bridge_section`. Either way the target is
# >=2 rails per edge, so a rope-family edge gets one MORE rope (the knee
# line) rather than a duplicate hand line on top of its existing rope.
# Posts are added every ~5 m on both edges regardless -- the authored posts
# only land at each DeckSection's own two endpoints, which can be tens of
# metres apart.
# ---------------------------------------------------------------------------

func _dress_bridge_rails() -> void:
	var bridges_root := _world.get_node_or_null(^"SuspendedBridges")
	if bridges_root == null:
		return
	var cfg: Dictionary = _cfg.get("bridge_rails", {})
	var post_radius := float(cfg.get("post_radius", 0.07))
	var post_height := float(cfg.get("post_height", 1.15))
	var post_spacing := maxf(1.0, float(cfg.get("post_spacing_m", 5.0)))
	var rope_radius := float(cfg.get("rope_radius", 0.05))
	var hand_height := float(cfg.get("hand_height_m", 1.0))
	var knee_height := float(cfg.get("knee_height_m", 0.5))
	var rope_segments := maxi(2, int(cfg.get("rope_segments", 12)))
	var rope_sag := float(cfg.get("rope_sag_m", 0.12))
	var inset := float(cfg.get("edge_inset_m", 0.05))
	var rope_material: Material = _materials.get("rope")

	for bridge in bridges_root.get_children():
		for section in bridge.get_children():
			var deck := section.get_node_or_null(^"WalkableDeck") as Node3D
			if deck == null:
				continue
			var box: BoxMesh = null
			for child in deck.get_children():
				if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
					box = (child as MeshInstance3D).mesh as BoxMesh
					break
			if box == null:
				continue
			var width: float = box.size.x
			var thickness: float = box.size.y
			var length: float = box.size.z
			var gt := deck.global_transform
			var right := gt.basis.x.normalized()
			var up := gt.basis.y.normalized()
			var forward := gt.basis.z.normalized()
			var centre := gt.origin
			var top_local_y := thickness * 0.5
			var half_len := length * 0.5
			var edge_x := width * 0.5 - inset

			var has_existing_rope := false
			for sibling in section.get_children():
				if str(sibling.name).begins_with("Rope"):
					has_existing_rope = true
					break

			var rails_root := Node3D.new()
			rails_root.name = "LookBridgeRails"
			section.add_child(rails_root)

			var post_count := maxi(2, int(round(length / post_spacing)) + 1)
			for side: float in [-1.0, 1.0]:
				var side_label := "Left" if side < 0.0 else "Right"
				var lx := edge_x * side
				for i in post_count:
					var t := float(i) / float(maxi(1, post_count - 1))
					var lz := lerpf(-half_len, half_len, t)
					var base := centre + right * lx + forward * lz + up * top_local_y
					_add_cylinder_between(rails_root, "RailPost%s%02d" % [side_label, i],
						base, base + up * post_height, post_radius, _materials.get("wood"))
				_bridge_post_count += post_count

				var rope_a := centre + right * lx + forward * (-half_len) + up * (top_local_y + hand_height)
				var rope_b := centre + right * lx + forward * half_len + up * (top_local_y + hand_height)
				var rope_a_knee := centre + right * lx + forward * (-half_len) + up * (top_local_y + knee_height)
				var rope_b_knee := centre + right * lx + forward * half_len + up * (top_local_y + knee_height)
				var side_rope_count := 1 if has_existing_rope else 0
				if not has_existing_rope:
					_add_catenary(rails_root, "RailRopeHand%s" % side_label, rope_a, rope_b,
						rope_sag, rope_segments, rope_radius, rope_material)
					side_rope_count += 1
				_add_catenary(rails_root, "RailRopeKnee%s" % side_label, rope_a_knee, rope_b_knee,
					rope_sag, rope_segments, rope_radius, rope_material)
				side_rope_count += 1
				var key := "%s/%s/%s" % [bridge.name, section.name, side_label]
				_bridge_rope_sides[key] = side_rope_count


# ---------------------------------------------------------------------------
# 2. Mooring lines. Every floating region top plus the fly-only shrine, the
# flight aerie and the high perches get 2-3 tarred rope lines from a rim
# bollard down to an anchor on the nearest lower platform within range (a
# vertical anchor pylon when nothing qualifies). Rim points are found by
# raycast, walking outward until the crown collider is lost -- not from an
# authored size, since the real crown edge is an irregular eroded ring the
# config never states a radius for.
# ---------------------------------------------------------------------------

func _collect_islands(config_data: Dictionary) -> Array:
	var islands: Array = []
	for raw: Variant in config_data.get("regions", []):
		if not raw is Dictionary:
			continue
		var spec: Dictionary = raw
		var pos := _vec3(spec.get("position", []))
		var label := _safe_name(str(spec.get("id", "Region")))
		islands.append({"label": label, "centre": Vector2(pos.x, pos.z), "top_y": pos.y,
			"node": _world.get_node_or_null(NodePath("CliffRegions/%s" % label))})
	for wanted_id in ["sky_shrine_heartstone", "windscar_flight_aerie", "high_roost_perches"]:
		for raw: Variant in config_data.get("landmarks", []):
			if not raw is Dictionary or str((raw as Dictionary).get("id", "")) != wanted_id:
				continue
			var spec: Dictionary = raw
			var pos := _vec3(spec.get("position", []))
			var label := _safe_name(wanted_id)
			islands.append({"label": label, "centre": Vector2(pos.x, pos.z), "top_y": pos.y,
				"node": _world.get_node_or_null(NodePath("Landmarks/%s" % label))})
	return islands


func _nearest_lower(source: Dictionary, islands: Array, cfg: Dictionary) -> Variant:
	var margin := float(cfg.get("lower_margin_m", 5.0))
	var max_dist := float(cfg.get("max_anchor_distance_m", 700.0))
	var best: Variant = null
	var best_d := INF
	for raw: Variant in islands:
		var other: Dictionary = raw
		if str(other.label) == str(source.label):
			continue
		if float(other.top_y) >= float(source.top_y) - margin:
			continue
		var d: float = (source.centre as Vector2).distance_to(other.centre as Vector2)
		if d <= max_dist and d < best_d:
			best_d = d
			best = other
	return best


func _find_rim(centre: Vector2, top_y: float, dir: Vector2, cfg: Dictionary) -> Vector3:
	var step := maxf(0.5, float(cfg.get("rim_probe_step_m", 4.0)))
	var max_radius := float(cfg.get("max_search_radius_m", 260.0))
	var tolerance := float(cfg.get("top_tolerance_m", 60.0))
	var last := Vector3.INF
	var r := step
	while r < max_radius:
		var xz := centre + dir * r
		var hit := _raycast_down(xz, top_y)
		if _is_turf_top(hit) and absf((hit.get("position") as Vector3).y - top_y) < tolerance:
			last = hit.get("position") as Vector3
			r += step
			continue
		# Some crowns (the summit's own "CliffMass" is deliberately built with
		# no collider at all -- a separate thin authored strip owns its real
		# collision) never return a raycast hit here. `ground_height_at` is a
		# pure-math lookup over the same ellipse the world already registered
		# for this island regardless of collision, so it still walks the same
		# outward search to an honest (if conservative) edge.
		var flat := float(_world.call("ground_height_at", xz.x, xz.y))
		if not is_nan(flat) and absf(flat - top_y) < tolerance:
			last = Vector3(xz.x, flat, xz.y)
			r += step
			continue
		break
	return last


func _add_bollard(parent: Node, label: String, at: Vector3, size: Vector3) -> Vector3:
	_add_box(parent, label, at + Vector3.UP * size.y * 0.5, size, _materials.get("masonry"))
	var ring := MeshInstance3D.new()
	ring.name = label + "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26
	torus.outer_radius = 0.34
	torus.rings = 16
	torus.ring_segments = 8
	ring.mesh = torus
	ring.material_override = _materials.get("look_iron_ring")
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(ring)
	ring.global_position = at + Vector3.UP * (size.y + 0.08)
	ring.global_rotation = Vector3(PI * 0.5, 0.0, 0.0)
	return ring.global_position


func _dress_moorings(config_data: Dictionary) -> void:
	var cfg: Dictionary = _cfg.get("mooring", {})
	var islands := _collect_islands(config_data)
	var root := Node3D.new()
	root.name = "LookMoorings"
	add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_cfg.get("seed", 20260906)) + 4001
	var lines_min := maxi(1, int(cfg.get("lines_min", 2)))
	var lines_max := maxi(lines_min, int(cfg.get("lines_max", 3)))
	var bollard_size := _vec3(cfg.get("bollard_size", [0.6, 1.4, 0.6]))
	var rope_radius := float(cfg.get("rope_radius", 0.16))
	var rope_segments := maxi(2, int(cfg.get("rope_segments", 16)))
	var sag_fraction := float(cfg.get("sag_fraction", 0.06))
	var pylon_drop := float(cfg.get("pylon_drop_m", 22.0))
	var tar_material: Material = _materials.get("look_rope_tar")

	for raw: Variant in islands:
		var island: Dictionary = raw
		var line_count := rng.randi_range(lines_min, lines_max)
		var base_angle := rng.randf() * TAU
		var island_root := Node3D.new()
		island_root.name = "Moor%s" % str(island.label)
		root.add_child(island_root)
		var built := 0
		for i in line_count:
			var angle := base_angle + TAU * float(i) / float(line_count)
			var dir := Vector2(cos(angle), sin(angle))
			var source_rim := _find_rim(island.centre, island.top_y, dir, cfg)
			if not source_rim.is_finite():
				continue
			var source_anchor := _add_bollard(island_root, "SourceBollard%d" % i, source_rim, bollard_size)
			var target: Variant = _nearest_lower(island, islands, cfg)
			var connected := false
			if target != null:
				var target_dict: Dictionary = target
				var target_dir := (Vector2(source_rim.x, source_rim.z) - (target_dict.centre as Vector2)).normalized()
				var target_rim := _find_rim(target_dict.centre, target_dict.top_y, target_dir, cfg)
				if target_rim.is_finite():
					var target_anchor := _add_bollard(island_root, "TargetBollard%d" % i, target_rim, bollard_size)
					var span := source_anchor.distance_to(target_anchor)
					_add_catenary(island_root, "MooringLine%d" % i, source_anchor, target_anchor,
						span * sag_fraction, rope_segments, rope_radius, tar_material)
					connected = true
			if not connected:
				var outward := Vector3(dir.x, 0.0, dir.y) * 4.0
				var pylon_top := source_rim + outward
				var pylon_base := pylon_top - Vector3.UP * pylon_drop
				_add_box(island_root, "AnchorPylonBase%d" % i, pylon_base, Vector3(1.1, 0.5, 1.1), _materials.get("masonry"))
				_add_cylinder_between(island_root, "AnchorPylon%d" % i, pylon_top, pylon_base, 0.32, _materials.get("masonry"))
				_add_catenary(island_root, "MooringLine%d" % i, source_anchor, pylon_top,
					0.35, 8, rope_radius, tar_material)
			built += 1
		_mooring_lines[str(island.label)] = built


# ---------------------------------------------------------------------------
# 3. Ground cover finish. `cloudreach_ground_cover.gd`'s own patches trust a
# single flat "top" height per ellipse, but a region/landmark crown is an
# eroded ring that dips and rises tens of metres around that flat number
# (`cloudreach_world.gd::_mesa`'s `eroded_crown`/`rugged_crown` waves) -- most
# of that first layer's samples land floating above a dip or clipped into a
# rise, which is why the map reads as a mown lawn outside a couple of frames.
# This second layer samples the SAME footprints `_build_regions`/
# `_build_landmarks` already registered (`world._cover_patches`) but places
# every tuft by a real downward raycast against the crown's own collider,
# plus a larger far tier and an alpine rim mix, under one shared instance
# budget.
# ---------------------------------------------------------------------------

func _dress_ground_cover_finish() -> void:
	var patches_raw: Variant = _world.get("_cover_patches")
	var patches: Array = patches_raw if patches_raw is Array else []
	var cfg: Dictionary = _cfg.get("ground_cover_finish", {})
	var budget := maxi(0, int(cfg.get("instance_budget_total", 220000)))
	var main_share := float(cfg.get("main_share", 0.75))
	var far_share := float(cfg.get("far_share", 0.15))
	var main_density := float(cfg.get("main_density_per_m2", 0.35))
	var far_density := float(cfg.get("far_density_per_m2", 0.06))
	var extra_clear := float(cfg.get("path_clearance_extra_m", 0.5))
	var far_scale := float(cfg.get("far_scale_m", 1.3))
	var far_visibility := float(cfg.get("far_visibility_range_m", 900.0))

	var ellipse_patches: Array = []
	for raw: Variant in patches:
		if raw is Dictionary and str((raw as Dictionary).get("kind", "ellipse")) == "ellipse":
			ellipse_patches.append(raw)
	_ellipse_patches_cache = ellipse_patches

	var desired_main: Array[float] = []
	var desired_far: Array[float] = []
	var total_main := 0.0
	var total_far := 0.0
	for raw: Variant in ellipse_patches:
		var patch: Dictionary = raw
		var half: Vector2 = patch.get("half", Vector2.ONE)
		var area := PI * half.x * half.y * 0.78
		var dm := area * main_density
		var df := area * far_density
		desired_main.append(dm)
		desired_far.append(df)
		total_main += dm
		total_far += df
	var main_scale := 1.0 if total_main <= 0.0 else minf(1.0, (float(budget) * main_share) / total_main)
	var far_scale_factor := 1.0 if total_far <= 0.0 else minf(1.0, (float(budget) * far_share) / total_far)

	var root := Node3D.new()
	root.name = "LookGroundCoverFinish"
	add_child(root)
	var grass_factory := GRASS_FIELD_SCRIPT.new()
	var tuft_mesh := grass_factory.call("surface_tuft_mesh", 7, 2) as ArrayMesh
	grass_factory.free()
	var tint_base := Color(str(cfg.get("tint_base", "#33421a")))
	var tint_tip := Color(str(cfg.get("tint_tip", "#889a3f")))
	var dry_base := Color(str(cfg.get("dry_tint_base", "#4b4919")))
	var dry_tip := Color(str(cfg.get("dry_tint_tip", "#a89b42")))
	var main_material := _tuft_material(tint_base, tint_tip)
	var main_material_dry := _tuft_material(dry_base, dry_tip)
	var far_material := _tuft_material(tint_base.lerp(Color.BLACK, 0.08), tint_tip.lerp(Color.WHITE, 0.05))

	for patch_index in ellipse_patches.size():
		var patch: Dictionary = ellipse_patches[patch_index]
		var centre: Vector3 = patch.get("centre", Vector3.ZERO)
		var half: Vector2 = patch.get("half", Vector2.ONE)
		var seed_value := int(patch.get("seed", patch_index * 17))
		var dry := bool(patch.get("dry", false))
		var inner_clear := float(patch.get("inner_clear_fraction", 0.0))
		var requested_main := int(desired_main[patch_index] * main_scale)
		var requested_far := int(desired_far[patch_index] * far_scale_factor)
		var placed_main := _plant_tufts(root, "CoverFinishMain%03d" % patch_index, centre, half, inner_clear,
			requested_main, seed_value, tuft_mesh, main_material_dry if dry else main_material,
			0.52, 0.95, extra_clear, 360.0, 1.0)
		var placed_far := _plant_tufts(root, "CoverFinishFar%03d" % patch_index, centre, half, inner_clear,
			requested_far, seed_value + 5000, tuft_mesh, far_material,
			far_scale * 0.85, far_scale * 1.2, extra_clear, far_visibility, 1.0)
		_cover_main_count += placed_main
		_cover_far_count += placed_far
		_cover_patch_centres.append(centre)
		_cover_counts_by_index.append(placed_main + placed_far)

	_dress_alpine_rim(ellipse_patches, cfg, budget)


func _tuft_material(base: Color, tip: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = COVER_SHADER
	material.set_shader_parameter("tint_base", base)
	material.set_shader_parameter("tint_tip", tip)
	material.set_shader_parameter("wind_strength", 0.11)
	material.set_shader_parameter("normal_soften", 0.5)
	material.set_shader_parameter("grass_curve", 0.3)
	material.set_shader_parameter("camera_clearance", true)
	return material


func _plant_tufts(parent: Node3D, label: String, centre: Vector3, half: Vector2, inner_clear: float,
		requested: int, seed_value: int, mesh: ArrayMesh, material: Material,
		scale_min: float, scale_max: float, extra_clear: float,
		visibility_range: float, width_mul: float) -> int:
	if requested <= 0 or mesh == null:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var transforms: Array[Transform3D] = []
	var attempts := 0
	var max_attempts := mini(requested * 3 + 24, 20000)
	var inner_sq := inner_clear * inner_clear
	while transforms.size() < requested and attempts < max_attempts:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf_range(inner_sq, 1.0))
		var x := centre.x + cos(angle) * half.x * radius
		var z := centre.z + sin(angle) * half.y * radius
		var probe := Vector3(x, centre.y, z)
		if _excluded(probe) or _near_route(probe, extra_clear):
			continue
		if bool(_world.call("_inside_settlement_clearance", probe)):
			continue
		var hit := _raycast_down(Vector2(x, z), centre.y)
		if not _is_turf_top(hit):
			continue
		var ground: Vector3 = hit.get("position")
		if absf(ground.y - centre.y) > 60.0:
			continue
		var scale_value := rng.randf_range(scale_min, scale_max)
		var width_scale := rng.randf_range(1.6, 2.3) * width_mul
		var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3(width_scale, scale_value, width_scale))
		transforms.append(Transform3D(basis, ground + Vector3.UP * 0.02))
	if transforms.is_empty():
		return 0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var instances := MultiMeshInstance3D.new()
	instances.name = label
	instances.multimesh = mm
	instances.material_override = material
	instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instances.visibility_range_end = visibility_range
	instances.visibility_range_end_margin = 40.0
	instances.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(instances)
	return transforms.size()


## Wind-bent tall grass and scree within a `alpine_band_m` ring of each
## region top's own outer edge -- restricted to region-scale patches
## (half.x large), which are the ones actually reachable and photographed at
## a rim; landmark ledges are small enough that their own tree/stone/mooring
## dressing already reads the edge.
func _dress_alpine_rim(ellipse_patches: Array, cfg: Dictionary, budget: int) -> void:
	var band_m := float(cfg.get("alpine_band_m", 6.0))
	var density := float(cfg.get("alpine_density_per_m2", 0.15))
	var share := float(cfg.get("alpine_share", 0.10))
	var region_half_threshold := float(cfg.get("region_half_threshold_m", 100.0))
	var qualifying: Array = []
	var desired: Array[float] = []
	var total := 0.0
	for raw: Variant in ellipse_patches:
		var patch: Dictionary = raw
		var half: Vector2 = patch.get("half", Vector2.ONE)
		if half.x < region_half_threshold:
			continue
		var perimeter := TAU * sqrt((half.x * half.x + half.y * half.y) * 0.5)
		var d := perimeter * band_m * density
		qualifying.append(patch)
		desired.append(d)
		total += d
	if qualifying.is_empty():
		return
	var scale_factor := 1.0 if total <= 0.0 else minf(1.0, (float(budget) * share) / total)
	var root := Node3D.new()
	root.name = "LookAlpineRimMix"
	add_child(root)
	var kinds: Dictionary = {
		"AlpineGrass": ALPINE_GRASS,
		"AlpinePebble1": ALPINE_PEBBLES[0], "AlpinePebble2": ALPINE_PEBBLES[1], "AlpinePebble3": ALPINE_PEBBLES[2],
		"AlpineScree1": ALPINE_SCREE[0], "AlpineScree2": ALPINE_SCREE[1],
	}
	var kind_names: Array = kinds.keys()
	var buckets: Dictionary = {}
	for kind_name: String in kind_names:
		buckets[kind_name] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_cfg.get("seed", 20260906)) + 7003
	for patch_index in qualifying.size():
		var patch: Dictionary = qualifying[patch_index]
		var centre: Vector3 = patch.get("centre", Vector3.ZERO)
		var half: Vector2 = patch.get("half", Vector2.ONE)
		var requested := int(desired[patch_index] * scale_factor)
		var attempts := 0
		var max_attempts := mini(requested * 3 + 24, 6000)
		var placed := 0
		var band_frac := clampf(1.0 - band_m / maxf(half.x, half.y), 0.5, 0.98)
		while placed < requested and attempts < max_attempts:
			attempts += 1
			var angle := rng.randf_range(0.0, TAU)
			var radius := rng.randf_range(band_frac, 1.0)
			var x := centre.x + cos(angle) * half.x * radius
			var z := centre.z + sin(angle) * half.y * radius
			var probe := Vector3(x, centre.y, z)
			if _excluded(probe) or _near_route(probe, 1.0) or bool(_world.call("_inside_settlement_clearance", probe)):
				continue
			var hit := _raycast_down(Vector2(x, z), centre.y)
			if not _is_turf_top(hit):
				continue
			var ground: Vector3 = hit.get("position")
			if absf(ground.y - centre.y) > 60.0:
				continue
			var roll := rng.randf()
			var kind_name := "AlpineGrass"
			if roll > 0.6:
				var pick := rng.randi_range(0, 4)
				kind_name = ["AlpinePebble1", "AlpinePebble2", "AlpinePebble3", "AlpineScree1", "AlpineScree2"][pick]
			var scale_value := rng.randf_range(0.7, 1.3)
			var basis := Basis(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * scale_value)
			(buckets[kind_name] as Array).append(Transform3D(basis, ground))
			placed += 1
		_cover_alpine_count += placed
	for kind_name: String in kind_names:
		var transforms: Array = buckets[kind_name]
		if transforms.is_empty():
			continue
		var mesh := _first_mesh(kinds[kind_name])
		if mesh == null:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
		var instances := MultiMeshInstance3D.new()
		instances.name = "AlpineMix%s" % kind_name
		instances.multimesh = mm
		instances.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instances.visibility_range_end = 500.0
		instances.visibility_range_end_margin = 40.0
		root.add_child(instances)


# ---------------------------------------------------------------------------
# 4. Trees and stones. Every region top and every landmark gets 3-5 tree
# clusters and 4-8 stone clusters, outside settlement clearance, landmark
# vistas and routes. Reuses each site's own ground-cover ellipse (matched by
# centre) as its planting footprint, same reasoning as the cover finish.
# ---------------------------------------------------------------------------

func _dress_trees_and_stones(config_data: Dictionary) -> void:
	var cfg: Dictionary = _cfg.get("trees_stones", {})
	var root := Node3D.new()
	root.name = "LookTreesAndStones"
	add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_cfg.get("seed", 20260906)) + 9007

	var sites: Array = []
	for raw: Variant in config_data.get("regions", []):
		if raw is Dictionary:
			var spec: Dictionary = raw
			# Landmark-vista exclusion is not applied to a region's own
			# footprint: high_roost_sky_shrine sits with its authored centre
			# only ~25 m from the sky_shrine_heartstone landmark it hosts, so
			# that landmark's own 170 m vista radius would otherwise eclipse
			# the region's entire usable crown, leaving it unplantable. A
			# landmark still guards its own immediate surroundings below.
			sites.append({"id": str(spec.get("id", "")), "position": _vec3(spec.get("position", [])), "respect_vista": false})
	for raw: Variant in config_data.get("landmarks", []):
		if raw is Dictionary:
			var spec: Dictionary = raw
			sites.append({"id": str(spec.get("id", "")), "position": _vec3(spec.get("position", [])), "respect_vista": true})

	for site: Dictionary in sites:
		var centre: Vector3 = site.position
		var half := _matching_half(centre)
		var is_summit := str(site.id).contains("summit") or centre.z > 5000.0
		var respect_vista: bool = site.respect_vista
		_plant_tree_clusters(root, centre, half, cfg, rng, is_summit, respect_vista)
		_plant_stone_clusters(root, centre, half, cfg, rng, respect_vista)


func _matching_half(centre: Vector3) -> Vector2:
	for raw: Variant in _ellipse_patches_cache:
		var patch: Dictionary = raw
		var patch_centre: Vector3 = patch.get("centre", Vector3.ZERO)
		if Vector2(patch_centre.x, patch_centre.z).distance_to(Vector2(centre.x, centre.z)) < 5.0:
			return patch.get("half", Vector2(60.0, 60.0))
	return Vector2(60.0, 60.0)


## Retries across a range of radii/angles (a landmark's own 170 m vista
## exclusion can eclipse most of a nearby region's usable footprint from any
## single fixed radius) and falls back to the registered flat ellipse height
## (`ground_height_at`) when the real collider is absent -- true for the
## summit region's own "CliffMass", which is deliberately unc-collided in
## favour of a separate thin authored crown strip.
func _tree_site_point(centre: Vector3, half: Vector2, rng: RandomNumberGenerator,
		radius_min: float, radius_max: float, respect_vista: bool = true, max_tries: int = 20) -> Dictionary:
	for _try in max_tries:
		var radius_frac := rng.randf_range(radius_min, radius_max)
		var angle := rng.randf_range(0.0, TAU)
		var x := centre.x + cos(angle) * half.x * radius_frac
		var z := centre.z + sin(angle) * half.y * radius_frac
		var probe := Vector3(x, centre.y, z)
		if _excluded(probe) or _near_route(probe, 1.0):
			continue
		if bool(_world.call("_inside_settlement_clearance", probe)):
			continue
		if respect_vista and bool(_world.call("_inside_landmark_vista", probe)):
			continue
		var hit := _raycast_down(Vector2(x, z), centre.y)
		if _is_turf_top(hit):
			return {"point": hit.get("position") as Vector3, "radius_frac": radius_frac}
		var flat := float(_world.call("ground_height_at", x, z))
		if not is_nan(flat) and absf(flat - centre.y) < 60.0:
			return {"point": Vector3(x, flat, z), "radius_frac": radius_frac}
	return {}


func _plant_tree_clusters(root: Node3D, centre: Vector3, half: Vector2, cfg: Dictionary,
		rng: RandomNumberGenerator, is_summit: bool, respect_vista: bool) -> void:
	var clusters := rng.randi_range(int(cfg.get("clusters_min", 3)), int(cfg.get("clusters_max", 5)))
	var scale_min := float(cfg.get("scale_min", 0.85))
	var scale_max := float(cfg.get("scale_max", 1.3))
	for c in clusters:
		var found := _tree_site_point(centre, half, rng, 0.15, 0.88, respect_vista)
		if found.is_empty():
			continue
		var base: Vector3 = found.point
		var exposed_rim: bool = float(found.radius_frac) > 0.72
		var per_cluster := rng.randi_range(int(cfg.get("trees_per_cluster_min", 2)), int(cfg.get("trees_per_cluster_max", 4)))
		for t in per_cluster:
			var jitter := Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-3.0, 3.0))
			var tx := base.x + jitter.x
			var tz := base.z + jitter.y
			var hit := _raycast_down(Vector2(tx, tz), base.y, 40.0, 40.0)
			var ground: Vector3 = hit.get("position") if _is_turf_top(hit) else base
			var scene: PackedScene
			if is_summit:
				scene = LOOK_DEAD_TREES[(c + t) % LOOK_DEAD_TREES.size()]
			elif exposed_rim:
				scene = LOOK_TWISTED_TREES[(c + t) % LOOK_TWISTED_TREES.size()]
			else:
				scene = LOOK_TREES[(c + t) % LOOK_TREES.size()]
			var tree := scene.instantiate() as Node3D
			tree.name = "LookTree%d_%d" % [c, t]
			tree.position = ground
			tree.rotation.y = rng.randf_range(0.0, TAU)
			tree.scale = Vector3.ONE * rng.randf_range(scale_min, scale_max)
			_world.call("_apply_tree_palette", tree, c * 13 + t)
			root.add_child(tree)
			_set_visibility(tree, 1050.0)
			_tree_count += 1
			_tree_positions.append(ground)


func _plant_stone_clusters(root: Node3D, centre: Vector3, half: Vector2, cfg: Dictionary,
		rng: RandomNumberGenerator, respect_vista: bool) -> void:
	var clusters := rng.randi_range(int(cfg.get("stone_clusters_min", 4)), int(cfg.get("stone_clusters_max", 8)))
	var scale_min := float(cfg.get("stone_scale_min", 0.9))
	var scale_max := float(cfg.get("stone_scale_max", 2.2))
	var embed_min := float(cfg.get("stone_embed_min", 0.5))
	var embed_max := float(cfg.get("stone_embed_max", 0.65))
	for c in clusters:
		var found := _tree_site_point(centre, half, rng, 0.1, 0.9, respect_vista)
		if found.is_empty():
			continue
		var base: Vector3 = found.point
		var per_cluster := rng.randi_range(2, 3)
		for s in per_cluster:
			var jitter := Vector2(rng.randf_range(-2.2, 2.2), rng.randf_range(-2.2, 2.2))
			var sx := base.x + jitter.x
			var sz := base.z + jitter.y
			var hit := _raycast_down(Vector2(sx, sz), base.y, 40.0, 40.0)
			var ground: Vector3 = hit.get("position") if _is_turf_top(hit) else base
			var scale_value := rng.randf_range(scale_min, scale_max)
			var embed := rng.randf_range(embed_min, embed_max)
			var rock := LOOK_STONES[(c + s) % LOOK_STONES.size()].instantiate() as Node3D
			rock.name = "LookStone%d_%d" % [c, s]
			rock.position = ground - Vector3.UP * (embed * 1.6 * scale_value)
			rock.rotation.y = rng.randf_range(0.0, TAU)
			rock.scale = Vector3.ONE * scale_value
			root.add_child(rock)
			_set_visibility(rock, 820.0)
			_stone_count += 1


func _set_visibility(node: Node, distance: float) -> void:
	for mi: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, true):
		mi.visibility_range_end = distance
		mi.visibility_range_end_margin = 40.0
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).visibility_range_end = distance
		(node as GeometryInstance3D).visibility_range_end_margin = 40.0


# ---------------------------------------------------------------------------
# 5. Cliffside settlement materials differ from the Meadows village. Both
# settlements reuse the exact same Quaternius medieval prefabs the Meadows
# village uses, so this recolours every roof/timber/wall surface in place
# (duplicated materials, textures kept) rather than swapping meshes.
# ---------------------------------------------------------------------------

func _dress_settlement_materials() -> void:
	var cfg: Dictionary = _cfg.get("settlement_materials", {})
	_roof_colour = Color(str(cfg.get("roof_colour", "#5a6572")))
	var timber_colour := Color(str(cfg.get("timber_colour", "#8a7d6a")))
	var wall_colour := Color(str(cfg.get("wall_colour", "#b9b4a8")))
	var guy_rope_radius := float(cfg.get("guy_rope_radius", 0.03))
	var landmarks_root := _world.get_node_or_null(^"Landmarks")
	if landmarks_root == null:
		return
	for settlement_id in ["lower_cliffs_waycamp", "cliffhold_settlement"]:
		var settlement := landmarks_root.get_node_or_null(NodePath(_safe_name(settlement_id))) as Node3D
		if settlement == null:
			continue
		for building in settlement.get_children():
			if not str(building.name).begins_with("Terrace_"):
				continue
			_recolour_building(building, timber_colour, wall_colour)
			_add_guy_ropes(building, guy_rope_radius)


func _recolour_building(building: Node3D, timber_colour: Color, wall_colour: Color) -> void:
	for mi: MeshInstance3D in building.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		var node_key := str(mi.name).to_lower()
		for surface in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(surface)
			if mat == null or not (mat is StandardMaterial3D):
				continue
			var std := mat as StandardMaterial3D
			var mat_key := std.resource_name.to_lower()
			var haystack := node_key + "|" + mat_key
			if haystack.contains("glass") or haystack.contains("chimney"):
				continue
			var target: Color
			if haystack.contains("roof") or haystack.contains("tile"):
				target = _roof_colour
			elif haystack.contains("wood") or haystack.contains("beam") or haystack.contains("trim") \
					or haystack.contains("corner") or haystack.contains("door") or haystack.contains("frame"):
				target = timber_colour
			else:
				target = wall_colour
			var dup := std.duplicate() as StandardMaterial3D
			dup.albedo_color = target
			mi.set_surface_override_material(surface, dup)
			_settlement_material_overrides += 1


func _add_guy_ropes(building: Node3D, rope_radius: float) -> void:
	var prefabs: Object = _world.get("_building_prefabs")
	var bounds: AABB
	if prefabs != null:
		bounds = prefabs.call("combined_aabb", building) as AABB
	else:
		bounds = AABB(Vector3(-2, 0, -3), Vector3(4, 4, 6))
	var centre := building.to_global(bounds.get_center())
	var ridge_y := building.to_global(Vector3(bounds.get_center().x, bounds.position.y + bounds.size.y * 0.92, bounds.get_center().z)).y
	var along_x := bounds.size.x >= bounds.size.z
	var half_span := (bounds.size.x if along_x else bounds.size.z) * 0.5 * 0.85
	var rope_material: Material = _materials.get("rope")
	for side: float in [-1.0, 1.0]:
		var local_ridge := bounds.get_center() + (Vector3(half_span * side, bounds.size.y * 0.92 - bounds.size.y * 0.5, 0.0) \
			if along_x else Vector3(0.0, bounds.size.y * 0.92 - bounds.size.y * 0.5, half_span * side))
		var ridge_point := building.to_global(local_ridge)
		ridge_point.y = ridge_y
		var outward := (ridge_point - centre)
		outward.y = 0.0
		outward = outward.normalized() if outward.length_squared() > 0.01 else Vector3.RIGHT
		var stake := ridge_point + outward * 2.4
		stake.y = centre.y - bounds.size.y * 0.5 + 0.05
		_add_cylinder_between(building, "GuyRope%s" % ("A" if side < 0.0 else "B"),
			ridge_point, stake, rope_radius, rope_material)
		_add_box(building, "GuyStake%s" % ("A" if side < 0.0 else "B"), stake, Vector3(0.14, 0.3, 0.14), rope_material)
		_settlement_guy_ropes += 1


# ---------------------------------------------------------------------------
# 7. Fog. The render fog itself lives in `data/config/cloudreach_visual.json`
# (`atmosphere.environment`), owned by the concurrent world-config pass, and
# is re-applied every frame by `world_look.gd::_apply_blended` from
# `art.json`'s time-of-day presets, so a one-time write here is overwritten
# within one frame. `cloudreach_atmosphere.json` carries this pass's own
# tunables instead: a persistent depth-fog floor (`fog_depth_begin`/
# `fog_depth_curve`, properties WorldLook never touches, so a one-time write
# sticks) that keeps 0-260 m completely clear, plus a small per-frame
# density/aerial-perspective SCALE applied after WorldLook's own write each
# frame -- the same "reapply after the owner" pattern WorldLook itself uses
# for weather, just layered from a file this pass owns instead of one the
# concurrent pass is actively editing. Together they keep a 400-900 m island
# from washing out to a flat grey slab.
# ---------------------------------------------------------------------------

func _dress_fog() -> void:
	var atmosphere_cfg: Dictionary = _read_json(ATMOSPHERE_CONFIG_PATH)
	var fog_cfg: Dictionary = atmosphere_cfg.get("distant_fog", {})
	if fog_cfg.is_empty():
		return
	var holder := _world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if holder == null or holder.environment == null:
		return
	_fog_env = holder.environment
	_fog_density_scale = float(fog_cfg.get("fog_density_scale", 1.0))
	_fog_aerial_scale = float(fog_cfg.get("aerial_perspective_scale", 1.0))
	_fog_env.fog_depth_begin = float(fog_cfg.get("fog_depth_begin_m", _fog_env.fog_depth_begin))
	_fog_env.fog_depth_curve = float(fog_cfg.get("fog_depth_curve", _fog_env.fog_depth_curve))
	set_process(true)


func _process(_delta: float) -> void:
	if _fog_env == null:
		return
	_fog_env.fog_density = _fog_env.fog_density * _fog_density_scale
	_fog_env.fog_aerial_perspective = _fog_env.fog_aerial_perspective * _fog_aerial_scale


# ---------------------------------------------------------------------------
# Public getters -- tests/smoke_cloudreach_look.gd and the operator report.
# ---------------------------------------------------------------------------

func bridge_rope_rail_sides() -> Dictionary:
	return _bridge_rope_sides.duplicate()


func bridge_post_count() -> int:
	return _bridge_post_count


func mooring_line_counts() -> Dictionary:
	return _mooring_lines.duplicate()


func cover_finish_main_count() -> int:
	return _cover_main_count


func cover_finish_far_count() -> int:
	return _cover_far_count


func cover_finish_alpine_count() -> int:
	return _cover_alpine_count


func cover_finish_total_count() -> int:
	return _cover_main_count + _cover_far_count + _cover_alpine_count


func cover_finish_count_near(at: Vector3, radius: float) -> int:
	var total := 0
	for i in _cover_patch_centres.size():
		if _cover_patch_centres[i].distance_to(at) <= radius:
			total += _cover_counts_by_index[i]
	return total


func tree_count() -> int:
	return _tree_count


func tree_count_near(at: Vector3, radius: float) -> int:
	var total := 0
	for p in _tree_positions:
		if p.distance_to(at) <= radius:
			total += 1
	return total


func stone_count() -> int:
	return _stone_count


func settlement_material_override_count() -> int:
	return _settlement_material_overrides


func settlement_guy_rope_count() -> int:
	return _settlement_guy_ropes


func settlement_roof_colour() -> Color:
	return _roof_colour
