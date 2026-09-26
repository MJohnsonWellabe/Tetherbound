extends SceneTree

## WO-F09-05: ordinary walk witness for the five Stormwood dead-end pockets
## (WORLD §5.1; ACCEPTANCE §6.1 F09 "five pockets ... physically traversable"),
## plus the per-pocket measurement of the junction lure seen from the road.
##
## DISCLOSED SEAMS (nothing else is staged):
##   1. Chapter entry: the `smoke_stormwood_continuous.gd` pattern. An
##      in-memory completed-Cloudreach party and entitlement, then the
##      production realm router enters Stormwood at its authored arrival. No
##      save is written and no `stormwood:*` flag is set by the entry.
##   2. Start positions: one `Game.debug_teleport_to` per pocket onto its
##      joined road, `START_BACK_M` of road arc-length before the spur
##      junction, facing along the road. The positions come from the road
##      polylines in stormwood_world.json, not from literals.
##   3. `stormwood:rootgate_released` is set before the two pockets behind
##      the Rootgate (deepwood_ridge_shelter, dynamo_scorch_pen): their
##      spurs and rewards carry that `requires_unlock`. Earning it is the
##      continuous smoke's job (Rootgate segment), not this one's.
##   4. Surge: if the storm is Building/Break when a walk is due, the harness
##      waits for Calm with Engine.time_scale raised (physics tick stays
##      1/60 s), as the continuous smoke does for its Break wait.
##
## Everything from the start stand on is ordinary play: the production Player
## driven by left-stick joypad events through tests/helpers/stick_navigator.gd
## along the road to the junction, up the spur, through the mouth to the
## reward; the reward is claimed by pressing the ordinary `interact` action on
## the production InteractionArbiter prompt, and the receipt (item count,
## realm-qualified cache flag, pickup gone) is asserted.
##
## Lure measurement (printed as LURE lines, asserted): from each side of the
## junction, at 30, 25 and 20 m of road before it, the trainer stands on the
## road facing along it and the production CameraRig sits in its normal
## exploration pose (behind the trainer, pitch_start_deg from movement.json).
## Recorded: whether the junction lamp's flame is inside the camera frustum,
## its normalised screen position, and a physics ray from the camera to the
## flame (terrain, trunks, rocks, walls, posts). The painted spur is sampled
## at 2 m steps over its first 20 m: in frustum and a clear ray. Physics rays
## cannot see non-colliding foliage (canopies, ferns, bushes); the rendered
## road frames from tools/capture_stormwood_pocket_walks.gd, inspected by eye,
## cover that. (That tool's lamp-on/lamp-off pixel count is dominated by rain
## and wind motion between the two grabs and is recorded, not judged.)
## The projection is taken at a 16:9 viewport (MEASURE_VIEWPORT); a headless
## window is otherwise square.
##
## Negative control: a straight stick push (no detour) at each pocket's back
## wall from outside must never put the trainer inside the pocket interior.
##
##   godot --headless --path . --script tests/smoke_stormwood_pocket_walks.gd \
##     [-- --only=<pocket_id>] [--measure-only]

const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")
const CACHE := preload("res://scripts/world/item_cache_pickup.gd")
const PICKUPS_PATH := "res://data/config/stormwood_pickups.json"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const MOVEMENT_PATH := "res://data/config/movement.json"
const ROOTGATE_FLAG := "stormwood:rootgate_released"
const SCENE_WAIT_FRAMES := 7200
const WATCHDOG_S := 3600.0
## Road arc-length before the junction where each walk starts.
const START_BACK_M := 32.0
const SAMPLE_BACK_M: Array[float] = [30.0, 25.0, 20.0]
const SPUR_SAMPLE_M := 20.0
const SPUR_SAMPLE_STEP_M := 2.0
## A lure sample passes when the flame is in frustum, its ray is clear, and
## it sits inside this normalised screen margin.
const SCREEN_MARGIN := 0.03
## Spur samples (of 10) that must be in frustum with a clear ray.
const SPUR_VISIBLE_MIN := 5
const NEGATIVE_PUSH_FRAMES := 480
const MEASURE_VIEWPORT := Vector2i(1280, 720)
const COMPLETED_CLOUDREACH_FLAGS: Array[String] = [
	"cloudreach_chapter_started", "cloudreach_act_i_complete", "cloudreach_act_ii_complete",
	"captain_veyra_defeated", "cloudreach_winds_restored", "realm_heart_cloudreach_earned",
	"realm_key_stormwood", "stormward_route_revealed", "cloudreach_chapter_complete",
]
const ENTRY_PARTY: Array[String] = ["sparkit", "mudsnout", "bramblebun", "terrapup", "brooktail"]

