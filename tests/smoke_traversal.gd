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
##
## §8.2 (ralph/BAKE-GUARDS) moved collision from FULL_GAME to dynamic with a
## radius Terrain3D grants (see COLLISION_DYNAMIC_GAME above), and asked for a
## body driven 600m down the corridor's spine as the real stress case -- that
## world does not exist yet on this branch (footprint work is out of scope
## here, see the branch's own task). What this file can and does check today:
## the granted radius covers this playground's actual WORLD_EDGE with margin,
## and the existing four-direction walk below already goes far enough to have
## caught the original 64m-bubble bug on its own terms. The 600m case is real
## work for whichever lane bakes the corridor (OW5C), not a box this ticks.

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
##
## UNVERIFIED against the corridor's own bake (D50/OW5B): -26m was measured
## on the old 512m world, which had no river gorge, no quarry pit, and no
## gully carve anywhere near this deep. The corridor's river alone is
## documented at 10-18m deep (`data/config/terrain_playground.json`'s
## `river.course`, and the relocated course is the same order of magnitude —
## see `_check_the_river` below), which is still comfortably above -80m, but
## nobody has re-measured the corridor's actual lowest point the way this
## constant claims to know it. Left unchanged because -80m is still a wide
## margin over every documented depth; revisit if a carve turns out deeper.
const THROUGH_THE_FLOOR := -80.0
## §8.2 (ralph/BAKE-GUARDS): dynamic collision, not FULL_GAME. FULL_GAME built
## real shapes across every loaded region at load; at the 64-region corridor
## that is real shapes for the whole world, at once, on the load screen.
## Dynamic (mode 1) rebuilds incrementally around the camera, out to whatever
## `collision_radius` Terrain3D actually grants -- see the readback check
## below, which asserts the GRANTED radius/shape_size, not the requested one:
## `tools/_probe_terrain_collision.gd` confirmed both are silently clamped
## (radius to [16,256] step 16, shape_size to [8,64] step 8) rather than
## rejected out of range.
const COLLISION_DYNAMIC_GAME := 1
## The baked world spans ±256m (terrain_playground.json world_size 512, centred
## on the origin). A leg that reaches this line stops early: past the rim there
## is legitimately no ground, and walking off it reads as "fell through the
## world" when nothing is wrong. CI hit exactly that — the forward leg from the
## D50 grew the baked world from a ±256m square (`terrain_playground.json`
## `world_size` 512, centred on the origin) to an 8192 x 2048m corridor: x in
## [-1024, 1024], z in [-512, 7680] — `docs/MEADOWS_MACRO_LAYOUT.md` §2, the
## same bounds `world_perimeter.gd`'s own `WORLD_X_WEST`/`WORLD_X_EAST`/
## `WORLD_Z_NORTH`/`WORLD_Z_SOUTH` use. A single `WORLD_EDGE` scalar checked
## against `absf(x)`/`absf(z)` assumed a square centred on the origin; the
## corridor is neither square nor centred — x is symmetric but z runs only
## 512m north of the origin against 7680m south. Four independent limits,
## one per direction, keep the same margin philosophy the old scalar used:
## stop a leg comfortably inside the real edge, before whatever ground
## exists there runs out and reads as "fell through the world" when nothing
## is wrong. `EDGE_MARGIN` keeps the same ~16m the old constant used (240 vs
## the old square's real 256).
## The floor for the GRANTED dynamic-collision radius.
##
## This replaces a `radius >= WORLD_EDGE` check that BAKE-GUARDS wrote when the
## world was a +/-256m square: back then "the radius covers the whole world" was
## both meaningful and achievable. On D50's 8192 x 2048m corridor it is neither
## -- Terrain3D clamps `collision_radius` to [16, 256] step 16, so no setting
## can span 8km, and not needing to is exactly what streaming collision is FOR.
## `WORLD_EDGE` itself is gone with the square.
##
## What still has teeth is the clamp: a requested value out of range is
## silently altered rather than rejected (the same trap that left
## `collision_shape_size` stuck at 16 for months -- see WALL1). So this asserts
## the granted radius is large enough that a sprinting player cannot reach its
## rim before the next rebuild, which is the property the old check was really
## reaching for. 128m is half the achievable maximum and ~18 seconds of sprint
## at this project's 7.0 m/s sustained pace.
const COLLISION_RADIUS_MIN := 128

