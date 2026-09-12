extends SceneTree

## OWNER-0912 Tier 2 #4: production-world receipts for every Meadows red-cloth
## geometry family that can still be encountered. This is intentionally a
## representative sweep rather than twenty near-identical roadside frames:
## one loose full standard, the Relay's mounted full standard, both installed
## cloth-only canopy variants, and one of the Hall's authored hanging banners.
## Subjects are never spawned, duplicated, retinted, reposed, or made visible
## by this tool. A missing production node makes the run incomplete.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_meadows_banner_treatments_0912.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-banner-treatments-01

const SCENE := "res://scenes/world/meadows_playground.tscn"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")
const READY_TIMEOUT_MS := 420_000
const TIMES := ["day", "night"]
const VIEWS := ["ordinary", "close-oblique"]

const SUBJECTS := [
	{
		"id": "roadside-full-standard",
		"label": "Tether waypost complete Banner_1 standard",
		"path": NodePath("Props/tether_waypost/Banner_1"),
		"required": [NodePath(".")],
		"focus": [NodePath(".")],
		"source": "res://data/config/bands/band1_lower_meadows/props.json",
		"front_axis": "z",
		"front_sign": 1.0,
		"side_sign": 1.0,
	},
	{
		"id": "relay-mounted-full-standard",
		"label": "Relay approach mounted Banner_1 standard",
		"path": NodePath("TetherRelay/Gate/GateStandard_west"),
		"required": [NodePath(".")],
		"focus": [NodePath(".")],
		"source": "res://data/config/tether_relay.json",
		"front_axis": "z",
		"front_sign": 1.0,
		"side_sign": -1.0,
	},
	{
		"id": "canopy-cloth-variants",
		"label": "Tournament canopy Banner_1_Cloth and Banner_2_Cloth accents",
		"path": NodePath("Tournament/GroundPresentation/MarshalCanopy"),
		"required": [NodePath("CanopyClothAccent_0"), NodePath("CanopyClothAccent_1")],
		"focus": [NodePath("CanopyClothAccent_0"), NodePath("CanopyClothAccent_1")],
		"source": "res://data/config/tournament_ground_presentation.json",
		"front_axis": "z",
		"front_sign": 1.0,
		"side_sign": 1.0,
	},
	{
		"id": "hall-hanging-banner",
		"label": "Stronghold shared-shader hanging swallow-tail banner",
		"path": NodePath("Stronghold"),
		"find_name": "ExteriorBanner",
		"required": [NodePath("BannerBar"), NodePath("BannerCloth")],
		"focus": [NodePath(".")],
		"source": "res://scripts/world/stronghold.gd",
		"front_axis": "x",
		"front_sign": 1.0,
		"side_sign": 1.0,
	},
]

const PLANNED_FRAMES := [
	"01-roadside-full-standard-ordinary-day",
	"02-roadside-full-standard-close-oblique-day",
	"03-roadside-full-standard-ordinary-night",
	"04-roadside-full-standard-close-oblique-night",
	"05-relay-mounted-full-standard-ordinary-day",
	"06-relay-mounted-full-standard-close-oblique-day",
	"07-relay-mounted-full-standard-ordinary-night",
	"08-relay-mounted-full-standard-close-oblique-night",
	"09-canopy-cloth-variants-ordinary-day",
	"10-canopy-cloth-variants-close-oblique-day",
	"11-canopy-cloth-variants-ordinary-night",
	"12-canopy-cloth-variants-close-oblique-night",
	"13-hall-hanging-banner-ordinary-day",
	"14-hall-hanging-banner-close-oblique-day",
	"15-hall-hanging-banner-ordinary-night",
	"16-hall-hanging-banner-close-oblique-night",
]

var _out_dir := ""
var _world: Node3D = null
var _player: CharacterBody3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _terrain: Node = null
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _manifest: Dictionary = {}


