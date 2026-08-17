extends SceneTree

## OW5-walk. Walk the corridor with a real body and measure how long it is.
##
##   godot --headless --path . --script tools/_probe_ow5_walk.gd -- --mode=spine
##   godot --headless --path . --script tools/_probe_ow5_walk.gd -- --mode=cross
##
## Headless on purpose, and it is the one shape of Godot run where that is
## right: this renders nothing, and `tests/smoke_traversal.gd` -- the same kind
## of driven-body check -- runs headless in CI for the same reason. The repo's
## standing "never pass --headless" trap is about the RENDERING tools
## (`survey.gd`, `capture_site_shots.gd`); under xvfb + software GL a walk this
## long would take 25x as much wall clock and flake under load.
##
## Read the printed summary, not the exit code: Terrain3D aborts on shutdown by
## design (D06).
##
## WHY THIS EXISTS, and why it does not sample the heightfield.
##
## The corridor's length -- 11,516m of authored spine across five bands in
## `data/config/terrain_playground.json`'s `trail.bands` -- is arithmetic over
## a polyline. It is not a measurement of anything. The owner's target ("a walk
## from the end of the meadows to the other end should take 40 minutes", ~12km
## at `movement.json`'s 5.0 m/s walk_speed) is about what a body can actually
## travel, and a body does not travel a polyline: it climbs, it slides along
## slopes it cannot ascend, it detours around props, and it stops dead against
## things the config has no opinion about.
##
## Three separate investigations of the phantom wall were misled by
## `ground_height_at()`, which is analytic and does not know what the physics
## engine will do (see `ralph/NOTES.md`, WALL1/COLL1). So this measures
## `global_position` deltas of a body driven by `move_and_slide()` -- the real
## `Player`, through the real `player_controller.gd`, steered by the real
## camera basis -- and nothing else.
##
## WHY IT DRIVES THE REAL PLAYER RATHER THAN A FRESH CharacterBody3D.
##
## Terrain collision is DYNAMIC with a granted radius (ralph/BAKE-GUARDS §8.2):
## shapes exist only near the CAMERA, and `playground_world.gd` hands Terrain3D
## the player's own camera. A bespoke probe body would walk out of the collision
## bubble the camera never followed it into and fall through a world that is
## actually fine. Driving `Player` keeps the camera rig, the collision bubble
## and the measured body as one thing -- and gets the real capsule, the real
## `floor_max_angle`, the real `_try_step_up` ledge handling and the real
## satiety speed scale for free.
##
## Steering: `player_controller.gd::_apply_movement` builds its direction from
## `camera_rig.planar_basis()` (a yaw-only Basis) times the input vector, so
## holding `move_forward` and writing the rig's `yaw` each frame walks the body
## wherever we point it, through the entire real input path. `Basis(UP, yaw) *
## (0,0,-1)` is `(-sin yaw, 0, -cos yaw)`, hence the `atan2(-dx, -dz)` below.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CONFIG := "res://data/config/terrain_playground.json"
const MOVEMENT := "res://data/config/movement.json"

## Long enough for the world's own deferred build passes (village, warrens,
## stronghold, scatter) to finish before anything is measured. smoke_traversal
## uses 240 for the same reason.
const SETTLE_FRAMES := 240
## After a teleport, before walking again. Terrain3D rebuilds dynamic collision
## incrementally around the camera; walking on the first frame after a jump
## means walking before the ground under the new position exists.
const RESETTLE_FRAMES := 90

## How close counts as "reached this waypoint". Two metres is inside the
## capsule's own turning behaviour and well under the 20-80m spacing of the
## authored polyline, so it never cuts a corner the trail actually has.
const ARRIVE_M := 2.0

## Wedge detection. A body that has covered less than WEDGE_PROGRESS_M of
## ground toward its target across WEDGE_WINDOW frames is not walking, whatever
## `is_on_wall()` says. Measured against the TARGET, not against total
## displacement: a body skating in a circle against a prop covers plenty of
## distance and arrives nowhere, and that is exactly the failure mode this item
## is looking for.
const WEDGE_WINDOW := 90
const WEDGE_PROGRESS_M := 1.5

## Frames of escape attempt before a wedge is declared unrecoverable. The
## escape strafes and jumps, which is what a player does; if that clears it,
## the trail is walkable-but-awkward rather than blocked, and the difference
## matters to whoever fixes it.
const ESCAPE_FRAMES := 240

