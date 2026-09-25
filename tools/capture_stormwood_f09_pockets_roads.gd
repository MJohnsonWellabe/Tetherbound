extends "res://tools/catalogue_survey.gd"

## Player-camera evidence for Stormwood F09 (WO-F09-01): the five walled
## dead-end pockets, the rerouted Rootgate legs, the new dynamo_west_approach
## road and the re-planted forest scatter.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_f09_pockets_roads.gd -- \
##     --out=res://ralph/reports/STORMWOOD-PROGRESS/visual/f09/after \
##     [--label=after] [--only=rootgate,pockets,spurs,dynamo,forest] [--pockets=id,id]
##     [--frames=pocket_verge_ash_hollow_a_approach,dynamo_west_mid,...]
##
## --frames keeps only the named frame ids (their stands are skipped too).
##
## Groups: rootgate (conductor_road south of the gate, closed and then open;
## deepwood_road north of it), pockets (per pocket: approach 30 m outside the
## mouth, standing in the mouth, close to the reward with its prompt, and the
## outside of the side wall), dynamo (dynamo_west_approach mid-road and
## arriving at Ember Bivouac), spurs (WO-F09-03, per pocket: on its joined
## road 18 m before the spur junction, facing 30 m up the spur so the junction
## lamp and the lane are in frame; plus one mid-spur frame facing the mouth,
## for the first pocket kept), forest (ash_road near (-590,1060), ash_road
## through Glowmoss Hollows, and the earlier matrix_forest_day stand).
##
## Camera: always the production CameraRig/Camera3D following the real Player,
## placed as tools/capture_stormwood_lane_evidence.gd does: one
## Game.debug_teleport_to, a Player transform at the stand point facing the
## subject, then the rig is given target/yaw/pitch and settles on its own.
## No free camera, no survey stand.
##
## State: the day clock is pinned to "day" and the Surge clock is re-pinned to
## Calm (elapsed 60 s) right before every frame. The HUD stays visible. The
## rootgate group takes its first frame with no flag, then sets
## `stormwood:rootgate_released`; every later frame carries that staged flag
## (the north pockets, Deepwood and Dynamo are behind the Rootgate).
## Engine.max_physics_steps_per_frame is raised during waits so game time
## keeps pace under software GL (ticks stay 1/60 s); a minimum number of
## rendered frames is still waited at every stand so streaming catches up.
## Everything staged is written per frame to frames_<label>.json.
##
## Stand coordinates are literals (pocket stands are derived from
## data/config/stormwood_pockets.json), so the same tool frames the same
## spots on a checkout without F09 ("before" frames: run without the pockets
## group).

const FRAME_W := 1280
const FRAME_H := 720
const SETTLE_TICKS := 90
const SETTLE_RENDERS := 10
const BANNER_MAX_TICKS := 900
const CALM_PIN_SECONDS := 60.0
const COARSE_STEPS := 20
const POCKETS_PATH := "res://data/config/stormwood_pockets.json"
const PICKUPS_PATH := "res://data/config/stormwood_pickups.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const POCKET_FRAME := preload("res://scripts/world/stormwood_pocket_frame.gd")
## Spur stands: metres back along the road from the junction, and how far up
## the spur the camera looks.
const SPUR_ROAD_BACK_M := 18.0
const SPUR_LOOK_UP_M := 30.0
const SCATTER_BAKE := preload("res://scripts/world/scatter_bake.gd")
const SCATTER_PATH := "res://scripts/world/stormwood_scatter.gd"
## Mouth/approach distances, measured from the pocket centre along its mouth.
const APPROACH_OUT_M := 30.0
const SIDE_OUT_M := 7.0
const REWARD_BACK_M := 2.0

