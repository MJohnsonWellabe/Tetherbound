extends SceneTree

## RIVER-GATE. What the river's recovery chain actually covers, and whether a
## body can walk the one authored crossing through it.
##
##   godot --headless --path . --script tools/_probe_river_gate.gd -- --mode=survey
##   godot --headless --path . --script tools/_probe_river_gate.gd -- --mode=walk
##   godot --headless --path . --script tools/_probe_river_gate.gd -- --mode=unit
##
## WHAT IT FOUND, so the next person does not have to re-run it to know:
##
##   * Both crossings walk correctly in both lock states, on unmodified `main`.
##     South Bridge -9.1m locked / +22.9m unlocked, Old Mill Crossing -8.0m /
##     +23.7m, ZERO world teleports at either. `RIVER-GATE` was filed on the
##     belief that the Old Mill Crossing could not be crossed; it can.
##   * The chain does overlap the Old Mill deck in plan — the middle 11.0m of
##     the 18.4m span — but the deck stands 5.10m above the volumes' ceiling,
##     so a body on the span never enters one. See `D56`.
##   * The 712 teleports `OW5-walk` measured are the SPINE, not the crossing:
##     11m of Band 3 trail at x=-150 lies inside a river volume, and the deck's
##     centreline is at x=-152.
##   * 16m of Band 5's spine lies inside the storm road spoke's own recovery
##     volume, whose recovery point (-34.0, 7513.5) is exactly `OW5-walk`'s
##     "stronghold gate approach" wedge. That site is very likely not terrain.
##
## Headless is right here for `tools/_probe_ow5_walk.gd`'s reason: this renders
## nothing, and the repo's standing "never pass --headless" trap is about the
## rendering tools. Read the printed summary, not the exit code — Terrain3D
## aborts on shutdown by design (D06).
##
## WHY IT DOES NOT USE `get_slide_collision()` OR `ground_height_at()`.
##
## `OW5-walk` established both. Nothing is TOUCHING a body that a
## `CarveFailsafe` moves — the Area3D writes `global_position` on
## `body_entered`, so `get_slide_collision()` returns zero colliders and
## `is_on_wall()` is false while the body goes nowhere. And `ground_height_at`
## is analytic and misled three separate investigations of the phantom wall.
##
## So the walk mode detects the world moving the body the only honest way
## there is: a single physics tick that displaces the body further than
## `player_controller.gd` can possibly move it in one tick is not walking.
##
## Survey mode does not drive anything. It reads the volumes the world
## actually built — position, size, yaw, owner — and asks whether specific
## world points are inside them, which is the question "does the chain span
## the crossing" reduced to arithmetic over real runtime geometry rather than
## over the config the geometry was derived from. It then does the same for
## every leg of the authored spine, which is a map-wide answer to "does any
## recovery volume swallow a route it should not" and is what found the
## storm road above.
##
## Unit mode boots no scene at all. It runs ONE `tests/test_*.gd` file the way
## `tests/run_tests.gd` runs it, because that runner has no filter and takes
## ~25 minutes on this box; this is the same assertions in seconds while
## iterating on the thing they are about.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## Long enough for the world's own deferred build passes to finish. Same
## number and same reason as `tools/_probe_ow5_walk.gd` and `smoke_traversal`.
const SETTLE_FRAMES := 240
const RESETTLE_FRAMES := 90

## See `_probe_ow5_walk.gd`'s own constant: at walk_speed 5.0 a physics tick
## covers 0.083m and nothing in `player_controller.gd` can produce 2m in one
## step. What can is a script writing `global_position`.
const TELEPORT_STEP_M := 2.0

## The walk: start this far back on the village side, aim at the same distance
## past. `smoke_traversal.gd`'s own BRIDGE_START_BACK, so the two agree.
const START_BACK := 11.0
const WALK_FRAMES := 420

var _mode := "survey"


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.split("=", true, 1)
		var key := parts[0].lstrip("-")
		var val := parts[1] if parts.size() > 1 else ""
		if key == "mode":
			_mode = val


