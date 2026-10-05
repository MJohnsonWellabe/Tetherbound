extends "res://tools/catalogue_survey.gd"

## PERF lane probe (F26#5 / ACCEPTANCE §7). Loads one realm's real
## production scene, stands the production trainer and camera at each
## F26 route stand (data/config/lookdev_routes.json, the same stands
## tools/capture_lookdev_route.gd walks) and records the CPU-side and
## scene-side costs that do not depend on the GPU:
##   - node census by class and by top-level subtree;
##   - MeshInstance3D / MultiMeshInstance3D counts, instance totals and
##     visibility-range coverage, and which scatter is or is not MultiMesh;
##   - lights and shadow casters;
##   - physics bodies, areas and shapes;
##   - per stand: draw calls, primitives and objects in frame, process and
##     physics-step milliseconds, and a frustum census of node-backed geometry
##     by distance band (what the realm far floor pulls in).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/perf_probe.gd -- --biome=meadows \
##     --output=res://ralph/reports/PERF/probe/meadows_before.json
##
## Optional: --label=<text>, --sample=<frames> (default 30),
## --settle=<frames> (default 90), --far=<metres> overrides the production
## camera far after the preset applies (structural A/B only).
##
## Never --headless: the Dummy driver reports zero for every RENDER_* monitor.
## llvmpipe frame TIME is meaningless and is not a device claim; draw calls,
## primitives, object counts, node counts and CPU physics/process costs are
## structural and are what this probe exists to compare.

const ROUTES_PATH := "res://data/config/lookdev_routes.json"
const MEADOWS_OPENING_FLAGS := [
	"opening:beat:wake", "opening:beat:house", "opening:beat:choose",
	"opening:starter_granted", "opening:beat:name", "opening:beat:return_starter",
	"opening:beat:walk_out",
]
const DISTANCE_BANDS: Array[float] = [100.0, 320.0, 1000.0, 3000.0]
const TOP_CLASSES := 30

var _label := ""
var _out_path := ""
var _sample := 30
var _settle := 90
var _far_override := -1.0
var _fars: Array[float] = []
var _attribute := false
var _attribute_stand := 0
var _route: Dictionary = {}
var _report: Dictionary = {}


func _prepare_character_fixture(game: Node) -> void:
	if _biome_id != "meadows":
		return
	# Same render-route fixture as capture_lookdev_route.gd: skip Grandpa's
	# opening modal so the production trainer stands in the ordinary world.
	for flag: String in MEADOWS_OPENING_FLAGS:
		game.get("progression").call("set_flag", flag)


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("perf probe requires a rendering display; never use --headless")
		quit(1)
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--biome="):
			_biome_id = arg.trim_prefix("--biome=").strip_edges().to_lower()
		elif arg.begins_with("--output="):
			_out_path = arg.trim_prefix("--output=").strip_edges()
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--sample="):
			_sample = maxi(1, int(arg.trim_prefix("--sample=")))
		elif arg.begins_with("--settle="):
			_settle = maxi(1, int(arg.trim_prefix("--settle=")))
		elif arg.begins_with("--far="):
			for value: String in arg.trim_prefix("--far=").split(",", false):
				_fars.append(float(value))
			_far_override = _fars[0]
		elif arg == "--attribute":
			_attribute = true
		elif arg.begins_with("--attribute-stand="):
			_attribute = true
			_attribute_stand = int(arg.trim_prefix("--attribute-stand="))
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROUTES_PATH))
	if not SCENES.has(_biome_id) or not config is Dictionary \
			or not (config as Dictionary).get("routes", {}).has(_biome_id) or _out_path == "":
		push_error("perf probe: needs --biome=meadows|water|cloudreach|stormwood and --output=<json>")
		quit(2)
		return
	_route = config.routes[_biome_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_path.get_base_dir()))
	_report = {
		"schema": "perf_probe/1",
		"biome": _biome_id,
		"label": _label,
		"scene": str(SCENES[_biome_id]),
		"source_commit": _git_head(),
		"captured_utc": Time.get_datetime_string_from_system(true),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"resolution": [root.size.x, root.size.y],
		"disclosure": "Structural counters only. Software-rasterised frame time is never device performance; process/physics ms are CPU costs on this container's CPU.",
	}
	var t0 := Time.get_ticks_msec()
	if not await _mount_production_world() or not _prepare_capture_shell():
		_report["failures"] = _failures
		_save()
		quit(1)
		return
	_report["boot_ms"] = Time.get_ticks_msec() - t0
	_look.call("refresh_graphics")
	# Structural comparison: freeze the day clock and clear weather so rows
	# differ only by what each row changes (catalogue_survey's audit pin).
	_report["clock"] = await _pin_time("day")
	_look.set_process(true)
	if _far_override > 0.0:
		_set_far(_far_override)
	_report["camera"] = {"far": _camera.far, "near": _camera.near, "fov": _camera.fov,
		"far_override": _far_override}
	_report["census"] = _census(_world)
	_report["terrain"] = _terrain_summary()
	var stands: Array = [_route.start]
	stands.append_array(_route.waypoints)
	var rows: Array[Dictionary] = []
	for index in stands.size():
		var here := _route_point(stands[index] as Array)
		var next_raw: Array = stands[index + 1] if index + 1 < stands.size() else stands[index - 1]
		var there := _route_point(next_raw)
		if not here.is_finite() or not there.is_finite():
			_failures.append("stand %d has no floor" % index)
			continue
		if _fars.size() <= 1:
			rows.append(await _measure_stand("stand_%d" % index, here, there))
		else:
			for far: float in _fars:
				_set_far(far)
				rows.append(await _measure_stand("stand_%d_far%d" % [index, int(far)], here, there))
		if _attribute and index == _attribute_stand:
			_report["attribution_stand_%d" % index] = await _attribute_subtrees()
		_save_rows(rows)
	_report["stands"] = rows
	_report["failures"] = _failures
	_save()
	print("PERF PROBE %s %s -> %s" % [_biome_id, "OK" if _failures.is_empty() else "FAILED", _out_path])
	quit(0 if _failures.is_empty() else 1)