var _label := "after"
var _only: Array[String] = []
var _pocket_filter: Array[String] = []
var _frame_filter: Array[String] = []
var _game: Node
var _arbiter: Node
var _surge: Node
var _frames: Array[Dictionary] = []
var _staged_flags: Array[String] = []
var _t0 := 0
var _scatter_fresh := false


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("f09 capture requires a rendering display; never use --headless")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_output_dir = "res://ralph/reports/STORMWOOD-PROGRESS/visual/f09/after"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--label="):
			_label = arg.trim_prefix("--label=")
		elif arg.begins_with("--only="):
			for part: String in arg.trim_prefix("--only=").split(",", false):
				_only.append(part.strip_edges())
		elif arg.begins_with("--pockets="):
			for part: String in arg.trim_prefix("--pockets=").split(",", false):
				_pocket_filter.append(part.strip_edges())
		elif arg.begins_with("--frames="):
			for part: String in arg.trim_prefix("--frames=").split(",", false):
				_frame_filter.append(part.strip_edges())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	_scatter_fresh = _scatter_bake_fresh()
	_log("scatter bake fresh for this checkout: %s" % str(_scatter_fresh))
	if not _scatter_fresh:
		_failures.append("stormwood scatter bake is stale for this checkout; forest frames would be empty")
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	_game = root.get_node(^"Game")
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_log("world mounted; pockets node present: %s" % str(_world.get_node_or_null(^"StormwoodPockets") != null))
	# Rootgate first: its first frame is the only one without a staged flag.
	if _want("rootgate"):
		await _rootgate()
	_flag("stormwood:rootgate_released")
	if _want("pockets"):
		await _pockets()
	if _want("spurs"):
		await _spurs()
	if _want("dynamo"):
		await _dynamo()
	if _want("forest"):
		await _forest()
	_done()


func _want(group: String) -> bool:
	return _only.is_empty() or _only.has(group)


func _keep(frame_id: String) -> bool:
	return _frame_filter.is_empty() or _frame_filter.has(frame_id)


func _log(text: String) -> void:
	print("F09 CAPTURE [%6.1fs] %s" % [(Time.get_ticks_msec() - _t0) / 1000.0, text])


func _done() -> void:
	var file := FileAccess.open("%s/frames_%s.json" % [_output_dir, _label], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"label": _label, "scatter_bake_fresh": _scatter_fresh,
			"frames": _frames, "failures": _failures}, "\t") + "\n")
		file.close()
	for failure: String in _failures:
		push_error("f09 capture: " + failure)
	_log("DONE %d frames, %d failures" % [_frames.size(), _failures.size()])
	quit(0 if _failures.is_empty() else 1)


func _scatter_bake_fresh() -> bool:
	var scatter: GDScript = load(SCATTER_PATH)
	var cfg: Dictionary = scatter.call("config")
	return SCATTER_BAKE.is_fresh("stormwood", int(cfg.get("seed", 1)), int(scatter.call("fingerprint")))


# ---------------------------------------------------------------- staging

func _flag(id: String) -> void:
	var flags: RefCounted = _game.get("progression")
	if not bool(flags.call("has", id)):
		flags.call("set_flag", id, true)
	if not _staged_flags.has(id):
		_staged_flags.append(id)


func _set_surge_elapsed(seconds: float) -> void:
	var environment: Dictionary = _game.get("realm_environment")
	var storm: Dictionary = (environment.get("stormwood", {}) as Dictionary).duplicate(true)
	storm["elapsed"] = seconds
	storm["schema_version"] = 1
	environment["stormwood"] = storm
	_game.set("realm_environment", environment)


func _surge_elapsed() -> float:
	var environment: Dictionary = _game.get("realm_environment")
	return float((environment.get("stormwood", {}) as Dictionary).get("elapsed", 0.0))


func _day_calm() -> void:
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", false)
	_look.call("apply_time", "day")
	if _look.has_method("set_clock_frozen"):
		_look.call("set_clock_frozen", true)
	_set_surge_elapsed(CALM_PIN_SECONDS)


func _ground(x: float, z: float) -> float:
	return float(_world.call("ground_height_at", x, z))


