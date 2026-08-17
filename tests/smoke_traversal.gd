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
## Physics ticks per leg. At the configured walk speed this is roughly 120m —
## still more than 1.8x the 64m dynamic radius that caused the original bug,
## and comfortably past this file's own `furthest < 100.0` failure floor
## below, just not the original 190m/2700-frame margin (was ~3x). Shortened
## 2026-08-15 because this was the single slowest step in CI (~6 min); the
## invariant this test exists to catch — collision reverting to a small
## bubble around the player — only needs "far enough to leave any plausible
## bubble," not "as far as possible."
const LEG_FRAMES := 1700
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

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")


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
	_check_rock_collision_alignment(world, failures)
	await _check_south_bridge(world, player, failures)
	await _check_the_quarry(world, player, failures)
	await _check_the_river(world, player, failures)
	await _check_mill_crossing(world, player, failures)

	print("")
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground, the perimeter holds, the kill volume returns a fallen player to spawn, the South Bridge is shut without its key and open with it, the Old Quarry past it stands and holds a player up, the river cannot be walked across between its crossings, and the Old Mill Crossing is shut without its gear and open with it.")
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


## SC14: spec §3's Gate 1, walked rather than asserted about.
##
## The check is deliberately shaped like the bug it would catch. "The gate
## node exists and `is_open()` returns false" would pass on a crossing a
## player can stroll around the leaf of, and that is exactly the failure this
## geometry invites: the deck sits 0.12m above its own levelled abutments, so
## anything the rails do not cover can be stepped onto from the side. So both
## halves are a real walk with real input, at the real gate, in the real
## scene: hold forward at it locked, hold forward at it unlocked, and measure
## how far past the gully's centreline the player got either way.
##
## `depth_past_crossing` comes from `south_bridge.gd` rather than being
## re-derived here from a hardcoded +Z, for the reason `SE21`/`SE22` will
## appreciate: which way "deeper" points is resolved at build time from the
## road, and a test that hardcodes it stops testing the thing when the
## geography moves.
const BRIDGE_START_BACK := 11.0
const BRIDGE_WALK_FRAMES := 420
## The player has crossed when they are this far past the gully's centre —
## past the span's far landing (9.2m) with room to spare, so a player merely
## standing ON the bridge cannot pass for one who got over it.
const BRIDGE_CROSSED_M := 11.0
## And is still shut when they never got past the centreline at all. The gate
## itself stands 8.5m short of it.
const BRIDGE_BLOCKED_M := 0.0


