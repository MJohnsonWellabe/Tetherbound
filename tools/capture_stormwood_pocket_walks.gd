extends "res://tools/capture_stormwood_f09_pockets_roads.gd"

## WO-F09-05 evidence: per Stormwood pocket, three production-camera frames
## with the HUD hidden: (1) on the joined road before the spur junction, at
## the camera's normal exploration pose looking along the road, the junction
## lure in view; (2) standing in the mouth looking in at the reward; (3) the
## reward claimed with the ordinary `interact` action on its prompt.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_stormwood_pocket_walks.gd -- \
##     --out=res://ralph/reports/STORMWOOD-PROGRESS/visual/f09/pocket_walks \
##     [--pockets=id,id] [--fast] [--back=25]
##
## The road frame also renders once with that pocket's junction lamp hidden
## and records how many pixels change (`lamp_pixels_changed`): a physics ray
## cannot see non-colliding foliage, a rendered difference can.
##
## Staging (recorded per frame in frames_walks.json): the inherited
## `_stand` (one Game.debug_teleport_to plus a Player transform; the
## production CameraRig settles itself), day pinned, Surge pinned to Calm,
## `stormwood:rootgate_released` set (two pockets sit behind the Rootgate).
## The ordinary walk itself is tests/smoke_stormwood_pocket_walks.gd; these
## are stills of its three stages. --fast halves settle waits for iteration.

const ROAD_BACK_DEFAULT_M := 25.0
const MOUTH_OUT_M := 5.0
const MOUTH_YAW_OFFSET_DEG := 14.0
const MOUTH_PITCH_EXTRA_DEG := 4.0
## Round 6 (judge 13: Dynamo's right-hand trunk filled a third of the gate
## frame): per-pocket shoulder side for the gate frame.
const MOUTH_YAW_BY_POCKET := {"dynamo_scorch_pen": -14.0}
const WALK_START_BACK_M := 32.0
const PIXEL_DIFF_THRESHOLD := 24
## A normal exploration arm is 5.2 m; shorter means a body is in the way.
const ARM_MIN_M := 4.0
const ARM_RETRIES := 6

var _back_m := ROAD_BACK_DEFAULT_M
var _fast := false
var _pitch_start := -12.0
var _measure := false
var _repeats := 1
var _picks: Array[Vector2] = []
## Road stands only: wild bodies within FREEZE_WILD_M of the trainer are
## process-disabled from the tick they appear until the stand is done, so a
## roadside pair (ROAD CP-2 authored clusters sit ~15 m from the Conductor
## stands) stays where it spawned instead of walking into the lens. Recorded
## per frame as `frozen_wild`.
var _freeze_wild := false
var _frozen: Array[Node] = []
var _director: Node
const FREEZE_WILD_M := 25.0


func _run() -> void:
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless":
		push_error("pocket walk capture requires a rendering display; never use --headless")
		quit(1)
		return
	_biome_id = "stormwood"
	_character_id = "trainer"
	_label = "walks"
	_hud_off = true
	_output_dir = "res://ralph/reports/STORMWOOD-PROGRESS/visual/f09/pocket_walks"
	_fast = OS.get_environment("VP_FAST") == "1"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_output_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--pockets="):
			for part: String in arg.trim_prefix("--pockets=").split(",", false):
				_pocket_filter.append(part.strip_edges())
		elif arg.begins_with("--back="):
			_back_m = float(arg.trim_prefix("--back="))
		elif arg == "--fast":
			_fast = true
		elif arg == "--measure":
			_measure = true
		elif arg.begins_with("--pick="):
			for part: String in arg.trim_prefix("--pick=").split(",", false):
				var xy := part.split(":")
				if xy.size() == 2:
					_picks.append(Vector2(float(xy[0]), float(xy[1])))
		elif arg.begins_with("--repeats="):
			_repeats = int(arg.trim_prefix("--repeats="))
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/movement.json"))
	_pitch_start = float((movement.get("camera", {}) as Dictionary).get("pitch_start_deg", -12.0))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	_scatter_fresh = _scatter_bake_fresh()
	_log("scatter bake fresh: %s fast=%s back=%.0fm" % [str(_scatter_fresh), str(_fast), _back_m])
	if not _scatter_fresh:
		_failures.append("stormwood scatter bake is stale for this checkout")
	if not await _mount_production_world() or not _prepare_capture_shell():
		_done()
		return
	if _fast:
		var viewport := root as Viewport
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_game = root.get_node(^"Game")
	_arbiter = _world.get_node_or_null(^"InteractionArbiter")
	if _arbiter == null:
		_arbiter = get_first_node_in_group(&"interaction_arbiter")
	_surge = _world.get_node_or_null(^"StormwoodSurge")
	_flag("stormwood:rootgate_released")
	var sync := _world.get_node_or_null(^"StormwoodPickups")
	if sync != null:
		sync.call("sync_progression")
	for node: Node in _world.find_children("*", "", true, false):
		if node.has_method("wild_creatures") and node.has_method("spawn_wild"):
			_director = node
			break
	physics_frame.connect(_freeze_tick)
	if _measure:
		await _measure_frames()
	else:
		await _walk_frames()
	_done()


