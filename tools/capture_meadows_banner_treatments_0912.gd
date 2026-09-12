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
##     --output=res://ralph/reports/MEADOWS-0912/final-banner-treatments-05

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
		# The complete standard is 3.7 m tall. The generic 1.35x close
		# distance made it fill 94% of the frame, which is a prop close-up
		# rather than evidence of its treatment in the roadside scene.
		"close_distance_scale": 1.8,
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
		"close_distance_scale": 1.8,
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
		# This first production Hall banner hangs inside a bounded room. The
		# generic 3.2x ordinary stand crossed the opposite wall; use the same
		# proven oblique hemisphere as the valid close frame and let the
		# collision-aware seat search below find contextual room depth.
		"ordinary_side_weight": 0.48,
		"ordinary_distance_scale": 1.85,
		"minimum_horizontal_depth_m": 0.32,
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
		var focus_box: Variant = _combined_world_aabb(focus_nodes)
		if focus_box == null or (focus_box as AABB).size.length_squared() < 0.01:
			_fail("%s has no measurable production visual bounds" % str(spec.id))
			frame_index += TIMES.size() * VIEWS.size()
			continue
		var required_depth := float(spec.get("minimum_horizontal_depth_m", 0.0))
		var horizontal_depth := minf((focus_box as AABB).size.x, (focus_box as AABB).size.z)
		if required_depth > 0.0 and horizontal_depth < required_depth:
			_fail("%s production cloth depth %.3fm is below the required %.3fm" % [
				spec.id, horizontal_depth, required_depth])
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
	var readable_subjects := _readable_subjects(focus_nodes)
	var readable_opts := _readable_opts(view_name)
	var seat := _pose_clear_camera(subject, spec, focus_box, view_name,
		readable_subjects, readable_opts)
	if seat.is_empty():
		var no_seat_name := "%02d-%s-%s-%s" % [index, str(spec.id), view_name, time_name]
		_fail("%s has no ordinary collision-free camera seat that keeps the complete subject readable" % no_seat_name)
		return
	var eye := _camera.global_position
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
		"camera_seat": seat,
		"focus_aabb": _aabb(focus_box),
		"capture_check": problems,
		"image_size": [image.get_width(), image.get_height()],
		"file_bytes": FileAccess.get_file_as_bytes(path).size(),
	}
	_records.append(record)
	_write_manifest()
	print("wrote %s" % path)


## Associate each visual focus with its exact production collision ownership.
## `props.gd` deliberately builds imported-prop collision as a SIBLING named
## `<visual>_Collision`, not a child of the imported scene. Passing only the
## visible node therefore left Banner_1_Collision in every ray query and made
## a physically clear roadside standard look occluded from every candidate.
## Exclude that one generated sibling when present; other props, trees, walls,
## and rocks remain real occluders. Builders that parent collision beneath the
## subject (the Relay path) keep using the visible hierarchy itself.
func _readable_subjects(focus_nodes: Array[Node3D]) -> Array[Dictionary]:
	var readable: Array[Dictionary] = []
	for focus: Node3D in focus_nodes:
		var box_value: Variant = _combined_world_aabb([focus])
		if box_value != null:
			readable.append({
				"name": focus.name,
				"aabb": box_value as AABB,
				"body": _production_collision_owner(focus),
			})
	return readable


func _production_collision_owner(focus: Node3D) -> Node:
	var parent := focus.get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null(NodePath("%s_Collision" % focus.name))
		if sibling is CollisionObject3D:
			return sibling
	return focus


func _readable_opts(view_name: String) -> Dictionary:
	return {
		"min_height_frac": 0.025 if view_name == "ordinary" else 0.07,
		"min_inside_frac": 0.90,
		"max_height_frac": 0.86,
		"max_overlap_frac": 0.0,
	}


