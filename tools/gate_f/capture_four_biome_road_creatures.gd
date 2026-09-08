extends SceneTree

## Production-render evidence for the four-biome ROAD creature-presence lane.
##
## This tool never constructs a studio scene, substitute camera, or display-only
## creature. It loads each shipped biome scene one at a time, moves the shipped
## trainer to a deterministic stand on an authored critical road, keeps the real
## exploration camera and PlaygroundHUD, and photographs only bodies returned by
## the realm's production EncounterDirector.
##
## Run from a freshly imported checkout, without --headless:
##
##   godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 \
##     --resolution 1280x800 --script tools/gate_f/capture_four_biome_road_creatures.gd \
##     -- --out=res://shots/road-creatures
##
## `--only=meadows|cloudreach|stormwood|water` limits an iteration run. Output
## names are deliberately neutral (`b01_s01.png` etc.) so a coordinator can copy
## two revisions to anonymous A/B sets without filenames revealing the treatment.

const DEFAULT_OUT := "res://shots/road-creatures"
const REALM_ORDER: Array[String] = ["meadows", "cloudreach", "stormwood", "water"]
const EXPECTED_SIZE := Vector2i(1280, 800)
const BOOT_TIMEOUT_FRAMES := 7200
const BOOT_SETTLE_FRAMES := 90
const STAND_SETTLE_FRAMES := 120
const BODY_WAIT_FRAMES := 240
const POSE_FRAMES := 8
const STAND_BEHIND_ANCHOR_M := 24.0
const LOOK_BEYOND_ANCHOR_M := 34.0
const MAX_BODY_DISTANCE_M := 130.0
const CAMERA_PITCH_DEG := -10.0
const MIN_FILE_BYTES := 32768
const MIN_IMAGE_SPREAD := 0.025

const SCENES := {
	"meadows": "res://scenes/world/meadows_playground.tscn",
	"cloudreach": "res://scenes/world/cloudreach_cliffs.tscn",
	"stormwood": "res://scenes/world/stormwood.tscn",
	"water": "res://scenes/world/water_archipelago.tscn",
}

## These are route identities, not arbitrary world coordinates. `_authored_pose`
## resolves each fraction against the ROAD-authored pair sites, projects that site
## onto the named route, and walks back 24m along the route for the trainer stand.
## Thus a terrain rebake can alter Y without invalidating the stand's road identity.
const CAPTURES: Array[Dictionary] = [
	# The Creek contract moved order 1911 outside its compact footprint. Capture
	# the exact formerly-empty 730m sample and its population-neutral order-1912
	# replacement, rather than allowing the generic anchor midpoint to skip it.
	{"realm": "meadows", "slot": 1, "route": "band1_lower_meadows", "fraction": 1.0,
		"route_distance_m": 730.0,
		"anchors": "res://data/config/bands/band1_lower_meadows/spawns.json"},
	{"realm": "meadows", "slot": 2, "route": "band3_the_river_lock", "fraction": 0.50,
		"anchors": "res://data/config/bands/band3_the_river_lock/spawns.json"},
	{"realm": "meadows", "slot": 3, "route": "band4_upper_meadows_ironwood", "fraction": 0.68,
		"anchors": "res://data/config/bands/band4_upper_meadows_ironwood/spawns.json"},
	{"realm": "cloudreach", "slot": 1, "route": "arrival_gate_road", "fraction": 0.50},
	{"realm": "cloudreach", "slot": 2, "route": "windscar_floor_loop", "fraction": 0.50,
		"required_sites": ["road_visibility_windscar_floor_loop_07"]},
	{"realm": "cloudreach", "slot": 3, "route": "upper_summit_road", "fraction": 0.58},
	{"realm": "stormwood", "slot": 1, "route": "ash_road", "fraction": 0.50},
	{"realm": "stormwood", "slot": 2, "route": "conductor_road", "fraction": 0.50},
	{"realm": "stormwood", "slot": 3, "route": "deepwood_road", "fraction": 0.50},
	{"realm": "water", "slot": 1, "route": "tidal_cradle_exploration_spine", "fraction": 0.50,
		"required_sites": ["road_visibility_tidal_cradle_exploration_spine_04",
			"water_tidal_cradle_wild_005", "water_tidal_cradle_wild_013"]},
	{"realm": "water", "slot": 2, "route": "salt_crown_exploration_spine", "fraction": 0.50},
	{"realm": "water", "slot": 3, "route": "sluice_isle_exploration_spine", "fraction": 0.50},
]