const EDGE_MARGIN := 16.0
const WORLD_X_WEST_LIMIT := -1024.0 + EDGE_MARGIN
const WORLD_X_EAST_LIMIT := 1024.0 - EDGE_MARGIN
const WORLD_Z_NORTH_LIMIT := -512.0 + EDGE_MARGIN
const WORLD_Z_SOUTH_LIMIT := 7680.0 - EDGE_MARGIN
## CI hit this for real once, under the old square: the forward leg from the
## (60, -60) start crossed z = -256 unobstructed and fell off the north rim,
## while the same leg on a local run happened to snag on the rocky rise and
## never got there. That failure needed the north limit to be reachable —
## the old square's north edge was 196m from spawn, inside what a leg could
## then walk unobstructed (`LEG_FRAMES` was 2700 at the time, ~190m).
##
## Judgement call: none of the four corridor limits above are reachable by a
## single leg at today's `LEG_FRAMES` (1700, ~120-140m unobstructed) even
## from this same spawn point. The closest is the north limit at 436m away
## (spawn z=-60 to z=-496); east is 948m, west is 1068m, south is 7724m —
## all far past what one leg can cover. Legs also chain (forward, then right
## from wherever forward ended, then back, then left), which traces a box
## roughly `LEG_FRAMES`-wide around spawn — nowhere near any of these four
## limits, and nowhere near any relocated place either (South Bridge z=1330,
## Old Quarry z=1800, the river z=4080-4222 are all hundreds of metres
## further south than this walk ever reaches). Left in per-axis form anyway,
## for the same reason the scalar existed at all: this is a safety net for
## whatever a leg's actual travel distance turns out to be, not a check
## expected to fire under today's `LEG_FRAMES`. A wrong single-scalar
## version would silently do nothing, or break early for the wrong reason,
## the moment that changes.

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
	# clear of the village, the rises and the pond. Unchanged from the old
	# square: `MEADOWS_MACRO_LAYOUT.md` §3 is explicit that Band 0 and the
	# whole shipped village keep their exact current coordinates, so this
	# point is exactly as clear of everything in the corridor as it was
	# before — nothing about D50 moved it or anything near it.
	var start := Vector3(60.0, 0.0, -60.0)
	start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
	player.global_position = start
	player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var failures: Array[String] = []

	# The direct cause, asserted directly. Everything below is the symptom.
	#
	# Radius/shape_size are read back and sanity-checked (positive, and a
	# player cannot outrun them within this playground's own extent) rather
	# than compared against a requested constant -- §8.2's clamping trap
	# means the requested value and the granted one are not the same number.
	var mode: int = int(terrain.get("collision_mode"))
	var radius: int = int(terrain.get("collision_radius"))
	var shape_size: int = int(terrain.get("collision_shape_size"))
	print("collision_mode = %d (want %d, Dynamic/Game)   collision_radius = %d   collision_shape_size = %d" % [
		mode, COLLISION_DYNAMIC_GAME, radius, shape_size])
	if mode != COLLISION_DYNAMIC_GAME:
		failures.append("collision_mode is %d, not Dynamic/Game; collision may be built all at once at load" % mode)
	if radius <= 0:
		failures.append("collision_radius read back as %d; dynamic collision has no usable radius" % radius)
	elif radius < COLLISION_RADIUS_MIN:
		failures.append("collision_radius %d is below %d; dynamic collision would not stay ahead of a sprinting player" % [
			radius, COLLISION_RADIUS_MIN])
	if shape_size <= 0:
		failures.append("collision_shape_size read back as %d; dynamic collision has no usable shapes" % shape_size)

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

			if pos.x < WORLD_X_WEST_LIMIT or pos.x > WORLD_X_EAST_LIMIT \
					or pos.z < WORLD_Z_NORTH_LIMIT or pos.z > WORLD_Z_SOUTH_LIMIT:
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
	await _check_village_doors(world, failures)

	print("")
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground, the perimeter holds, the kill volume returns a fallen player to spawn, the South Bridge is shut without its key and open with it, the Old Quarry past it stands and holds a player up, the river cannot be walked across between its crossings, the Old Mill Crossing is shut without its gear and open with it, and every village house door starts shut, blocks the doorway, and opens on interact into a real room.")
		quit(0)
	else:
		for line in failures:
			print("traversal FAIL: %s" % line)
		quit(1)