func _route_point(raw: Array) -> Vector3:
	if raw.size() == 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	if raw.size() != 2:
		return Vector3(INF, INF, INF)
	var height := float(_world.call("ground_height_at", float(raw[0]), float(raw[1])))
	if not is_finite(height):
		return Vector3(INF, INF, INF)
	return Vector3(float(raw[0]), resolve_capture_ground(_player, float(raw[0]), float(raw[1]), height), float(raw[1]))


func _measure_stand(stand_name: String, here: Vector3, there: Vector3) -> Dictionary:
	var forward := Vector2(there.x - here.x, there.z - here.z).normalized()
	if forward.length_squared() < 0.5:
		forward = Vector2(0.0, 1.0)
	_player.global_position = here + Vector3.UP * TRAINER_CLEARANCE
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	var yaw := capture_yaw(forward)
	_rig.set("yaw", yaw)
	_rig.rotation = Vector3(float(_rig.get("pitch")), yaw, 0.0)
	_rig.global_position = _player.global_position
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in _settle:
		await process_frame
	var monitors := {
		"draw_calls": Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME,
		"primitives": Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME,
		"objects": Performance.RENDER_TOTAL_OBJECTS_IN_FRAME,
		"process_ms": Performance.TIME_PROCESS,
		"physics_step_ms": Performance.TIME_PHYSICS_PROCESS,
		"navigation_ms": Performance.TIME_NAVIGATION_PROCESS,
		"node_count": Performance.OBJECT_NODE_COUNT,
		"orphan_nodes": Performance.OBJECT_ORPHAN_NODE_COUNT,
		"physics_active_objects": Performance.PHYSICS_3D_ACTIVE_OBJECTS,
		"physics_collision_pairs": Performance.PHYSICS_3D_COLLISION_PAIRS,
		"physics_islands": Performance.PHYSICS_3D_ISLAND_COUNT,
		"video_mem_mb": Performance.RENDER_VIDEO_MEM_USED,
	}
	var sums := {}
	var peaks := {}
	for key: String in monitors:
		sums[key] = 0.0
		peaks[key] = 0.0
	var physics_before := Engine.get_physics_frames()
	var frames_before := Engine.get_process_frames()
	for _frame in _sample:
		await RenderingServer.frame_post_draw
		for key: String in monitors:
			var value := float(Performance.get_monitor(monitors[key]))
			sums[key] = float(sums[key]) + value
			peaks[key] = maxf(float(peaks[key]), value)
	var averages := {}
	for key: String in monitors:
		averages[key] = float(sums[key]) / float(_sample)
	if averages.has("video_mem_mb"):
		averages["video_mem_mb"] = float(averages.video_mem_mb) / 1048576.0
		peaks["video_mem_mb"] = float(peaks.video_mem_mb) / 1048576.0
	var steps := Engine.get_physics_frames() - physics_before
	var frames := Engine.get_process_frames() - frames_before
	var row := {
		"stand": stand_name,
		"player": [here.x, here.y, here.z],
		"heading_xz": [forward.x, forward.y],
		"camera_position": [_camera.global_position.x, _camera.global_position.y, _camera.global_position.z],
		"camera_far": _camera.far,
		"avg": averages,
		"peak": peaks,
		"physics_steps_per_frame": float(steps) / maxf(1.0, float(frames)),
		"frustum": _frustum_census(),
	}
	print("PERF STAND %s %s draws=%.0f prims=%.0f objs=%.0f proc=%.1fms phys=%.1fms" % [
		_biome_id, stand_name, averages.draw_calls, averages.primitives, averages.objects,
		averages.process_ms * 1000.0, averages.physics_step_ms * 1000.0])
	return row