func _run() -> void:
	_parse_args()
	print("=== RIVER-GATE probe (mode=%s) ===" % _mode)

	# The geometry check needs no scene at all, so it does not pay for one.
	# `tests/run_tests.gd` runs the whole suite (~25 minutes on this box) and
	# has no filter; this is the same file's assertions in a few seconds while
	# iterating on the thing they are about.
	if _mode == "unit":
		quit(1 if _run_one_test_file("res://tests/test_river_crossings_stay_open.gd") > 0 else 0)
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if player == null or rig == null:
		print("PROBE FAIL: scene is missing Player or CameraRig")
		quit(1)
		return

	match _mode:
		"survey":
			_survey(world)
		"walk":
			await _walk(world, player, rig)
		_:
			print("PROBE FAIL: unknown mode %s" % _mode)
			quit(1)
			return
	quit(0)


## One `tests/test_*.gd` file, run the way `tests/run_tests.gd` runs it.
## Returns the number of failed methods.
func _run_one_test_file(path: String) -> int:
	var script: GDScript = load(path)
	if script == null or not script.can_instantiate():
		print("  FAIL  %s :: could not be parsed" % path)
		return 1
	var instance: Object = script.new()
	var failed := 0
	for method: Dictionary in script.get_script_method_list():
		if not str(method["name"]).begins_with("test_"):
			continue
		instance.failures.clear()
		instance.before_each()
		instance.callv(str(method["name"]), [])
		instance.after_each()
		if instance.failures.is_empty():
			print("  ok    %s" % method["name"])
		else:
			failed += 1
			print("  FAIL  %s" % method["name"])
			for message: String in instance.failures:
				print("          %s" % message)
	print("%d failed" % failed)
	return failed


## ------------------------------------------------------------------ survey

func _survey(world: Node) -> void:
	var areas := _failsafes(world)
	print("%d CarveFailsafe volumes in the scene" % areas.size())
	for area: Area3D in areas:
		var shape: CollisionShape3D = area.get_child(0) as CollisionShape3D
		var box: BoxShape3D = shape.shape as BoxShape3D if shape != null else null
		if box == null:
			print("  %-46s (no box shape)" % _owner_label(area))
			continue
		var to: Vector3 = area.get_meta("recover_to", Vector3.ZERO)
		print("  %-46s at (%8.1f,%7.2f,%8.1f) size (%6.1f,%5.1f,%5.1f) yaw %6.1f -> back to (%.1f, %.1f)" % [
			_owner_label(area), area.global_position.x, area.global_position.y, area.global_position.z,
			box.size.x, box.size.y, box.size.z, rad_to_deg(area.global_rotation.y), to.x, to.z])

	for id: String in ["MillCrossing", "SouthBridge"]:
		var crossing: Node3D = world.get_node_or_null(NodePath(id)) as Node3D
		if crossing == null:
			print("\n[%s] NOT IN THE SCENE" % id)
			continue
		var centre: Vector2 = crossing.call("crossing_centre")
		var deck_y: float = crossing.global_position.y
		print("\n[%s] centre (%.1f, %.1f), deck y %.2f, open=%s" % [
			id, centre.x, centre.y, deck_y, crossing.call("is_open")])
		print("  near_point(11) = %s   far_point(11) = %s" % [
			crossing.call("near_point", 11.0), crossing.call("far_point", 11.0)])

		# The deck line, sampled at the height a body standing on the deck
		# occupies: deck surface 0.12 above the node, plus half a capsule.
		var probe_y := deck_y + 0.12 + 0.9
		print("  --- along the deck centreline at y %.2f (a body standing on the span)" % probe_y)
		_report_line(areas, world, crossing, centre, 0.0, probe_y)

		# The same line, but at whatever height the GROUND is — which is what a
		# body walking the approach is at, and what a body that went over the
		# edge ends up near.
		print("  --- the same line, a capsule's half-height above the ground")
		_report_line(areas, world, crossing, centre, 0.0, NAN)

		# And 2m to one side of it, which is where the authored spine crosses
		# the river: trail.bands band3 runs x=-150 while this deck sits at
		# x=-152. Reported, not fixed — `trail.bands[]` is another lane's.
		print("  --- 2.0m off the deck along the channel, above the ground")
		_report_line(areas, world, crossing, centre, 2.0, NAN)

	_report_spine(areas, world)


