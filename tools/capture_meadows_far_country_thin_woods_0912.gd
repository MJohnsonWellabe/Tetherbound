extends SceneTree

## OWNER-0912 Tier 2 #9/#10: one production-world visual receipt for the
## post-Warden far-country silhouette and the two authored walkable thin-wood
## zones. The last pair is an established ordinary Band 2 corridor station,
## retained as the dense-woods control. Every view is clear-weather,
## ordinary-player-eye-height, and repeated at the production day/night keys.
##
## The tool never creates, moves, hides, retints, relights, or reposes scenery.
## It only sets the durable Warden flag before the production world boots,
## relocates the diagnostic eye/player, hides CanvasLayers, pins time/weather,
## and redirects the production terrain/grass/collision streams to that eye.
##
## Windows production command (Compatibility renderer; deliberately no
## `--headless`):
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/capture_meadows_far_country_thin_woods_0912.gd -- \
##     --output=res://ralph/reports/MEADOWS-0912/final-far-country-thin-woods-03

const SCENE := "res://scenes/world/meadows_playground.tscn"
const RIFT_CONFIG := "res://data/config/rift_collapse.json"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const B2_VEGETATION := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const B3_VEGETATION := "res://data/config/bands/band3_the_river_lock/vegetation.json"
const FRESH_OUTPUT := preload("res://tools/fresh_capture_output.gd")
const CAPTURE_CHECK := preload("res://tools/capture_check.gd")

const READY_TIMEOUT_MS := 420_000
const HORIZON_SETTLE_MARGIN_MS := 3_000
const IMAGE_SIZE := Vector2i(1280, 800)
const MIN_PNG_BYTES := 50_000
const EYE_HEIGHT_M := 1.70
const FOV_DEG := 70.0
const TIMES := ["day", "night"]
const FAR_FLAG := "legendary_freed"
const FAR_HOLDER := NodePath("RiftCollapse/FarCountry")

## The first two are resolved from their named production clearing records.
## Offsets remain inside each partial clearing and deliberately avoid the
## Warrens' nested, fully-open r30 mouth clearing. The control is the stable
## 07-band2-mid corridor station from tools/_capture_corridor.gd: it is an
## ordinary dense route segment, not a hand-built capture fixture.
const LANDSCAPE_VIEWS := [
	{
		"id": "warrens-thin-woods",
		"label": "Warrens walkable partial-clearing",
		"config": B2_VEGETATION,
		"clearing_id": "warrens_walkable_thin_wood",
		"eye_offset": Vector2(15.0, -28.0),
		"look_offset": Vector2(-20.0, 20.0),
		"sample_offset": Vector2(10.0, -12.0),
	},
	{
		"id": "stonewater-thin-woods",
		"label": "Stonewater walkable partial-clearing",
		"config": B3_VEGETATION,
		"clearing_id": "stonewater_walkable_thin_wood",
		"eye_offset": Vector2(-25.0, -30.0),
		"look_offset": Vector2(20.0, 30.0),
		"sample_offset": Vector2.ZERO,
	},
	{
		"id": "dense-woods-control",
		"label": "ordinary dense Band 2 corridor control",
		"source": "res://tools/_capture_corridor.gd#07-band2-mid",
		"eye": Vector2(20.0, 2130.0),
		"look": Vector2(-150.0, 2210.0),
		"sample": Vector2(-5.0, 2142.0),
	},
]

const PLANNED_FRAMES := [
	"01-post-warden-far-country-day",
	"02-post-warden-far-country-night",
	"03-warrens-thin-woods-day",
	"04-warrens-thin-woods-night",
	"05-stonewater-thin-woods-day",
	"06-stonewater-thin-woods-night",
	"07-dense-woods-control-day",
	"08-dense-woods-control-night",
]

var _out_dir := ""
var _world: Node3D = null
var _player: CharacterBody3D = null
var _camera: Camera3D = null
var _look: Node = null
var _weather: Node = null
var _terrain: Node = null
var _vegetation: Node = null
var _rift: Node3D = null
var _far_country: Node3D = null
var _records: Array[Dictionary] = []
var _failures: Array[String] = []
var _manifest: Dictionary = {}