# ---------------------------------------------------------------- placement

func _floor_at(x: float, z: float) -> float:
	var terrain := _ground(x, z)
	var top := terrain + 4.0
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, top - 400.0, z), 1)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		return float((hit.position as Vector3).y)
	return resolve_capture_ground(_player, x, z, terrain)


## Stand the real trainer at `xz` facing `look_at` and let the production rig
## settle behind them (tools/capture_stormwood_lane_evidence.gd::_stand).
func _stand(xz: Vector2, look_at: Vector3, pitch_deg: float, yaw_offset_deg: float = 0.0) -> void:
	_day_calm()
	Engine.max_physics_steps_per_frame = COARSE_STEPS
	var moved := bool(_game.call("debug_teleport_to", xz.x, xz.y, "stormwood", ""))
	if not moved:
		_failures.append("debug_teleport_to refused %s" % str(xz))
	for _frame in 10:
		await physics_frame
	var ground := _floor_at(xz.x, xz.y)
	var forward := Vector2(look_at.x - xz.x, look_at.z - xz.y).normalized()
	_player.global_position = Vector3(xz.x, ground + TRAINER_CLEARANCE, xz.y)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = atan2(forward.x, forward.y)
	_rig.call("set_target", _player)
	var yaw := capture_yaw(forward) + deg_to_rad(yaw_offset_deg)
	var pitch := deg_to_rad(pitch_deg)
	_rig.set("yaw", yaw)
	_rig.set("pitch", pitch)
	_rig.rotation = Vector3(pitch, yaw, 0.0)
	_rig.global_position = _player.global_position
	_camera.make_current()
	_player.reset_physics_interpolation()
	_rig.reset_physics_interpolation()
	_camera.reset_physics_interpolation()
	for _frame in SETTLE_TICKS:
		await physics_frame
	for _frame in SETTLE_RENDERS:
		await process_frame
	var banner := _world.find_child("RegionBanner", true, false) as CanvasItem
	var waited := 0
	while banner != null and banner.visible and waited < BANNER_MAX_TICKS:
		await physics_frame
		waited += 1
	Engine.max_physics_steps_per_frame = 8
	_set_surge_elapsed(CALM_PIN_SECONDS)
	for _frame in 2:
		await process_frame


func _capture(frame_id: String, description: String, extra: Dictionary = {}) -> void:
	for _frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_failures.append("%s: empty viewport image" % frame_id)
		return
	if image.get_width() != FRAME_W or image.get_height() != FRAME_H:
		image.resize(FRAME_W, FRAME_H, Image.INTERPOLATE_LANCZOS)
	var path := "%s/%s.jpg" % [_output_dir, frame_id]
	if image.save_jpg(ProjectSettings.globalize_path(path), 0.8) != OK:
		_failures.append("%s: save_jpg failed" % frame_id)
		return
	var combat := _world.get_node_or_null(^"CombatManager")
	var record := {
		"id": frame_id, "file": path.get_file(), "label": _label, "description": description,
		"camera": "player camera (production CameraRig/Camera3D)",
		"player": _vec3(_player.global_position), "camera_pos": _vec3(_camera.global_position),
		"camera_player_m": _camera.global_position.distance_to(_player.global_position),
		"prompt": str(_arbiter.call("prompt")) if _arbiter != null else "",
		"surge_phase": str(_surge.get("phase")) if _surge != null else "",
		"surge_elapsed": _surge_elapsed(),
		"time_of_day": str(_look.call("time_of_day")) if _look.has_method("time_of_day") else "",
		"in_fight": combat != null and combat.has_method("is_fighting") and bool(combat.call("is_fighting")),
		"staged": {"flags": _staged_flags.duplicate(), "clock": "day pinned; surge elapsed re-pinned to %d s (Calm) before the frame" % int(CALM_PIN_SECONDS),
			"placement": "debug_teleport_to + Player transform at stand point"},
	}
	record.merge(extra, true)
	_frames.append(record)
	_log("captured %s prompt='%s' phase=%s cam=%.1fm" % [frame_id, record.prompt, record.surge_phase,
		record.camera_player_m])


