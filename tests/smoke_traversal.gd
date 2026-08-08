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

	print("")
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground.")
		quit(0)
	else:
		for line in failures:
			print("traversal FAIL: %s" % line)
		quit(1)
