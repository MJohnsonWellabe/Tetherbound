extends SceneTree
## VIS probe (AUDIT M9): are the South Bridge gully walls Terrain3D cells or a
## mesh? The slope-rock WIP (`26b7216d`, opt-in rock blend on steep cells in
## `shaders/terrain_ground.gdshader`) rendered with no visible change at the
## gully, so before reviving it we need to know what the camera actually sees.
##
##   godot --headless --path . --script tools/_probe_south_bridge_gully.gd
##
## Reports, for cross-sections of the carve (`terrain_playground.json`
## `crossings[0].carve`):
##   * the Terrain3D height profile across the trench and its steepest slope,
##     plus the terrain vertex spacing (how many vertices the wall spans);
##   * the control-map base/overlay ids and blend along the same line;
##   * horizontal raycasts into each wall, one per height step: the collider's
##     class and path (Terrain3D vs a StaticBody/CSG mesh). Headless runs may
##     not build Terrain3D collision; the summary line says when no ray hit,
##     in which case the rays prove nothing and the height/control data stand;
##   * every GeometryInstance3D whose world AABB reaches into the trench below
##     the highest rim, largest extent first (so flat wall cards still show).
## Read-only: it boots the production Meadows scene and quits.

const SCENE := "res://scenes/world/meadows_playground.tscn"
## The carve runs along world X (`axis_deg` 0) and the bridge road crosses it
## north-south, so each section samples ALONG Z at one X station.
const SECTIONS_X := [-160.0, -60.0, -20.0, 8.0, 30.0, 80.0, 200.0]
const HALF_SPAN := 18.0
const STEP := 0.5


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_playground.json"))
	var carve: Dictionary = (cfg["crossings"] as Array)[0]["carve"]
	var cz := float(carve["centre"][1])
	print("PROBE carve centre=%s half_width=%s rim=%s depth=%s axis_deg=%s" % [
		carve["centre"], carve["half_width"], carve["rim"], carve["depth"], carve["axis_deg"]])
	var game: Node = root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
		game.set("current_realm", "meadows")
	var world := (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(world)
	current_scene = world
	for i in 3000:
		await process_frame
		if (not world.has_method("shell_build_complete") or bool(world.call("shell_build_complete"))) and i >= 30:
			break
	for i in 20:
		await physics_frame
	var terrain: Node = _find_class(world, "Terrain3D")
	var data: Object = terrain.get("data") if terrain != null else null
	var spacing := float(terrain.get("vertex_spacing")) if terrain != null else -1.0
	print("PROBE terrain=%s vertex_spacing=%.2f material_shader=%s" % [
		terrain.get_path() if terrain != null else "NONE", spacing, _terrain_shader(terrain)])
	var space := world.get_world_3d().direct_space_state
	var rim_top := -INF
	var rays := 0
	var ray_hits := 0
	for x: float in SECTIONS_X:
		var profile: Array = []
		var steepest := 0.0
		var prev := NAN
		var rim_h := -INF
		var floor_h := INF
		var z := cz - HALF_SPAN
		while z <= cz + HALF_SPAN + 0.001:
			var h := float(data.call("get_height", Vector3(x, 0, z))) if data != null else NAN
			profile.append("%.1f" % h)
			if is_finite(prev):
				steepest = maxf(steepest, rad_to_deg(atan(absf(h - prev) / STEP)))
			prev = h
			rim_h = maxf(rim_h, h)
			floor_h = minf(floor_h, h)
			z += STEP
		rim_top = maxf(rim_top, rim_h)
		print("PROBE section x=%.0f floor=%.2f rim=%.2f steepest=%.1fdeg profile(z %.0f..%.0f step %.1f)=%s" % [
			x, floor_h, rim_h, steepest, cz - HALF_SPAN, cz + HALF_SPAN, STEP, " ".join(profile)])
		# Control-map ids on the same line, one per 2 m texel: base/overlay@blend.
		var ids: Array = []
		var zc := cz - HALF_SPAN
		while data != null and zc <= cz + HALF_SPAN + 0.001:
			var at := Vector3(x, 0, zc)
			ids.append("%d/%d@%.2f" % [int(data.call("get_control_base_id", at)),
				int(data.call("get_control_overlay_id", at)), float(data.call("get_control_blend", at))])
			zc += 2.0
		print("PROBE   control x=%.0f (z %.0f..%.0f step 2)=%s" % [x, cz - HALF_SPAN, cz + HALF_SPAN, " ".join(ids)])
		# Horizontal rays from the trench centre line out into each wall.
		for side: float in [-1.0, 1.0]:
			var y := floor_h + 1.0
			while y < rim_h:
				var from := Vector3(x, y, cz)
				var to := Vector3(x, y, cz + side * HALF_SPAN)
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
				rays += 1
				if not hit.is_empty():
					ray_hits += 1
				if hit.is_empty():
					print("PROBE   ray x=%.0f side=%+.0f y=%.1f -> no hit" % [x, side, y])
				else:
					var col: Object = hit["collider"]
					print("PROBE   ray x=%.0f side=%+.0f y=%.1f -> hit z=%.2f normal=%s collider=%s %s" % [
						x, side, y, (hit["position"] as Vector3).z, _v(hit["normal"]), col.get_class(),
						(col as Node).get_path() if col is Node else str(col)])
				y += 2.5
	print("PROBE rays: %d of %d hit%s" % [ray_hits, rays,
		" -- no collision in the trench (headless Terrain3D builds none); rays prove nothing" if ray_hits == 0 else ""])
	# Geometry reaching into the trench below the rim anywhere along the probed run.
	var reach := float(carve["half_width"]) + float(carve["rim"]) + 1.0
	var box := AABB(Vector3(SECTIONS_X[0] - 10.0, -INF, cz - reach), Vector3(SECTIONS_X[-1] - SECTIONS_X[0] + 20.0, 0, 2.0 * reach))
	var found: Array = []
	for n: Node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := n as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var aabb: AABB = gi.global_transform * gi.get_aabb()
		if aabb.position.x > box.position.x + box.size.x or aabb.end.x < box.position.x:
			continue
		if aabb.position.z > box.position.z + box.size.z or aabb.end.z < box.position.z:
			continue
		if aabb.position.y > rim_top:
			continue  # entirely above the trench
		if aabb.size.length() > 3000.0:
			continue  # sky dome / world-scale cards
		var res := ""
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
			res = (gi as MeshInstance3D).mesh.resource_path
		found.append({"extent": aabb.size.length(), "line": "%s %s size=%s pos=%s mesh=%s" % [
			gi.get_class(), gi.get_path(), _v(aabb.size), _v(aabb.position), res]})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["extent"]) > float(b["extent"]))
	print("PROBE geometry in trench footprint: %d" % found.size())
	for i in mini(found.size(), 40):
		print("PROBE   " + str(found[i]["line"]))
	quit(0)


func _terrain_shader(terrain: Node) -> String:
	if terrain == null:
		return ""
	var mat: Object = terrain.get("material")
	if mat == null:
		return "no material"
	var shader_override: Variant = mat.get("shader_override")
	var enabled: Variant = mat.get("shader_override_enabled")
	var auto: Variant = mat.get("auto_shader")
	return "override=%s enabled=%s auto_shader=%s" % [
		(shader_override as Shader).resource_path if shader_override is Shader else str(shader_override), enabled, auto]


func _find_class(n: Node, cls: String) -> Node:
	if n.get_class() == cls:
		return n
	for c: Node in n.get_children():
		var r := _find_class(c, cls)
		if r != null:
			return r
	return null


func _v(v: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [v.x, v.y, v.z]