func _walk_frames() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POCKETS_PATH))
	var routes: Array = (JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH)) as Dictionary).routes
	var half := float(cfg.interior_half_m)
	var wall_mid := half + float(cfg.wall_thickness_m) * 0.5
	for pocket: Dictionary in cfg.pockets:
		var id := str(pocket.id)
		if not _pocket_filter.is_empty() and not _pocket_filter.has(id):
			continue
		var spur := {}
		for route: Dictionary in routes:
			if str(route.get("kind", "")) == "spur" and str(route.get("pocket_id", "")) == id:
				spur = route
		if spur.is_empty():
			_failures.append("%s: no spur" % id)
			continue
		var road := _road_of(spur, routes)
		var points: Array[Vector2] = road.points
		var js := float(road.junction_s)
		# The same side of the junction the walk smoke starts from.
		var sense := 1 if js >= WALK_START_BACK_M else -1
		var here := _along(points, js - _back_m * sense)
		var heading: Vector2 = (here.dir as Vector2) * sense
		var stand: Vector2 = here.at
		var info := {"pocket": id, "joins": str(spur.joins), "junction": [float(spur.points[0][0]), float(spur.points[0][1])],
			"road_back_m": _back_m, "side": "along" if sense == 1 else "against"}
		# (1) Road, normal exploration pose, looking along the road. The walk
		# smoke's side first; if a body keeps blocking the view there (a
		# creature that walks up to the trainer), the other side of the
		# junction at the same distance.
		var lamp := _world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s/SpurLamp" % id)) as Node3D
		var flame := lamp.get_node_or_null(^"AmberFlame") as Node3D if lamp != null else null
		var obstructions: Array[Dictionary] = []
		var lure := {}
		_begin_freeze()
		for attempt in ARM_RETRIES:
			var side := sense if attempt < ARM_RETRIES / 2 else -sense
			here = _along(points, js - _back_m * side)
			heading = (here.dir as Vector2) * side
			stand = here.at
			info["side"] = "along" if side == 1 else "against"
			var ahead := stand + heading * 20.0
			await _stand(stand, Vector3(ahead.x, _ground(ahead.x, ahead.y) + 1.5, ahead.y), _pitch_start)
			lure = {}
			if flame != null:
				var with_lamp := await _grab()
				lamp.visible = false
				var without := await _grab()
				lamp.visible = true
				var px := _camera.unproject_position(flame.global_position)
				var size := _camera.get_viewport().get_visible_rect().size
				lure = {"flame_in_frustum": _camera.is_position_in_frustum(flame.global_position),
					"flame_screen": [px.x / size.x, px.y / size.y],
					"camera_to_flame_m": _camera.global_position.distance_to(flame.global_position),
					"lamp_pixels_changed": _diff(with_lamp, without)}
			var arm := _camera.global_position.distance_to(_player.global_position)
			var blocker := _flame_blocker(id)
			if arm >= ARM_MIN_M and blocker.is_empty():
				break
			var seen := {"attempt": attempt + 1, "side": info["side"], "arm_m": arm,
				"flame_ray_blocked_by": blocker, "bodies_near": _bodies_near(_camera.global_position, 4.0)}
			obstructions.append(seen)
			_log("%s road stand obstructed: %s" % [id, str(seen)])
			for _frame in 300:
				await physics_frame
		if not obstructions.is_empty():
			info["road_stand_obstructions"] = obstructions
		lure["spur_pixels"] = await _spur_pixels(id, spur, points, flame)
		await _capture("%s_1_road_lure" % id, "%s: on %s %d m of road before the spur junction (%s side), normal exploration camera looking along the road" % [
			id, str(spur.joins), int(_back_m), str(info["side"])], _with(info, _with(lure, {"stand": [stand.x, stand.y]})))
		lure["spur_pixels"]["frozen_wild"] = _end_freeze()
		_frames[_frames.size() - 1]["frozen_wild"] = lure["spur_pixels"]["frozen_wild"]
		_log("SPURPIX %s side=%s %s" % [id, str(info["side"]), _pix_line(lure["spur_pixels"])])
		_log_view(id)
		# (2) In the mouth, looking in at the reward.
		var f := POCKET_FRAME.frame(pocket)
		var centre: Vector2 = f.centre
		# Round 3 (judge: the Dynamo gate's lantern bracket was cut by the top
		# edge): the gate is framed from MOUTH_OUT_M outside its opening.
		var mouth: Vector2 = centre + (f.forward as Vector2) * (wall_mid + MOUTH_OUT_M)
		var reward_id := str(pocket.reward_pickup_id)
		var reward := _reward_node(reward_id)
		var reward_at := reward.global_position if reward != null else Vector3(centre.x, _ground(centre.x, centre.y), centre.y)
		# Round 5 (judge: the reward sat behind the trainer's head): the camera
		# looks past the trainer's shoulder, a little higher.
		await _stand(mouth, reward_at + Vector3.UP, _pitch_start - MOUTH_PITCH_EXTRA_DEG,
			float(MOUTH_YAW_BY_POCKET.get(id, MOUTH_YAW_OFFSET_DEG)))
		await _capture("%s_2_mouth" % id, "%s: standing in the mouth, looking in at the reward" % id,
			_with(info, {"stand": [mouth.x, mouth.y], "reward_node": _reward_state(reward_id)}))
		# (3) Claim with the ordinary interact action, then the frame.
		var toward := (mouth - Vector2(reward_at.x, reward_at.z)).normalized()
		var close := Vector2(reward_at.x, reward_at.z) + toward * 1.4
		await _stand(close, reward_at, _pitch_start, 24.0)
		var prompt_before := str(_arbiter.call("prompt")) if _arbiter != null else ""
		await _capture("%s_3a_reward_before" % id, "%s: 1.4 m from the reward, its prompt '%s' offered (HUD hidden), before interact" % [id, prompt_before],
			_with(info, {"stand": [close.x, close.y], "reward_node": _reward_state(reward_id)}))
		var item := _item_of(reward_id)
		var inventory: RefCounted = _game.get("inventory")
		var before := int(inventory.call("count", item))
		await _press_interact()
		for _frame in 30:
			await physics_frame
		var after := int(inventory.call("count", item))
		if after != before + 1:
			_failures.append("%s: claim did not land (%s %d->%d, prompt '%s')" % [id, item, before, after, prompt_before])
		await _capture("%s_3b_reward_claimed" % id, "%s: same pose, after pressing interact on the reward prompt '%s'" % [id, prompt_before],
			_with(info, {"stand": [close.x, close.y], "prompt_before": prompt_before, "item": item,
				"count_before": before, "count_after": after, "reward_node": _reward_state(reward_id)}))