func _init() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	_run()


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Meadows banner-treatment capture"):
		quit(1)
		return
	_begin_manifest()
	if not _write_manifest():
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		_fail("capture requires a rendering display; do not use --headless")
		_finish()
		return
	if not await _mount_production_world():
		_finish()
		return

	var frame_index := 0
	for raw: Variant in SUBJECTS:
		var spec := raw as Dictionary
		var subject := _resolve_subject(spec)
		if subject == null:
			_fail("planned subject '%s' is missing" % str(spec.id))
			frame_index += TIMES.size() * VIEWS.size()
			continue
		var missing := _missing_required(subject, spec)
		if not missing.is_empty():
			_fail("%s is missing required production nodes: %s" % [spec.id, ", ".join(missing)])
			frame_index += TIMES.size() * VIEWS.size()
			continue
		var focus_nodes := _focus_nodes(subject, spec)
		var focus_box := _combined_world_aabb(focus_nodes)
		if focus_box == null or (focus_box as AABB).size.length_squared() < 0.01:
			_fail("%s has no measurable production visual bounds" % str(spec.id))
			frame_index += TIMES.size() * VIEWS.size()
			continue
		_manifest["subjects"].append(_subject_record(subject, spec, focus_nodes, focus_box as AABB))
		_write_manifest()
		for time_name: String in TIMES:
			await _pin_time(time_name)
			for view_name: String in VIEWS:
				frame_index += 1
				await _capture(frame_index, subject, spec, focus_nodes,
					focus_box as AABB, view_name, time_name)
	_finish()


func _mount_production_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	var packed := load(SCENE) as PackedScene
	if packed == null:
		_fail("could not load production Meadows scene")
		return false
	_world = packed.instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	var deadline := Time.get_ticks_msec() + READY_TIMEOUT_MS
	while _world.has_method("shell_build_complete") and not bool(_world.call("shell_build_complete")):
		if Time.get_ticks_msec() > deadline:
			_fail("production Meadows shell build timed out")
			return false
		await physics_frame
	for index in 30:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	_terrain = _world.get_node_or_null(^"Terrain")
	var rig := _world.get_node_or_null(^"CameraRig")
	if _player == null or _look == null or _terrain == null:
		_fail("production Player, WorldLook, or Terrain is missing")
		return false
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if _weather != null:
		if _weather.has_method("set_weather"):
			_weather.call("set_weather", "clear")
		_weather.set_process(false)
		_weather.set_physics_process(false)
	_hide_overlays()
	_camera = Camera3D.new()
	_camera.name = "MeadowsBannerEvidenceCamera"
	_camera.fov = 54.0
	_camera.far = 3000.0
	_world.add_child(_camera)
	_camera.make_current()
	if _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	return true


func _resolve_subject(spec: Dictionary) -> Node3D:
	var anchor := _world.get_node_or_null(spec.path) as Node3D
	if anchor == null:
		return null
	var find_name := str(spec.get("find_name", ""))
	if find_name == "":
		return anchor
	return anchor.find_child(find_name, true, false) as Node3D