## Below this the body is definitionally through the floor. Same constant and
## same reasoning as `tests/smoke_traversal.gd`.
const THROUGH_THE_FLOOR := -80.0

var _mode := "spine"
var _speed := 0.0          ## 0 = leave walk_speed alone
var _max_frames := 0       ## 0 = no cap
var _z_from := -99999.0
var _z_to := 99999.0
var _label := ""

var _walk_speed_cfg := 5.0
var _day_length := 600.0


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.split("=", true, 1)
		var key := parts[0].lstrip("-")
		var val := parts[1] if parts.size() > 1 else ""
		match key:
			"mode": _mode = val
			"speed": _speed = float(val)
			"max_frames": _max_frames = int(val)
			"z_from": _z_from = float(val)
			"z_to": _z_to = float(val)
			"label": _label = val


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## The authored spine, five bands concatenated, with the shared band joins
## dropped so the same point is not a waypoint twice.
func _spine_points() -> Array[Vector2]:
	var cfg := _load_json(CONFIG)
	var trail: Dictionary = cfg.get("trail", {})
	var out: Array[Vector2] = []
	for band in trail.get("bands", []):
		for p in band.get("points", []):
			var v := Vector2(float(p[0]), float(p[1]))
			if out.is_empty() or out[out.size() - 1].distance_to(v) > 0.01:
				out.append(v)
	return out


func _config_length(points: Array[Vector2]) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	return total


func _run() -> void:
	_parse_args()

	var move_cfg := _load_json(MOVEMENT)
	_walk_speed_cfg = float((move_cfg.get("locomotion", {}) as Dictionary).get("walk_speed", 5.0))
	var art := _load_json("res://data/config/art.json")
	_day_length = float(art.get("day_length_seconds", 600.0))

	print("=== OW5-walk probe ===")
	print("mode=%s  speed_override=%s  walk_speed(cfg)=%.2f  day_length=%.0fs" % [
		_mode, ("none" if _speed <= 0.0 else "%.2f" % _speed), _walk_speed_cfg, _day_length])

	var boot_start := Time.get_ticks_msec()
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame
	print("world booted and settled in %.1fs" % ((Time.get_ticks_msec() - boot_start) / 1000.0))

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if player == null or rig == null or terrain == null:
		print("PROBE FAIL: scene is missing Player, CameraRig or Terrain")
		quit(1)
		return

	print("collision_mode=%d  granted radius=%d  granted shape_size=%d" % [
		int(terrain.get("collision_mode")),
		int(terrain.get("collision_radius")),
		int(terrain.get("collision_shape_size"))])

	if _speed > 0.0:
		player.set("_walk_speed", _speed)
		print("walk_speed overridden to %.2f m/s (distance is measured, not wall-clock)" % _speed)

	match _mode:
		"spine":
			await _walk_spine(world, player, rig)
		"cross":
			await _walk_cross(world, player, rig)
		_:
			print("PROBE FAIL: unknown mode %s" % _mode)
			quit(1)
			return

	quit(0)


## ---------------------------------------------------------------- the spine

func _walk_spine(world: Node, player: CharacterBody3D, rig: Node3D) -> void:
	var all_points := _spine_points()
	var points: Array[Vector2] = []
	for p in all_points:
		if p.y >= _z_from and p.y <= _z_to:
			points.append(p)
	if points.size() < 2:
		print("PROBE FAIL: z window [%.0f, %.0f] selects %d spine points" % [_z_from, _z_to, points.size()])
		quit(1)
		return

	print("spine: %d of %d authored points selected, config polyline length %.1fm" % [
		points.size(), all_points.size(), _config_length(points)])
	print("start (%.0f, %.0f) -> end (%.0f, %.0f)" % [
		points[0].x, points[0].y, points[points.size() - 1].x, points[points.size() - 1].y])

	var result := await _drive(world, player, rig, points, "spine")
	_report(result, _config_length(points))


## ------------------------------------------------------- side to side (width)