## Name of whatever a physics ray from the camera to this pocket's junction
## flame hits first (stopping 0.4 m short of it), or "" when clear.
func _flame_blocker(id: String) -> String:
	var flame := _world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s/SpurLamp/AmberFlame" % id)) as Node3D
	if flame == null:
		return ""
	var from := _camera.global_position
	var to := flame.global_position - (flame.global_position - from).normalized() * 0.4
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player.get_rid()]
	var hit := _player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	var collider: Variant = hit.get("collider")
	return str((collider as Node).get_path()) if collider is Node else str(collider)


func _bodies_near(at: Vector3, radius: float) -> Array[String]:
	var out: Array[String] = []
	for node: Node in _world.find_children("*", "PhysicsBody3D", true, false):
		var body := node as Node3D
		if body != _player and body.global_position.distance_to(at) < radius + 3.0:
			out.append("%s (%s) %.1fm" % [body.get_path(), body.get_class(), body.global_position.distance_to(at)])
	return out


func _grab() -> Image:
	if _hud_off:
		for layer: Node in _world.find_children("*", "CanvasLayer", true, false) + root.find_children("*", "CanvasLayer", true, false):
			(layer as CanvasLayer).visible = false
	for _frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _diff(a: Image, b: Image) -> int:
	if a == null or b == null or a.get_size() != b.get_size():
		return -1
	var changed := 0
	for y in range(0, a.get_height(), 2):
		for x in range(0, a.get_width(), 2):
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			if (absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)) * 255.0 > PIXEL_DIFF_THRESHOLD:
				changed += 4
	return changed