## WorldLook re-applies graphics_prefs.apply_camera every frame, whose result
## is max(preset far, the realm's vista floor meta). Overriding the meta is
## the only override that survives the next frame; the Low preset's 320 m
## remains the lower bound.
func _set_far(far: float) -> void:
	_camera.set_meta(&"vista_far_floor_m", far)
	_camera.far = far


func _sample_render(frames: int) -> Vector3:
	var sum := Vector3.ZERO
	for _frame in frames:
		await RenderingServer.frame_post_draw
		sum += Vector3(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	return sum / float(frames)


## Hide one family of top-level children at a time (and the sun's shadow)
## at the current stand and record what the RenderingServer stops drawing.
## Families group numbered siblings (Wild_pipwing_10_1 -> Wild); each toggle
## is bracketed by its own fresh baseline so slow drift cannot leak in.
func _attribute_subtrees() -> Array:
	var families := {}
	for child: Node in _world.get_children():
		var node3d := child as Node3D
		if node3d == null or not node3d.visible or child == _player or child == _rig \
				or child is WorldEnvironment or child is Light3D:
			continue
		var family := _family(str(child.name))
		if not families.has(family):
			families[family] = []
		(families[family] as Array).append(node3d)
	var rows: Array = []
	var sun := _world.get_node_or_null(^"Sun") as DirectionalLight3D
	if sun != null and sun.shadow_enabled:
		var delta := await _toggle_delta(func(on: bool) -> void: sun.shadow_enabled = on)
		rows.append({"subtree": "(sun shadow)", "members": 1, "draws": delta.x,
			"primitives": delta.y, "objects": delta.z})
		print("PERF ATTR (sun shadow) draws=%.0f prims=%.0f" % [delta.x, delta.y])
	for family: String in families:
		var members: Array = families[family]
		var delta := await _toggle_delta(func(on: bool) -> void:
			for node: Node3D in members:
				node.visible = on)
		if delta.x >= 5.0 or delta.y >= 10000.0:
			rows.append({"subtree": family, "members": members.size(), "draws": delta.x,
				"primitives": delta.y, "objects": delta.z})
			print("PERF ATTR %s (%d) draws=%.0f prims=%.0f" % [family, members.size(), delta.x, delta.y])
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.draws) > float(b.draws))
	# One level down inside the costliest single-node subtree.
	for row: Dictionary in rows:
		if int(row.get("members", 0)) != 1:
			continue
		var top := _world.get_node_or_null(NodePath(str(row.subtree))) as Node3D
		if top == null:
			continue
		var inner: Array = []
		for child: Node in top.get_children():
			var node3d := child as Node3D
			if node3d == null or not node3d.visible:
				continue
			var delta := await _toggle_delta(func(on: bool) -> void: node3d.visible = on)
			if delta.x >= 20.0:
				inner.append({"subtree": "%s/%s" % [top.name, child.name], "draws": delta.x,
					"primitives": delta.y, "objects": delta.z})
				print("PERF ATTR   %s/%s draws=%.0f prims=%.0f" % [top.name, child.name, delta.x, delta.y])
		inner.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.draws) > float(b.draws))
		rows.append_array(inner)
		break
	return rows