# ---------------------------------------------------------------- 2. Rootgate

func _rootgate() -> void:
	var gate := Vector2(-650.0, 3550.0)
	var gate_focus := Vector3(gate.x, _ground(gate.x, gate.y) + 8.0, gate.y)
	var south := Vector2(-650.0, 3420.0)
	var north := Vector2(-650.0, 3680.0)
	await _stand(south, gate_focus, 4.0)
	await _capture("rootgate_south_closed", "conductor_road at (-650,3420) looking north to the Rootgate, gate closed (no flag)",
		{"gate_visible": _gate_visible()})
	_flag("stormwood:rootgate_released")
	for _frame in 30:
		await physics_frame
	await _stand(south, gate_focus, 4.0)
	await _capture("rootgate_south_open", "conductor_road at (-650,3420) looking north through the released Rootgate",
		{"gate_visible": _gate_visible()})
	await _stand(north, gate_focus, 2.0)
	await _capture("rootgate_north_open", "deepwood_road at (-650,3680) looking south to the released Rootgate",
		{"gate_visible": _gate_visible()})


func _gate_visible() -> bool:
	var gate := _world.get_node_or_null(^"Rootgate") as Node3D
	return gate != null and gate.visible


# ---------------------------------------------------------------- 1. Pockets

func _pockets() -> void:
	if not FileAccess.file_exists(POCKETS_PATH):
		_failures.append("no pockets config on this checkout")
		return
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POCKETS_PATH))
	var rewards := _pocket_rewards()
	var half := float(cfg.interior_half_m)
	var thick := float(cfg.wall_thickness_m)
	var wall_mid := half + thick * 0.5
	for pocket: Dictionary in cfg.pockets:
		var id := str(pocket.id)
		if not _pocket_filter.is_empty() and not _pocket_filter.has(id):
			continue
		var f := POCKET_FRAME.frame(pocket)
		var forward: Vector2 = f.forward
		var right: Vector2 = f.right
		var centre: Vector2 = f.centre
		var mouth := centre + forward * wall_mid
		var mouth_focus := Vector3(mouth.x, _ground(mouth.x, mouth.y) + 2.0, mouth.y)
		var centre_focus := Vector3(centre.x, _ground(centre.x, centre.y) + 1.0, centre.y)
		var reward_id := str(pocket.get("reward_pickup_id", ""))
		var reward_at: Vector3 = rewards.get(reward_id, centre_focus)
		var info := {"pocket": id, "pocket_centre": [centre.x, centre.y],
			"mouth_centre": [mouth.x, mouth.y], "mouth_yaw_deg": float(pocket.mouth_yaw_deg),
			"reward_pickup_id": reward_id, "reward_config_pos": _vec3(reward_at),
			"pockets_node_present": _world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s" % id)) != null}
		# (a) road-side approach, 30 m outside the mouth.
		var approach := centre + forward * (wall_mid + APPROACH_OUT_M)
		if _keep("pocket_%s_a_approach" % id):
			await _stand(approach, mouth_focus, -6.0)
			await _capture("pocket_%s_a_approach" % id, "%s: 30 m outside the mouth on the road side, facing the mouth" % id,
				_with(info, {"stand": [approach.x, approach.y], "reward_node": _reward_state(reward_id)}))
		# (b) standing in the mouth, looking in.
		if _keep("pocket_%s_b_mouth" % id):
			await _stand(mouth, centre_focus, -12.0)
			await _capture("pocket_%s_b_mouth" % id, "%s: standing in the mouth, looking in at the reward" % id,
				_with(info, {"stand": [mouth.x, mouth.y], "reward_node": _reward_state(reward_id),
					"player_to_reward_m": Vector2(reward_at.x, reward_at.z).distance_to(mouth)}))
		# (b2) close to the reward, so its 2.4 m prompt is in range.
		var toward_mouth := (mouth - Vector2(reward_at.x, reward_at.z)).normalized()
		var close := Vector2(reward_at.x, reward_at.z) + toward_mouth * REWARD_BACK_M
		if _keep("pocket_%s_b2_reward" % id):
			await _stand(close, reward_at, -16.0, 24.0)
			await _capture("pocket_%s_b2_reward" % id, "%s: 2 m from the moved reward, facing it (prompt range 2.4 m)" % id,
				_with(info, {"stand": [close.x, close.y], "reward_node": _reward_state(reward_id)}))
		# (c) outside the right side wall, facing the pocket centre.
		var side := centre + right * (wall_mid + thick * 0.5 + SIDE_OUT_M)
		if _keep("pocket_%s_c_side_wall" % id):
			await _stand(side, centre_focus, -4.0)
			await _capture("pocket_%s_c_side_wall" % id, "%s: outside the side wall, %d m from its outer face, facing the pocket centre" % [id, int(SIDE_OUT_M)],
				_with(info, {"stand": [side.x, side.y]}))


# ---------------------------------------------------------------- 1b. Spurs

func _spurs() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POCKETS_PATH))
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH))
	var roads := {}
	var spurs := {}
	for route: Dictionary in world.routes:
		if str(route.get("kind", "")) == "spur":
			spurs[str(route.get("pocket_id", ""))] = route
		else:
			roads[str(route.id)] = route
	var mid_done := false
	for pocket: Dictionary in cfg.pockets:
		var id := str(pocket.id)
		if not _pocket_filter.is_empty() and not _pocket_filter.has(id):
			continue
		var spur: Dictionary = spurs.get(id, {})
		if spur.is_empty():
			_failures.append("%s has no spur route on this checkout" % id)
			continue
		var points: Array = spur.points
		var junction := Vector2(float(points[0][0]), float(points[0][1]))
		var end := Vector2(float(points[points.size() - 1][0]), float(points[points.size() - 1][1]))
		var up := (Vector2(float(points[1][0]), float(points[1][1])) - junction).normalized()
		var along := _road_direction(roads.get(str(spur.joins), {}), junction)
		var stand := junction - along * SPUR_ROAD_BACK_M
		var look := junction + up * SPUR_LOOK_UP_M
		var info := {"pocket": id, "spur": str(spur.id), "joins": str(spur.joins),
			"junction": [junction.x, junction.y], "spur_length_m": junction.distance_to(end),
			"spur_lamp_present": _world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s/SpurLamp" % id)) != null}
		if _keep("spur_%s_junction" % id):
			await _stand(stand, Vector3(look.x, _ground(look.x, look.y) + 2.5, look.y), -4.0)
			await _capture("spur_%s_junction" % id, "%s: on %s, %d m before the spur junction, facing %d m up the spur toward the pocket" % [
				id, str(spur.joins), int(SPUR_ROAD_BACK_M), int(SPUR_LOOK_UP_M)], _with(info, {"stand": [stand.x, stand.y]}))
		if not mid_done and _keep("spur_%s_mid" % id):
			mid_done = true
			var mid := junction.lerp(end, 0.5)
			await _stand(mid, Vector3(end.x, _ground(end.x, end.y) + 2.0, end.y), -4.0)
			await _capture("spur_%s_mid" % id, "%s: halfway along the spur, facing the mouth %d m ahead" % [
				id, int(mid.distance_to(end))], _with(info, {"stand": [mid.x, mid.y]}))


## Travel direction of `road` through `at`: the first segment whose closest
## point to `at` is within 1 m, from its earlier vertex to its later one.
func _road_direction(road: Dictionary, at: Vector2) -> Vector2:
	var points: Array = road.get("points", [])
	for i in range(1, points.size()):
		var a := Vector2(float(points[i - 1][0]), float(points[i - 1][1]))
		var b := Vector2(float(points[i][0]), float(points[i][1]))
		if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) <= 1.0:
			return (b - a).normalized()
	_failures.append("no segment of %s passes %s" % [str(road.get("id", "?")), str(at)])
	return Vector2(0, 1)