func _press_interact() -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		for _frame in 3:
			await physics_frame


func _reward_node(pickup_id: String) -> Node3D:
	var service := _world.get_node_or_null(^"StormwoodPickups")
	if service == null:
		return null
	var node: Variant = (service.get("_placements") as Dictionary).get(pickup_id)
	return node as Node3D if node is Node3D and is_instance_valid(node) else null


func _item_of(pickup_id: String) -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PICKUPS_PATH))
	for row: Dictionary in data.pickups:
		if str(row.id) == pickup_id:
			return str(row.item_id)
	return ""


func _road_of(spur: Dictionary, routes: Array) -> Dictionary:
	var junction := Vector2(float(spur.points[0][0]), float(spur.points[0][1]))
	for route: Dictionary in routes:
		if str(route.id) != str(spur.joins):
			continue
		var points: Array[Vector2] = []
		for raw: Array in route.points:
			points.append(Vector2(float(raw[0]), float(raw[1])))
		var walked := 0.0
		var best := INF
		var at_s := 0.0
		for i in range(1, points.size()):
			var closest := Geometry2D.get_closest_point_to_segment(junction, points[i - 1], points[i])
			if closest.distance_to(junction) < best:
				best = closest.distance_to(junction)
				at_s = walked + points[i - 1].distance_to(closest)
			walked += points[i - 1].distance_to(points[i])
		return {"points": points, "junction_s": at_s, "length": walked}
	return {"points": [junction, junction + Vector2(0, 1)] as Array[Vector2], "junction_s": 0.0, "length": 1.0}


func _along(points: Array[Vector2], s: float) -> Dictionary:
	var walked := 0.0
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if walked + seg >= s or i == points.size() - 1:
			var t := clampf((s - walked) / maxf(seg, 0.001), 0.0, 1.0)
			return {"at": points[i - 1].lerp(points[i], t), "dir": (points[i] - points[i - 1]).normalized()}
		walked += seg
	return {"at": points[0], "dir": Vector2(0, 1)}


# ---------------------------------------------------------------- pixel measure