func _toggle_delta(apply: Callable) -> Vector3:
	await process_frame
	var before := await _sample_render(2)
	apply.call(false)
	for _frame in 2:
		await process_frame
	var without := await _sample_render(2)
	apply.call(true)
	for _frame in 2:
		await process_frame
	var after := await _sample_render(2)
	return (before + after) * 0.5 - without


static func _family(node_name: String) -> String:
	var parts := node_name.split("_")
	if parts.size() > 1 and parts[0] == "Wild":
		return "Wild"
	var out: Array[String] = []
	for part: String in parts:
		if part.is_valid_int():
			break
		out.append(part)
	var joined := "_".join(out)
	while joined.length() > 0 and joined.right(1).is_valid_int():
		joined = joined.left(-1)
	return joined if joined != "" else node_name


func _census(scene_root: Node) -> Dictionary:
	var by_class := {}
	var by_subtree := {}
	var meshes := {"count": 0, "visible": 0, "with_visibility_range": 0, "shadow_casting": 0,
		"shadow_casting_no_range": 0, "surfaces": 0}
	var multimesh := {"count": 0, "instances": 0, "visible_instances": 0, "with_visibility_range": 0,
		"shadow_casting": 0, "by_owner": {}}
	var lights := {"directional": 0, "omni": 0, "spot": 0, "shadowed": 0, "shadowed_omni_spot": 0}
	var physics := {"static_bodies": 0, "character_bodies": 0, "rigid_bodies": 0, "animatable_bodies": 0,
		"areas": 0, "collision_shapes": 0, "collision_polygons": 0}
	var particles := {"gpu": 0, "cpu": 0}
	var processing := {"process": 0, "physics_process": 0, "animation_players": 0, "animation_trees": 0,
		"skeletons": 0}
	var mesh_subtrees := {}
	var owners_of := {"CharacterBody3D": {}, "AnimationPlayer": {}, "OmniLight3D": {}, "Node3D": {},
		"CollisionShape3D": {}, "GPUParticles3D": {}}
	var total := 0
	var stack: Array = []
	for child: Node in scene_root.get_children():
		stack.append([child, str(child.name)])
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var top: String = item[1]
		total += 1
		var cls := node.get_class()
		by_class[cls] = int(by_class.get(cls, 0)) + 1
		by_subtree[top] = int(by_subtree.get(top, 0)) + 1
		if owners_of.has(cls):
			var owned: Dictionary = owners_of[cls]
			var key := top
			if node.get_parent() != null and node.get_parent() != scene_root:
				key = top + "/" + str(node.get_parent().name).left(24)
			owned[key] = int(owned.get(key, 0)) + 1
		if node.is_processing():
			processing.process += 1
		if node.is_physics_processing():
			processing.physics_process += 1
		if node is AnimationPlayer:
			processing.animation_players += 1
		elif node is AnimationTree:
			processing.animation_trees += 1
		elif node is Skeleton3D:
			processing.skeletons += 1
		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			meshes.count += 1
			mesh_subtrees[top] = int(mesh_subtrees.get(top, 0)) + 1
			if mi.is_visible_in_tree():
				meshes.visible += 1
			if mi.visibility_range_end > 0.0:
				meshes.with_visibility_range += 1
			if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				meshes.shadow_casting += 1
				if mi.visibility_range_end <= 0.0:
					meshes.shadow_casting_no_range += 1
			if mi.mesh != null:
				meshes.surfaces += mi.mesh.get_surface_count()
		elif node is MultiMeshInstance3D:
			var mmi := node as MultiMeshInstance3D
			multimesh.count += 1
			var n := 0
			var vis := 0
			if mmi.multimesh != null:
				n = mmi.multimesh.instance_count
				vis = mmi.multimesh.visible_instance_count
				vis = n if vis < 0 else vis
			multimesh.instances += n
			multimesh.visible_instances += vis
			if mmi.visibility_range_end > 0.0:
				multimesh.with_visibility_range += 1
			if mmi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				multimesh.shadow_casting += 1
			var owners: Dictionary = multimesh.by_owner
			var entry: Dictionary = owners.get(top, {"count": 0, "instances": 0})
			entry.count = int(entry.count) + 1
			entry.instances = int(entry.instances) + vis
			owners[top] = entry
		elif node is DirectionalLight3D:
			lights.directional += 1
			if (node as Light3D).shadow_enabled:
				lights.shadowed += 1
		elif node is OmniLight3D or node is SpotLight3D:
			if node is OmniLight3D:
				lights.omni += 1
			else:
				lights.spot += 1
			if (node as Light3D).shadow_enabled:
				lights.shadowed += 1
				lights.shadowed_omni_spot += 1
		elif node is CharacterBody3D:
			physics.character_bodies += 1
		elif node is AnimatableBody3D:
			physics.animatable_bodies += 1
		elif node is StaticBody3D:
			physics.static_bodies += 1
		elif node is RigidBody3D:
			physics.rigid_bodies += 1
		elif node is Area3D:
			physics.areas += 1
		elif node is CollisionShape3D:
			physics.collision_shapes += 1
		elif node is CollisionPolygon3D:
			physics.collision_polygons += 1
		elif node is GPUParticles3D:
			particles.gpu += 1
		elif node is CPUParticles3D:
			particles.cpu += 1
		for child: Node in node.get_children():
			stack.append([child, top])
	return {
		"total_nodes": total,
		"by_class": _top(by_class, TOP_CLASSES),
		"by_subtree": _top(by_subtree, 40),
		"mesh_instances_by_subtree": _top(mesh_subtrees, 25),
		"class_owners": _owners_top(owners_of),
		"meshes": meshes,
		"multimesh": multimesh,
		"lights": lights,
		"physics": physics,
		"particles": particles,
		"processing": processing,
	}