func _with(base: Dictionary, more: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	out.merge(more, true)
	return out


func _pocket_rewards() -> Dictionary:
	var out := {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PICKUPS_PATH))
	var rows: Array = []
	if data is Array:
		rows = data
	elif data is Dictionary:
		for value: Variant in (data as Dictionary).values():
			if value is Array:
				rows.append_array(value)
	for row: Variant in rows:
		if row is Dictionary and (row as Dictionary).has("position"):
			var p: Array = (row as Dictionary).position
			out[str((row as Dictionary).get("id", ""))] = Vector3(float(p[0]), float(p[1]), float(p[2]))
	return out


func _reward_state(pickup_id: String) -> Dictionary:
	var node := _world.find_child(pickup_id, true, false) as Node3D
	if node == null:
		return {"found": false}
	return {"found": true, "visible": node.is_visible_in_tree(), "pos": _vec3(node.global_position),
		"ground_below": _ground(node.global_position.x, node.global_position.z)}


# ---------------------------------------------------------------- 3. Dynamo west

func _dynamo() -> void:
	var mid := Vector2(-700.0, 4820.0)
	var ahead := Vector3(-480.0, _ground(-480.0, 5120.0) + 4.0, 5120.0)
	# Stand a few metres back along the first leg so the vertex is in frame.
	var back := mid + (mid - Vector2(-890.0, 4490.0)).normalized() * -8.0
	if _keep("dynamo_west_mid"):
		await _stand(back, ahead, -4.0)
		await _capture("dynamo_west_mid", "dynamo_west_approach near (-700,4820), looking along the road toward (-480,5120)",
			{"stand": [back.x, back.y]})
	var camp := Vector2(-140.0, 5242.0)
	var leg := (camp - Vector2(-480.0, 5120.0)).normalized()
	var arrive := camp - leg * 30.0
	if _keep("dynamo_west_ember_arrival"):
		await _stand(arrive, Vector3(camp.x, _ground(camp.x, camp.y) + 1.5, camp.y), -6.0)
		await _capture("dynamo_west_ember_arrival", "dynamo_west_approach last leg, 30 m before Ember Bivouac, facing the camp",
			{"stand": [arrive.x, arrive.y]})


