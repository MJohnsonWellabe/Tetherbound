extends SceneTree

## SA4 — does each severed spoke actually stop the player?
##
##   godot --headless --path . --script tools/_probe_sa4.gd
##
## The claim SA4 makes is physical, not decorative: seven old roads leave the
## Meadows and something on each one refuses to let you follow it. A render can
## show the gorge; only a body walking into it can show it is a wall. So this
## drives the REAL player controller down each spoke's own road, on that road's
## own bearing, at the real walk speed — the same harness `smoke_traversal.gd`
## uses for its perimeter bearings, for the same reason: hand-rolled motion
## proves nothing about `floor_max_angle`.
##
## Pass condition per spoke: starting `RUN_UP` metres short of the blocker and
## walking straight at it for `WALK_FRAMES`, the player's progress ALONG the
## road must stop short of `PASS_MARGIN` past the blocker's centre. Two of the
## blockers are terrain (a carve steeper than the 45-degree limit) and four are
## colliding bodies, and this does not care which: it only asks whether the
## road is still a road.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const CONFIG := "res://data/config/terrain_playground.json"
const SETTLE_FRAMES := 240
## Long enough to cover RUN_UP several times over at walk speed, so a spoke that
## fails does so because it is passable, never because the walk was too short.
const WALK_FRAMES := 900
const RUN_UP := 16.0
## How far past the blocker's centre counts as "through". The carves are 10-18m
## wide rim to rim and the built barriers 1-3m thick, so a body that gets this
## far past the centre line is out the other side on any of them.
const PASS_MARGIN := 8.0
const THROUGH_THE_FLOOR := -80.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var camera_rig: Node = world.get_node_or_null(^"CameraRig")
	if player == null or camera_rig == null:
		print("sa4 probe FAIL: scene is missing the player or the camera rig")
		quit(1)
		return

	var spokes: Dictionary = _load_spokes()
	var routes: Array = spokes.get("routes", [])
	var failures: Array[String] = []
	var checked := 0

	for entry: Variant in routes:
		if not entry is Dictionary:
			continue
		var spoke: Dictionary = entry as Dictionary
		var id := str(spoke.get("id", "?"))
		if not bool(spoke.get("built", false)):
			failures.append("%s is not built — SA4 wants all seven standing" % id)
			continue
		var target := _blocker_centre(spoke)
		if target == Vector2.INF:
			failures.append("%s has no blocker centre to walk at" % id)
			continue

		# The approach direction is the road's OWN last leg, not the bearing:
		# the road is what the player follows, and a spoke whose final leg
		# curves off its nominal bearing would otherwise be probed off-road.
		var road: Array = spoke.get("road", [])
		if road.size() < 2:
			failures.append("%s has no road to walk" % id)
			continue
		var last := _vec2(road[road.size() - 1])
		var prev := _vec2(road[road.size() - 2])
		var outward := (last - prev).normalized()
		var start_xz := target - outward * RUN_UP
		var ground: float = float(world.call("ground_height_at", start_xz.x, start_xz.y))
		if is_nan(ground):
			failures.append("%s: no ground at its own run-up point %.0f, %.0f" % [
				id, start_xz.x, start_xz.y])
			continue

		player.global_position = Vector3(start_xz.x, ground + 1.0, start_xz.y)
		player.velocity = Vector3.ZERO
		var heading := Vector3(outward.x, 0.0, outward.y)
		camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(heading, Vector3.UP))
		for i in 20:
			await physics_frame

		Input.action_press("move_forward")
		var furthest := -RUN_UP
		for i in WALK_FRAMES:
			await physics_frame
			var here := player.global_position
			# Progress measured along the approach, relative to the blocker's
			# centre: negative is short of it, positive is past it. The high
			# water mark, not the final position — a player who gets across and
			# then wanders back has still crossed.
			var progress := (Vector2(here.x, here.z) - target).dot(outward)
			furthest = maxf(furthest, progress)
			if here.y < THROUGH_THE_FLOOR:
				break
		Input.action_release("move_forward")
		for i in 20:
			await physics_frame

		var final_pos := player.global_position
		checked += 1
		var verdict := "HELD" if furthest < PASS_MARGIN else "PASSED"
		print("  %-16s %s  furthest %+6.1fm relative to the blocker (limit %+.1f), ended at %6.1f, %6.1f, %6.1f" % [
			id, verdict, furthest, PASS_MARGIN, final_pos.x, final_pos.y, final_pos.z])
		if furthest >= PASS_MARGIN:
			failures.append("%s: the player walked %.1fm past the blocker — the road is not severed" % [
				id, furthest])
		if final_pos.y < THROUGH_THE_FLOOR:
			failures.append("%s: the player fell through the world at the blocker (y=%.0f)" % [
				id, final_pos.y])

	print("")
	if failures.is_empty():
		print("sa4 probe: OK — all %d spokes are built and every one of them holds." % checked)
		quit(0)
		return
	for line: String in failures:
		print("sa4 probe FAIL: %s" % line)
	quit(1)


## Where to aim. Terrain blockers keep their centre inside `carve`; the built
## ones carry it on the blocker itself.
func _blocker_centre(spoke: Dictionary) -> Vector2:
	var blocker: Dictionary = spoke.get("blocker", {})
	var carve: Dictionary = blocker.get("carve", {})
	if carve.has("centre"):
		return _vec2(carve["centre"])
	if blocker.has("centre"):
		return _vec2(blocker["centre"])
	return Vector2.INF


func _vec2(raw: Variant) -> Vector2:
	var array: Array = raw as Array if raw is Array else []
	if array.size() < 2:
		return Vector2.INF
	return Vector2(float(array[0]), float(array[1]))


func _load_spokes() -> Dictionary:
	var file := FileAccess.open(CONFIG, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	return (parsed as Dictionary).get("spokes", {})