func _frustum_census() -> Dictionary:
	# Node-backed geometry only: Terrain3D's own scatter and clipmap live as
	# raw RenderingServer instances and are not walked here.
	var eye := _camera.global_position
	var planes := _camera.get_frustum()
	var bands := {}
	var labels: Array[String] = []
	var lower := 0.0
	for edge in DISTANCE_BANDS:
		labels.append("%d-%d" % [int(lower), int(edge)])
		lower = edge
	labels.append("%d+" % int(lower))
	for label in labels:
		bands[label] = {"meshes": 0, "shadow_casting": 0, "ranged": 0, "multimesh": 0, "mm_instances": 0}
	var far_owners := {}
	var lit := {"omni_spot_in_view": 0, "shadowed_in_view": 0, "shadowed": []}
	var stack: Array = []
	for child: Node in _world.get_children():
		stack.append([child, str(child.name)])
	while not stack.is_empty():
		var item: Array = stack.pop_back()
		var node: Node = item[0]
		var top: String = item[1]
		for child: Node in node.get_children():
			stack.append([child, top])
		if (node is OmniLight3D or node is SpotLight3D) and (node as Light3D).is_visible_in_tree():
			var light := node as Light3D
			var reach := float(light.get("omni_range") if light is OmniLight3D else light.get("spot_range"))
			var sphere := AABB(light.global_position - Vector3.ONE * reach, Vector3.ONE * reach * 2.0)
			if _aabb_in_frustum(sphere, planes) and eye.distance_to(light.global_position) - reach < _camera.far:
				lit.omni_spot_in_view += 1
				if light.shadow_enabled:
					lit.shadowed_in_view += 1
					(lit.shadowed as Array).append("%s r=%.0f d=%.0f" % [str(_world.get_path_to(light)),
						reach, eye.distance_to(light.global_position)])
			continue
		if not node is GeometryInstance3D or node is Label3D:
			continue
		var gi := node as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var box: AABB = gi.global_transform * gi.get_aabb()
		if not _aabb_in_frustum(box, planes):
			continue
		var centre := box.get_center()
		var distance := eye.distance_to(centre)
		if gi.visibility_range_end > 0.0 and distance > gi.visibility_range_end + gi.visibility_range_end_margin:
			continue
		if distance > _camera.far + box.size.length() * 0.5:
			continue
		var index := 0
		while index < DISTANCE_BANDS.size() and distance >= DISTANCE_BANDS[index]:
			index += 1
		var band: Dictionary = bands[labels[index]]
		if gi is MultiMeshInstance3D:
			band.multimesh += 1
			var mm := (gi as MultiMeshInstance3D).multimesh
			if mm != null:
				band.mm_instances += mm.instance_count if mm.visible_instance_count < 0 else mm.visible_instance_count
		else:
			band.meshes += 1
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			band.shadow_casting += 1
		if gi.visibility_range_end > 0.0:
			band.ranged += 1
		if distance >= DISTANCE_BANDS[1]:
			far_owners[top] = int(far_owners.get(top, 0)) + 1
	return {"bands": bands, "beyond_320m_by_subtree": _top(far_owners, 20), "lights": lit}