func _missing_required(subject: Node3D, spec: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	for raw: Variant in spec.required:
		var path := raw as NodePath
		if path != NodePath(".") and subject.get_node_or_null(path) == null:
			missing.append(str(path))
	return missing


func _focus_nodes(subject: Node3D, spec: Dictionary) -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	for raw: Variant in spec.focus:
		var path := raw as NodePath
		var node := subject if path == NodePath(".") else subject.get_node_or_null(path) as Node3D
		if node != null:
			nodes.append(node)
	return nodes


func _capture(index: int, subject: Node3D, spec: Dictionary,
		focus_nodes: Array[Node3D], focus_box: AABB, view_name: String,
		time_name: String) -> void:
	var target := focus_box.get_center()
	var front := subject.global_basis.z.normalized()
	if str(spec.front_axis) == "x":
		front = subject.global_basis.x.normalized()
	front *= float(spec.front_sign)
	var side := Vector3.UP.cross(front).normalized() * float(spec.side_sign)
	var bearing := (front + side * (0.18 if view_name == "ordinary" else 0.48)).normalized()
	var span := maxf(focus_box.size.x, maxf(focus_box.size.y, focus_box.size.z))
	var distance := maxf(10.0, span * 3.2) if view_name == "ordinary" \
		else maxf(3.4, span * 1.35)
	var eye := target + bearing * distance
	eye.y += maxf(0.45, focus_box.size.y * (0.12 if view_name == "ordinary" else 0.04))
	var ground := float(_world.call("ground_height_at", eye.x, eye.z))
	if not is_nan(ground):
		eye.y = maxf(eye.y, ground + 1.8)
	_camera.global_position = eye
	_camera.look_at(target + Vector3.UP * focus_box.size.y * 0.02, Vector3.UP)
	if _terrain.has_method("set_camera"):
		_terrain.call("set_camera", _camera)
	_player.global_position = Vector3(eye.x, eye.y + 20.0, eye.z)
	_player.velocity = Vector3.ZERO
	for frame in 75:
		await physics_frame
	_hide_overlays()
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw

	var frame_name := "%02d-%s-%s-%s" % [index, str(spec.id), view_name, time_name]
	var problems := CAPTURE_CHECK.problems(self, _camera, "clear", subject, [_player])
	var readable_subjects: Array[Dictionary] = []
	for focus: Node3D in focus_nodes:
		var box_value := _combined_world_aabb([focus])
		if box_value != null:
			readable_subjects.append({"name": focus.name, "aabb": box_value as AABB})
	var readable_opts := {
		"min_height_frac": 0.025 if view_name == "ordinary" else 0.07,
		"min_inside_frac": 0.90,
		"max_height_frac": 0.86,
		"max_overlap_frac": 0.0,
	}
	problems.append_array(CAPTURE_CHECK.readable_problems_for_camera(
		_camera, readable_subjects, readable_opts))
	if not problems.is_empty():
		_fail("%s refused by capture checks: %s" % [frame_name, " | ".join(problems)])
		return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("%s returned no image" % frame_name)
		return
	var path := "%s/%s.png" % [_out_dir, frame_name]
	if image.save_png(path) != OK:
		_fail("%s could not save PNG" % frame_name)
		return
	var record := {
		"frame": frame_name,
		"subject_id": str(spec.id),
		"subject_path": str(_world.get_path_to(subject)),
		"time": time_name,
		"view": view_name,
		"camera_source": "diagnostic evidence camera; production subject unchanged",
		"camera_transform": _transform(_camera.global_transform),
		"camera_to_subject_m": _camera.global_position.distance_to(target),
		"focus_aabb": _aabb(focus_box),
		"capture_check": problems,
		"image_size": [image.get_width(), image.get_height()],
		"file_bytes": FileAccess.get_file_as_bytes(path).size(),
	}
	_records.append(record)
	_write_manifest()
	print("wrote %s" % path)


func _pin_time(time_name: String) -> void:
	_look.call("apply_time", time_name)
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_look.set_process(false)
	_look.set_physics_process(false)
	for frame in 8:
		await process_frame


func _subject_record(subject: Node3D, spec: Dictionary,
		focus_nodes: Array[Node3D], focus_box: AABB) -> Dictionary:
	var focus_paths: Array[String] = []
	for node: Node3D in focus_nodes:
		focus_paths.append(str(_world.get_path_to(node)))
	return {
		"id": str(spec.id),
		"label": str(spec.label),
		"resolved_path": str(_world.get_path_to(subject)),
		"production_source": str(spec.source),
		"focus_paths": focus_paths,
		"focus_aabb": _aabb(focus_box),
		"meshes": _mesh_records(subject),
	}


func _mesh_records(subject: Node3D) -> Array[Dictionary]:
	var meshes: Array[Node] = []
	if subject is MeshInstance3D:
		meshes.append(subject)
	meshes.append_array(subject.find_children("*", "MeshInstance3D", true, false))
	var result: Array[Dictionary] = []
	for raw: Node in meshes:
		var mesh_instance := raw as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var surfaces: Array[Dictionary] = []
		for surface in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.get_active_material(surface)
			surfaces.append({
				"index": surface,
				"material_class": material.get_class() if material != null else "",
				"material_name": material.resource_name if material != null else "",
				"material_path": material.resource_path if material != null else "",
			})
		result.append({
			"path": str(_world.get_path_to(mesh_instance)),
			"mesh_class": mesh_instance.mesh.get_class(),
			"mesh_path": mesh_instance.mesh.resource_path,
			"surfaces": surfaces,
		})
	return result


func _combined_world_aabb(nodes: Array) -> Variant:
	var combined: Variant = null
	for raw: Variant in nodes:
		var node := raw as Node3D
		if node == null:
			continue
		var box := _node_world_aabb(node)
		if box != null:
			combined = (combined as AABB).merge(box as AABB) if combined != null else box
	return combined


func _node_world_aabb(node: Node3D) -> Variant:
	var result: Variant = null
	if node is VisualInstance3D and node.is_visible_in_tree():
		result = node.global_transform * (node as VisualInstance3D).get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_box := _node_world_aabb(child as Node3D)
			if child_box != null:
				result = (result as AABB).merge(child_box as AABB) if result != null else child_box
	return result


func _hide_overlays() -> void:
	for raw: Node in _world.find_children("*", "CanvasLayer", true, false):
		(raw as CanvasLayer).visible = false


func _begin_manifest() -> void:
	_manifest = {
		"production_scene": SCENE,
		"output_directory": _out_dir,
		"owner_requirement": "OWNER-0912 Tier 2 #4 red flags / paper cutouts",
		"expected_frame_count": PLANNED_FRAMES.size(),
		"captured_frame_count": 0,
		"planned_frames": PLANNED_FRAMES.duplicate(),
		"planned_subjects": _planned_subjects(),
		"fixture_disclosure": "One unmodified production Meadows boot. Named authored banner nodes are photographed in place with a diagnostic camera at ordinary and close-oblique distances, clear weather, and production day/night presets. The tool resets the game to its ordinary new-game state, hides CanvasLayers, and redirects Terrain3D/GrassField streaming to the rendering camera. It never spawns, duplicates, retints, reposes, or reveals a banner subject.",
		"complete": false,
		"subjects": [],
		"frames": [],
		"failures": [],
	}


func _planned_subjects() -> Array[Dictionary]:
	var planned: Array[Dictionary] = []
	for raw: Variant in SUBJECTS:
		var spec := raw as Dictionary
		var required: Array[String] = []
		for path: NodePath in spec.required:
			required.append(str(path))
		planned.append({
			"id": str(spec.id),
			"label": str(spec.label),
			"anchor_path": str(spec.path),
			"descendant_name": str(spec.get("find_name", "")),
			"required": required,
			"production_source": str(spec.source),
		})
	return planned


func _finish() -> void:
	_manifest["captured_frame_count"] = _records.size()
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	_manifest["complete"] = _failures.is_empty() \
		and _records.size() == PLANNED_FRAMES.size() \
		and (_manifest.subjects as Array).size() == SUBJECTS.size()
	var manifest_written := _write_manifest()
	quit(0 if bool(_manifest.complete) and manifest_written else 1)


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)
	_manifest["failures"] = _failures
	_write_manifest()


func _write_manifest() -> bool:
	_manifest["captured_frame_count"] = _records.size()
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var file := FileAccess.open("%s/manifest.json" % _out_dir, FileAccess.WRITE)
	if file == null:
		push_error("could not write banner-treatment manifest")
		return false
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.close()
	return true


func _transform(value: Transform3D) -> Dictionary:
	return {
		"origin": _vec3(value.origin),
		"basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y),
		"basis_z": _vec3(value.basis.z),
	}


func _aabb(value: AABB) -> Dictionary:
	return {"position": _vec3(value.position), "size": _vec3(value.size)}


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