func _init() -> void:
	_out_dir = FRESH_OUTPUT.requested(OS.get_cmdline_user_args())
	# SceneTree autoloads are attached after this script constructor returns.
	# Defer the production boot so /root/Game exists before the Warden state is
	# reset/set; calling `_run()` here produced final-01's immediate false fail.
	call_deferred("_run")


func _run() -> void:
	if not FRESH_OUTPUT.create_fresh(_out_dir, "Meadows far-country/thin-woods capture"):
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
	if not await _validate_far_country():
		_finish()
		return

	var landscapes := _resolve_landscape_views()
	if landscapes.size() != LANDSCAPE_VIEWS.size():
		_finish()
		return
	_manifest["landscapes"] = _json_safe(landscapes)
	_write_manifest()

	var frame_index := 0
	var seam_view := _far_country_view()
	if seam_view.is_empty():
		_fail("the storm-road seam view could not be resolved from production data")
		frame_index += TIMES.size()
	else:
		for time_name: String in TIMES:
			frame_index += 1
			await _capture(frame_index, "post-warden-far-country", time_name,
				(seam_view.eye as Vector2), (seam_view.look as Vector2), _far_country)

	for raw: Variant in landscapes:
		var view := raw as Dictionary
		for time_name: String in TIMES:
			frame_index += 1
			await _capture(frame_index, str(view.id), time_name,
				(view.eye as Vector2), (view.look as Vector2))
	_finish()


## The flag is set before instantiate/add_child so this remains a persisted
## post-Warden boot. The receipt then follows RiftCollapse's public horizon
## state whether the component snaps on build or observes startup via polling.
func _mount_production_world() -> bool:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		_fail("production Game autoload is missing")
		return false
	if game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
	var progression: Variant = game.get("progression")
	if progression == null or not (progression as Object).has_method("set_flag"):
		_fail("production progression store cannot set the Warden flag")
		return false
	(progression as Object).call("set_flag", FAR_FLAG, true)
	if not bool((progression as Object).call("has", FAR_FLAG)):
		_fail("the production Warden flag did not persist before world boot")
		return false

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
	for frame in 30:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_look = _world.get_node_or_null(^"WorldLook")
	_weather = _world.get_node_or_null(^"WorldWeather")
	_terrain = _world.get_node_or_null(^"Terrain")
	_vegetation = _world.get_node_or_null(^"Vegetation")
	_rift = _world.get_node_or_null(^"RiftCollapse") as Node3D
	_far_country = _world.get_node_or_null(FAR_HOLDER) as Node3D
	if _player == null or _look == null or _terrain == null or _vegetation == null \
			or _rift == null or _far_country == null:
		_fail("production Player/WorldLook/Terrain/Vegetation/RiftCollapse/FarCountry is missing")
		return false
	var rig := _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	if _weather != null:
		if _weather.has_method("set_weather"):
			_weather.call("set_weather", "clear")
		_weather.set_process(false)
		_weather.set_physics_process(false)
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	_player.velocity = Vector3.ZERO
	_hide_overlays()

	_camera = Camera3D.new()
	_camera.name = "MeadowsFarCountryThinWoodsEvidenceCamera"
	_camera.fov = FOV_DEG
	_camera.near = 0.1
	_camera.far = 3500.0
	_world.add_child(_camera)
	_camera.make_current()
	_redirect_streaming()
	return true


