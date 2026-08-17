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

## A single physics tick that moves the body further than this did not walk.
##
## At walk_speed 5.0 a tick covers 0.083m and nothing in `player_controller.gd`
## can produce 2m in one step. What CAN is a script writing `global_position`
## directly, and the world does exactly that: `severed_spokes.gd`'s
## `CarveFailsafe` Area3D teleports the Player back to the near bank on
## `body_entered`, and `river.gd` builds a chain of them along the ENTIRE river
## course. Summing those jumps into the path length would have credited the
## corridor with metres nobody walked -- the first end-to-end run took 712 of
## them at one spot. Counted separately instead, because the count is itself a
## finding.
const TELEPORT_STEP_M := 2.0

## How many times the same spot may be re-attempted before the escape is
## declared a failure regardless of what it reports.
##
## `_escape` returns true when it gains ground toward the target, which is
## honest as far as it goes -- but at a `CarveFailsafe` the body gains that
## ground, gets teleported back, and gains it again forever. The first run
## logged 653 "escapes" at ONE crossing and would have run until its timeout.
## An escape that has to be repeated at the same place is not an escape.
const WEDGE_REPEAT_LIMIT := 6
## Two wedges closer together than this are the same wedge.
const WEDGE_SAME_SITE_M := 8.0

## SPINE-WEDGE. How many frames of history to dump when a wedge fires.
##
## `--trace=N`. Off by default because the whole-spine run prints enough
## already; a single-window run into one wedge site wants every frame.
##
## The reason this exists: `OW5-walk` could say a wedge ended with `on_floor=
## false` and ZERO slide colliders, and could not say what the body was doing
## for the second and a half before that. "Zero colliders" is four different
## defects wearing one face -- falling through absent collision, embedded in
## collision and being depenetrated, standing still with locomotion suspended,
## or oscillating on/off the floor -- and the trace is what tells them apart.
var _trace := 0

var _mode := "spine"
var _speed := 0.0          ## 0 = leave walk_speed alone
var _max_frames := 0       ## 0 = no cap
var _z_from := -99999.0
var _z_to := 99999.0
var _label := ""

var _walk_speed_cfg := 5.0
var _day_length := 600.0

## Set once in `_run` so `_describe_wedge` can reach the world without the
## driving loop threading three more arguments through every call.
var _world: Node = null
var _terrain: Node = null
var _camera: Node3D = null
var _player_shape: CollisionShape3D = null
## Ring buffer of per-frame state, `_trace` deep. Dumped at each wedge.
var _ring: Array = []


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
			"trace": _trace = int(val)
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

	# SPINE-WEDGE. Held for `_describe_wedge`'s deep probe. The camera matters
	# because Terrain3D builds dynamic collision around IT, not around the body:
	# a wedge whose camera is far from the body is a streaming question, and a
	# wedge whose camera is 5m behind it is not.
	_world = world
	_terrain = terrain
	_camera = world.get_node_or_null(^"CameraRig/Camera3D") as Node3D
	_player_shape = player.get_node_or_null(^"Collision") as CollisionShape3D
	if _player_shape == null:
		print("PROBE WARN: Player has no `Collision` child; overlap diagnosis disabled")

	if _speed > 0.0:
		player.set("_walk_speed", _speed)
		print("walk_speed overridden to %.2f m/s (distance is measured, not wall-clock)" % _speed)

	match _mode:
		"spine":
			await _walk_spine(world, player, rig)
		"cross":
			await _walk_cross(world, player, rig)
		"clear":
			_sweep_routes(world, player)
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
		var reach := {}
		var path := {}
		for dir_name in ["east", "west"]:
			var target_x := 1024.0 if dir_name == "east" else -1024.0
			var lane: Array[Vector2] = [st, Vector2(target_x, st.y)]
			var r := await _drive(world, player, rig, lane, "cross-%s@z%.0f" % [dir_name, st.y], true)
			# WIDTH is measured as x REACHED, not as path walked. A body that
			# strafes around a rock covers path length going nowhere across,
			# and the owner's "five minutes from side to side" is about how far
			# across the corridor is, not how far a wandering route is.
			reach[dir_name] = r["end"].x
			path[dir_name] = r["walked"]
			print("  %s: reached x=%.1f (%.1fm of x from the station), path walked %.1fm, %s" % [
				dir_name, r["end"].x, absf(r["end"].x - st.x), r["walked"],
				("stopped short of the lane end" if r["blocked"] else "walked the whole lane")])
		var width: float = float(reach["east"]) - float(reach["west"])
		totals.append({"z": st.y, "width": width, "east": reach["east"], "west": reach["west"],
			"path": float(path["east"]) + float(path["west"])})
		print("  WIDTH at z=%.0f: %.1fm (x %.1f to %.1f) = %.1f min at %.1f m/s" % [
			st.y, width, reach["west"], reach["east"],
			width / _walk_speed_cfg / 60.0, _walk_speed_cfg])

	print("\n=== WIDTH SUMMARY ===")
	for t in totals:
		print("  z=%-6.0f  x %8.1f .. %-8.1f  width %8.1fm   %5.2f min at walk_speed %.1f   (path walked %.1fm)" % [
			t["z"], t["west"], t["east"], t["width"],
			float(t["width"]) / _walk_speed_cfg / 60.0, _walk_speed_cfg, t["path"]])