## WO-F09-05 round 2 (blind judge: the spur does not read from the road). The
## spur and lure measured in rendered pixels at the production camera, from
## both sides of each junction at `_back_m` of road. Frames go to --out as
## <pocket>_road_<side>.jpg; one SPURPIX line per stand.
func _measure_frames() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POCKETS_PATH))
	var routes: Array = (JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH)) as Dictionary).routes
	for pocket: Dictionary in cfg.pockets:
		var id := str(pocket.id)
		if not _pocket_filter.is_empty() and not _pocket_filter.has(id):
			continue
		var spur := {}
		for route: Dictionary in routes:
			if str(route.get("kind", "")) == "spur" and str(route.get("pocket_id", "")) == id:
				spur = route
		var road := _road_of(spur, routes)
		var points: Array[Vector2] = road.points
		var js := float(road.junction_s)
		var flame := _world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s/SpurLamp/AmberFlame" % id)) as Node3D
		for side: int in [1, -1]:
			var s := js - _back_m * side
			if s < 0.0 or s > float(road.length):
				continue
			var here := _along(points, s)
			var heading: Vector2 = (here.dir as Vector2) * side
			var stand: Vector2 = here.at
			var ahead := stand + heading * 20.0
			_begin_freeze()
			await _stand(stand, Vector3(ahead.x, _ground(ahead.x, ahead.y) + 1.5, ahead.y), _pitch_start)
			var metrics := await _spur_pixels(id, spur, points, flame)
			var name := "along" if side == 1 else "against"
			var image := await _grab()
			image.save_jpg(ProjectSettings.globalize_path("%s/%s_road_%s.jpg" % [_output_dir, id, name]), 0.85)
			metrics["frozen_wild"] = _end_freeze()
			_log("SPURPIX %s side=%s arm=%.1f %s" % [id, name, _camera.global_position.distance_to(_player.global_position), _pix_line(metrics)])
			_log_view("%s_%s" % [id, name])
			_frames.append({"id": "%s_road_%s" % [id, name], "stand": [stand.x, stand.y], "spur_pixels": metrics})


func _pix_line(m: Dictionary) -> String:
	return "reads=%s (current=%s paint=%s) lane_px=%d contrast=%.1f gold_px=%d lane_rgb=%s flank_rgb=%s current_changed=%d first=%d lamp_changed=%d lamp_on_screen=%s frozen_wild=%d" % [
		str(m.get("reads", false)), str(m.get("reads_current", false)), str(m.get("reads_paint", false)), int(m.get("lane_px", 0)), float(m.get("contrast", 0.0)), int(m.get("gold_px", 0)),
		str(m.get("lane_rgb", [])), str(m.get("flank_rgb", [])), int(m.get("current_changed", -1)), int(m.get("current_changed_first", -1)),
		int(m.get("lamp_changed", -1)), str(m.get("lamp_on_screen", false)), int(m.get("frozen_wild", 0))]


