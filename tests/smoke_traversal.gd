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

	for direction in ["move_forward", "move_right", "move_back", "move_left"]:
		Input.action_press(direction)
		for i in LEG_FRAMES:
			await physics_frame
			var pos := player.global_position
			furthest = maxf(furthest, Vector2(pos.x, pos.z).length())
			lowest = minf(lowest, pos.y)

			# A jump or a slope crest legitimately leaves the floor for a few
			# frames. Falling through does not come back.
			ungrounded_streak = 0 if player.is_on_floor() else ungrounded_streak + 1
			worst_streak = maxi(worst_streak, ungrounded_streak)

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

	if furthest < 100.0:
		failures.append("only reached %.0fm from spawn; too short to prove anything about collision" % furthest)
	if worst_streak > 240:
		failures.append("airborne for %d consecutive frames; the ground is not continuous" % worst_streak)

	print("")
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground.")
		quit(0)
	else:
		for line in failures:
			print("traversal FAIL: %s" % line)
		quit(1)
