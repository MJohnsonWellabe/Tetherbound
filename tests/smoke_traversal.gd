extends SceneTree

## Can the player cross the whole playground without falling through it?
##
##   godot --headless --path . --script tests/smoke_traversal.gd
##
## This exists because of a bug that every other check passed. Terrain3D's
## `collision_mode` silently reverted to Dynamic/Game, which builds collision
## only inside a 64m radius. The terrain rendered, the player spawned on solid
## ground, the smoke test confirmed they were standing on it, and the input test
## confirmed they moved — all true, all inside the bubble. Two hundred metres
## out the ground stopped existing and the player fell to y = -49950 at
## terminal velocity.
##
## The lesson is about test DISTANCE, not about terrain. A traversal check that
## walks thirteen metres proves the spawn point works and nothing else. This one
## walks far enough to leave any plausible bubble, and asserts the terrain is
## solid the entire way.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
## Physics ticks per leg. At the configured walk speed this is roughly 190m,
## comfortably past the 64m dynamic radius that caused the original bug.
const LEG_FRAMES := 2700
## Below this the player is definitionally through the floor: the whole
## playground's lowest point is about -26m.
const THROUGH_THE_FLOOR := -80.0
const COLLISION_FULL_GAME := 3
## The baked world spans ±256m (terrain_playground.json world_size 512, centred
## on the origin). A leg that reaches this line stops early: past the rim there
## is legitimately no ground, and walking off it reads as "fell through the
## world" when nothing is wrong. CI hit exactly that — the forward leg from the
## (60, -60) start crossed z = -256 unobstructed and fell off the north rim,
## while the same leg on a local run happened to snag on the rocky rise and
## never got there. The margin keeps the player clear of edge interpolation.
const WORLD_EDGE := 240.0


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if player == null or terrain == null:
		print("traversal FAIL: scene is missing the player or the terrain")
		quit(1)
		return

	# Out of the farmhouse. The opening's staging wakes the player in
	# Grandpa's bed, and this test is about the TERRAIN — four long walks that
	# start inside a building end at its walls and prove nothing. Open meadow,
	# clear of the village, the rises and the pond.
	var start := Vector3(60.0, 0.0, -60.0)
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var failures: Array[String] = []

	# The direct cause, asserted directly. Everything below is the symptom.
	var mode: int = int(terrain.get("collision_mode"))
	print("collision_mode = %d (want %d, Full/Game)" % [mode, COLLISION_FULL_GAME])
	if mode != COLLISION_FULL_GAME:
		failures.append("collision_mode is %d, not Full/Game; collision exists only near the player" % mode)

	var furthest := 0.0
	var lowest := player.global_position.y
	var ungrounded_streak := 0
	var worst_streak := 0
	# Where the worst ungrounded run happened, and whether the player was
	# LOSING HEIGHT during it.
	#
	# Without this the failure message is unfalsifiable: "the ground is not
	# continuous" was reported on runs where the player never went below
	# y = -0.4m, i.e. never fell anywhere, which the message cannot explain and
	# nobody can act on. It also flapped — the same commit passed and failed —
	# so a report that names a place and a direction is the difference between
	# fixing it and arguing about it.
	var streak_start := Vector3.ZERO
	var streak_start_y := 0.0
	var worst_start := Vector3.ZERO
	var worst_drop := 0.0
	## Deepest the player ever got BELOW the terrain surface under them.
	var below := 0.0

	for direction in ["move_forward", "move_right", "move_back", "move_left"]:
		Input.action_press(direction)
		for i in LEG_FRAMES:
			await physics_frame
			var pos := player.global_position
			furthest = maxf(furthest, Vector2(pos.x, pos.z).length())
			lowest = minf(lowest, pos.y)

			# A jump or a slope crest legitimately leaves the floor for a few
			# frames. Falling through does not come back.
			if player.is_on_floor():
				ungrounded_streak = 0
			else:
				if ungrounded_streak == 0:
					streak_start = pos
					streak_start_y = pos.y
				ungrounded_streak += 1
				if ungrounded_streak > worst_streak:
					worst_streak = ungrounded_streak
					worst_start = streak_start
					worst_drop = streak_start_y - pos.y
				# The invariant that actually means "fell through the world":
				# being BELOW the terrain surface at your own x/z. Sampled from
				# the same heightfield the terrain was baked from, which is the
				# sanctioned way to ask (D09 — never raycast for ground).
				var surface: float = float(world.call("ground_height_at", pos.x, pos.z))
				below = maxf(below, surface - pos.y)

			if pos.y < THROUGH_THE_FLOOR:
				Input.action_release(direction)
				print("traversal FAIL: fell through the world holding %s at %.0f, %.0f (y=%.0f)" % [
					direction, pos.x, pos.z, pos.y
				])
				quit(1)
				return

			if absf(pos.x) > WORLD_EDGE or absf(pos.z) > WORLD_EDGE:
				print("  %-14s reached the world edge at %.0f, %.0f — leg ends here" % [
					direction, pos.x, pos.z
				])
				break
		Input.action_release(direction)
		var here := player.global_position
		print("  %-14s -> %7.1f, %6.1f, %7.1f   grounded=%s" % [
			direction, here.x, here.y, here.z, player.is_on_floor()
		])
		# Settle between legs so a crest does not carry into the next one.
		for i in 30:
			await physics_frame

	print("furthest from spawn: %.0fm   lowest y: %.1fm   longest airborne run: %d frames" % [
		furthest, lowest, worst_streak
	])

	if worst_streak > 0:
		print("  longest run began at %.0f, %.0f, %.0f and lost %.2fm of height" % [
			worst_start.x, worst_start.y, worst_start.z, worst_drop])

	if furthest < 100.0:
		failures.append("only reached %.0fm from spawn; too short to prove anything about collision" % furthest)

	# Ungrounded ALONE is not the bug this test exists to catch, and asserting on
	# it made this test flap for days.
	#
	# The bug it was written for was Terrain3D's collision quietly reverting to
	# a 64m bubble: two hundred metres out the ground stopped existing and the
	# player fell to y = -49950. That is ungrounded AND below the ground, and it
	# never recovers.
	#
	# Being ungrounded while holding height is something else entirely. A slope
	# steeper than floor_max_angle (45 degrees) reports is_on_floor() false while
	# the player stands on perfectly solid ground, and this playground has hills.
	# On that basis this test reported "the ground is not continuous" for runs
	# where the player never went below y = -0.4m — a message nobody could act
	# on, which is how it came to be red and ignored.
	#
	# The invariant that actually distinguishes the two is whether the player is
	# UNDER the terrain surface at their own x/z. The fell-through-the-world
	# check above is unchanged and still absolute.
	if below > 1.5:
		failures.append("sank %.1fm below the terrain surface; the ground is not continuous" % below)
	elif worst_streak > 240:
		print("  NOTE: ungrounded for %d frames near %.0f, %.0f (%.2fm of height lost),"
			% [worst_streak, worst_start.x, worst_start.z, worst_drop])
		print("        but never below the terrain surface — a steep slope or a fall down")
		print("        one, not missing collision. Deepest below surface: %.2fm." % below)

	await _check_perimeter(world, player, failures)
	await _check_kill_volume(world, player, failures)

	print("")
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground, the perimeter holds, and the kill volume returns a fallen player to spawn.")
		quit(0)
	else:
		for line in failures:
			print("traversal FAIL: %s" % line)
		quit(1)