## Find a real camera seat rather than assuming a formula cannot cross a wall.
## Candidates stay in the authored subject's front hemisphere, at the requested
## ordinary/oblique distance band. A candidate is accepted only when the camera
## point is outside every production solid and the same readability/occlusion
## checks used at the shutter already pass. Nothing in the world is moved,
## hidden, disabled, or excluded except the subject's own collider hierarchy.
func _pose_clear_camera(subject: Node3D, spec: Dictionary, focus_box: AABB,
		view_name: String, readable_subjects: Array[Dictionary],
		readable_opts: Dictionary) -> Dictionary:
	var target := focus_box.get_center()
	var front := subject.global_basis.z.normalized()
	if str(spec.front_axis) == "x":
		front = subject.global_basis.x.normalized()
	front *= float(spec.front_sign)
	var side := Vector3.UP.cross(front).normalized() * float(spec.side_sign)
	var default_side := 0.18 if view_name == "ordinary" else 0.48
	var preferred_side := float(spec.get("%s_side_weight" % view_name, default_side))
	var default_scale := 3.2 if view_name == "ordinary" else 1.35
	var distance_scale := float(spec.get("%s_distance_scale" % view_name, default_scale))
	var span := maxf(focus_box.size.x, maxf(focus_box.size.y, focus_box.size.z))
	var base_distance := maxf(10.0, span * distance_scale) if view_name == "ordinary" \
		else maxf(3.4, span * distance_scale)
	var side_weights: Array[float] = [
		preferred_side,
		preferred_side * 0.5,
		0.0,
		preferred_side * 1.35,
		-preferred_side * 0.5,
	]
	var distance_factors: Array[float] = [1.0, 0.9, 1.1, 0.8, 1.2]
	var rejected: Array[String] = []
	for side_weight: float in side_weights:
		var bearing := (front + side * side_weight).normalized()
		for distance_factor: float in distance_factors:
			var distance := base_distance * distance_factor
			var eye := target + bearing * distance
			eye.y += maxf(0.45,
				focus_box.size.y * (0.12 if view_name == "ordinary" else 0.04))
			var ground := float(_world.call("ground_height_at", eye.x, eye.z))
			if not is_nan(ground):
				eye.y = maxf(eye.y, ground + 1.8)
			_camera.global_position = eye
			_camera.look_at(target + Vector3.UP * focus_box.size.y * 0.02, Vector3.UP)
			if _terrain.has_method("set_camera"):
				_terrain.call("set_camera", _camera)
			var embedded := _camera_solid_at(eye)
			if embedded != "":
				rejected.append("%.2f/%.2f inside %s" % [side_weight, distance, embedded])
				continue
			var frame_problems := CAPTURE_CHECK.readable_problems_for_camera(
				_camera, readable_subjects, readable_opts)
			if not frame_problems.is_empty():
				rejected.append("%.2f/%.2f: %s" % [
					side_weight, distance, " | ".join(frame_problems)])
				continue
			return {
				"collision_free": true,
				"side_weight": side_weight,
				"distance_m": distance,
				"candidate_rejections_before_accept": rejected.size(),
			}
	return {}


func _camera_solid_at(point: Vector3) -> String:
	var world := _camera.get_world_3d()
	if world == null or world.direct_space_state == null:
		return ""
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collide_with_areas = false
	query.collide_with_bodies = true
	for hit: Dictionary in world.direct_space_state.intersect_point(query, 16):
		var collider: Variant = hit.get("collider")
		if collider is Node and _is_player_body(collider as Node):
			continue
		return (collider as Node).name if collider is Node else "unnamed geometry"
	return ""


func _is_player_body(node: Node) -> bool:
	return node == _player or _player.is_ancestor_of(node) or node.is_ancestor_of(_player)


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
		var box: Variant = _node_world_aabb(node)
		if box != null:
			combined = (combined as AABB).merge(box as AABB) if combined != null else box
	return combined


func _node_world_aabb(node: Node3D) -> Variant:
	var result: Variant = null
	if node is VisualInstance3D and node.is_visible_in_tree():
		result = node.global_transform * (node as VisualInstance3D).get_aabb()
	for child: Node in node.get_children():
		if child is Node3D:
			var child_box: Variant = _node_world_aabb(child as Node3D)
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