## Walk east and west from a spine station until the body stops making
## progress, and call the sum of the two the corridor's walkable width there.
##
## The world's authored bounds are x in [-1024, 1024] -- 2048m, which at 5 m/s
## is nearly 7 minutes, not the owner's "maybe five minutes of walking from side
## to side" (~1500m). But bounds are not width: `world_perimeter.gd` puts a
## collision edge inside them, and the terrain does its own blocking. This walks
## it rather than reading it.
func _walk_cross(world: Node, player: CharacterBody3D, rig: Node3D) -> void:
	var spine := _spine_points()
	# Three stations spread down the corridor: one per end and one mid. Taken
	# from the spine itself so each cross-walk starts somewhere a player
	# actually stands, not at an arbitrary x.
	var stations: Array[Vector2] = []
	for z in [900.0, 3600.0, 6400.0]:
		stations.append(_spine_point_near_z(spine, z))

	var totals: Array = []
	for st in stations:
		if st.y < _z_from or st.y > _z_to:
			continue
		print("\n--- cross station (%.0f, %.0f) ---" % [st.x, st.y])
		var legs := {}
		for dir_name in ["east", "west"]:
			var target_x := 1024.0 if dir_name == "east" else -1024.0
			var lane: Array[Vector2] = [st, Vector2(target_x, st.y)]
			var r := await _drive(world, player, rig, lane, "cross-%s@z%.0f" % [dir_name, st.y])
			legs[dir_name] = r
			print("  %s: walked %.1fm, reached x=%.1f, %s" % [
				dir_name, r["walked"], r["end"].x,
				("hit the edge" if r["blocked"] else "ran out of lane")])
		var width: float = float(legs["east"]["walked"]) + float(legs["west"]["walked"])
		totals.append({"z": st.y, "width": width})
		print("  WIDTH at z=%.0f: %.1fm  = %.1f min at %.1f m/s" % [
			st.y, width, width / _walk_speed_cfg / 60.0, _walk_speed_cfg])

	print("\n=== WIDTH SUMMARY ===")
	for t in totals:
		print("  z=%-6.0f  %8.1fm   %5.2f min at walk_speed %.1f" % [
			t["z"], t["width"], float(t["width"]) / _walk_speed_cfg / 60.0, _walk_speed_cfg])


func _spine_point_near_z(spine: Array[Vector2], z: float) -> Vector2:
	var best := spine[0]
	for p in spine:
		if absf(p.y - z) < absf(best.y - z):
			best = p
	return best


## ------------------------------------------------------------- the driving