func _validate_far_country() -> bool:
	var game := root.get_node_or_null(^"Game")
	var progression: Variant = game.get("progression") if game != null else null
	if progression == null or not bool((progression as Object).call("has", FAR_FLAG)):
		_fail("the production Warden flag was lost while Meadows built")
		return false
	var settle := await _wait_for_post_warden_horizon()
	var horizon := settle.get("horizon", {}) as Dictionary
	if horizon.is_empty():
		return false
	if not bool(horizon.get("collapsed", false)) or float(horizon.get("far_cover", 0.0)) <= 0.0:
		_fail("post-Warden production horizon did not reveal FarCountry")
	if float(horizon.get("storm_cover", 1.0)) > 0.01:
		_fail("post-Warden production horizon still draws the StormWall")
	var meshes: Array[MeshInstance3D] = []
	for raw: Node in _far_country.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh != null and mesh.mesh != null:
			meshes.append(mesh)
	if meshes.size() != 5:
		_fail("FarCountry must contain four production ridges plus one glow; found %d meshes" % meshes.size())
	var runtime_layers: Array[Dictionary] = []
	var horizon_origin: Vector2 = horizon.get("origin", Vector2.ZERO) as Vector2
	for mesh: MeshInstance3D in meshes:
		if not mesh.is_visible_in_tree():
			_fail("FarCountry runtime layer '%s' is not visible after the production reveal" % mesh.name)
		var material := mesh.material_override as StandardMaterial3D
		if material == null:
			_fail("FarCountry runtime layer '%s' has no StandardMaterial3D override" % mesh.name)
			continue
		var alpha := material.albedo_color.a
		var distance := Vector2(mesh.global_position.x, mesh.global_position.z).distance_to(horizon_origin)
		if distance < 600.0:
			_fail("FarCountry runtime layer '%s' moved to looming distance %.1fm" % [mesh.name, distance])
		if material == null or alpha <= 0.0 or alpha > 0.5:
			_fail("FarCountry runtime layer '%s' has invalid atmospheric alpha %.3f" % [mesh.name, alpha])
		runtime_layers.append({"name": mesh.name, "distance_from_far_rim_m": distance,
			"material_alpha": alpha})
	for node: Node in _all_descendants(_far_country):
		if node is CollisionObject3D or node is CollisionShape3D \
				or node is NavigationRegion3D or node is NavigationLink3D \
				or node is NavigationObstacle3D:
			_fail("FarCountry contains gameplay geometry '%s'; the silhouette itself became enterable" % node.name)
		if node.has_method("interact"):
			_fail("FarCountry contains interactable '%s'; the silhouette itself became gameplay" % node.name)
	var cfg := _json(RIFT_CONFIG)
	var far := cfg.get("far_country", {}) as Dictionary
	var ridges := far.get("ridges", []) as Array
	if ridges.size() != 4:
		_fail("far-country source no longer has four layered ridges")
	for raw: Variant in ridges:
		var ridge := raw as Dictionary
		if float(ridge.get("distance", 0.0)) < 600.0 or float(ridge.get("alpha", 1.0)) > 0.5:
			_fail("far-country ridge escaped the distant/low-contrast source contract")
	var glow := far.get("glow", {}) as Dictionary
	if float(glow.get("distance", 0.0)) < 600.0 or float(glow.get("alpha", 1.0)) > 0.1:
		_fail("far-country glow escaped the distant/low-contrast source contract")
	_manifest["far_country"] = {
		"flag": FAR_FLAG,
		"flag_present_before_world_boot": true,
		"flag_present_after_world_boot": true,
		"runtime_path": str(_world.get_path_to(_far_country)),
		"mesh_count": meshes.size(),
		"runtime_layers": runtime_layers,
		"horizon": _json_safe(horizon),
		"production_transition_wait_ms": int(settle.get("elapsed_ms", 0)),
		"production_transition_budget_ms": int(settle.get("budget_ms", 0)),
		"source_config": RIFT_CONFIG,
		"presentation_only_runtime_scan": _failures.is_empty(),
		"separate_crossing_disclosure": "RiftCrossing is the separately authorised storm-road bridge/realm handoff. This receipt proves only that RiftCollapse/FarCountry remains non-enterable presentation geometry.",
	}
	_write_manifest()
	return _failures.is_empty()