var _out_dir := DEFAULT_OUT
var _only_realm := ""
var _game: Node = null
var _failures: Array[String] = []
var _records: Array[Dictionary] = []
var _tier_coverage := {"small": 0, "mid": 0, "large": 0}


func _init() -> void:
	_run()


func _run() -> void:
	_parse_args()
	if DisplayServer.get_name() == "headless":
		_failures.append("headless display server cannot produce production render evidence")
		_finish()
		return
	var method := RenderingServer.get_current_rendering_method()
	if method != "gl_compatibility":
		_failures.append("renderer is '%s', expected Compatibility/gl_compatibility" % method)
		_finish()
		return
	# A SceneTree script starts with a 100x100 root viewport even when the CLI
	# window-size flag is present. Set both the native window and render viewport
	# explicitly so evidence pixels and the camera projection are deterministic.
	DisplayServer.window_set_size(EXPECTED_SIZE)
	root.size = EXPECTED_SIZE
	await process_frame
	if root.size != EXPECTED_SIZE:
		_failures.append("viewport is %s, expected %s" % [root.size, EXPECTED_SIZE])
		_finish()
		return
	_game = root.get_node_or_null(^"Game")
	if _game == null:
		_failures.append("Game autoload is missing")
		_finish()
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	for realm: String in REALM_ORDER:
		if not _only_realm.is_empty() and realm != _only_realm:
			continue
		await _capture_realm(realm)
	await _write_manifest()
	_finish()


func _parse_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.substr("--out=".length()).trim_suffix("/")
			if not _out_dir.begins_with("res://"):
				_out_dir = "res://" + _out_dir
		elif arg.begins_with("--only="):
			_only_realm = arg.substr("--only=".length()).to_lower()
	if not _only_realm.is_empty() and not REALM_ORDER.has(_only_realm):
		_failures.append("unknown --only realm '%s'" % _only_realm)


func _capture_realm(realm: String) -> void:
	var plans: Array[Dictionary] = []
	for entry: Dictionary in CAPTURES:
		if str(entry.realm) == realm:
			var planned := _authored_pose(entry)
			if planned.is_empty():
				_failures.append("%s/%s: authored road pose could not be resolved" % [realm, entry.route])
			else:
				plans.append(planned)
	if plans.is_empty():
		return

	_prepare_game(realm)
	var packed := load(str(SCENES[realm])) as PackedScene
	if packed == null:
		_failures.append("%s: production scene did not load" % realm)
		return
	var world := packed.instantiate() as Node3D
	if world == null:
		_failures.append("%s: production scene did not instantiate as Node3D" % realm)
		return
	root.add_child(world)
	current_scene = world
	print("[road-capture] %s: loading %s" % [realm, SCENES[realm]])
	if not await _wait_for_runtime(world, plans[0].stand):
		_failures.append("%s: production world/EncounterDirector did not become ready" % realm)
		await _release_world(world)
		return
	for i in BOOT_SETTLE_FRAMES:
		await physics_frame

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as Node3D
	var camera := world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var director := world.get_node_or_null(^"EncounterDirector")
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if player == null or rig == null or camera == null or director == null:
		_failures.append("%s: Player, CameraRig, Camera3D or EncounterDirector missing" % realm)
		await _release_world(world)
		return
	if hud == null or not hud.visible:
		_failures.append("%s: production PlaygroundHUD is missing or hidden" % realm)

	_pin_daylight(world)
	for plan: Dictionary in plans:
		await _capture_stand(world, player, rig, camera, director, plan)
	await _release_world(world)