## Drive the body through `points` and return what actually happened.
##
## Everything here is displacement of a body that ran `move_and_slide()`. No
## height query is used to decide anything about progress; `ground_height_at`
## appears only to place the body at the very start and to re-place it after an
## unrecoverable wedge, both of which are announced in the output.
func _drive(world: Node, player: CharacterBody3D, rig: Node3D,
		points: Array[Vector2], tag: String) -> Dictionary:
	var start := Vector3(points[0].x, 0.0, points[0].y)
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	rig.global_position = start
	for i in RESETTLE_FRAMES:
		await physics_frame

	var walked := 0.0          ## planar path length, summed per physics frame
	var walked_3d := 0.0
	var skipped := 0.0         ## metres handed over by an unrecoverable wedge
	var frames := 0
	var idx := 1
	var prev := player.global_position
	var wedges: Array = []
	var lowest := prev.y
	var fell_through := false
	var speed_scale_min := 1.0

	var window_start := prev
	var window_target_dist := Vector2(prev.x, prev.z).distance_to(points[idx])
	var window_frames := 0

	Input.action_press("move_forward")
	var run_start := Time.get_ticks_msec()

	while idx < points.size():
		if _max_frames > 0 and frames >= _max_frames:
			print("  [%s] frame cap %d reached" % [tag, _max_frames])
			break

		var pos := player.global_position
		var target := points[idx]
		var to_target := Vector2(target.x - pos.x, target.y - pos.z)

		if to_target.length() <= ARRIVE_M:
			idx += 1
			if idx >= points.size():
				break
			window_start = pos
			window_frames = 0
			window_target_dist = Vector2(pos.x, pos.z).distance_to(points[idx])
			continue

		rig.set("yaw", atan2(-to_target.x, -to_target.y))
		await physics_frame
		frames += 1

		var now := player.global_position
		var step := Vector2(now.x - prev.x, now.z - prev.z).length()
		# 1mm floor: a body standing still against a wall jitters, and summing
		# that jitter would inflate the corridor's length with metres nobody
		# walked.
		if step > 0.001:
			walked += step
			walked_3d += now.distance_to(prev)
		prev = now
		lowest = minf(lowest, now.y)

		var vitals: Object = player.get("vitals")
		if vitals != null and vitals.has_method("move_speed_scale"):
			speed_scale_min = minf(speed_scale_min, float(vitals.call("move_speed_scale")))

		if now.y < THROUGH_THE_FLOOR:
			print("  [%s] FELL THROUGH THE WORLD at (%.0f, %.0f), y=%.0f" % [tag, now.x, now.z, now.y])
			fell_through = true
			break

		window_frames += 1
		if window_frames >= WEDGE_WINDOW:
			var dist_now := Vector2(now.x, now.z).distance_to(points[idx])
			if window_target_dist - dist_now < WEDGE_PROGRESS_M:
				var wedge := _describe_wedge(player, now, points[idx], tag)
				var freed := await _escape(player, rig, points[idx])
				wedge["escaped"] = freed
				wedges.append(wedge)
				if not freed:
					# Hand the body forward rather than end the run: the item
					# wants the whole length AND the whole list of wedge sites,
					# and stopping at the first one delivers neither. The gap is
					# counted as skipped, never as walked.
					var jump_to := points[idx]
					var gap := Vector2(now.x, now.z).distance_to(jump_to)
					skipped += gap
					print("  [%s] SKIPPING %.1fm past the wedge to (%.0f, %.0f) -- this distance is NOT counted as walked" % [
						tag, gap, jump_to.x, jump_to.y])
					Input.action_release("move_forward")
					var landing := Vector3(jump_to.x, 0.0, jump_to.y)
					landing.y = float(world.call("ground_height_at", landing.x, landing.z)) + 1.0
					player.global_position = landing
					player.velocity = Vector3.ZERO
					rig.global_position = landing
					for i in RESETTLE_FRAMES:
						await physics_frame
					Input.action_press("move_forward")
					idx += 1
					if idx >= points.size():
						break
				prev = player.global_position
			window_start = player.global_position
			window_frames = 0
			window_target_dist = Vector2(window_start.x, window_start.z).distance_to(points[idx])

		if frames % 6000 == 0:
			print("  [%s] %6d frames  walked %8.1fm  at (%.0f, %.0f)  waypoint %d/%d  %.0fs elapsed" % [
				tag, frames, walked, prev.x, prev.z, idx, points.size(),
				(Time.get_ticks_msec() - run_start) / 1000.0])

	Input.action_release("move_forward")

	return {
		"walked": walked,
		"walked_3d": walked_3d,
		"skipped": skipped,
		"frames": frames,
		"wedges": wedges,
		"end": player.global_position,
		"lowest": lowest,
		"fell_through": fell_through,
		"blocked": idx < points.size(),
		"reached_index": idx,
		"total_points": points.size(),
		"speed_scale_min": speed_scale_min,
		"seconds": (Time.get_ticks_msec() - run_start) / 1000.0,
	}


## Name the collider, not the symptom.
##
## This is the technique that closed WALL1 after props, terrain slope and
## collision seams had each been confidently and wrongly blamed: every previous
## probe asked `is_on_wall()`, which is a boolean, and never asked what the body
## was on a wall AGAINST. The answer was an NPC capsule 3.15m off the reported
## coordinate, which no downward raycast could ever have found.
func _describe_wedge(player: CharacterBody3D, pos: Vector3, target: Vector2, tag: String) -> Dictionary:
	var colliders: Array[String] = []
	for i in player.get_slide_collision_count():
		var col := player.get_slide_collision(i)
		var obj := col.get_collider()
		var name_str := "<freed>"
		if obj != null:
			name_str = str(obj.get_path()) if obj is Node else str(obj)
		var normal := col.get_normal()
		colliders.append("%s  normal=(%.2f, %.2f, %.2f) angle_from_up=%.1f deg" % [
			name_str, normal.x, normal.y, normal.z, rad_to_deg(normal.angle_to(Vector3.UP))])

	print("  [%s] WEDGE at (%.1f, %.1f, %.1f) heading for (%.0f, %.0f)" % [
		tag, pos.x, pos.y, pos.z, target.x, target.y])
	print("       on_floor=%s on_wall=%s slide_collisions=%d" % [
		player.is_on_floor(), player.is_on_wall(), player.get_slide_collision_count()])
	if colliders.is_empty():
		print("       NO slide collision at all -- the body is not being stopped by a collider. "
			+ "Unclimbable slope, no ground, or friction, not a wall.")
	for c in colliders:
		print("       hit: %s" % c)

	return {
		"pos": pos,
		"target": target,
		"colliders": colliders,
		"on_floor": player.is_on_floor(),
		"on_wall": player.is_on_wall(),
		"tag": tag,
	}