var game: Node
var world: Node3D
var player: CharacterBody3D
var rig: Node3D
var camera: Camera3D
var arbiter: Node
var navigator: RefCounted
var cfg: Dictionary
var routes: Array
var pitch_start := -12.0
var failures: Array[String] = []
var checks := 0
var finished := false
var _refusal := ""
var _measure_only := false
var _results: Array[String] = []


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(WATCHDOG_S, true, false, true).timeout.connect(func() -> void:
		if not finished:
			_fail("watchdog expired after %d s" % int(WATCHDOG_S))
			_finish())
	var only := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
		elif argument == "--measure-only":
			_measure_only = true
	if not await _enter_stormwood():
		_finish()
		return
	cfg = POCKETS.config()
	routes = (JSON.parse_string(FileAccess.get_file_as_string(WORLD_PATH)) as Dictionary).routes
	var movement: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MOVEMENT_PATH))
	pitch_start = float((movement.get("camera", {}) as Dictionary).get("pitch_start_deg", -12.0))
	for pocket: Dictionary in cfg.pockets:
		if not only.is_empty() and only != str(pocket.id):
			continue
		var spur := POCKETS.spur(pocket, routes)
		if not _check(not spur.is_empty(), "%s has no spur route" % pocket.id):
			continue
		if str(spur.get("requires_unlock", "")) == ROOTGATE_FLAG:
			_disclosed_rootgate()
		await _pocket(pocket, spur)
	for line: String in _results:
		print(line)
	_finish()


# ------------------------------------------------------------------ seam 1

func _enter_stormwood() -> bool:
	game = root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	game.set("save_system", SAVE_GAME.new("user://smoke_stormwood_pocket_walks_%d_%d" % [
		OS.get_process_id(), Time.get_ticks_usec()]))
	await process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "stormwood-pocket-walks")
	game.get("world").set("world_id", "stormwood-pocket-walks-world")
	# CHAPTER-ENTRY FIXTURE (disclosed seam 1), as smoke_stormwood_continuous.gd.
	for flag: String in COMPLETED_CLOUDREACH_FLAGS:
		var verdict: Dictionary = game.get("ledger").call("submit", {
			"kind": "set_world_flag", "realm": "cloudreach", "id": flag, "value": true})
		_check(bool(verdict.get("ok", false)), "chapter-entry fixture accepted Cloudreach fact %s" % flag)
	for species_id: String in ENTRY_PARTY:
		var creature: RefCounted = SPECIES.spawn(species_id)
		if creature != null:
			creature.call("set_level", 44, PROGRESSION.config())
		_check(creature != null and bool(game.get("party").call("add", creature)),
			"chapter-entry fixture carries %s" % species_id)
	var source := Node3D.new()
	source.name = "StormwoodPocketWalksEntrySource"
	root.add_child(source)
	current_scene = source
	await process_frame
	if not _check(await game.call("enter_realm", "stormwood", "stormwood_arrival_from_cloudreach"),
			"production router accepted the Stormwood entry"):
		return false
	for _frame in SCENE_WAIT_FRAMES:
		var candidate := current_scene as Node3D
		if candidate != null and candidate.name == "Stormwood" and bool(candidate.call("shell_build_complete")):
			world = candidate
			break
		await physics_frame
	if not _check(world != null, "production Stormwood scene became current"):
		return false
	for _frame in SCENE_WAIT_FRAMES:
		if str(game.get("pending_realm_entry")) == "":
			break
		await physics_frame
	player = world.get_node_or_null(^"Player") as CharacterBody3D
	rig = world.get_node_or_null(^"CameraRig") as Node3D
	arbiter = get_first_node_in_group(&"interaction_arbiter")
	if rig != null:
		for child: Node in rig.find_children("*", "Camera3D", true, false):
			camera = child as Camera3D
			break
	if not _check(player != null and rig != null and camera != null and arbiter != null,
			"production Player, CameraRig/Camera3D and InteractionArbiter present"):
		return false
	navigator = NAVIGATOR.new(self, player, rig, _stick)
	# Headless windows default to a square viewport; project the lure at the
	# shipped 16:9 aspect instead (the camera keeps its vertical FOV).
	root.size = MEASURE_VIEWPORT
	await _frames(30)
	print("POCKET WALKS viewport=%s realm=%s pockets_node=%s" % [
		str(camera.get_viewport().get_visible_rect().size), str(game.get("current_realm")),
		str(world.get_node_or_null(^"StormwoodPockets") != null)])
	return true


