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
	if _report:
		print("[cloudreach_grounding] seated=", _seated.size(), " applied=", apply)


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
	# Probe from inside the piece's own body (a ray never hits the convex
	# collider it starts in), so ground that rises above the base reads as a
	# sunk foot rather than as void under it.
	var start_up := minf(height * 0.5, float(_cfg.get("probe_start_inside_m", 1.0)))
	for point: Vector3 in points:
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * start_up,
			point - Vector3.UP * max_probe)
		var hit := _space.intersect_ray(query)
		if hit.is_empty():
			void_points += 1
			continue
		var hit_y := float((hit.position as Vector3).y)
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
	result.action = "seat"
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
	var entry := {"path": str(mesh_instance.get_path()), "gap": float(result.max_gap),
		"radius": bottom_radius, "skirt_height": height, "rocks": 0}
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