## A flag set during startup can be observed by RiftCollapse's revision poll on
## its first process tick. That is still the production transition, and its
## authoritative `collapsed` bit turns true before either visual group has
## finished fading. Wait for the configured transition rather than calling the
## private snap method or changing visibility/materials from the harness.
func _wait_for_post_warden_horizon() -> Dictionary:
	var cfg := _json(RIFT_CONFIG)
	var collapse := cfg.get("collapse", {}) as Dictionary
	var hold := maxf(float(collapse.get("hold_seconds", 1.2)), 0.0)
	var dissipate := maxf(float(collapse.get("dissipate_seconds", 9.0)), 0.01)
	var reveal := maxf(float(collapse.get("reveal_seconds", 7.0)), 0.01)
	var reveal_delay := maxf(float(collapse.get("reveal_delay_seconds", 2.5)), 0.0)
	var budget_ms := ceili((hold + maxf(dissipate, reveal_delay + reveal)) * 1000.0) \
		+ HORIZON_SETTLE_MARGIN_MS
	var started_ms := Time.get_ticks_msec()
	var deadline_ms := started_ms + budget_ms
	var last_horizon: Dictionary = {}
	while Time.get_ticks_msec() <= deadline_ms:
		last_horizon = _rift.call("horizon") as Dictionary
		if bool(last_horizon.get("collapsed", false)) \
				and float(last_horizon.get("far_cover", 0.0)) > 0.0 \
				and float(last_horizon.get("storm_cover", 1.0)) <= 0.01:
			return {
				"horizon": last_horizon,
				"elapsed_ms": Time.get_ticks_msec() - started_ms,
				"budget_ms": budget_ms,
			}
		await process_frame
	_fail("post-Warden production horizon did not settle within %dms; last state: %s" \
		% [budget_ms, JSON.stringify(_json_safe(last_horizon))])
	return {}


func _resolve_landscape_views() -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	for raw: Variant in LANDSCAPE_VIEWS:
		var spec := raw as Dictionary
		if spec.has("clearing_id"):
			var clearing := _named_clearing(str(spec.config), str(spec.clearing_id))
			if clearing.is_empty():
				_fail("named production clearing '%s' is missing" % str(spec.clearing_id))
				continue
			var centre := Vector2(float(clearing.x), float(clearing.z))
			var radius := float(clearing.get("radius", 0.0))
			var eye := centre + (spec.eye_offset as Vector2)
			var look := centre + (spec.look_offset as Vector2)
			var sample := centre + (spec.sample_offset as Vector2)
			if radius <= 0.0 or eye.distance_to(centre) >= radius \
					or look.distance_to(centre) >= radius or sample.distance_to(centre) >= radius:
				_fail("%s evidence points escaped its authored partial-clearing radius" % str(spec.id))
				continue
			var retain := float(clearing.get("retain_fraction", -1.0))
			if retain <= 0.0 or retain >= 0.55:
				_fail("%s is no longer a partial thin-wood clearing" % str(spec.id))
				continue
			resolved.append({
				"id": str(spec.id), "label": str(spec.label), "eye": eye,
				"look": look, "sample": sample, "sample_radius_m": 24.0,
				"blocking_scatter_count": _blocking_scatter_within(sample, 24.0),
				"source_config": str(spec.config), "clearing_id": str(spec.clearing_id),
				"clearing_center": _vec2(centre), "clearing_radius_m": radius,
				"retain_fraction": retain,
			})
		else:
			var control_eye := spec.eye as Vector2
			var control_look := spec.look as Vector2
			var control_sample := spec.sample as Vector2
			if _inside_any_clearing(control_sample):
				_fail("dense control sample unexpectedly falls inside an authored clearing")
				continue
			resolved.append({
				"id": str(spec.id), "label": str(spec.label), "eye": control_eye,
				"look": control_look, "sample": control_sample, "sample_radius_m": 24.0,
				"blocking_scatter_count": _blocking_scatter_within(control_sample, 24.0),
				"source_config": str(spec.source), "clearing_id": "",
			})
	for entry: Dictionary in resolved:
		if int(entry.blocking_scatter_count) <= 0:
			_fail("%s has no live blocking scatter in its 24m evidence sample" % str(entry.id))
	return resolved