## Colour contrast between the spur's own pixels and the ground either side
## of it, sampled on the frame the player sees, plus two toggles with the
## rain hidden: the spur's current chunks, and the junction lamp.
func _spur_pixels(id: String, spur: Dictionary, road_points: Array[Vector2], flame: Node3D) -> Dictionary:
	var surface: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_road_surface.json"))
	var lane := float(surface.lane_half_width_m.spur)
	var flare := float(surface.junction.flare_m)
	var flare_len := float(surface.junction.flare_length_m)
	var road_half := float(surface.lane_half_width_m.get("critical", 2.8))
	var j := Vector2(float(spur.points[0][0]), float(spur.points[0][1]))
	var up := (Vector2(float(spur.points[1][0]), float(spur.points[1][1])) - j).normalized()
	var right := Vector2(up.y, -up.x)
	var image := await _grab()
	var size := image.get_size()
	# Dense world-space raster of the spur lane beyond the road's own lane,
	# and of a ground band either side of it, each reduced to the unique
	# screen pixels it lands on.
	var lane_px := {}
	var flank_px := {}
	var centres: Array[Vector2] = []
	var d := SPUR_PIX_START_M
	while d <= SPUR_PIX_END_M + 0.01:
		var c := j + up * d
		var half := lane + flare * (1.0 - smoothstep(0.0, flare_len, d))
		var across := -half
		while across <= half + 0.01:
			var q := c + right * across
			if _distance_to_polyline(q, road_points) >= road_half + 1.0:
				var qp := _screen(q, 0.05)
				if qp.x >= 0.0:
					lane_px[Vector2i(qp)] = true
					if absf(across) < 0.3:
						centres.append(qp)
			across += SPUR_PIX_GRID_M
		for sign: float in [1.0, -1.0]:
			var out_m := half + 1.0
			while out_m <= half + 1.0 + SPUR_PIX_FLANK_M + 0.01:
				var q := c + right * sign * out_m
				if _distance_to_polyline(q, road_points) >= road_half + 1.0:
					var qp := _screen(q, 0.05)
					if qp.x >= 0.0:
						flank_px[Vector2i(qp)] = true
				out_m += SPUR_PIX_GRID_M
		d += SPUR_PIX_GRID_M
	var lane_mean := _mean_colour(image, lane_px)
	var flank_mean := _mean_colour(image, flank_px)
	var gold := 0
	for key: Vector2i in lane_px:
		if _is_gold(image.get_pixelv(key)):
			gold += 1
	var contrast := _delta(lane_mean, flank_mean) if not lane_px.is_empty() and not flank_px.is_empty() else 0.0
	var out := {"lane_px": lane_px.size(), "flank_px": flank_px.size(), "contrast": contrast, "gold_px": gold,
		"lane_rgb": [lane_mean.r8, lane_mean.g8, lane_mean.b8], "flank_rgb": [flank_mean.r8, flank_mean.g8, flank_mean.b8],
		"thresholds": {"current_changed_px": SPUR_CURRENT_PX, "contrast": SPUR_PIX_CONTRAST, "min_lane_px": SPUR_PIX_MIN_PX}}
	# Toggles, rain hidden so falling streaks do not count as change.
	var rain_layers := _hide_rain()
	var current := _world.get_node_or_null(^"StormwoodRoadCurrent")
	var chunks: Array[GeometryInstance3D] = []
	if current != null:
		for child: Node in current.get_children():
			if child is GeometryInstance3D and str(child.get_meta("route", "")) == str(spur.id):
				chunks.append(child as GeometryInstance3D)
	var with_all: Image = null
	var changes: Array[int] = []
	for repeat in maxi(1, _repeats):
		var with_current := await _grab()
		if with_all == null:
			with_all = with_current
		for chunk in chunks:
			chunk.visible = false
		var without_current := await _grab()
		for chunk in chunks:
			chunk.visible = true
		changes.append(_changed_near(with_current, without_current, centres, SPUR_PIX_BAND_PX))
	out["current_chunks"] = chunks.size()
	# The first pair is the round-1 baseline protocol; with --repeats=N the
	# median of N pairs is recorded too (the pulses move between grabs).
	out["current_changed_first"] = changes[0]
	out["current_changed_all"] = changes
	var ordered := changes.duplicate()
	ordered.sort()
	out["current_changed"] = ordered[ordered.size() / 2]
	if flame != null:
		var lamp := flame.get_parent() as Node3D
		var fp := _camera.unproject_position(flame.global_position)
		var in_view := _camera.is_position_in_frustum(flame.global_position) and fp.x >= 0 and fp.y >= 0 and fp.x < size.x and fp.y < size.y
		out["lamp_on_screen"] = in_view
		out["lamp_screen"] = [fp.x / size.x, fp.y / size.y]
		var lamps: Array[Node3D] = [lamp]
		var second := lamp.get_parent().get_node_or_null(^"SpurLamp2") as Node3D
		if second != null:
			lamps.append(second)
		for each in lamps:
			each.visible = false
		var without_lamp := await _grab()
		for each in lamps:
			each.visible = true
		var flame_at: Array[Vector2] = [fp]
		out["lamp_changed"] = _changed_near(with_all, without_lamp, flame_at, LAMP_PIX_BOX_PX) if in_view else 0
	_restore_rain(rain_layers)
	# Primary: the spur's own current, toggled, changes enough pixels in the
	# band round its off-road centre line. Secondary: its painted lane stands
	# off the flanking ground by colour.
	out["reads_current"] = int(out.get("current_changed", 0)) >= SPUR_CURRENT_PX
	out["reads_paint"] = int(out.lane_px) >= SPUR_PIX_MIN_PX and float(out.contrast) >= SPUR_PIX_CONTRAST
	out["reads"] = bool(out.reads_current) or bool(out.reads_paint)
	return out