## SA3: eight compass bearings, each walked from just inside the ring toward
## it, each expected to be stopped by something the player can see — not
## walked from the true centre, which would also have to clear the village
## and the rises this test's own header already avoids for the same reason.
const PERIMETER_RADIUS := 235.0
const PERIMETER_START_RADIUS := 200.0
const PERIMETER_BEARINGS := 8
## OF6: the eight evenly-spaced bearings above never land on a rise, and a
## real leak reproduced specifically where one does — `world_perimeter.gd`'s
## `COLLISION_MARGIN_UP` header has the full measurement. Three of
## `terrain_playground.json`'s `rises.peaks` reach far enough out to overlap
## this ring's own 235m radius; two of these bearings sit inside the worst
## overlap (peak centred -165,-150, up to 46m past the ring — 227° is the
## bearing that leaked furthest, to 278m) and the third inside the next-
## largest overlap (peak centred 140,-90, up to 9m past the ring, at 327°).
## Evenly-spaced sampling alone missed this for as long as `OF6` sat open in
## `BACKLOG.md`; these are added explicitly rather than trusted to come up
## by chance.
const EXTRA_RISE_BEARINGS_DEG: PackedFloat32Array = [215.0, 227.0, 327.3]
## ~35m of gap between the start radius and the ring at this playground's
## walk speed (5.0 m/s, data/config/movement.json) is ~7s / 420 frames;
## this leaves comfortable room to actually reach and settle against
## whatever stops the player without paying for 900+ unused frames eight
## times over.
const PERIMETER_WALK_FRAMES := 600
## Wall/fence/hedge/rock thickness plus the player capsule's own radius plus
## a little settle slack — comfortably outside this and the ring leaked.
const PERIMETER_LEAK_MARGIN := 25.0