func _check_south_bridge(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	await _check_gated_crossing(world, player, failures,
		NodePath("SouthBridge"), "the South Bridge", "south_bridge_key", "south_bridge_open")


## SE22: the Old Mill Crossing, the only way over SE21's river. Same
## assertions as the South Bridge and deliberately the same function — the two
## crossings are one mechanism (`gated_crossing.gd`) with two sets of ids, and
## a second copy of this walk would be a second thing to keep in step.
func _check_mill_crossing(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	await _check_gated_crossing(world, player, failures,
		NodePath("MillCrossing"), "the Old Mill Crossing", "mill_bridge_gear", "mill_crossing_restored")


func _check_gated_crossing(world: Node, player: CharacterBody3D, failures: Array[String],
		node_name: NodePath, label: String, key_item: String, flag: String) -> void:
	var bridge: Node3D = world.get_node_or_null(node_name) as Node3D
	if bridge == null:
		failures.append("no %s in the scene; %s is not built" % [node_name, label])
		return
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if camera_rig == null:
		failures.append("no CameraRig in the scene; cannot aim the walk at %s" % label)
		return
	var game := root.get_node_or_null(^"Game")
	if game == null:
		failures.append("no Game autoload; %s has no inventory or flag store to read" % label)
		return
	var inventory: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")

	var prompt: Node3D = bridge.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		failures.append("%s has no Interactable; the gate cannot be tried at all" % label)
		return

	if bool(bridge.call("is_open")):
		failures.append("%s started open on a fresh world; it is not a gate" % label)
		return

	# --- locked: the key is not in the satchel, and trying it changes nothing.
	# `remove` is all-or-nothing, so ask for exactly what is there — a blanket
	# "remove 99" would return false and leave a key sitting in the satchel.
	var carried := int(inventory.call("count", key_item))
	if carried > 0:
		inventory.call("remove", key_item, carried)
	prompt.call("interaction_activate")
	await physics_frame
	if bool(bridge.call("is_open")):
		failures.append("%s opened without its key" % label)
	if bool(progression.call("has", flag)):
		failures.append("trying the locked gate at %s set its open flag anyway" % label)

	var reached_locked: float = await _walk_at_the_bridge(bridge, player, camera_rig)
	print("  %s, locked:   reached %+.1fm past the gap" % [label, reached_locked])
	if reached_locked > BRIDGE_BLOCKED_M:
		failures.append("crossed %s without the key (%.1fm past the gap) — the gate can be walked around" % [
			label, reached_locked])

	# --- unlocked: the key opens it, is spent doing so, and the span carries.
	inventory.call("add", key_item, 1)
	prompt.call("interaction_activate")
	await physics_frame
	if not bool(bridge.call("is_open")):
		failures.append("%s stayed shut with its key in the satchel" % label)
		return
	if int(inventory.call("count", key_item)) != 0:
		failures.append("'%s' was not consumed opening %s" % [key_item, label])
	if not bool(progression.call("has", flag)):
		failures.append("the open crossing at %s did not set its progression flag; a reload would relock it" % label)

	var reached_open: float = await _walk_at_the_bridge(bridge, player, camera_rig)
	print("  %s, unlocked: reached %+.1fm past the gap" % [label, reached_open])
	if reached_open < BRIDGE_CROSSED_M:
		failures.append("could not cross the open %s (only %.1fm past the gap)" % [label, reached_open])
	if player.global_position.y < THROUGH_THE_FLOOR:
		failures.append("fell into the gap while crossing the open %s" % label)


## SE21: the river itself, asserted the only way that is worth anything — by
## walking a body at it, away from the one place it can be crossed, and
## measuring how far the body got. Not "is the config deep enough": the gully
## SC14 cut was deep enough too, and what its own probe caught was a player
## stepping onto the deck from the side, which no config check can see.
##
## Three stations, spread down the course, none of them near the narrows.
const RIVER_STATIONS: Array[int] = [11, 13, 15]
const RIVER_START_BACK := 14.0
const RIVER_WALK_FRAMES := 420
## The player has crossed the river when they are this far past the
## centreline. Deliberately NOT a small number, and the reason is the shape of
## the thing: the channel is 22-26m wide, so a player who slides down the near
## wall and comes to rest on the bed is legitimately within a few metres of the
## centreline without having crossed anything. 12m puts them up the FAR wall.
## The stricter half of this check is the settled position below — whatever
## happened mid-walk, a player who did not cross ends up back on the near bank,
## because that is where river.gd's recovery volumes put them.
const RIVER_CROSSED_M := 12.0
## And where they must have ended up: still on the near side, or at worst on
## the bed. Anything past this is standing on the far bank.
const RIVER_SETTLED_M := 4.0
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"


func _check_the_river(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if camera_rig == null:
		failures.append("no CameraRig in the scene; cannot aim a walk at the river")
		return
	var file := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	var course: Array = ((parsed as Dictionary).get("river", {}) as Dictionary).get("course", []) \
		if parsed is Dictionary else []
	if course.size() < 3:
		failures.append("no river course in %s; SE21's river is not authored" % TERRAIN_CONFIG)
		return
	if world.get_node_or_null(^"River") == null:
		failures.append("no River node in the scene; nothing would recover a player who walks in")

	for index in RIVER_STATIONS:
		if index >= course.size() - 1:
			continue
		var here := _course_point(course, index)
		var next := _course_point(course, index + 1)
		var previous := _course_point(course, maxi(index - 1, 0))
		var along := (next - previous).normalized()
		var across := Vector2(-along.y, along.x)
		# Toward the far bank, whichever side that is here: the course bends,
		# and a hardcoded +X would stop testing the thing the moment it moves.
		if (here - Vector2(10.0, -10.0)).dot(across) < 0.0:
			across = -across

		var start := here - across * RIVER_START_BACK
		var ground: float = float(world.call("ground_height_at", start.x, start.y))
		if is_nan(ground):
			failures.append("no ground at the river's near bank at %.0f, %.0f" % [start.x, start.y])
			continue
		player.global_position = Vector3(start.x, ground + 1.0, start.y)
		player.velocity = Vector3.ZERO
		var outward := Vector3(across.x, 0.0, across.y)
		camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
		for i in 10:
			await physics_frame

		var best := -INF
		Input.action_press("move_forward")
		for i in RIVER_WALK_FRAMES:
			await physics_frame
			var at := player.global_position
			best = maxf(best, (Vector2(at.x, at.z) - here).dot(across))
		Input.action_release("move_forward")
		for i in 20:
			await physics_frame
		var settled := player.global_position
		print("  river at %.0f, %.0f: reached %+.1fm past the centreline, settled %+.1fm across at y %.1f" % [
			here.x, here.y, best, (Vector2(settled.x, settled.z) - here).dot(across), settled.y])
		if best >= RIVER_CROSSED_M:
			failures.append("walked across the river at %.0f, %.0f (%.1fm past the centreline) — it divides nothing" % [
				here.x, here.y, best])
		var ended := (Vector2(settled.x, settled.z) - here).dot(across)
		if ended >= RIVER_SETTLED_M:
			failures.append("ended up %.1fm past the river's centreline at %.0f, %.0f — on the far bank, without a crossing" % [
				ended, here.x, here.y])
		# And whatever happened, the player is not left at the bottom of a
		# channel they cannot climb out of: river.gd's recovery volumes put
		# them back on the bank they started from.
		if settled.y < THROUGH_THE_FLOOR:
			failures.append("fell out of the world at the river at %.0f, %.0f" % [here.x, here.y])


func _course_point(course: Array, index: int) -> Vector2:
	var at: Array = (course[index] as Dictionary).get("at", [])
	return Vector2(float(at[0]), float(at[1]))


## SD16: the Old Quarry is reachable past the bridge, and it is a place rather
## than a coordinate — the floor holds the player up, its foundations and
## conduit run actually stood, and the Rootstone deposits are standing on
## ground rather than skipped for want of it.
##
## `_place_harvest_nodes()` drops any node whose ground sample is NaN without
## a word, which is exactly how a deposit authored into a hole disappears; the
## count check is what catches that.
const QUARRY_SETTLE_FRAMES := 90


func _check_the_quarry(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var quarry: Node3D = world.get_node_or_null(^"OldQuarry") as Node3D
	if quarry == null:
		failures.append("no OldQuarry in the scene; spec §3 Band 2's quarry is not built")
		return
	var stats: Dictionary = quarry.call("stats")
	print("  quarry: %d foundations, %d pylons" % [int(stats["foundations"]), int(stats["pylons"])])
	if int(stats["foundations"]) < 1:
		failures.append("the Old Quarry stood no foundations")
	if int(stats["pylons"]) < 2:
		failures.append("the Old Quarry stood %d pylons; the conduit run needs at least two to carry a cable between them" % int(stats["pylons"]))

	# Every authored rootstone deposit, standing where it was authored.
	var wanted := 0
	var file := FileAccess.open("res://data/config/harvest.json", FileAccess.READ)
	if file != null:
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			for entry: Variant in (parsed as Dictionary).get("nodes", []):
				if entry is Dictionary and str((entry as Dictionary).get("item", "")) == "rootstone":
					wanted += 1
	var standing := 0
	var first := Vector3.ZERO
	for node in world.get_children():
		if not node.has_method("setup") or not (node is Node3D):
			continue
		if str(node.get("_item_id")) != "rootstone":
			continue
		standing += 1
		if standing == 1:
			first = (node as Node3D).global_position
	print("  quarry: %d of %d authored rootstone deposits standing" % [standing, wanted])
	if wanted > 0 and standing < wanted:
		failures.append("%d of %d rootstone deposits never stood up — a harvest node whose ground sampled NaN is skipped silently" % [
			wanted - standing, wanted])
	if standing == 0:
		return

	# And the floor they stand on holds a player up.
	player.velocity = Vector3.ZERO
	player.global_position = first + Vector3.UP * 1.5
	for i in QUARRY_SETTLE_FRAMES:
		await physics_frame
	var landed := player.global_position
	var surface: float = float(world.call("ground_height_at", landed.x, landed.z))
	print("  quarry: player dropped at a deposit settled at %.1f, %.1f, %.1f (ground %.1f, grounded=%s)" % [
		landed.x, landed.y, landed.z, surface, player.is_on_floor()])
	if landed.y < surface - 1.5:
		failures.append("the quarry floor did not hold the player up (%.1fm below the terrain surface)" % (surface - landed.y))


## One walk at the crossing from the village side, returning how far past the
## gully's centreline the player ended up.
func _walk_at_the_bridge(bridge: Node3D, player: CharacterBody3D, camera_rig: Node3D) -> float:
	var start: Vector2 = bridge.call("near_point", BRIDGE_START_BACK)
	var target: Vector2 = bridge.call("far_point", BRIDGE_START_BACK)
	var ground: float = float(bridge.get_parent().call("ground_height_at", start.x, start.y))
	player.global_position = Vector3(start.x, ground + 1.0, start.y)
	player.velocity = Vector3.ZERO
	var outward := Vector3(target.x - start.x, 0.0, target.y - start.y).normalized()
	camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
	for i in 10:
		await physics_frame

	var best := -INF
	Input.action_press("move_forward")
	for i in BRIDGE_WALK_FRAMES:
		await physics_frame
		var here := player.global_position
		best = maxf(best, float(bridge.call("depth_past_crossing", Vector2(here.x, here.z))))
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame
	return best


## OF14: the owner reported the player/objects passing through rocks and
## terrain props in places. `vegetation.gd`'s `rocks` layer tilts its VISUAL
## mesh to the ground normal on a slope (`align_to_slope`) but, before this
## check existed, left the collider vertical regardless — on a steep anchor
## site (up to 52 degrees, `data/config/vegetation.json`) a scaled-up boulder
## leans its silhouette out past a world-up cylinder's footprint, so a player
## approaching from the downhill side walks into visible rock before
## touching collision. Rather than trust the fix was exercised, this samples
## the SAME heightfield the render/placement path used and checks every
## sloped rock's real collider basis against it directly.
const ROCK_SLOPE_CHECK_MIN_DEG := 10.0
## Dot-product slack between the collider's up and the terrain normal, loose
## enough for float noise but tight enough that "still world-up" (dot ~=
## cos(slope)) reliably fails it on anything above the min-slope floor.
const ROCK_ALIGNMENT_MIN_DOT := 0.98


## COLL1 / §8.3: collision now streams (see `vegetation.gd`'s
## `update_collision_streaming`), so a rock's `CollisionShape3D` only exists
## when something has recentred the streaming bubble near it. This check's
## whole point is to look at EVERY sloped rock, not whichever ones the
## traversal walk's own four legs happened to pass within
## `COLLISION_STREAM_RADIUS` of -- so it force-streams every rock/pebble
## resident first (`force_collision_resident`, a test-only escape hatch that
## ignores the streaming radius; gameplay never calls it) rather than either
## disabling streaming or silently checking a subset and calling it
## complete. The StaticBody3D naming this check keys off (`Rock_`/`Pebble_`)
## is unchanged by streaming -- only which CollisionShape3D children exist
## underneath it varies now, never the body itself.
func _check_rock_collision_alignment(world: Node, failures: Array[String]) -> void:
	var vegetation: Node = world.get_node_or_null(^"Vegetation")
	if vegetation == null:
		failures.append("no Vegetation node in the scene; cannot check rock collision alignment")
		return
	if vegetation.has_method("force_collision_resident"):
		vegetation.call("force_collision_resident", "Rock_")
		vegetation.call("force_collision_resident", "Pebble_")

	var field := HEIGHTFIELD.new()
	var checked := 0
	var mismatched := 0
	for body in vegetation.get_children():
		if not (body is StaticBody3D):
			continue
		var body_name := (body as Node).name as String
		if not (body_name.begins_with("Rock_") or body_name.begins_with("Pebble_")):
			continue
		for shape_node in (body as Node).get_children():
			if not (shape_node is CollisionShape3D):
				continue
			var cyl := (shape_node as CollisionShape3D).shape as CylinderShape3D
			if cyl == null:
				continue
			var actual_up: Vector3 = (shape_node as Node3D).global_transform.basis.y.normalized()
			# vegetation.gd positions the shape's NODE at the ground contact
			# point plus half its height along `up` (so the cylinder's base,
			# not its centre, sits on the ground) — recover that base point
			# rather than querying the heightfield at the node's own
			# position, which is offset horizontally by exactly the tilt
			# this check exists to verify.
			var base: Vector3 = (shape_node as Node3D).global_position - actual_up * (cyl.height * 0.5)
			var slope_deg: float = field.call("slope_degrees_at", base.x, base.z)
			if slope_deg < ROCK_SLOPE_CHECK_MIN_DEG:
				continue
			checked += 1
			var expected_up: Vector3 = field.call("normal_at", base.x, base.z)
			var alignment := actual_up.dot(expected_up)
			if alignment < ROCK_ALIGNMENT_MIN_DOT:
				mismatched += 1
				if mismatched <= 5:
					print("  rock collider %s at %.1f,%.1f (slope %.0f deg): alignment=%.3f (want >= %.2f)" % [
						body_name, base.x, base.z, slope_deg, alignment, ROCK_ALIGNMENT_MIN_DOT
					])

	print("rock collision alignment: checked %d sloped rock colliders, %d not tilted to match the visual mesh" % [
		checked, mismatched
	])
	if checked == 0:
		failures.append("no sloped rock colliders found to check -- the rocks layer may not have scattered")
	elif mismatched > 0:
		failures.append("%d of %d sloped rock colliders are not tilted to match their visual mesh -- a player can clip through the gap (OF14)" % [
			mismatched, checked
		])