## The spur is sampled from the junction to SPUR_PIX_END_M up it, on a
## SPUR_PIX_GRID_M world grid; the flank band starts 1 m beyond the painted
## lane edge and is SPUR_PIX_FLANK_M wide. Samples within the joined road's
## lane (+1 m) are left out, so the road's own paint and current never count.
const SPUR_PIX_START_M := 0.0
const SPUR_PIX_END_M := 24.0
const SPUR_PIX_GRID_M := 0.4
const SPUR_PIX_FLANK_M := 3.0
## A spur reads when hiding its own current chunks (rain hidden) changes at
## least SPUR_CURRENT_PX pixels within SPUR_PIX_BAND_PX of its off-road centre
## line, or, as paint alone, when at least SPUR_PIX_MIN_PX of its lane is on
## screen with a mean colour SPUR_PIX_CONTRAST (weighted RGB, 0-255) off the
## flanking ground. Calibrated on the round-1 frames the blind judge saw (the
## "along" stands, 25 m): Verge, the one reading spur, 1559 px; the failing
## Hollows 436, Deepwood 551, Dynamo 179, ambiguous Conductor 89. Paint
## contrast there was 2.4-13.9 for all five, Verge 7.4, so it separated
## nothing; 20 sits above every round-1 value.
const SPUR_CURRENT_PX := 1000
const SPUR_PIX_MIN_PX := 400
const SPUR_PIX_CONTRAST := 20.0
const SPUR_PIX_BAND_PX := 6
const LAMP_PIX_BOX_PX := 40


## Viewport position of ground point `xz` lifted `lift` m, or (-1,-1) when
## it is behind the camera or off screen.
func _screen(xz: Vector2, lift: float) -> Vector2:
	var at := Vector3(xz.x, _ground(xz.x, xz.y) + lift, xz.y)
	if not _camera.is_position_in_frustum(at):
		return Vector2(-1, -1)
	var p := _camera.unproject_position(at)
	var size := _camera.get_viewport().get_visible_rect().size
	if p.x < 3 or p.y < 3 or p.x > size.x - 4 or p.y > size.y - 4:
		return Vector2(-1, -1)
	return p


func _mean_colour(image: Image, pixels: Dictionary) -> Color:
	var sum := Color(0, 0, 0, 0)
	for key: Vector2i in pixels:
		sum += image.get_pixelv(key)
	return sum / maxf(1.0, pixels.size()) if not pixels.is_empty() else Color(0, 0, 0)


## The road current's yellow-gold, not the amber lamp or orange fungi:
## bright, strongly warm, low blue.
func _is_gold(c: Color) -> bool:
	return c.r > 0.55 and c.g > 0.42 and c.b < 0.4 and c.g > c.b + 0.22 and c.r - c.b > 0.3


func _patch(image: Image, p: Vector2) -> Color:
	var sum := Color(0, 0, 0)
	var n := 0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var x := clampi(int(p.x) + dx, 0, image.get_width() - 1)
			var y := clampi(int(p.y) + dy, 0, image.get_height() - 1)
			sum += image.get_pixel(x, y)
			n += 1
	return sum / float(n)


## Weighted RGB distance on a 0-255 scale (weights 2,4,3, normalised).
func _delta(a: Color, b: Color) -> float:
	var dr := (a.r - b.r) * 255.0
	var dg := (a.g - b.g) * 255.0
	var db := (a.b - b.b) * 255.0
	return sqrt((2.0 * dr * dr + 4.0 * dg * dg + 3.0 * db * db) / 3.0)