func _disclosed_rootgate() -> void:
	var flags: RefCounted = game.get("progression")
	if bool(flags.call("has", ROOTGATE_FLAG)):
		return
	print("DISCLOSED SEAM 3: set %s for the pockets behind the Rootgate" % ROOTGATE_FLAG)
	flags.call("set_flag", ROOTGATE_FLAG, true)


# ------------------------------------------------------------------ geometry

## The joined road's polyline as Vector2s, and the junction's arc-length on it.
func _road(spur: Dictionary) -> Dictionary:
	var junction := _p(spur.points[0])
	for route: Dictionary in routes:
		if str(route.id) != str(spur.joins):
			continue
		var points: Array[Vector2] = []
		for raw: Array in route.points:
			points.append(_p(raw))
		var walked := 0.0
		var best := INF
		var at_s := 0.0
		for i in range(1, points.size()):
			var closest := Geometry2D.get_closest_point_to_segment(junction, points[i - 1], points[i])
			var d := closest.distance_to(junction)
			if d < best:
				best = d
				at_s = walked + points[i - 1].distance_to(closest)
			walked += points[i - 1].distance_to(points[i])
		return {"points": points, "junction_s": at_s, "length": walked, "offset_m": best}
	return {}


## Point and travel tangent at arc-length `s` on `points`.
func _along(points: Array[Vector2], s: float) -> Dictionary:
	var walked := 0.0
	for i in range(1, points.size()):
		var seg := points[i - 1].distance_to(points[i])
		if walked + seg >= s or i == points.size() - 1:
			var t := clampf((s - walked) / maxf(seg, 0.001), 0.0, 1.0)
			return {"at": points[i - 1].lerp(points[i], t), "dir": (points[i] - points[i - 1]).normalized()}
		walked += seg
	return {"at": points[0], "dir": Vector2(0, 1)}