func _spine_point_near_z(spine: Array[Vector2], z: float) -> Vector2:
	var best := spine[0]
	for p in spine:
		if absf(p.y - z) < absf(best.y - z):
			best = p
	return best


## ------------------------------------------------- does a body FIT along it

## How far apart to test the body's own capsule along an authored route.
##
## The capsule is 0.8m across, so 2m samples cannot miss anything a body would
## have to walk through -- a wall thin enough to fall between two samples is a
## wall thin enough that the samples either side of it overlap it.
const CLEAR_STEP_M := 2.0
## Ground clearance for the test capsule, matching where `_drive` drops the
## body to start a walk.
const CLEAR_LIFT_M := 1.0


## SPINE-WEDGE. Stand the player's own capsule at every point along every
## authored route and name everything solid it is standing inside.
##
##   godot --headless --path . --script tools/_probe_ow5_walk.gd -- --mode=clear
##
## WHY THIS IS SEPARATE FROM WALKING IT, and why walking it was not enough.
##
## `OW5-walk` walked the spine and reported four of its six blockages as
## "Terrain" at 4.6-17 degrees -- walkable angles, which made them read as a
## terrain defect. Three of the four were not terrain. `get_slide_collision()`
## reports what `move_and_slide` collided with DURING ITS MOTION, and a body
## that has already come fully to rest against a wall has no motion left: the
## wall drops out of the list and the floor it is standing on is all that
## remains. The technique that solved WALL1 -- name the collider -- is right,
## and on a STOPPED body it names the wrong one.
##
## A sweep does not have that problem, and neither does this: it asks the
## physics server what a body-shaped volume overlaps, at rest, everywhere the
## trail goes, in about a minute for 13 km. What a half-hour walk found four
## of, this finds all of, and names.
func _sweep_routes(world: Node, player: CharacterBody3D) -> void:
	var shape: CollisionShape3D = _player_shape
	if shape == null or shape.shape == null:
		print("PROBE FAIL: Player has no `Collision` child to sweep with")
		return
	var space := player.get_world_3d().direct_space_state
	var terrain_path := str(_terrain.get_path()) if _terrain != null else ""

	# Park the real body somewhere it cannot be its own answer.
	player.global_position = Vector3(0.0, 5000.0, 0.0)

	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape.shape
	q.collision_mask = player.collision_mask
	q.exclude = [player.get_rid()]

	var total := 0
	for route: Dictionary in _authored_routes():
		var points: Array = route["points"]
		if points.size() < 2:
			continue
		var hits := {}
		var samples := 0
		for i in range(points.size() - 1):
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var n := maxi(1, int(ceil(a.distance_to(b) / CLEAR_STEP_M)))
			for k in range(n + 1):
				var at: Vector2 = a.lerp(b, float(k) / float(n))
				var ground := float(world.call("ground_height_at", at.x, at.y))
				if is_nan(ground):
					continue
				samples += 1
				q.transform = Transform3D(Basis.IDENTITY,
					Vector3(at.x, ground + CLEAR_LIFT_M, at.y) + shape.position)
				for h in space.intersect_shape(q, 8):
					var o: Object = h.get("collider")
					if not o is Node:
						continue
					var path := str((o as Node).get_path())
					# The ground is not an obstruction; standing on it is the
					# point. Everything else along a road is.
					if path == terrain_path:
						continue
					if not hits.has(path):
						hits[path] = {"n": 0, "first": at, "last": at}
					hits[path]["n"] += 1
					hits[path]["last"] = at

		print("\n--- %s: %d samples every %.0f m ---" % [route["name"], samples, CLEAR_STEP_M])
		if hits.is_empty():
			print("  clear: a body-sized capsule fits the whole way")
			continue
		for path: String in hits:
			var e: Dictionary = hits[path]
			print("  %4d sample(s) INSIDE %s  from (%.1f, %.1f) to (%.1f, %.1f)" % [
				e["n"], path, e["first"].x, e["first"].y, e["last"].x, e["last"].y])
			total += 1
	print("\n=== %d route/collider pair(s) where a body does not fit ===" % total)