func _far_country_view() -> Dictionary:
	var terrain := _json(TERRAIN_CONFIG)
	var wanted := str(_json(RIFT_CONFIG).get("spoke", ""))
	for raw: Variant in (terrain.get("spokes", {}).get("routes", []) as Array):
		var spoke := raw as Dictionary
		if str(spoke.get("id", "")) != wanted:
			continue
		var road := spoke.get("road", []) as Array
		var far_road := spoke.get("far_road", {}) as Dictionary
		if road.size() < 2 or not far_road.has("to"):
			return {}
		var seam := _array_vec2(road[road.size() - 1])
		var far_rim := _array_vec2(far_road.to)
		var forward := (far_rim - seam).normalized()
		var far_box: Variant = _node_world_aabb(_far_country)
		if far_box == null:
			return {}
		var far_centre := (far_box as AABB).get_center()
		return {
			"eye": seam - forward * 55.0,
			"look": Vector2(far_centre.x, far_centre.z),
			"look_y": far_centre.y,
			"spoke": wanted,
			"seam": _vec2(seam),
			"far_rim": _vec2(far_rim),
		}
	return {}


func _capture(index: int, view_id: String, time_name: String, eye_xz: Vector2,
		look_xz: Vector2, subject: Node3D = null) -> void:
	await _pin_time(time_name)
	var look_y := NAN
	if subject == _far_country:
		var far_box: Variant = _node_world_aabb(_far_country)
		if far_box != null:
			look_y = (far_box as AABB).get_center().y
	var seat: Dictionary = await _pose_clear_eye(eye_xz, look_xz, look_y)
	var frame_name := "%02d-%s-%s" % [index, view_id, time_name]
	if seat.is_empty():
		_fail("%s has no collision-free ordinary-height camera seat" % frame_name)
		return
	_player.global_position = _camera.global_position + Vector3.UP * 20.0
	_player.velocity = Vector3.ZERO
	_redirect_streaming()
	for frame in 75:
		await physics_frame
	_hide_overlays()
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw

	var problems := CAPTURE_CHECK.problems(self, _camera, "clear", subject, [_player])
	var horizon_screen: Dictionary = {}
	if subject == _far_country:
		horizon_screen = _far_country_screen_metrics()
		if float(horizon_screen.get("max_mesh_height_fraction", 1.0)) > 0.28:
			problems.append("FarCountry exceeds 28% of frame height and reads as a looming wall")
		if int(horizon_screen.get("visible_mesh_centres", 0)) < 3:
			problems.append("fewer than three far-country layers place their centres in the frame")
	if not problems.is_empty():
		_fail("%s refused by capture checks: %s" % [frame_name, " | ".join(problems)])
		return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("%s returned no image" % frame_name)
		return
	if Vector2i(image.get_width(), image.get_height()) != IMAGE_SIZE:
		_fail("%s returned %dx%d, expected %dx%d" % [frame_name,
			image.get_width(), image.get_height(), IMAGE_SIZE.x, IMAGE_SIZE.y])
		return
	var path := "%s/%s.png" % [_out_dir, frame_name]
	if image.save_png(path) != OK:
		_fail("%s could not save PNG" % frame_name)
		return
	var bytes := FileAccess.get_file_as_bytes(path).size()
	if bytes < MIN_PNG_BYTES:
		_fail("%s PNG is implausibly small (%d bytes)" % [frame_name, bytes])
		return
	_records.append({
		"frame": frame_name,
		"view_id": view_id,
		"time": time_name,
		"eye_height_above_terrain_m": EYE_HEIGHT_M,
		"fov_deg": FOV_DEG,
		"camera_transform": _transform(_camera.global_transform),
		"camera_seat": seat,
		"look_xz": _vec2(look_xz),
		"subject_path": str(_world.get_path_to(subject)) if subject != null else "production landscape",
		"horizon_screen_metrics": horizon_screen,
		"capture_check": problems,
		"image_size": [image.get_width(), image.get_height()],
		"file_bytes": bytes,
	})
	_write_manifest()
	print("wrote %s" % path)