# ---------------------------------------------------------------- 4. Forest

func _forest() -> void:
	var ash := Vector2(-590.0, 1060.0)
	var ash_stand := ash + (ash - Vector2(-380.0, 1400.0)).normalized() * 6.0
	await _stand(ash_stand, Vector3(-380.0, _ground(-380.0, 1400.0) + 4.0, 1400.0), -3.0)
	await _capture("forest_ash_road_1060", "ash_road near (-590,1060) looking north-east along the road toward (-380,1400)",
		{"stand": [ash_stand.x, ash_stand.y]})
	var hollows := Vector2(-536.0, 1514.0)
	await _stand(hollows, Vector3(-900.0, _ground(-900.0, 1780.0) + 4.0, 1780.0), -3.0)
	await _capture("forest_hollows_ash_road", "ash_road through Glowmoss Hollows at (-536,1514) looking north-west toward (-900,1780)",
		{"stand": [hollows.x, hollows.y]})
	# The earlier lane tool's matrix_forest_day stand, for direct comparison.
	var forest := Vector2(-470.0, 3905.0)
	await _stand(forest, Vector3(-430.0, _ground(-430.0, 3990.0) + 6.0, 3990.0), -2.0)
	await _capture("forest_deepwood_matrix_stand", "Deepwood near Lantern Hollow, the matrix_forest_day stand of the earlier lane tool",
		{"stand": [forest.x, forest.y]})