## Every stretch of the authored corridor spine that runs through a recovery
## volume — the river's chain, a crossing's gully, or a severed spoke's gorge.
##
## This is the question `RIVER-GATE`'s brief actually asked: does the chain
## swallow anything it should not, anywhere. A volume is invisible, silent, has
## no collider, and moves the body rather than blocking it, so a stretch of
## authored trail running through one reads to every other tool on this project
## as terrain that is somehow unwalkable. `OW5-walk` had to invent a
## teleport counter to see it at all.
func _report_spine(areas: Array, world: Node) -> void:
	var config: Dictionary = _load_json("res://data/config/terrain_playground.json")
	var bands: Array = (config.get("trail", {}) as Dictionary).get("bands", [])
	print("\n[spine] stretches of the authored trail that run through a recovery volume")
	var found := 0
	for band: Variant in bands:
		var points: Array = (band as Dictionary).get("points", [])
		for i in points.size() - 1:
			var pa := Vector2(float(points[i][0]), float(points[i][1]))
			var pb := Vector2(float(points[i + 1][0]), float(points[i + 1][1]))
			var length := pa.distance_to(pb)
			if length <= 0.001:
				continue
			var from := Vector2.INF
			var to := Vector2.INF
			var who := ""
			for s in int(length) + 1:
				var at := pa.lerp(pb, float(s) / length)
				var y := float(world.call("ground_height_at", at.x, at.y))
				var inside := _containing(areas, Vector3(at.x, y + 0.9, at.y)) if not is_nan(y) else ([] as Array[String])
				if inside.is_empty():
					if from != Vector2.INF:
						found += 1
						print("  %-28s %5.0fm of trail from (%.0f, %.0f) to (%.0f, %.0f) inside %s" % [
							band["id"], from.distance_to(to) + 1.0, from.x, from.y, to.x, to.y, who])
						from = Vector2.INF
					continue
				if from == Vector2.INF:
					from = at
					who = inside[0]
				to = at
			if from != Vector2.INF:
				found += 1
				print("  %-28s %5.0fm of trail from (%.0f, %.0f) to (%.0f, %.0f) inside %s" % [
					band["id"], from.distance_to(to) + 1.0, from.x, from.y, to.x, to.y, who])
	if found == 0:
		print("  none — no authored spine leg passes through a recovery volume")


func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## Walk the crossing's own line from the village side to the far side, and say
## which volumes a point on it falls inside. `offset` slides the whole line
## along the channel axis; a NAN `y` samples the ground instead of a fixed
## height and stands a capsule's half-height on it.
func _report_line(areas: Array, world: Node, crossing: Node3D, centre: Vector2,
		offset: float, y: float) -> void:
	var near1: Vector2 = crossing.call("near_point", 1.0)
	var across := (centre - near1).normalized()
	var along := Vector2(-across.y, across.x)
	var hits := 0
	for step in range(-14, 15):
		var at := centre + across * float(step) + along * offset
		var height := y
		if is_nan(height):
			height = float(world.call("ground_height_at", at.x, at.y)) + 0.9
		var inside := _containing(areas, Vector3(at.x, height, at.y))
		if inside.is_empty():
			continue
		hits += 1
		print("    %+3dm past the centre (%.1f, %.1f) y %.2f is INSIDE %s" % [
			step, at.x, at.y, height, ", ".join(inside)])
	if hits == 0:
		print("    clear: no point on this line is inside any recovery volume")


## Every recovery volume in the scene, found by what it IS rather than by what
## it is called.
##
## `_add_carve_failsafe` names every one of them "CarveFailsafe" and puts them
## all in one holder, and Godot's fast rename path turns each collision into
## `@CarveFailsafe@NNNN` — the same shape as the `@StaticBody3D@3458` collider
## `OW5-walk` logged at the Warrens. So `name == "CarveFailsafe"` matches
## exactly one volume per holder: it found 4 of 19 here and cheerfully reported
## the crossing deck clear of a chain it had not looked at. `begins_with` is no
## better, because the `@` comes first.
##
## The `recover_to` meta is the volume's actual identity — it is the thing that
## makes one of these a recovery volume rather than any other Area3D.
func _failsafes(node: Node) -> Array:
	var out: Array = []
	if node is Area3D and node.has_meta("recover_to"):
		out.append(node)
	for child: Node in node.get_children():
		out.append_array(_failsafes(child))
	return out