func _prepare_game(realm: String) -> void:
	_game.call("reset_for_new_game")
	_game.set("world_seed", 0)
	_game.set("current_realm", realm)
	var progression: RefCounted = _game.get("progression")
	if progression != null:
		var flags: Array[String] = [
			"realm_key_cloudreach", "realm_gate_cloudreach_unlocked",
			"cloudreach_chapter_started", "fly_traversal_unlocked",
			"cloudreach_upper_route_unlocked", "realm_key_stormwood",
			"realm_gate_stormwood_unlocked", "realm_key_water",
			"realm_gate_water_unlocked",
		]
		for flag: String in flags:
			progression.call("set_flag", flag)
	var party: RefCounted = _game.get("party")
	if party != null and (party.call("members") as Array).is_empty():
		var starter: RefCounted = _game.call("make_creature", "terrapup")
		if starter != null:
			party.call("add", starter)
	if _game.has_method("autofill_hotbar"):
		_game.call("autofill_hotbar")


func _wait_for_runtime(world: Node3D, stand: Vector3) -> bool:
	for i in BOOT_TIMEOUT_FRAMES:
		var director := world.get_node_or_null(^"EncounterDirector")
		var player := world.get_node_or_null(^"Player")
		var camera := world.get_node_or_null(^"CameraRig/Camera3D")
		if director != null and director.has_method("wild_creatures") \
				and player != null and camera != null:
			var height := _ground_height(world, stand)
			if is_finite(height):
				return true
		await physics_frame
	return false


func _capture_stand(world: Node3D, player: CharacterBody3D, rig: Node3D,
		camera: Camera3D, director: Node, plan: Dictionary) -> void:
	var stand: Vector3 = plan.stand
	var look: Vector3 = plan.look
	stand.y = _ground_height(world, stand) + 0.25
	look.y = _ground_height(world, look) + 1.8
	var authored_stand := stand
	var ahead := look - stand
	ahead.y = 0.0
	if ahead.length_squared() < 0.01:
		_failures.append("%s: zero-length authored road heading" % plan.file)
		return
	ahead = ahead.normalized()

	# This is a deterministic still, not simulated traversal between stands. The
	# production controller otherwise integrates the teleport as extreme velocity
	# and can trigger the real recovery volume, silently returning the trainer to
	# the preceding capture origin while the camera keeps the new route heading.
	player.set_physics_process(false)
	player.global_position = stand
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	var model := player.get_node_or_null(^"Model") as Node3D
	if model != null:
		model.rotation.y = atan2(ahead.x, ahead.z)
	if rig.has_method("set_target"):
		rig.call("set_target", player, {})
	var yaw := atan2(-ahead.x, -ahead.z)
	rig.set("yaw", yaw)
	rig.set("pitch", deg_to_rad(CAMERA_PITCH_DEG))
	rig.rotation = Vector3(deg_to_rad(CAMERA_PITCH_DEG), yaw, 0.0)
	for i in STAND_SETTLE_FRAMES:
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	var stand_drift := player.global_position.distance_to(authored_stand)
	if stand_drift > 0.5:
		_failures.append("%s: trainer drifted %.2fm from authored stand during capture settle" % [
			plan.file, stand_drift])

	var bodies: Array[Dictionary] = []
	for i in BODY_WAIT_FRAMES:
		bodies = _front_runtime_bodies(director, camera, player.global_position, ahead)
		if _framed_count(bodies) >= 2:
			break
		await physics_frame
	for i in POSE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var forward_count := bodies.size()
	var framed_count := _framed_count(bodies)
	var required_sites: Array[String] = []
	if str(plan.realm) in ["cloudreach", "water"]:
		required_sites.append(str(plan.anchor))
	for required: Variant in plan.get("required_sites", []):
		var required_id := str(required)
		if not required_sites.has(required_id):
			required_sites.append(required_id)
	var site_state := _required_site_state(director, required_sites)
	if forward_count < 2:
		_failures.append("%s: only %d runtime creature bodies in the forward 180 degrees" % [plan.file, forward_count])
	if framed_count < 2:
		_failures.append("%s: only %d forward runtime creature bodies inside the real camera frustum" % [plan.file, framed_count])
	for required_id: String in site_state.failed:
		_failures.append("%s: required runtime site failed footing: %s" % [plan.file, required_id])
	for required_id: String in site_state.missing:
		_failures.append("%s: required runtime site did not spawn: %s" % [plan.file, required_id])
	if not camera.is_position_in_frustum(player.global_position + Vector3.UP * 1.35):
		_failures.append("%s: trainer is not inside the real gameplay camera frustum" % plan.file)

	var image := root.get_texture().get_image()
	var validity := _save_validated_image(image, "%s/%s" % [_out_dir, plan.file])
	if not bool(validity.ok):
		_failures.append("%s: %s" % [plan.file, validity.reason])
	for body: Dictionary in bodies:
		var tier := str(body.tier)
		_tier_coverage[tier] = int(_tier_coverage.get(tier, 0)) + 1
	_records.append({
		"file": str(plan.file), "realm": str(plan.realm), "route": str(plan.route),
		"anchor": str(plan.anchor), "stand": _v3_array(player.global_position),
		"heading": _v3_array(ahead), "forward_runtime_bodies": forward_count,
		"framed_runtime_bodies": framed_count, "required_site_state": site_state,
		"bodies": bodies,
		"image": validity,
	})
	print("[road-capture] %-12s %-30s forward=%d framed=%d -> %s" % [
		plan.realm, plan.route, forward_count, framed_count, plan.file])