static func _aabb_in_frustum(box: AABB, planes: Array[Plane]) -> bool:
	# Camera frustum planes face outward. A box is outside when even its
	# corner furthest along -normal is over one plane.
	for plane: Plane in planes:
		var q := box.position
		if plane.normal.x <= 0.0:
			q.x += box.size.x
		if plane.normal.y <= 0.0:
			q.y += box.size.y
		if plane.normal.z <= 0.0:
			q.z += box.size.z
		if plane.distance_to(q) > 0.0:
			return false
	return true


func _terrain_summary() -> Dictionary:
	var terrain := _world.get_node_or_null(^"Terrain")
	if terrain == null:
		return {"present": false}
	var out := {"present": true, "class": terrain.get_class()}
	for key: String in ["mesh_lods", "mesh_size", "vertex_spacing", "collision_mode",
			"collision_radius", "collision_shape_size", "render_layers", "cast_shadows",
			"region_size"]:
		var value: Variant = terrain.get(key)
		if value != null:
			out[key] = value if typeof(value) in [TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING] else str(value)
	var data: Variant = terrain.get("data")
	if data is Object and (data as Object).has_method("get_region_count"):
		out["region_count"] = int((data as Object).call("get_region_count"))
	var assets: Variant = terrain.get("assets")
	if assets is Object and (assets as Object).has_method("get_mesh_count"):
		var mesh_count := int((assets as Object).call("get_mesh_count"))
		out["instancer_mesh_assets"] = mesh_count
		var rows: Array = []
		for index in mesh_count:
			var asset: Variant = (assets as Object).call("get_mesh_asset", index)
			if asset is Object:
				var a := asset as Object
				rows.append({"id": index, "name": str(a.get("name")),
					"lod0_range": a.get("lod0_range"),
					"fade_margin": a.get("fade_margin"),
					"last_lod": a.get("last_lod"),
					"cast_shadows": a.get("cast_shadows"),
					"enabled": a.get("enabled"),
					"instance_count": _instance_total(data, index)})
		out["instancer_assets"] = rows
	return out


static func _instance_total(data: Variant, mesh_id: int) -> int:
	# Terrain3D keeps instances per region as {mesh_id: [transforms, ...]}.
	if not data is Object or not (data as Object).has_method("get_regions_active"):
		return -1
	var total := 0
	for region: Variant in (data as Object).call("get_regions_active"):
		var instances: Variant = (region as Object).get("instances")
		if not instances is Dictionary or not (instances as Dictionary).has(mesh_id):
			continue
		var cells: Variant = (instances as Dictionary)[mesh_id]
		if cells is Dictionary:
			for cell: Variant in (cells as Dictionary).values():
				if cell is Array and not (cell as Array).is_empty() and (cell as Array)[0] is Array:
					total += ((cell as Array)[0] as Array).size()
	return total


static func _owners_top(owners_of: Dictionary) -> Dictionary:
	var out := {}
	for cls: String in owners_of:
		out[cls] = _top(owners_of[cls], 12)
	return out


static func _top(counts: Dictionary, limit: int) -> Array:
	var rows: Array = []
	for key: Variant in counts:
		rows.append([str(key), int(counts[key])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
	return rows.slice(0, limit)


func _git_head() -> String:
	var output: Array = []
	if OS.execute("git", ["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "HEAD"], output) == 0 \
			and not output.is_empty():
		return str(output[0]).strip_edges()
	return ""


func _save_rows(rows: Array[Dictionary]) -> void:
	_report["stands"] = rows
	_save()


func _save() -> void:
	var file := FileAccess.open(_out_path, FileAccess.WRITE)
	if file == null:
		push_error("perf probe: cannot write %s" % _out_path)
		return
	file.store_string(JSON.stringify(_report, "\t") + "\n")
	file.close()