## Which volumes contain `point`, by name. Box containment in the area's own
## frame — the areas are boxes and this is the same test the physics server
## makes, without needing a body to be there.
func _containing(areas: Array, point: Vector3) -> Array[String]:
	var out: Array[String] = []
	for area: Area3D in areas:
		var shape: CollisionShape3D = area.get_child(0) as CollisionShape3D
		if shape == null or not shape.shape is BoxShape3D:
			continue
		var half: Vector3 = (shape.shape as BoxShape3D).size * 0.5
		var local: Vector3 = area.global_transform.affine_inverse() * point
		if absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z:
			out.append(_owner_label(area))
	return out


## Which builder put this volume here — the river's chain, a crossing's own
## gully volume, or a severed spoke's.
func _owner_label(area: Area3D) -> String:
	var path := str(area.get_path())
	var parts := path.split("/")
	var tail := parts.slice(maxi(parts.size() - 3, 0))
	return "/".join(tail)


## -------------------------------------------------------------------- walk

func _walk(world: Node, player: CharacterBody3D, rig: Node3D) -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("PROBE FAIL: no Game autoload")
		return
	var inventory: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")

	for spec: Array in [
		["SouthBridge", "south_bridge_key"],
		["MillCrossing", "mill_bridge_gear"],
	]:
		var id: String = spec[0]
		var key: String = spec[1]
		var crossing: Node3D = world.get_node_or_null(NodePath(id)) as Node3D
		if crossing == null:
			print("\n[%s] NOT IN THE SCENE" % id)
			continue
		var prompt: Node3D = crossing.get_node_or_null(^"Interactable") as Node3D

		print("\n[%s] locked" % id)
		var carried := int(inventory.call("count", key))
		if carried > 0:
			inventory.call("remove", key, carried)
		if prompt != null:
			prompt.call("interaction_activate")
		await physics_frame
		var locked := await _one_walk(world, crossing, player, rig)
		print("  locked:   reached %+.1fm past the gap, %d world teleports, open=%s" % [
			locked[0], locked[1], crossing.call("is_open")])

		inventory.call("add", key, 1)
		if prompt != null:
			prompt.call("interaction_activate")
		await physics_frame
		var open := await _one_walk(world, crossing, player, rig)
		print("  unlocked: reached %+.1fm past the gap, %d world teleports, open=%s" % [
			open[0], open[1], crossing.call("is_open")])
		if progression != null:
			print("  flag set: %s" % progression.call("has",
				"south_bridge_open" if id == "SouthBridge" else "mill_crossing_restored"))


## One held-forward walk at a crossing. Returns [furthest depth past the gap,
## number of ticks in which the WORLD moved the body rather than the body
## walking]. See TELEPORT_STEP_M.
func _one_walk(world: Node, crossing: Node3D, player: CharacterBody3D, rig: Node3D) -> Array:
	var start: Vector2 = crossing.call("near_point", START_BACK)
	var target: Vector2 = crossing.call("far_point", START_BACK)
	var ground: float = float(world.call("ground_height_at", start.x, start.y))
	player.global_position = Vector3(start.x, ground + 1.0, start.y)
	player.velocity = Vector3.ZERO
	var outward := Vector3(target.x - start.x, 0.0, target.y - start.y).normalized()
	rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
	for i in RESETTLE_FRAMES:
		await physics_frame

	var best := -INF
	var teleports := 0
	var previous := player.global_position
	Input.action_press("move_forward")
	for i in WALK_FRAMES:
		await physics_frame
		var here := player.global_position
		if previous.distance_to(here) > TELEPORT_STEP_M:
			teleports += 1
		previous = here
		best = maxf(best, float(crossing.call("depth_past_crossing", Vector2(here.x, here.z))))
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame
	return [best, teleports]