## Every route the game asks a player to walk: the spine, the ten regional
## loops and the two shortcuts. All authored the same way in the same file, so
## all of them get looked at the same way.
func _authored_routes() -> Array:
	var cfg := _load_json(CONFIG)
	var trail: Dictionary = cfg.get("trail", {})
	var out: Array = [{"name": "spine", "points": _spine_points()}]
	for key in ["loops", "shortcuts"]:
		for entry in trail.get(key, []):
			var pts: Array[Vector2] = []
			for p in (entry as Dictionary).get("points", []):
				pts.append(Vector2(float(p[0]), float(p[1])))
			out.append({"name": "%s:%s" % [key, str((entry as Dictionary).get("id", "?"))],
				"points": pts})
	return out


## ------------------------------------------------------------- the driving

## Drive the body through `points` and return what actually happened.
##
## Everything here is displacement of a body that ran `move_and_slide()`. No
## height query is used to decide anything about progress; `ground_height_at`
## appears only to place the body at the very start and to re-place it after an
## unrecoverable wedge, both of which are announced in the output.
## `stop_on_wedge` exists because the two modes want opposite things from a
## wedge. The spine wants the whole length and the whole list of sites, so an
## unrecoverable wedge hands the body forward to the next waypoint and the gap
## is booked as skipped. The cross-walk wants the opposite: its target is
## x = +/-1024, the world's authored bound, which is OUTSIDE the baked region
## grid (`ground_height_at` returns NaN from x=1022.5 on -- OW5E measured it).
## Teleporting there would drop the body into unbaked void and report a width
## that is an artefact of the probe. For a cross-walk, being stopped IS the
## measurement.
func _drive(world: Node, player: CharacterBody3D, rig: Node3D,
		points: Array[Vector2], tag: String, stop_on_wedge: bool = false) -> Dictionary:
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
	var teleported := 0.0      ## metres the WORLD moved the body, never walked
	var teleports := 0
	var repeat_at := Vector3.INF
	var repeat_count := 0
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
			# One line per waypoint reached, carrying the running total. This is
			# what lets the summary say WHERE the corridor is short rather than
			# only that it is: the 6000-frame progress lines resolve to ~500m,
			# which is wider than a whole band's shortfall.
			print("  [%s] wp %d/%d (%.0f, %.0f) reached  walked=%.1fm  frames=%d" % [
				tag, idx, points.size() - 1, target.x, target.y, walked, frames])
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
		# walked. The ceiling is the same argument at the other end -- see
		# TELEPORT_STEP_M; a `CarveFailsafe` recovery is not a stride.
		if step > TELEPORT_STEP_M:
			teleported += step
			teleports += 1
		elif step > 0.001:
			walked += step
			walked_3d += now.distance_to(prev)
		prev = now
		lowest = minf(lowest, now.y)

		if _trace > 0:
			_ring.append({
				"f": frames, "pos": now, "vel": player.velocity, "step": step,
				"floor": player.is_on_floor(), "wall": player.is_on_wall(),
				"n": player.get_slide_collision_count(),
				"first": _first_collider(player),
			})
			if _ring.size() > _trace:
				_ring.pop_front()

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
				if repeat_at != Vector3.INF and now.distance_to(repeat_at) < WEDGE_SAME_SITE_M:
					repeat_count += 1
				else:
					repeat_at = now
					repeat_count = 1

				var wedge := _describe_wedge(player, now, points[idx], tag)
				var freed := await _escape(player, rig, points[idx])
				if freed and repeat_count >= WEDGE_REPEAT_LIMIT:
					print("       ...but this is attempt %d at the same spot. Treating it as blocked: "
						% repeat_count
						+ "an escape that has to be repeated is not an escape.")
					freed = false
					repeat_at = Vector3.INF
					repeat_count = 0
				# `_escape` leaves every input released so its strafe cannot
				# bleed into the next frame's heading. Without this re-press the
				# body stands still after the first wedge it escapes, redetects
				# a wedge 90 frames later, and the walk quietly stops measuring
				# a corridor and starts measuring a probe bug.
				Input.action_press("move_forward")
				wedge["escaped"] = freed
				wedges.append(wedge)
				if not freed and stop_on_wedge:
					print("  [%s] stopped here -- this is the measurement, not a failure" % tag)
					prev = player.global_position
					break
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
		"teleported": teleported,
		"teleports": teleports,
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

	_deep_probe(player, target)
	_dump_ring(tag)

	return {
		"pos": pos,
		"target": target,
		"colliders": colliders,
		"on_floor": player.is_on_floor(),
		"on_wall": player.is_on_wall(),
		"tag": tag,
	}