func _front_runtime_bodies(director: Node, camera: Camera3D, origin: Vector3,
		ahead: Vector3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not director.has_method("wild_creatures"):
		return result
	for value: Variant in director.call("wild_creatures"):
		var body := value as Node3D
		if body == null or not is_instance_valid(body) or not body.is_inside_tree() \
				or not body.visible:
			continue
		if body.has_method("is_alive") and not bool(body.call("is_alive")):
			continue
		var delta := body.global_position - origin
		delta.y = 0.0
		var distance := delta.length()
		if distance > MAX_BODY_DISTANCE_M or (distance > 0.05 and delta.dot(ahead) < 0.0):
			continue
		var height := _body_height(body)
		var sample := body.global_position + Vector3.UP * height * 0.52
		var framed := camera.is_position_in_frustum(sample) and not camera.is_position_behind(sample)
		result.append({
			"species": str(body.get("species_id")), "height_m": snappedf(height, 0.01),
			"tier": _height_tier(height), "distance_m": snappedf(distance, 0.1),
			"framed": framed, "position": _v3_array(body.global_position),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.distance_m) < float(b.distance_m))
	return result


func _framed_count(bodies: Array[Dictionary]) -> int:
	var count := 0
	for body: Dictionary in bodies:
		if bool(body.framed):
			count += 1
	return count


func _required_site_state(director: Node, required: Array[String]) -> Dictionary:
	var result := {"spawned": [], "failed": [], "missing": []}
	# Meadows and Stormwood do not expose the Cloudreach/Water site ledgers, and
	# their capture plans do not require them. Avoid casting the absent property.
	if required.is_empty():
		return result
	var spawned_value: Variant = director.get("_site_spawned")
	var failures_value: Variant = director.get("_site_failures")
	var spawned: Dictionary = spawned_value as Dictionary if spawned_value is Dictionary else {}
	var failures: Dictionary = failures_value as Dictionary if failures_value is Dictionary else {}
	for id: String in required:
		if failures.has(id):
			result.failed.append(id)
		elif spawned.has(id):
			result.spawned.append(id)
		else:
			result.missing.append(id)
	return result


func _body_height(body: Node3D) -> float:
	if body.has_method("body_height"):
		return maxf(0.1, float(body.call("body_height")))
	return 1.0


func _height_tier(height: float) -> String:
	if height < 2.8:
		return "small"
	if height < 4.8:
		return "mid"
	return "large"


func _save_validated_image(image: Image, path: String) -> Dictionary:
	if image == null:
		return {"ok": false, "reason": "viewport returned no image"}
	if image.get_size() != EXPECTED_SIZE:
		return {"ok": false, "reason": "image is %s, expected %s" % [image.get_size(), EXPECTED_SIZE]}
	var spread := _image_spread(image)
	if spread < MIN_IMAGE_SPREAD:
		return {"ok": false, "reason": "image is nearly flat (sampled spread %.4f)" % spread}
	var error := image.save_png(path)
	if error != OK:
		return {"ok": false, "reason": "save_png returned %d" % error}
	var bytes := FileAccess.get_file_as_bytes(path).size()
	if bytes < MIN_FILE_BYTES:
		return {"ok": false, "reason": "PNG is only %d bytes" % bytes}
	return {"ok": true, "width": image.get_width(), "height": image.get_height(),
		"bytes": bytes, "sampled_spread": snappedf(spread, 0.0001)}


func _image_spread(image: Image) -> float:
	var minimum := 1.0
	var maximum := 0.0
	for yi in 15:
		var y := mini(image.get_height() - 1, int((float(yi) + 0.5) * image.get_height() / 15.0))
		for xi in 24:
			var x := mini(image.get_width() - 1, int((float(xi) + 0.5) * image.get_width() / 24.0))
			var colour := image.get_pixel(x, y)
			var luma := colour.r * 0.2126 + colour.g * 0.7152 + colour.b * 0.0722
			minimum = minf(minimum, luma)
			maximum = maxf(maximum, luma)
	return maximum - minimum


func _pin_daylight(world: Node3D) -> void:
	var look := world.get_node_or_null(^"WorldLook")
	if look != null:
		if look.has_method("set_clock_frozen"):
			look.call("set_clock_frozen", true)
		if look.has_method("apply_time"):
			look.call("apply_time", "day")
	var weather := world.get_node_or_null(^"WorldWeather")
	if weather != null:
		if weather.has_method("set_weather"):
			weather.call("set_weather", "clear")
		weather.set_process(false)
		weather.set_physics_process(false)


func _release_world(world: Node3D) -> void:
	if current_scene == world:
		current_scene = null
	world.queue_free()
	await process_frame
	await process_frame


func _authored_pose(entry: Dictionary) -> Dictionary:
	var anchors := _road_anchors(entry)
	var points := _route_points(str(entry.realm), str(entry.route))
	if anchors.is_empty() or points.size() < 2:
		return {}
	var index := clampi(roundi(float(entry.fraction) * float(anchors.size() - 1)), 0, anchors.size() - 1)
	var anchor: Dictionary = anchors[index]
	var anchor_at := _array_to_v3(anchor.get("centre", anchor.get("position", [])))
	var projection := _project_to_route(anchor_at, points)
	if projection.is_empty():
		return {}
	var total := _route_length(points)
	var at_distance := float(projection.distance)
	var stand_distance := float(entry.get("route_distance_m",
		maxf(0.0, at_distance - STAND_BEHIND_ANCHOR_M)))
	var stand := _point_at_distance(points, clampf(stand_distance, 0.0, total))
	var look := _point_at_distance(points, minf(total, stand_distance + LOOK_BEYOND_ANCHOR_M))
	if Vector2(look.x - stand.x, look.z - stand.z).length() < 1.0:
		look = anchor_at
	var realm_index := REALM_ORDER.find(str(entry.realm)) + 1
	var filename := "b%02d_s%02d.png" % [realm_index, int(entry.slot)]
	return {
		"realm": str(entry.realm), "route": str(entry.route), "slot": int(entry.slot),
		"file": filename, "stand": stand, "look": look,
		"anchor": str(anchor.get("id", "order_%d" % int(anchor.get("order", -1)))),
		"required_sites": entry.get("required_sites", []).duplicate(),
	}


func _road_anchors(entry: Dictionary) -> Array[Dictionary]:
	var path := str(entry.get("anchors", ""))
	if path.is_empty():
		path = {
			"cloudreach": "res://data/config/cloudreach_encounters.json",
			"stormwood": "res://data/config/stormwood_encounters.json",
			"water": "res://data/config/water_encounters.json",
		}.get(str(entry.realm), "")
	var data := _read_json(path)
	var rows: Array = []
	if str(entry.realm) == "meadows":
		rows = data.get("spawns", [])
	elif str(entry.realm) == "stormwood":
		rows = data.get("wild_clusters", [])
	else:
		rows = data.get("wild_sites", [])
	var prefix := "road_visibility_%s_" % str(entry.route)
	var result: Array[Dictionary] = []
	for row: Dictionary in rows:
		if str(row.get("_why_road_visibility_0907", "")).is_empty():
			continue
		if str(entry.realm) != "meadows" and not str(row.get("id", "")).begins_with(prefix):
			continue
		result.append(row)
	return result


func _route_points(realm: String, route_id: String) -> Array[Vector3]:
	var path := ""
	var rows: Array = []
	var point_key := ""
	if realm == "meadows":
		path = "res://data/config/terrain_playground.json"
		rows = _read_json(path).get("trail", {}).get("bands", [])
		point_key = "points"
	elif realm == "cloudreach":
		path = "res://data/config/cloudreach_world.json"
		rows = _read_json(path).get("routes", [])
		point_key = "polyline"
	elif realm == "stormwood":
		path = "res://data/config/stormwood_world.json"
		rows = _read_json(path).get("routes", [])
		point_key = "points"
	elif realm == "water":
		path = "res://data/config/water_world.json"
		rows = _read_json(path).get("land_routes", [])
		point_key = "polyline"
	for row: Dictionary in rows:
		if str(row.get("id", "")) != route_id:
			continue
		var result: Array[Vector3] = []
		for raw: Variant in row.get(point_key, []):
			if raw is Array:
				result.append(_array_to_v3(raw as Array))
		return result
	return []


func _project_to_route(at: Vector3, points: Array[Vector3]) -> Dictionary:
	var best_distance := INF
	var best_along := 0.0
	var walked := 0.0
	var best_point := Vector3.ZERO
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var segment := Vector2(b.x - a.x, b.z - a.z)
		var length := segment.length()
		if length <= 0.001:
			continue
		var delta := Vector2(at.x - a.x, at.z - a.z)
		var t := clampf(delta.dot(segment) / segment.length_squared(), 0.0, 1.0)
		var point := a.lerp(b, t)
		var distance := Vector2(at.x - point.x, at.z - point.z).length()
		if distance < best_distance:
			best_distance = distance
			best_along = walked + length * t
			best_point = point
		walked += length
	return {} if not is_finite(best_distance) else {
		"distance": best_along, "point": best_point, "offset_m": best_distance}


func _route_length(points: Array[Vector3]) -> float:
	var total := 0.0
	for i in points.size() - 1:
		total += Vector2(points[i + 1].x - points[i].x, points[i + 1].z - points[i].z).length()
	return total


func _point_at_distance(points: Array[Vector3], distance: float) -> Vector3:
	var walked := 0.0
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		if length <= 0.001:
			continue
		if walked + length >= distance:
			return a.lerp(b, clampf((distance - walked) / length, 0.0, 1.0))
		walked += length
	return points[-1]


func _ground_height(world: Node3D, at: Vector3) -> float:
	if world.has_method("ground_height_at"):
		var height := float(world.call("ground_height_at", at.x, at.z))
		if is_finite(height):
			return height
	return at.y


func _array_to_v3(raw: Array) -> Vector3:
	if raw.size() >= 3:
		return Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	if raw.size() >= 2:
		return Vector3(float(raw[0]), 0.0, float(raw[1]))
	return Vector3.ZERO


func _v3_array(value: Vector3) -> Array[float]:
	return [snappedf(value.x, 0.001), snappedf(value.y, 0.001), snappedf(value.z, 0.001)]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failures.append("cannot open capture source %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		_failures.append("cannot parse capture source %s" % path)
		return {}
	return parsed as Dictionary


func _write_manifest() -> void:
	var path := "%s/capture-manifest.json" % _out_dir
	var payload := {
		"contract": "production scenes, real exploration camera/HUD, runtime wild bodies",
		"renderer": RenderingServer.get_current_rendering_method(),
		"display_server": DisplayServer.get_name(), "viewport": [root.size.x, root.size.y],
		"world_seed": 0, "forward_cone_degrees": 180,
		"minimum_forward_runtime_bodies": 2, "tier_coverage": _tier_coverage,
		"captures": _records, "failures": _failures,
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("could not open capture manifest for writing")
		return
	file.store_string(JSON.stringify(payload, "\t") + "\n")
	if file.get_error() != OK:
		_failures.append("capture manifest write failed")
	file.close()
	await process_frame


func _finish() -> void:
	print("")
	print("[road-capture] %d frame records; tier observations=%s" % [_records.size(), _tier_coverage])
	if not _failures.is_empty():
		for failure: String in _failures:
			print("FAIL: " + failure)
		quit(1)
		return
	print("[road-capture] PASS -> %s" % _out_dir)
	quit(0)