## SA3, corridor version. D51/`MEADOWS_MACRO_LAYOUT.md` §6 replaced the 235m
## ring with two long edges (x = -1024/+1024, z: -512..7680) and two short
## end-caps (z = -512/+7680, x: -1024..1024) — see `docs/decisions/D51` and
## the macro layout doc for the shape; do not re-derive it here. Compass
## bearings toward a ring cannot express a rectangle — there is no single
## "outward from the centre" a corridor has one of — so this walks straight
## at each of the four edges instead, from a handful of representative
## points, same invariant as before: start just inside the true line, walk
## at it, expect to be stopped by whatever that edge's own style puts in the
## way (D51/§6's per-band table), well short of the true line plus a leak
## margin.
const WORLD_X_WEST := -1024.0
const WORLD_X_EAST := 1024.0
const WORLD_Z_NORTH := -512.0
const WORLD_Z_SOUTH := 7680.0
## Same ~35m-of-gap-at-walk-speed reasoning the ring used (5.0 m/s,
## `data/config/movement.json`): ~7s to close, comfortable room to actually
## reach and settle against whatever stops the walk. Independent of the
## boundary's shape — this is about how far a leg covers in a walk-frames
## budget, not about a radius, so it did not need to change with the shape.
const PERIMETER_APPROACH_MARGIN := 35.0
const PERIMETER_WALK_FRAMES := 600
## Wall/fence/hedge/rock thickness plus the player capsule's own radius plus
## a little settle slack — unchanged from the ring. This is a property of
## the props and the capsule, not of the boundary's shape, so it did not
## need to change either.
const PERIMETER_LEAK_MARGIN := 25.0