## SPINE-WEDGE. Everything a slide-collision list cannot say.
##
## `OW5-walk` proved the technique that names the collider, and then hit four
## sites where the answer was "no collider at all". That answer is not a dead
## end and it is not one defect: a body reporting zero slide collisions and
## `on_floor=false` is EITHER falling through collision that does not exist,
## OR embedded in collision that does and being depenetrated back out every
## tick, OR standing still because something suspended its locomotion, OR
## simply airborne for one frame of a hop. Those want four different fixes and
## the printout could not tell them apart. Each query below separates one pair:
##
## 1. `intersect_shape` with the body's OWN capsule at its OWN transform names
##    every body it currently overlaps. Overlap with zero slide collisions is
##    the embedded case, and it is invisible to `get_slide_collision()` because
##    depenetration recovery is not reported as a slide.
## 2. `body_test_motion` with `recovery_as_collision = true` gives the DEPTH of
##    that overlap in metres -- the number that says how far inside.
## 3. A ray straight down says whether there is any ground under the body at
##    all, and how far. Used as identity and distance only, never to decide
##    whether the body can walk (D09/WALL1: rays and shape casts disagree, and
##    three investigations died believing the ray).
## 4. Camera-to-body distance, against the GRANTED collision radius. Terrain3D
##    streams collision around the camera; a body that has outrun its own
##    camera is standing over ground that has not been built.
## 5. `locomotion_enabled` and `is_carried` -- a body held still by a cutscene,
##    a fight or a mount looks exactly like a body held still by terrain.
func _deep_probe(player: CharacterBody3D, target: Vector2) -> void:
	print("       velocity=(%.2f, %.2f, %.2f) speed_h=%.2f" % [
		player.velocity.x, player.velocity.y, player.velocity.z,
		Vector3(player.velocity.x, 0.0, player.velocity.z).length()])

	var loco := "?"
	if player.has_method("locomotion_enabled"):
		loco = str(bool(player.call("locomotion_enabled")))
	var carried := "?"
	if player.has_method("is_carried"):
		carried = str(bool(player.call("is_carried")))
	print("       locomotion_enabled=%s  is_carried=%s  layer=%d mask=%d" % [
		loco, carried, player.collision_layer, player.collision_mask])

	var space := player.get_world_3d().direct_space_state

	if _player_shape != null and _player_shape.shape != null:
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = _player_shape.shape
		q.transform = _player_shape.global_transform
		q.collision_mask = player.collision_mask
		q.exclude = [player.get_rid()]
		var hits := space.intersect_shape(q, 16)
		if hits.is_empty():
			print("       capsule overlaps NOTHING -- the body is in free space, not embedded.")
		else:
			print("       capsule OVERLAPS %d body(ies) -- embedded, not blocked:" % hits.size())
			for h in hits:
				var o: Object = h.get("collider")
				print("         overlap: %s" % (str((o as Node).get_path()) if o is Node else str(o)))
			var rest := space.get_rest_info(q)
			if not rest.is_empty():
				var rn: Vector3 = rest.get("normal", Vector3.UP)
				print("         deepest contact at (%.2f, %.2f, %.2f) normal angle_from_up=%.1f deg" % [
					rest["point"].x, rest["point"].y, rest["point"].z,
					rad_to_deg(rn.angle_to(Vector3.UP))])

		# And every AREA the body is standing in. `OW5-walk` found that the
		# thing stopping a body can be an `Area3D` writing `global_position`
		# rather than anything solid -- and the inverse is just as useful:
		# a body stuck in a trench that HAS a recovery volume, and is not
		# inside it, says the volume is mis-sized rather than missing.
		q.collide_with_bodies = false
		q.collide_with_areas = true
		var areas := space.intersect_shape(q, 16)
		if areas.is_empty():
			print("       inside NO Area3D.")
		else:
			for h in areas:
				var a: Object = h.get("collider")
				print("       inside area: %s" % (str((a as Node).get_path()) if a is Node else str(a)))

	# Depth of penetration, in metres, through the same server call
	# `move_and_slide` uses -- so this agrees with the physics rather than
	# describing it from outside.
	var params := PhysicsTestMotionParameters3D.new()
	params.from = player.global_transform
	params.motion = Vector3.DOWN * 0.001
	params.recovery_as_collision = true
	var res := PhysicsTestMotionResult3D.new()
	if PhysicsServer3D.body_test_motion(player.get_rid(), params, res):
		print("       penetration depth %.4f m, recovery normal angle_from_up=%.1f deg" % [
			res.get_collision_depth(), rad_to_deg(res.get_collision_normal().angle_to(Vector3.UP))])
	else:
		print("       no penetration: a 1mm downward sweep hits nothing.")

	var origin := player.global_position + Vector3.UP * 0.9
	var down := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 200.0)
	down.exclude = [player.get_rid()]
	down.collision_mask = player.collision_mask
	var hit_down := space.intersect_ray(down)
	if hit_down.is_empty():
		print("       ray DOWN 200m from the body hits NOTHING -- there is no ground here at all.")
	else:
		var o: Object = hit_down.get("collider")
		print("       ray down: %s at %.3f m below the capsule centre, normal angle_from_up=%.1f deg" % [
			(str((o as Node).get_path()) if o is Node else str(o)),
			origin.y - float(hit_down["position"].y),
			rad_to_deg((hit_down["normal"] as Vector3).angle_to(Vector3.UP))])

	if _camera != null:
		var d := _camera.global_position.distance_to(player.global_position)
		var granted := int(_terrain.get("collision_radius")) if _terrain != null else -1
		print("       camera is %.1f m from the body (granted collision radius %d m)" % [d, granted])

	# Is the body still being ASKED to walk? A body that has stopped because
	# nothing is telling it to move looks identical, from outside, to a body
	# that has stopped because something is in the way -- and this probe drives
	# the real input path, so the input is a thing that can go wrong.
	var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	print("       input vector=(%.2f, %.2f)  fwd=%s back=%s left=%s right=%s" % [
		stick.x, stick.y,
		Input.is_action_pressed("move_forward"), Input.is_action_pressed("move_back"),
		Input.is_action_pressed("move_left"), Input.is_action_pressed("move_right")])

	# And finally: sweep the capsule the way it is trying to go, and name what
	# it hits. This is the query that had no equivalent in `OW5-walk`. Its four
	# blockages that reported only floor-angle normals were not a mystery about
	# terrain -- they were a body pressed against something `move_and_slide`
	# had already stopped reporting, and a half-metre sweep names it outright.
	var heading := Vector3(target.x - player.global_position.x, 0.0,
		target.y - player.global_position.z)
	if heading.length() > 0.001:
		heading = heading.normalized()
		var sweep := PhysicsTestMotionParameters3D.new()
		sweep.from = player.global_transform
		sweep.motion = heading * 0.5
		sweep.max_collisions = 4
		var out := PhysicsTestMotionResult3D.new()
		if PhysicsServer3D.body_test_motion(player.get_rid(), sweep, out):
			print("       0.5 m sweep toward the target is BLOCKED after %.3f m, %d contact(s):" % [
				out.get_travel().length(), out.get_collision_count()])
			for i in out.get_collision_count():
				var who: Object = out.get_collider(i)
				var n := out.get_collision_normal(i)
				print("         blocker: %s  normal=(%.2f, %.2f, %.2f) angle_from_up=%.1f deg" % [
					(str((who as Node).get_path()) if who is Node else str(who)),
					n.x, n.y, n.z, rad_to_deg(n.angle_to(Vector3.UP))])
		else:
			print("       0.5 m sweep toward the target is CLEAR -- nothing is in the way at all.")