func _p(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


func _ground(x: float, z: float) -> float:
	return float(world.call("ground_height_at", x, z))


# ------------------------------------------------------------------ per pocket

func _pocket(pocket: Dictionary, spur: Dictionary) -> void:
	var id := str(pocket.id)
	var road := _road(spur)
	if not _check(not road.is_empty() and float(road.offset_m) < 1.5, "%s: junction lies on %s" % [id, spur.joins]):
		return
	var lamp := world.get_node_or_null(NodePath("StormwoodPockets/Pocket_%s/SpurLamp/AmberFlame" % id)) as Node3D
	if not _check(lamp != null, "%s: junction lamp flame is built" % id):
		return
	await _wait_calm()
	# Lure seen from the road, from each side of the junction.
	var points: Array[Vector2] = road.points
	var js := float(road.junction_s)
	for sense: int in [1, -1]:
		var side := "along" if sense == 1 else "against"
		var passes := 0
		var measured := 0
		for back: float in SAMPLE_BACK_M:
			var s := js - back * sense
			if s < 0.0 or s > float(road.length):
				print("LURE %s side=%s back=%.0fm n/a (road ends %.0f m from the junction)" % [
					id, side, back, js if sense == 1 else float(road.length) - js])
				continue
			var here := _along(points, s)
			var heading: Vector2 = (here.dir as Vector2) * sense
			measured += 1
			if await _lure_sample(id, side, back, here.at, heading, lamp, spur):
				passes += 1
		if measured > 0:
			_check(passes == measured, "%s: junction lamp in view with a clear line from the road (%s): %d/%d stands" % [
				id, side, passes, measured])
	if _measure_only:
		return
	# The walk: start on the road, road -> junction -> spur -> mouth -> reward.
	var sense := 1 if js >= START_BACK_M else -1
	var start: Dictionary = _along(points, js - START_BACK_M * sense)
	var t0 := Time.get_ticks_msec()
	await _stand(start.at, (start.dir as Vector2) * sense)
	var from := player.global_position
	var legs: Array[Vector2] = []
	# Road leg: follow the polyline vertices between start and junction.
	var walked := 0.0
	for i in range(1, points.size()):
		walked += points[i - 1].distance_to(points[i])
		var vertex_s := walked
		if (sense == 1 and vertex_s > js - START_BACK_M and vertex_s < js) \
				or (sense == -1 and vertex_s < js + START_BACK_M and vertex_s > js):
			legs.append(points[i])
	if sense == -1:
		legs.reverse()
	for raw: Array in spur.points:
		legs.append(_p(raw))
	var reward_id := str(pocket.reward_pickup_id)
	var service := world.get_node_or_null(^"StormwoodPickups")
	var reward: Node3D = null
	if service != null:
		reward = (service.get("_placements") as Dictionary).get(reward_id) as Node3D
	if not _check(reward != null and is_instance_valid(reward), "%s: reward %s is mounted" % [id, reward_id]):
		return
	var metres := 0.0
	var last := player.global_position
	var resets := 0
	for index in legs.size():
		var goal := Vector3(legs[index].x, 0.0, legs[index].y)
		var budget := maxi(900, int(Vector2(player.global_position.x, player.global_position.z).distance_to(legs[index]) * 90.0))
		var arrived: bool = await navigator.walk_to(goal, budget, 1.6)
		resets += int(navigator.call("confined_resets"))
		metres += Vector2(last.x, last.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
		last = player.global_position
		if not _check(arrived, "%s: walk stalled at leg %d/%d player=%s goal=%s" % [id, index + 1, legs.size(),
				player.global_position, goal]):
			_stick(0.0, 0.0)
			_results.append("WALK %s FAIL stalled leg %d" % [id, index + 1])
			return
	var mouth_at := player.global_position
	var inside_before := POCKETS.contains(pocket, cfg, Vector2(player.global_position.x, player.global_position.z))
	# Through the mouth to the reward.
	var reward_xz := Vector2(reward.global_position.x, reward.global_position.z)
	var arrived_reward: bool = await navigator.walk_to(Vector3(reward_xz.x, 0.0, reward_xz.y), 1200, 1.2)
	metres += Vector2(last.x, last.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
	_stick(0.0, 0.0)
	var inside := POCKETS.contains(pocket, cfg, Vector2(player.global_position.x, player.global_position.z))
	_check(arrived_reward and inside, "%s: walked through the mouth into the pocket to the reward (arrived=%s inside=%s player=%s)" % [
		id, arrived_reward, inside, player.global_position])
	var prompt := reward.get_node_or_null("Interactable")
	var offered := await _approach_prompt(prompt, reward.global_position)
	if not _check(offered, "%s: reward prompt offered; winner=%s" % [id, str(arbiter.call("prompt"))]):
		_results.append("WALK %s FAIL prompt" % id)
		return
	var prompt_text := str(arbiter.call("prompt"))
	var item := _reward_item(reward_id)
	var before: int = int(game.get("inventory").call("count", item))
	_refusal = ""
	if reward.has_signal("claim_refused"):
		reward.connect("claim_refused", _on_refused)
	await _press_interact()
	await _frames(20)
	var after: int = int(game.get("inventory").call("count", item))
	var receipt := CACHE.was_taken(game, item, reward_id, "stormwood")
	service.call("sync_progression")
	await _frames(2)
	var gone := not is_instance_valid(reward) or not (service.get("_placements") as Dictionary).has(reward_id) \
		or not (reward as Node3D).is_inside_tree()
	var accepted := after == before + 1 and receipt
	_check(accepted, "%s: claim receipt: refusal='%s' %s %d->%d flag=%s" % [id, _refusal, item, before, after, receipt])
	_results.append("WALK %s from=(%.1f,%.1f) on %s %s junction, %d legs, walked=%.0fm, confined_resets=%d, reached mouth=(%.1f,%.1f) inside_at_mouth=%s, reward=%s prompt='%s' %s %d->%d flag=%s node_gone=%s wall=%.0fs result=%s" % [
		id, from.x, from.z, str(spur.joins), "before" if sense == 1 else "after", legs.size() + 1, metres, resets,
		mouth_at.x, mouth_at.z, inside_before, reward_id, prompt_text, item, before, after, receipt, gone,
		float(Time.get_ticks_msec() - t0) / 1000.0, "PASS" if accepted else "FAIL"])
	await _negative_control(pocket)


## Straight stick push at the back wall from outside: never inside.
func _negative_control(pocket: Dictionary) -> void:
	var id := str(pocket.id)
	var f := POCKETS.frame(pocket)
	var centre: Vector2 = f.centre
	var outside := centre - (f.forward as Vector2) * (float(cfg.interior_half_m) + float(cfg.wall_thickness_m) + 6.0)
	await _stand(outside, (centre - outside).normalized())
	var entered := false
	var closest := INF
	for _frame in NEGATIVE_PUSH_FRAMES:
		var to := Vector3(centre.x - player.global_position.x, 0.0, centre.y - player.global_position.z)
		navigator.call("push_once", to.normalized())
		await physics_frame
		var xz := Vector2(player.global_position.x, player.global_position.z)
		closest = minf(closest, xz.distance_to(centre))
		if POCKETS.contains(pocket, cfg, xz):
			entered = true
	_stick(0.0, 0.0)
	_check(not entered, "%s NEGATIVE CONTROL: a straight push at the back wall got inside" % id)
	_results.append("NEGATIVE %s pushed %d frames at the back wall from (%.1f,%.1f): closest to centre %.2f m (interior half %.1f m) entered=%s result=%s" % [
		id, NEGATIVE_PUSH_FRAMES, outside.x, outside.y, closest, float(cfg.interior_half_m), entered,
		"PASS" if not entered else "FAIL"])


# ------------------------------------------------------------------ lure

func _lure_sample(id: String, side: String, back: float, at: Vector2, heading: Vector2, lamp: Node3D, spur: Dictionary) -> bool:
	await _stand(at, heading)
	var flame := lamp.global_position
	var cam := camera.global_position
	var in_frustum := camera.is_position_in_frustum(flame)
	var size := camera.get_viewport().get_visible_rect().size
	var px := camera.unproject_position(flame)
	var nx := px.x / size.x
	var ny := px.y / size.y
	var on_screen := in_frustum and nx > SCREEN_MARGIN and nx < 1.0 - SCREEN_MARGIN and ny > SCREEN_MARGIN and ny < 1.0 - SCREEN_MARGIN
	var hit := _ray(cam, flame, 0.3)
	var clear := hit.is_empty()
	# Painted spur: its first 20 m.
	var j := _p(spur.points[0])
	var up := (_p(spur.points[1]) - j).normalized()
	var seen := 0
	var samples := 0
	var d := SPUR_SAMPLE_STEP_M
	while d <= SPUR_SAMPLE_M + 0.01:
		var q := j + up * d
		var target := Vector3(q.x, _ground(q.x, q.y) + 0.15, q.y)
		samples += 1
		if camera.is_position_in_frustum(target) and _ray(cam, target, 0.4).is_empty():
			seen += 1
		d += SPUR_SAMPLE_STEP_M
	var bearing := rad_to_deg(heading.angle_to(Vector2(flame.x - cam.x, flame.z - cam.z)))
	var ok := on_screen and clear and seen >= SPUR_VISIBLE_MIN
	print("LURE %s side=%s back=%.0fm stand=(%.1f,%.1f) cam=(%.1f,%.1f,%.1f) flame=(%.1f,%.1f,%.1f) dist=%.1fm bearing=%+.1fdeg in_frustum=%s screen=(%.3f,%.3f) ray=%s spur_visible=%d/%d result=%s" % [
		id, side, back, at.x, at.y, cam.x, cam.y, cam.z, flame.x, flame.y, flame.z, cam.distance_to(flame), bearing,
		in_frustum, nx, ny, "clear" if clear else "BLOCKED by %s at %.1fm" % [_name(hit.get("collider")), cam.distance_to(hit.position)],
		seen, samples, "PASS" if ok else "FAIL"])
	return ok


func _ray(from: Vector3, to: Vector3, stop_short: float) -> Dictionary:
	var end := to - (to - from).normalized() * stop_short
	var query := PhysicsRayQueryParameters3D.create(from, end, 0xFFFFFFFF)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	return player.get_world_3d().direct_space_state.intersect_ray(query)


func _name(collider: Variant) -> String:
	if collider is Node:
		var node := collider as Node
		return "%s/%s" % [node.get_parent().name if node.get_parent() != null else "", node.name]
	return str(collider)


## Stand the trainer at `xz` facing `heading`, the rig in its normal pose.
func _stand(xz: Vector2, heading: Vector2) -> void:
	_stick(0.0, 0.0)
	var heading_deg := rad_to_deg(atan2(heading.x, heading.y))
	_check(await game.call("debug_teleport_to", xz.x, xz.y, "", "", heading_deg), "debug_teleport_to accepted %s" % str(xz))
	rig.set("pitch", deg_to_rad(pitch_start))
	rig.rotation = Vector3(deg_to_rad(pitch_start), float(rig.get("yaw")), 0.0)
	player.rotation.y = atan2(heading.x, heading.y)
	await _frames(45)


func _wait_calm() -> void:
	var surge := world.get_node_or_null(^"StormwoodSurge")
	if surge == null:
		return
	var phase := str(surge.get("phase"))
	if phase == "calm":
		return
	print("DISCLOSED SEAM 4: surge is %s; waiting for Calm at time_scale 8" % phase)
	Engine.time_scale = 8.0
	Engine.max_physics_steps_per_frame = 32
	for _frame in 60 * 60 * 10:
		await physics_frame
		if str(surge.get("phase")) == "calm":
			break
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8


# ------------------------------------------------------------------ input

func _approach_prompt(prompt: Node, at: Vector3) -> bool:
	if prompt == null:
		return false
	for _frame in 600:
		await physics_frame
		if arbiter.call("winning_provider") == prompt:
			_stick(0.0, 0.0)
			await _frames(4)
			if arbiter.call("winning_provider") == prompt:
				return true
		var flat := Vector3(at.x - player.global_position.x, 0.0, at.z - player.global_position.z)
		if flat.length() < 0.5:
			_stick(0.0, 0.0)
			continue
		navigator.call("push_once", flat.normalized() * 0.45)
	_stick(0.0, 0.0)
	return false


func _reward_item(pickup_id: String) -> String:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PICKUPS_PATH))
	for row: Dictionary in data.pickups:
		if str(row.id) == pickup_id:
			return str(row.item_id)
	return ""


func _on_refused(code: String, reason: String) -> void:
	_refusal = "%s: %s" % [code, reason]


func _press_interact() -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = &"interact"
		event.pressed = pressed
		event.strength = 1.0 if pressed else 0.0
		Input.parse_input_event(event)
		await _frames(3)


func _stick(x: float, y: float) -> void:
	for axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = x if axis == JOY_AXIS_LEFT_X else y
		Input.parse_input_event(event)


func _frames(count: int) -> void:
	for _frame in count:
		await physics_frame


func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)
	return condition


func _fail(message: String) -> void:
	failures.append(message)
	print("FAIL: ", message)


func _finish() -> void:
	if finished:
		return
	finished = true
	_stick(0.0, 0.0)
	print("Stormwood pocket walks smoke: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
