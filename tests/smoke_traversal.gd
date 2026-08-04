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

## Frames of continuous airborne after which the failure is described rather
## than merely counted.
##
## The counter alone says "the ground is not continuous", which turned out to be
## a guess dressed as a finding: this test failed one run in three with the
## player sitting at y = 0.4 — ground level — for three thousand frames without
## ever falling. Not through the floor, not falling, just never on it. Three
## explanations fit that equally well (wedged against a prop collider, a hole in
## terrain collision, a face steeper than the controller's floor limit) and they
## want opposite fixes.
##
## Well before the 240-frame failure threshold, so the diagnosis prints on runs
## that go on to pass too — a rare failure is best understood next to the near
## misses.
const DIAGNOSE_AFTER := 90


func _init() -> void:
	_run()


## Say WHY the player is off the floor, at the moment it is happening.
##
## Each line separates two of the three candidate causes, so one printout
## settles it rather than narrowing it:
##
## - the collision list distinguishes "wedged against a prop" (a collider with a
##   name, a horizontal normal) from "on a steep face" (the terrain, a normal
##   tilted past the controller's floor limit) from "touching nothing at all";
## - terrain height against player height distinguishes "the heightfield says
##   there is ground here and physics disagrees" from "there is genuinely a
##   hole". These are different bugs with different owners, and D09 is the
##   standing warning that the two mechanisms can disagree;
## - velocity distinguishes wedged from sliding, which the position alone does
##   not: a player creeping down a slope and a player pinned against a trunk
##   both look stationary over a single frame.
func _diagnose(player: CharacterBody3D, world: Node, direction: String) -> void:
	var at := player.global_position
	var ground: float = float(world.call("ground_height_at", at.x, at.z)) \
		if world.has_method("ground_height_at") else NAN

	print("  --- ungrounded %d frames while holding %s ---" % [DIAGNOSE_AFTER, direction])
	print("      at %.2f, %.2f, %.2f   velocity %.2f, %.2f, %.2f" % [
		at.x, at.y, at.z, player.velocity.x, player.velocity.y, player.velocity.z
	])
	if is_nan(ground):
		print("      terrain height: NaN — no terrain at this point at all")
	else:
		print("      terrain height %.2f, player %.2f, gap %+.2f" % [ground, at.y, at.y - ground])

	var hits := player.get_slide_collision_count()
	if hits == 0:
		print("      touching nothing")
	for i in hits:
		var hit := player.get_slide_collision(i)
		var normal := hit.get_normal()
		var collider: Object = hit.get_collider()
		# The angle is what the controller actually tests, so report the number
		# it tests rather than the raw vector.
		print("      hit %d: %s  normal %.2f, %.2f, %.2f  (%.1f deg from up)" % [
			i,
			(collider as Node).name if collider is Node else str(collider),
			normal.x, normal.y, normal.z,
			rad_to_deg(normal.angle_to(Vector3.UP))
		])
	print("      floor_max_angle %.1f deg" % rad_to_deg(player.floor_max_angle))


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
			if ungrounded_streak == DIAGNOSE_AFTER:
				_diagnose(player, world, direction)

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
		# Deliberately does NOT say "the ground is not continuous" any more. It
		# used to, and that was a conclusion rather than a measurement: the one
		# time it fired, the ground was continuous and present, and the player
		# was underneath it. A failure message that names a cause it did not
		# observe sends the next reader to the wrong file.
		failures.append(
			"airborne for %d consecutive frames — see the diagnosis above for whether that is "
			% worst_streak + "a hole, a prop, a slope, or a body inside the terrain"
		)

	print("")
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground.")
		quit(0)
	else:
		for line in failures:
			print("traversal FAIL: %s" % line)
		quit(1)