## The one-line identity of whatever the body hit hardest this frame, for the
## per-frame trace. Full detail belongs in `_describe_wedge`; this has to be
## cheap enough to build every physics tick.
func _first_collider(player: CharacterBody3D) -> String:
	if player.get_slide_collision_count() == 0:
		return "-"
	var col := player.get_slide_collision(0)
	var obj := col.get_collider()
	var nm: String = (obj as Node).name if obj is Node else "<obj>"
	return "%s@%.0f" % [nm, rad_to_deg(col.get_normal().angle_to(Vector3.UP))]


## Dump the trace. A wedge is the END of a story and the interesting part is
## the second before it: whether the body decelerated into something, dropped,
## or was simply switched off.
func _dump_ring(tag: String) -> void:
	if _ring.is_empty():
		return
	print("       --- last %d frames [%s] ---" % [_ring.size(), tag])
	print("       %6s %9s %9s %9s %7s %6s %5s %5s %2s %s" % [
		"frame", "x", "y", "z", "step", "vy", "floor", "wall", "n", "hit"])
	for r in _ring:
		var p: Vector3 = r["pos"]
		print("       %6d %9.2f %9.2f %9.2f %7.3f %6.2f %5s %5s %2d %s" % [
			r["f"], p.x, p.y, p.z, r["step"], r["vel"].y,
			("Y" if r["floor"] else "."), ("Y" if r["wall"] else "."),
			r["n"], r["first"]])
	_ring.clear()


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
	print("moved BY THE WORLD         : %.1f m over %d teleports  (CarveFailsafe recoveries; never counted as walked)" % [
		r["teleported"], r["teleports"]])
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