## One station per test: `edge` says which of the four true lines it is
## walking at (west/east/north/south) and which coordinate check applies;
## `other` is the coordinate along that edge that does NOT move during the
## walk (the z for west/east, the x for north/south).
##
## Three z-values for west/east — near the village (z=200, Band 1's
## hedgerow-and-fence / fieldstone-wall pair), partway through the journey
## (z=2270, the midpoint of Band 2 "Stone & Root" — quarried scarp / dense
## growth ridge — chosen as "mid-corridor" in the sense of partway through
## the spine's own 11.6km, NOT the geometric midpoint of the z range, which
## falls in Band 3's marsh instead; see the dedicated marsh station below
## for that), and near the stronghold (z=7200, the approach band's authored
## Team Tether barrier on both edges) — plus one north-cap walk near spawn
## and one south-cap walk near the stronghold approach, the four-ish
## representative points the prep brief asked for rather than a walk per
## band.
##
## OF6's own lesson on the old ring (see its own header, preserved in
## `docs/decisions/D51`'s history) was that evenly-spaced sampling alone
## missed a rise that specifically overlapped the ring's own radius, and the
## fix was aiming a bearing AT that named landform rather than trusting it
## to come up by chance. The corridor's nearest equivalent — a spoke blocker
## close enough to the true edge to interact with it — does not exist:
## `MEADOWS_MACRO_LAYOUT.md` §7 is explicit that all six lateral spoke
## blockers sit 284-324m INSIDE the ±1024 edge, comfortably clear of this
## file's own 35m approach margin, and that the doc calls that margin "the
## design's floor, not slack" — i.e. it is not expected to erode. No known
## leak to aim at, so none is added; recorded here rather than left for
## someone to wonder whether it was considered.
##
## What IS flagged, by `world_perimeter.gd`'s own header (the corridor
## rewrite this test is walking against), is Band 3's west edge: "water —
## the broad marsh the river drains into" is "the one edge style with no
## existing implementation." Real collision exists there (the same box
## every style uses), but nothing about it is actually water, which is
## exactly the kind of specific, already-named risk OF6's extra bearings
## existed to aim at rather than average over. One station below is aimed
## at it directly (z=4000, inside Band 3).
const PERIMETER_STATIONS := [
	{"label": "west @ village (Band 1, hedge/fence)", "edge": "west", "other": 200.0},
	{"label": "east @ village (Band 1, fieldstone wall)", "edge": "east", "other": 200.0},
	{"label": "west @ Band 2 midpoint (rock scarp)", "edge": "west", "other": 2270.0},
	{"label": "east @ Band 2 midpoint (growth ridge)", "edge": "east", "other": 2270.0},
	{"label": "west @ the marsh (Band 3, unimplemented style)", "edge": "west", "other": 4000.0},
	{"label": "west @ stronghold approach (barrier)", "edge": "west", "other": 7200.0},
	{"label": "east @ stronghold approach (barrier)", "edge": "east", "other": 7200.0},
	{"label": "north cap, near spawn (gentle)", "edge": "north", "other": 60.0},
	{"label": "south cap, near stronghold approach (barrier)", "edge": "south", "other": 500.0},
]