func _check_perimeter(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if camera_rig == null:
		failures.append("no CameraRig in the scene; cannot aim the walk to test the perimeter")
		return

	var bearings_deg: PackedFloat32Array = []
	for i in PERIMETER_BEARINGS:
		bearings_deg.append(rad_to_deg(i * TAU / PERIMETER_BEARINGS))
	bearings_deg.append_array(EXTRA_RISE_BEARINGS_DEG)

	for bearing_deg in bearings_deg:
		var angle := deg_to_rad(bearing_deg)
		var outward := Vector3(cos(angle), 0.0, sin(angle))
		var start_xz := outward * PERIMETER_START_RADIUS
		var ground: float = float(world.call("ground_height_at", start_xz.x, start_xz.z))
		if is_nan(ground):
			failures.append("bearing %.0f°: no ground at the test start point %.0f, %.0f" % [
				bearing_deg, start_xz.x, start_xz.z
			])
			continue

		player.global_position = Vector3(start_xz.x, ground + 1.0, start_xz.z)
		player.velocity = Vector3.ZERO
		# Vector3(0,0,-1) is player_controller.gd's own "forward" input
		# direction before the camera's planar_basis rotates it — see
		# `_apply_movement()`. Deriving the yaw from the engine's own
		# `signed_angle_to` rather than hand-deriving the rotation's sign
		# convention is what makes this match the real game exactly.
		camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
		for i2 in 10:
			await physics_frame

		Input.action_press("move_forward")
		for i2 in PERIMETER_WALK_FRAMES:
			await physics_frame
		Input.action_release("move_forward")
		for i2 in 20:
			await physics_frame

		var final_pos := player.global_position
		var distance := Vector2(final_pos.x, final_pos.z).length()
		print("  bearing %3.0f°: walked to %6.1f, %6.1f  (%.0fm from centre)" % [
			rad_to_deg(angle), final_pos.x, final_pos.z, distance
		])
		if distance > PERIMETER_RADIUS + PERIMETER_LEAK_MARGIN:
			failures.append("bearing %.0f°: reached %.0fm from centre, past the %.0fm ring with margin — the perimeter leaked" % [
				rad_to_deg(angle), distance, PERIMETER_RADIUS
			])
		if final_pos.y < THROUGH_THE_FLOOR:
			failures.append("bearing %.0f°: fell through the world while testing the perimeter (y=%.0f)" % [
				rad_to_deg(angle), final_pos.y
			])


## SA3's failsafe: a player placed inside the below-world kill band should be
## returned to spawn, not left to fall forever.
const KILL_SETTLE_FRAMES := 30


func _check_kill_volume(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var kill_volume: Node = world.get_node_or_null(^"WorldPerimeter/KillVolume")
	if kill_volume == null:
		failures.append("no WorldPerimeter/KillVolume in the scene; the below-world failsafe is missing")
		return

	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0.0, -120.0, 0.0) # inside the kill band, see world_perimeter.gd
	for i in KILL_SETTLE_FRAMES:
		await physics_frame

	var after := player.global_position
	print("  kill volume: player now at %.1f, %.1f, %.1f" % [after.x, after.y, after.z])
	if after.y < THROUGH_THE_FLOOR:
		failures.append("kill volume did not return the player to spawn (still at y=%.0f after %d frames)" % [
			after.y, KILL_SETTLE_FRAMES
		])