## What a player does at a wedge: sidestep and hop. If this clears it the trail
## is passable-but-bad; if it does not, the trail is blocked there.
func _escape(player: CharacterBody3D, rig: Node3D, target: Vector2) -> bool:
	var origin := player.global_position
	Input.action_release("move_forward")
	var base := atan2(-(target.x - origin.x), -(target.y - origin.z))

	for attempt in 4:
		# Fan out further each attempt: 35, -35, 70, -70 degrees off the line.
		var offset := deg_to_rad(35.0 * float(attempt / 2 + 1) * (1.0 if attempt % 2 == 0 else -1.0))
		rig.set("yaw", base + offset)
		Input.action_press("move_forward")
		for i in int(ESCAPE_FRAMES / 4):
			if i % 20 == 0:
				Input.action_press("jump")
			else:
				Input.action_release("jump")
			await physics_frame
			var moved := Vector2(player.global_position.x, player.global_position.z).distance_to(
				Vector2(target.x, target.y))
			var was := Vector2(origin.x, origin.z).distance_to(target)
			if was - moved > WEDGE_PROGRESS_M * 2.0:
				Input.action_release("jump")
				Input.action_release("move_forward")
				print("       escaped by strafing %.0f deg off the line" % rad_to_deg(offset))
				return true
		Input.action_release("jump")
		Input.action_release("move_forward")

	print("       NOT escaped after %d frames of strafing and jumping" % ESCAPE_FRAMES)
	return false


func _report(r: Dictionary, config_length: float) -> void:
	var walked: float = r["walked"]
	var skipped: float = r["skipped"]
	print("\n=== RESULT ===")
	print("physics frames driven      : %d  (%.0fs of simulated time at 60Hz)" % [
		r["frames"], float(r["frames"]) / 60.0])
	print("wall-clock for the walk    : %.1f min" % (float(r["seconds"]) / 60.0))
	print("config polyline length     : %.1f m" % config_length)
	print("WALKED path length (planar): %.1f m" % walked)
	print("walked path length (3D)    : %.1f m" % r["walked_3d"])
	print("skipped past wedges        : %.1f m  (%d unrecoverable)" % [
		skipped, _unrecovered(r["wedges"])])
	print("waypoints reached          : %d / %d" % [r["reached_index"], r["total_points"]])
	print("end position               : (%.1f, %.1f, %.1f)" % [
		r["end"].x, r["end"].y, r["end"].z])
	print("lowest y                   : %.1f m   fell_through=%s" % [r["lowest"], r["fell_through"]])
	print("min satiety speed scale    : %.3f" % r["speed_scale_min"])

	# The three numbers the item asks for. Time is derived from the WALKED
	# distance and the CONFIGURED walk speed, never from the wall clock or from
	# whatever speed this run was driven at -- see the header.
	var minutes := walked / _walk_speed_cfg / 60.0
	var minutes_full := (walked + skipped) / _walk_speed_cfg / 60.0
	print("\nAt walk_speed %.1f m/s:" % _walk_speed_cfg)
	print("  walked distance          : %.1f min" % minutes)
	print("  walked + skipped         : %.1f min  (upper bound if the wedges were cleared)" % minutes_full)
	print("  in-game days elapsed     : %.2f  (day_length %.0fs)" % [
		(walked / _walk_speed_cfg) / _day_length, _day_length])

	print("\n=== WEDGE SITES (%d) ===" % r["wedges"].size())
	for w in r["wedges"]:
		var p: Vector3 = w["pos"]
		print("  (%.1f, %.1f) %s  floor=%s wall=%s  colliders=%d" % [
			p.x, p.z, ("ESCAPED" if w["escaped"] else "BLOCKED"),
			w["on_floor"], w["on_wall"], w["colliders"].size()])
		for c in w["colliders"]:
			print("      %s" % c)


func _unrecovered(wedges: Array) -> int:
	var n := 0
	for w in wedges:
		if not w["escaped"]:
			n += 1
	return n