func _changed_near(a: Image, b: Image, centres: Array[Vector2], radius: int) -> int:
	if a == null or b == null or a.get_size() != b.get_size():
		return -1
	var seen := {}
	var changed := 0
	for c: Vector2 in centres:
		for y in range(int(c.y) - radius, int(c.y) + radius + 1):
			for x in range(int(c.x) - radius, int(c.x) + radius + 1):
				if x < 0 or y < 0 or x >= a.get_width() or y >= a.get_height():
					continue
				var key := y * 10000 + x
				if seen.has(key):
					continue
				seen[key] = true
				var p := a.get_pixel(x, y)
				var q := b.get_pixel(x, y)
				if (absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b)) * 255.0 > PIXEL_DIFF_THRESHOLD:
					changed += 1
	return changed


func _distance_to_polyline(q: Vector2, points: Array[Vector2]) -> float:
	var best := INF
	for i in range(1, points.size()):
		best = minf(best, Geometry2D.get_closest_point_to_segment(q, points[i - 1], points[i]).distance_to(q))
	return best


func _hide_rain() -> Dictionary:
	var saved := {}
	if _surge == null:
		return saved
	for node: Node in _surge.find_children("*", "GPUParticles3D", true, false):
		saved[node] = (node as GPUParticles3D).layers
		(node as GPUParticles3D).layers = 1 << 19
	_camera.set_cull_mask_value(20, false)
	return saved


func _restore_rain(saved: Dictionary) -> void:
	for node: Variant in saved:
		if is_instance_valid(node):
			(node as GPUParticles3D).layers = int(saved[node])


func _freeze_tick() -> void:
	if not _freeze_wild or _director == null or _player == null:
		return
	for wild: Node3D in _director.call("wild_creatures"):
		if is_instance_valid(wild) and wild.process_mode != Node.PROCESS_MODE_DISABLED \
				and wild.global_position.distance_to(_player.global_position) < FREEZE_WILD_M:
			wild.process_mode = Node.PROCESS_MODE_DISABLED
			_frozen.append(wild)


func _begin_freeze() -> void:
	_freeze_wild = true
	_frozen.clear()


func _end_freeze() -> int:
	_freeze_wild = false
	var count := _frozen.size()
	for node: Node in _frozen:
		if is_instance_valid(node):
			node.process_mode = Node.PROCESS_MODE_INHERIT
	_frozen.clear()
	return count


## Round 3 identification aid: which meshes lie under each --pick pixel
## (nearest three whose world AABB the view ray crosses), and which wild
## bodies are on screen and where.
func _log_view(tag: String) -> void:
	var size := _camera.get_viewport().get_visible_rect().size
	for pixel: Vector2 in _picks:
		var from := _camera.project_ray_origin(pixel)
		var dir := _camera.project_ray_normal(pixel)
		var hits: Array = []
		for node: Node in _world.find_children("*", "VisualInstance3D", true, false):
			var visual := node as VisualInstance3D
			if not visual.is_visible_in_tree() or not (visual is GeometryInstance3D):
				continue
			var box := visual.global_transform * visual.get_aabb()
			if box.size.x > 300.0 or box.size.z > 300.0:
				continue
			var hit: Variant = box.intersects_ray(from, dir)
			if hit != null:
				hits.append([from.distance_to(hit as Vector3), str(visual.get_path()).trim_prefix(str(_world.get_path())), box.size])
		hits.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
		_log("PICK %s px=%s -> %s" % [tag, str(pixel), str(hits.slice(0, 4))])
	if _director != null:
		for wild: Node3D in _director.call("wild_creatures"):
			if is_instance_valid(wild) and _camera.is_position_in_frustum(wild.global_position + Vector3.UP) \
					and wild.global_position.distance_to(_camera.global_position) < 60.0:
				var p := _camera.unproject_position(wild.global_position + Vector3.UP)
				if p.x > -200 and p.x < size.x + 200:
					_log("WILD %s %s species=%s at=%s screen=(%.0f,%.0f) frozen=%s" % [tag, wild.name, str(wild.get("species_id")),
						str(wild.global_position), p.x, p.y, str(wild.process_mode == Node.PROCESS_MODE_DISABLED)])