func _check_perimeter(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if camera_rig == null:
		failures.append("no CameraRig in the scene; cannot aim the walk to test the perimeter")
		return

	for entry in PERIMETER_STATIONS:
		var station: Dictionary = entry
		var label: String = str(station["label"])
		var edge: String = str(station["edge"])
		var other: float = float(station["other"])

		var start_xz := Vector2.ZERO
		var outward := Vector3.ZERO
		match edge:
			"west":
				start_xz = Vector2(WORLD_X_WEST + PERIMETER_APPROACH_MARGIN, other)
				outward = Vector3(-1.0, 0.0, 0.0)
			"east":
				start_xz = Vector2(WORLD_X_EAST - PERIMETER_APPROACH_MARGIN, other)
				outward = Vector3(1.0, 0.0, 0.0)
			"north":
				start_xz = Vector2(other, WORLD_Z_NORTH + PERIMETER_APPROACH_MARGIN)
				outward = Vector3(0.0, 0.0, -1.0)
			"south":
				start_xz = Vector2(other, WORLD_Z_SOUTH - PERIMETER_APPROACH_MARGIN)
				outward = Vector3(0.0, 0.0, 1.0)
			_:
				failures.append("perimeter station '%s' has an unknown edge '%s'" % [label, edge])
				continue

		var ground: float = float(world.call("ground_height_at", start_xz.x, start_xz.y))
		if is_nan(ground):
			failures.append("%s: no ground at the test start point %.0f, %.0f" % [
				label, start_xz.x, start_xz.y
			])
			continue

		player.global_position = Vector3(start_xz.x, ground + 1.0, start_xz.y)
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
		print("  %-40s walked to %7.1f, %7.1f" % [label, final_pos.x, final_pos.z])

		var leaked := false
		match edge:
			"west":
				leaked = final_pos.x < WORLD_X_WEST - PERIMETER_LEAK_MARGIN
			"east":
				leaked = final_pos.x > WORLD_X_EAST + PERIMETER_LEAK_MARGIN
			"north":
				leaked = final_pos.z < WORLD_Z_NORTH - PERIMETER_LEAK_MARGIN
			"south":
				leaked = final_pos.z > WORLD_Z_SOUTH + PERIMETER_LEAK_MARGIN
		if leaked:
			failures.append("%s: reached %.0f, %.0f — past the true edge with margin, the perimeter leaked" % [
				label, final_pos.x, final_pos.z
			])
		if final_pos.y < THROUGH_THE_FLOOR:
			failures.append("%s: fell through the world while testing the perimeter (y=%.0f)" % [
				label, final_pos.y
			])


## SA3's failsafe: a player placed inside the below-world kill band should be
## returned to spawn, not left to fall forever.
const KILL_SETTLE_FRAMES := 30
## Must sit inside `world_perimeter.gd`'s own kill band (`KILL_PLANE_Y` ±
## half of `KILL_PLANE_THICKNESS`). The corridor moved this: the pre-corridor
## `world_perimeter.gd` centred its kill band at y=-120; the corridor version
## centres its own at y=-150, because the whole kill volume grew to cover
## the corridor's much larger x/z footprint and was re-derived from the
## corridor's own bounds (`WORLD_X_WEST`/`EAST`/`WORLD_Z_NORTH`/`SOUTH`
## above) rather than kept as a fixed square centred on the origin — see
## that file's own `KILL_PLANE_Y`/`KILL_PLANE_THICKNESS`/`KILL_PLANE_MARGIN`.
## y=-120 sits entirely OUTSIDE the corridor's own band (which spans
## [-170,-130] at 40m thick); this constant exists so that fact gets
## asserted once, here, rather than discovered as a check that silently
## never tested what it claimed to. x=0, z=0 are unchanged from before and
## still land inside the corridor kill volume's much larger x/z footprint
## (it is centred at the corridor's own midpoint, x=0/z=3584, with margin
## added on top — the origin is comfortably inside it either way).
const KILL_TEST_Y := -150.0


func _check_kill_volume(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var kill_volume: Node = world.get_node_or_null(^"WorldPerimeter/KillVolume")
	if kill_volume == null:
		failures.append("no WorldPerimeter/KillVolume in the scene; the below-world failsafe is missing")
		return

	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0.0, KILL_TEST_Y, 0.0) # inside the kill band, see world_perimeter.gd
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
##
## The South Bridge and Old Mill Crossing both moved for the corridor (carve
## centre (0,1330), abutments (0,1317)/(0,1343) for the bridge; channel
## centre (-150,4203) for the crossing — this prep brief's own numbers). This
## function and `_check_gated_crossing` below do not reference either
## location: `near_point`/`far_point`/`depth_past_crossing` all come from the
## bridge/crossing NODE itself at test time, so the relocation is transparent
## to this test — the only coordinate that would need to change if the span
## width or gully depth changed is inside those nodes' own scripts, not here.
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
## The old course ran diagonally near the village (18 points, roughly
## (211,-87) to (75,246), narrows at index 7 / (162.4,42.1) — verified
## directly against `data/config/terrain_playground.json` while writing this)
## and named three fixed indices, `[11,13,15]`, chosen once by inspecting
## that specific array. The corridor's course is a different shape entirely —
## an 18-19 point crossing of the whole 8192m-wide corridor at z ~4080-4222,
## narrowing to a channel at the Old Mill Crossing near (-150,4203) — and per
## this task's brief, the sibling task authoring its real values has not
## landed them in `terrain_playground.json` yet; this file only knows the
## shape and the crossing's location. Fixed indices into an array whose exact
## point count and station spacing are not yet known would be a guess dressed
## as a measurement, so stations are chosen by DISTANCE FROM THE CROSSING
## instead of by index — the same intent the old `RIVER_STATIONS` had
## ("three stations, spread down the course, none of them near the
## narrows"), expressed as a property of the course's own shape rather than
## three numbers that happened to be true of one specific array. See
## `_pick_river_stations` below.
const RIVER_NARROWS := Vector2(-152.0, 4203.0)
## Stay at least this far from the crossing — well outside the ~3.6m
## half-width the channel narrows to there (this task's brief; the old
## course's own narrows shrank to the same 3.6m half-width at its index 7),
## so a "mid-river" station cannot land in the one place the river is meant
## to be crossable.
const RIVER_NARROWS_CLEARANCE := 120.0
const RIVER_STATION_COUNT := 3
const RIVER_START_BACK := 14.0
const RIVER_WALK_FRAMES := 420
## The player has crossed the river when they are this far past the
## centreline. Deliberately NOT a small number, and the reason is the shape of
## the thing: away from the narrows the channel is 22-26m wide (~10-13m
## half-width — this task's brief gives the same figures the old course's own
## non-narrows stations used, e.g. index 11-15 above), so a player who slides
## down the near wall and comes to rest on the bed is legitimately within a
## few metres of the centreline without having crossed anything. 12m puts
## them up the FAR wall. Unchanged from the old course: verified against the
## new course's own dimensions above rather than assumed, and they are the
## same order of magnitude.
const RIVER_CROSSED_M := 12.0
## And where they must have ended up: still on the near side, or at worst on
## the bed. Anything past this is standing on the far bank. Unchanged for the
## same reason as `RIVER_CROSSED_M` above.
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

	var stations := _pick_river_stations(course)
	if stations.is_empty():
		failures.append("could not find any river course station %.0fm clear of the Old Mill Crossing narrows; SE21's river may be authored entirely inside the narrows" % RIVER_NARROWS_CLEARANCE)
		return

	for index in stations:
		var here := _course_point(course, index)
		var next := _course_point(course, index + 1)
		var previous := _course_point(course, maxi(index - 1, 0))
		var along := (next - previous).normalized()
		var across := Vector2(-along.y, along.x)
		# Toward the far bank, whichever side that is here: the course bends,
		# and a hardcoded +X would stop testing the thing the moment it moves.
		# The reference point below is the village — `MEADOWS_MACRO_LAYOUT.md`
		# §3: "Band 0 and the whole of the shipped village do not move at
		# all" — which was already far north of the old course near the
		# village and is now ~4,100m north of the relocated one. It is an
		# even safer "near/village side" anchor than it was before, not a
		# value that needed to move with the river.
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


## How far a candidate station's own course point must sit inside
## `WORLD_X_WEST/EAST` (the same bounds `_check_perimeter` walks against) to be
## usable. OW5E: `terrain_playground.json`'s own `_comment_ow5c_rederive`
## states the river's course is AUTHORED to run ~100m past both world edges on
## purpose — the same "runs past the ring, no walking around either end"
## design `spokes.routes` already uses — so a candidate near either end is not
## a world defect to fix; it is this test trying to stand a player outside the
## playable world. `RIVER_START_BACK` (the near-bank offset every station
## backs off by) plus a river's own half-width (10-13m away from the narrows)
## is comfortably covered by a round 40m margin.
const RIVER_EDGE_MARGIN := 40.0


## Picks up to `RIVER_STATION_COUNT` indices, spread across whatever course
## points sit at least `RIVER_NARROWS_CLEARANCE` from the Old Mill Crossing,
## rather than trusting fixed indices to still mean "mid-river" once the
## corridor course's real values land in `terrain_playground.json`. Excludes
## the array's own first and last point too — those are the course's own
## bank ends, not a mid-river station, the same exclusion the old
## `[11,13,15]` implicitly had by never naming index 0 or the last index.
func _pick_river_stations(course: Array) -> Array[int]:
	var candidates: Array[int] = []
	for i in range(1, course.size() - 1):
		var pt := _course_point(course, i)
		if pt.distance_to(RIVER_NARROWS) < RIVER_NARROWS_CLEARANCE:
			continue
		if pt.x < WORLD_X_WEST + RIVER_EDGE_MARGIN or pt.x > WORLD_X_EAST - RIVER_EDGE_MARGIN \
				or pt.y < WORLD_Z_NORTH + RIVER_EDGE_MARGIN or pt.y > WORLD_Z_SOUTH - RIVER_EDGE_MARGIN:
			continue
		candidates.append(i)

	var stations: Array[int] = []
	if candidates.is_empty():
		return stations
	for k in RIVER_STATION_COUNT:
		var f := float(k) / float(maxi(RIVER_STATION_COUNT - 1, 1))
		var idx: int = candidates[int(round(f * float(candidates.size() - 1)))]
		if not stations.has(idx):
			stations.append(idx)
	return stations


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
##
## The quarry itself moved for the corridor (floor/site now at (400,1800),
## was (23,158) — this task's own brief) but this function never references
## either location: it finds `OldQuarry` and every `rootstone`-tagged node by
## NAME, not by position, and asks the quarry node itself for its own stats
## and the first deposit's own `global_position`. The relocation is
## transparent to this test for the same reason it is to `_check_south_bridge`
## above.
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
##
## Scans the `Vegetation` node's own children by name prefix and samples the
## heightfield at each rock's own position — nothing here references a
## world-size-specific coordinate, so this needed no change for the corridor.
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


## R7.8: every house door starts shut, physically blocks the doorway, and
## opens into a real room on interact -- checked against every prefab that
## authored a `door` in building_prefabs.json, not just one, since the bug
## this catches (a doorway hole with no matching gate, or a gate that never
## clears) is per-prefab data, not shared code.
const VILLAGE_DOOR_PREFABS: Array[String] = ["cottage_a", "cottage_b", "ranger_station", "inn"]

func _check_village_doors(world: Node, failures: Array[String]) -> void:
	var village: Node = world.get_node_or_null(^"Village")
	if village == null:
		failures.append("no Village in the scene; village.gd did not build")
		return

	for prefab_name in VILLAGE_DOOR_PREFABS:
		var building: Node3D = null
		for child in village.get_children():
			if (child as Node).name.begins_with(prefab_name + "_"):
				building = child as Node3D
				break
		if building == null:
			failures.append("no placed '%s' in the Village; cannot check its door" % prefab_name)
			continue

		var door: Node3D = building.get_node_or_null(^"Door") as Node3D
		if door == null:
			failures.append("%s has no Door -- it is a solid brick with a painted-on door" % prefab_name)
			continue
		var prompt: Node3D = door.get_node_or_null(^"Prompt") as Node3D
		if prompt == null:
			failures.append("%s's Door has no interact prompt" % prefab_name)
			continue
		var interior: Node3D = building.get_node_or_null(^"Interior") as Node3D
		if interior == null or interior.get_child_count() == 0:
			failures.append("%s has a door but no furnished room behind it" % prefab_name)
			continue

		if bool(door.call("is_open")):
			failures.append("%s's door started open on a fresh world" % prefab_name)
			continue

		var gate := _door_gate_shape(door)
		if gate == null:
			failures.append("%s's door has no gate collider; a shut door blocks nothing" % prefab_name)
			continue
		if gate.disabled:
			failures.append("%s's gate starts disabled; a shut door blocks nothing" % prefab_name)
			continue

		prompt.call("interaction_activate")
		await physics_frame
		if not bool(door.call("is_open")):
			failures.append("%s's door did not open on interact" % prefab_name)
			continue
		if not gate.disabled:
			failures.append("%s's gate stayed enabled after the door opened; the doorway is still blocked" % prefab_name)
			continue

		print("  %-16s door: shut and blocking -> interact -> open and clear, room behind it (%d pieces)" % [
			prefab_name, interior.get_child_count()
		])


func _door_gate_shape(door: Node3D) -> CollisionShape3D:
	var gate := door.get_node_or_null(^"Gate")
	if gate == null:
		return null
	for child in gate.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null