func _pose_clear_eye(nominal_eye: Vector2, look_xz: Vector2,
		target_y_override: float = NAN) -> Dictionary:
	var toward := (look_xz - nominal_eye).normalized()
	if toward.length_squared() < 0.5:
		return {}
	var side := Vector2(-toward.y, toward.x)
	for offset: Vector2 in [Vector2.ZERO, side * 1.5, side * -1.5,
			toward * 1.5, toward * -1.5, side * 3.0, side * -3.0]:
		var xz := nominal_eye + offset
		var ground := float(_world.call("ground_height_at", xz.x, xz.y))
		var target_y := target_y_override
		if is_nan(target_y):
			var target_ground := float(_world.call("ground_height_at", look_xz.x, look_xz.y))
			if not is_nan(target_ground):
				target_y = target_ground + 1.15
		if is_nan(ground) or is_nan(target_y):
			continue
		var eye := Vector3(xz.x, ground + EYE_HEIGHT_M, xz.y)
		_camera.global_position = eye
		_camera.look_at(Vector3(look_xz.x, target_y, look_xz.y), Vector3.UP)
		_redirect_streaming()
		# Both Terrain3D's dynamic body and Vegetation's collision bubble are
		# stream-owned. Let their server-side shapes catch up before accepting
		# the seat; a pre-stream point query can falsely call a tree hollow.
		for frame in 2:
			await physics_frame
		var embedded := _camera_solid_at(eye)
		if embedded == "":
			return {
				"collision_free": true,
				"nominal_eye_xz": _vec2(nominal_eye),
				"resolved_eye_xz": _vec2(xz),
				"lateral_or_forward_adjustment_m": offset.length(),
			}
	return {}


func _far_country_screen_metrics() -> Dictionary:
	var viewport_size := _camera.get_viewport().get_visible_rect().size
	var max_height_fraction := 0.0
	var visible_centres := 0
	var layers: Array[Dictionary] = []
	for raw: Node in _far_country.find_children("*", "MeshInstance3D", true, false):
		var mesh := raw as MeshInstance3D
		if mesh == null or not mesh.visible or mesh.mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		var centre := box.get_center()
		var top := centre + Vector3.UP * box.size.y * 0.5
		var bottom := centre - Vector3.UP * box.size.y * 0.5
		if _camera.is_position_behind(centre):
			continue
		var screen := _camera.unproject_position(centre)
		var height_fraction := absf(_camera.unproject_position(top).y \
			- _camera.unproject_position(bottom).y) / maxf(viewport_size.y, 1.0)
		max_height_fraction = maxf(max_height_fraction, height_fraction)
		var centre_in_frame := Rect2(Vector2.ZERO, viewport_size).has_point(screen)
		visible_centres += 1 if centre_in_frame else 0
		layers.append({
			"name": mesh.name,
			"camera_distance_m": _camera.global_position.distance_to(centre),
			"screen_height_fraction": height_fraction,
			"centre_in_frame": centre_in_frame,
		})
	return {
		"max_mesh_height_fraction": max_height_fraction,
		"visible_mesh_centres": visible_centres,
		"layers": layers,
	}


func _blocking_scatter_within(centre: Vector2, radius: float) -> int:
	var batches: Variant = _vegetation.get("_collision_batches")
	if not batches is Array:
		return 0
	var count := 0
	var radius_sq := radius * radius
	for raw: Variant in (batches as Array):
		var batch := raw as Dictionary
		for placement: Dictionary in (batch.get("placements", []) as Array):
			var spot := placement.get("position", Vector3.ZERO) as Vector3
			if Vector2(spot.x, spot.z).distance_squared_to(centre) <= radius_sq:
				count += 1
	return count


func _inside_any_clearing(point: Vector2) -> bool:
	for path: String in [B2_VEGETATION, B3_VEGETATION]:
		for raw: Variant in (_json(path).get("clearings", []) as Array):
			var clearing := raw as Dictionary
			var centre := Vector2(float(clearing.get("x", INF)), float(clearing.get("z", INF)))
			if point.distance_to(centre) < float(clearing.get("radius", 0.0)):
				return true
	return false


func _named_clearing(path: String, id: String) -> Dictionary:
	for raw: Variant in (_json(path).get("clearings", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func _redirect_streaming() -> void:
	if _terrain != null and _terrain.has_method("set_camera") and _camera != null:
		_terrain.call("set_camera", _camera)
	if _vegetation != null and _vegetation.has_method("update_collision_streaming") \
			and _camera != null:
		_vegetation.call("update_collision_streaming", _camera.global_position)


func _camera_solid_at(point: Vector3) -> String:
	var world := _camera.get_world_3d()
	if world == null or world.direct_space_state == null:
		return "no physics world"
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


func _hide_overlays() -> void:
	for raw: Node in _world.find_children("*", "CanvasLayer", true, false):
		(raw as CanvasLayer).visible = false


func _all_descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child: Node in node.get_children():
		result.append(child)
		result.append_array(_all_descendants(child))
	return result


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


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("required production source is missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_fail("required production source does not parse: %s" % path)
		return {}
	return parsed as Dictionary


func _begin_manifest() -> void:
	_manifest = {
		"production_scene": SCENE,
		"output_directory": _out_dir,
		"owner_requirements": [
			"OWNER-0912 Tier 2 #9 distant, low-contrast, non-enterable far-country silhouette",
			"OWNER-0912 Tier 2 #10 walkable thin woods at Warrens and Stonewater, contrasted with dense woods",
		],
		"expected_frame_count": PLANNED_FRAMES.size(),
		"captured_frame_count": 0,
		"planned_frames": PLANNED_FRAMES.duplicate(),
		"fixture_disclosure": "One production Meadows boot in persisted post-Warden state. Production terrain, scatter, RiftCollapse geometry, WorldLook day/night presets, and clear weather are unchanged. A 70-degree diagnostic camera stands 1.70m above production terrain; CanvasLayers are hidden and the disabled production player is parked out of frame. No scenery, light, material, pose, visibility, collision, or navigation is created or modified.",
		"complete": false,
		"far_country": {},
		"landscapes": [],
		"frames": [],
		"failures": [],
	}


func _finish() -> void:
	_manifest["captured_frame_count"] = _records.size()
	_manifest["frames"] = _records
	_manifest["failures"] = _failures
	var actual_names: Array[String] = []
	for record: Dictionary in _records:
		actual_names.append(str(record.frame))
	_manifest["complete"] = _failures.is_empty() \
		and _records.size() == PLANNED_FRAMES.size() \
		and actual_names == PLANNED_FRAMES \
		and (_manifest.landscapes as Array).size() == LANDSCAPE_VIEWS.size() \
		and not (_manifest.far_country as Dictionary).is_empty()
	var written := _write_manifest()
	quit(0 if bool(_manifest.complete) and written else 1)


func _fail(message: String) -> void:
	if not message in _failures:
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
		push_error("could not write far-country/thin-woods manifest")
		return false
	file.store_string(JSON.stringify(_manifest, "\t") + "\n")
	file.close()
	return true


func _json_safe(value: Variant) -> Variant:
	if value is Vector2:
		return _vec2(value as Vector2)
	if value is Vector3:
		return _vec3(value as Vector3)
	if value is Dictionary:
		var result_dict: Dictionary = {}
		for key: Variant in (value as Dictionary).keys():
			result_dict[str(key)] = _json_safe((value as Dictionary)[key])
		return result_dict
	if value is Array:
		var result_array: Array = []
		for item: Variant in (value as Array):
			result_array.append(_json_safe(item))
		return result_array
	return value


func _transform(value: Transform3D) -> Dictionary:
	return {
		"origin": _vec3(value.origin),
		"basis_x": _vec3(value.basis.x),
		"basis_y": _vec3(value.basis.y),
		"basis_z": _vec3(value.basis.z),
	}


func _array_vec2(raw: Variant) -> Vector2:
	var values := raw as Array
	return Vector2(float(values[0]), float(values[1])) if values.size() >= 2 else Vector2.ZERO


func _vec2(value: Vector2) -> Array[float]:
	return [value.x, value.y]


func _vec3(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]
