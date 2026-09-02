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
## [-1024, 1024], z in [-512, 7680] — `docs/specs/MEADOWS_MACRO_LAYOUT.md` §2, the
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
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

## OF15: the owner reported movement getting WEDGED against geometry rather
## than passing through -- a different shape of bug than falling through the
## floor, which is everything above. Falling-through shows up as height loss;
## a wedge shows up as the player holding an input, still grounded, and simply
## not going anywhere -- snagged on a prop collider or a seam. Checked every
## `STUCK_CHECK_INTERVAL` frames as distance moved since the last checkpoint;
## `STUCK_MIN_PROGRESS` is well under the ~1.65m a clear 20-frame window covers
## at the 5.0 m/s walk speed (data/config/movement.json), so a real climb or a
## glancing brush off a rock will not trip it -- only a dead stop.
## `STUCK_SUSTAIN_WINDOWS` requires three such windows running (~1s) before
## logging, so a single frame of physics settling at a leg's start does not
## count.
##
## This rides along the legs the sweep already walks and adds no frames of its
## own, which is why it is worth having even though the wedge OF15 was filed
## for turned out to be Captain Halder's capsule collider rather than terrain:
## the next one will be found by something watching every leg, not by a
## check aimed at the last cause.
const STUCK_CHECK_INTERVAL := 20
const STUCK_MIN_PROGRESS := 0.5
const STUCK_SUSTAIN_WINDOWS := 3
## Do not flag stalls within this far of a world edge: the perimeter stops the
## player there ON PURPOSE, and `_check_perimeter` already proves it does.
## OF15 wrote this as a 200m RADIUS, because the world was then a disc with a
## ring fence at ~235m. The corridor has no centre and no ring -- distance from
## the origin means nothing across 8192x2048m -- so the same intent is a margin
## measured from whichever edge is nearest.
const STUCK_EDGE_MARGIN := 60.0
## Nor flag a stall against ground the player is not ALLOWED to climb. A face
## steeper than the controller's `floor_max_angle` (45 degrees) stops a walk on
## purpose, and from inside the walk loop that is indistinguishable from a
## wedge: input held, still grounded, going nowhere.
##
## OF15 did not need this — under the old 512m disc its interior was gentle and
## the only deliberate stop was the ring fence, which its radius exclusion
## covered. The corridor is built out of authored rises, gorge rims and spoke
## carves whose whole job is to be unclimbable, so without this the check fires
## on correct terrain. Verified at the first place it fired, ~(62, -105): the
## ground climbs 0.0 -> 2.6 -> 7.1m over 8m eastward (~48 degrees), a shape
## query there finds Terrain3D and no prop at all, and the player walks away
## west unobstructed. That is the meadow working.
##
## Sampled at two radii, not one. `slope_degrees_at` on the exact spot reads the
## gentle ground the player is STANDING on (8.8 degrees where this fired), and a
## single 4m ring still misses a face that begins just past it — measured at the
## same spot, the ground runs 0.22 -> 0.15m out to 4m east and only then climbs
## to 4.50m by 8m (~47 degrees). Both rings are needed; either alone lets a real
## rise through as a false wedge.
const STUCK_SLOPE_PROBE_M: Array[float] = [4.0, 8.0]
const STUCK_MAX_WALKABLE_DEG := 45.0
## Nor flag a stall the player could simply walk out of. Eight compass
## directions at `STUCK_ESCAPE_M` -- far enough to clear the obstacle the walk
## is pressed against, short enough that an escape route this finds is one the
## player could actually take. See `_can_walk_away`.
const STUCK_ESCAPE_DIRECTIONS := 8
const STUCK_ESCAPE_M := 1.5


## True when any ground near `pos` is too steep for the player to climb, i.e.
## something is legitimately in the way rather than snagging them.
func _blocked_by_unclimbable_ground(field: RefCounted, pos: Vector3) -> bool:
	for radius: float in STUCK_SLOPE_PROBE_M:
		for offset in [
			Vector2(radius, 0.0), Vector2(-radius, 0.0),
			Vector2(0.0, radius), Vector2(0.0, -radius),
		]:
			var slope: float = field.slope_degrees_at(pos.x + offset.x, pos.z + offset.y)
			if not is_nan(slope) and slope > STUCK_MAX_WALKABLE_DEG:
				return true
	return false


## True when the player could walk out of here under their own steam, i.e.
## something is merely IN THE WAY rather than holding them.
##
## OF15's wedge was a prop collider (Captain Halder's capsule), so the check
## cannot simply excuse every prop. What separates the two is whether the
## player can leave: a body pressed against a rock has open meadow behind and
## either side of them; a body snagged on a bad collider does not.
##
## This is the prop analogue of `_blocked_by_unclimbable_ground` above, and it
## exists for the same reason -- the walk holds ONE direction for the whole
## leg, so the moment it meets any solid object it dead-stops for the rest of
## it. That makes the constants' stated assumption ("only a snag causes a dead
## stop, a glancing brush off a rock will not trip it") false for a
## straight-line hold: a single scattered rock anywhere along a 120m leg reads
## as a wedge. Measured at the spot this first fired, (53, -65): the blocker is
## `Vegetation/Rock_Medium_1_Collision` occupying (52..54, -63..-64), the
## terrain there runs -0.83m to +1.05m over eight metres (about 14 degrees, well
## inside the slope exclusion), and every direction except backward is clear.
## That is the meadow working, and it had been failing this test at random on
## main for days depending on how the runner's physics timing steered the walk.
##
## Each probe is placed at the GROUND under it, carrying the player's own
## height above ground with it. Reusing the player's absolute y instead reads
## every upslope direction as blocked -- the capsule simply sinks into the
## rising ground -- which is how the first version of this returned "cannot
## walk away" at a spot with open meadow on seven sides. Terrain is not this
## check's business in any case: `_blocked_by_unclimbable_ground` above is
## what governs ground the player may not climb.
##
## Queried with the player's OWN collider rather than a guessed capsule, so
## "can they fit" means the same thing here as it does in the walk.
func _can_walk_away(field: RefCounted, player: CharacterBody3D, pos: Vector3) -> bool:
	var space := player.get_world_3d().direct_space_state
	var shape: Shape3D = null
	## The collider's offset from the body's own origin. The player's origin
	## sits at their feet and the capsule is centred about a metre up, so
	## placing the bare shape at a ground position buries half of it and every
	## direction reads as blocked.
	var shape_offset := Vector3.ZERO
	for child in player.get_children():
		var cs := child as CollisionShape3D
		if cs != null and not cs.disabled and cs.shape != null:
			shape = cs.shape
			shape_offset = cs.position
			break
	if shape == null:
		# No collider to reason with. Say nothing rather than excuse a stall
		# on the strength of a failed lookup.
		return false
	var here_ground: float = field.height_at(pos.x, pos.z)
	if is_nan(here_ground):
		return false
	var above_ground: float = pos.y - here_ground
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collide_with_areas = false
	q.collide_with_bodies = true
	q.exclude = [player.get_rid()]
	for step in STUCK_ESCAPE_DIRECTIONS:
		var angle: float = TAU * float(step) / float(STUCK_ESCAPE_DIRECTIONS)
		var to := Vector2(cos(angle), sin(angle)) * STUCK_ESCAPE_M
		var ground: float = field.height_at(pos.x + to.x, pos.z + to.y)
		if is_nan(ground):
			continue
		q.transform = Transform3D(Basis(), Vector3(
			pos.x + to.x, ground + above_ground, pos.z + to.y) + shape_offset)
		if space.intersect_shape(q, 1).is_empty():
			return true
	return false


## One tracker per concurrent walk. Returned as a Dictionary rather than a
## class because SceneTree test scripts here do not otherwise define inner
## classes (see `_check_gated_crossing` etc.) and this is the smallest
## consistent addition.
func _new_stuck_tracker() -> Dictionary:
	return {
		"checkpoint": Vector3.ZERO,
		"window_frames": 0,
		"stalled_windows": 0,
		"stuck": false,
	}


## True when this position is close enough to a world edge that the perimeter,
## not a wedge, is the likely reason a walk stopped.
func _near_world_edge(pos: Vector3) -> bool:
	return pos.x - WORLD_X_WEST < STUCK_EDGE_MARGIN \
		or WORLD_X_EAST - pos.x < STUCK_EDGE_MARGIN \
		or pos.z - WORLD_Z_NORTH < STUCK_EDGE_MARGIN \
		or WORLD_Z_SOUTH - pos.z < STUCK_EDGE_MARGIN


## Call once per physics frame from inside a walk loop. Appends to
## `stuck_log` the first time a stall crosses the sustain threshold; prints
## when it releases so the log reads as episodes, not a spam of frames.
func _stuck_tick(tracker: Dictionary, field: RefCounted, player: CharacterBody3D, pos: Vector3, grounded: bool, label: String, stuck_log: Array) -> void:
	if tracker["window_frames"] == 0:
		tracker["checkpoint"] = pos
	tracker["window_frames"] = int(tracker["window_frames"]) + 1
	if int(tracker["window_frames"]) < STUCK_CHECK_INTERVAL:
		return
	tracker["window_frames"] = 0

	var checkpoint: Vector3 = tracker["checkpoint"]
	var moved := Vector2(pos.x, pos.z).distance_to(Vector2(checkpoint.x, checkpoint.z))

	if grounded and moved < STUCK_MIN_PROGRESS and not _near_world_edge(pos) \
			and not _blocked_by_unclimbable_ground(field, pos) \
			and not _can_walk_away(field, player, pos):
		tracker["stalled_windows"] = int(tracker["stalled_windows"]) + 1
		if int(tracker["stalled_windows"]) >= STUCK_SUSTAIN_WINDOWS and not bool(tracker["stuck"]):
			tracker["stuck"] = true
			print("  STUCK: %-14s wedged near %.1f, %.1f, %.1f (moved %.2fm over the last %.1fs)" % [
				label, pos.x, pos.y, pos.z, moved, STUCK_CHECK_INTERVAL * STUCK_SUSTAIN_WINDOWS / 60.0
			])
			stuck_log.append({"label": label, "pos": pos})
	else:
		if bool(tracker["stuck"]):
			print("  ...%-14s freed near %.1f, %.1f, %.1f" % [label, pos.x, pos.y, pos.z])
		tracker["stalled_windows"] = 0
		tracker["stuck"] = false


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
	## OF15: every place a leg below logged a sustained wedge. Reported in
	## full at the end regardless of pass/fail so a location survives even
	## when nothing else about the run looks wrong.
	var stuck_positions: Array = []
	## OF15's slope exclusion reads the same analytic heightfield the bake was
	## made from, so it costs no physics query per frame.
	var stuck_field: RefCounted = HEIGHTFIELD.new()

	for direction in ["move_forward", "move_right", "move_back", "move_left"]:
		Input.action_press(direction)
		var stuck_tracker := _new_stuck_tracker()
		for i in LEG_FRAMES:
			await physics_frame
			var pos := player.global_position
			_stuck_tick(stuck_tracker, stuck_field, player, pos, player.is_on_floor(), direction, stuck_positions)
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
	await _check_sigil_gate(world, player, failures)
	await _check_village_doors(world, failures)
	_check_no_severed_spoke_blocks_a_route(failures)

	print("")
	if not stuck_positions.is_empty():
		var coords: Array[String] = []
		for entry: Dictionary in stuck_positions:
			var pos: Vector3 = entry["pos"]
			coords.append("%s at (%.0f, %.0f)" % [entry["label"], pos.x, pos.z])
		failures.append("player got wedged (held an input, stayed grounded, moved under %.1fm for %.1fs+) at %d spot(s): %s" % [
			STUCK_MIN_PROGRESS, STUCK_CHECK_INTERVAL * STUCK_SUSTAIN_WINDOWS / 60.0, stuck_positions.size(), ", ".join(coords)
		])
	if failures.is_empty():
		print("traversal: OK — the ground is solid across the playground, the perimeter holds, the kill volume returns a fallen player to spawn, the South Bridge is shut without its key and open with it, the Old Quarry past it stands and holds a player up, the river cannot be walked across between its crossings, the Old Mill Crossing is shut without its gear and open with it, the Sigil Gate's causeway cannot be walked past locked and genuinely opens with all three Sigils, every village house door starts shut, blocks the doorway, and opens on interact into a real room, and no severed spoke's blocker lies across a route the player is asked to walk.")
		quit(0)
	else:
		for line in failures:
			print("traversal FAIL: %s" % line)
		quit(1)



## SPINE-WEDGE. A severed spoke's blocker may never touch a route the game
## asks the player to walk.
##
## THE DEFECT THIS EXISTS FOR, because it is not the obvious one.
##
## `storm_road`'s `collapsed_bridge` carve was 55 half_length + 18 end_fade --
## a 73m reach each way, i.e. a 146m trench across the corridor, to sever a 3m
## road. The spine's own last leg to the stronghold gate crossed it at full 11m
## depth. The trench carries a `CarveFailsafe`, so a body walking the authored
## trail fell in and was teleported back to the storm road's end, walked back,
## fell in again -- six times, and the last 57.6m of the corridor's 11.3km were
## not walkable at all. A half-hour walk with a real body found it and reported
## it as "Terrain, 12-17 degrees", which are walkable angles: the trail's
## problem was never the ground's steepness, and no amount of looking at the
## terrain would have found the spoke.
##
## WHY THIS SHAPE OF CHECK AND NOT A SLOPE SURVEY. Both spokes and the trail
## are authored polylines in one config, and `OW5C` re-sited all seven spokes
## by a rotate+scale+translate transform while `trail.bands[]` was authored
## separately -- so the two were never compared, and nothing anywhere compares
## them. That is an arithmetic question about two arrays, answerable exactly, in
## milliseconds, with no world and no heightfield: a carve's footprint is a
## rotated rectangle (half_length+end_fade along its axis, half_width+rim
## across) and a route is a polyline. This clips each segment against each
## rectangle. It is deliberately EXACT rather than sampled -- a 1m sample walk
## can step over a corner clip, and a guard that can miss is a guard nobody can
## rely on.
##
## The wider survey does not fit in CI and lives in two tools instead:
## `tools/_probe_spine_slope.gd` (every authored route against the analytic
## landform, no bake needed) and `tools/_probe_ow5_walk.gd --mode=clear` (the
## player's own capsule stood at every point of every route, naming every
## structure it does not fit past). Run those when authoring a route. This
## asserts the one invariant that is absolute, is true today, and has no
## legitimate exception: a blocker built to sever ONE road must not lie across
## another.
##
## `crossings[]` carves are deliberately NOT asserted here -- a crossing exists
## to be crossed, on the bridge that spans it, so a route passing through one is
## right when it is on the deck and wrong when it is not. That distinction needs
## the deck, and the one place it is currently wrong (the spine enters the South
## Bridge gully 8.7m west of the crossing's own road) is a trail-routing fix
## owned by `SPINE-LAYOUT`. Reported below as a NOTE so it is visible in CI
## without being a failure this branch cannot fix.
func _check_no_severed_spoke_blocks_a_route(failures: Array[String]) -> void:
	var cfg := _terrain_config()
	if cfg.is_empty():
		failures.append("could not read terrain_playground.json; spoke/route clearance is unchecked")
		return
	var routes := _authored_routes(cfg)

	for entry in (cfg.get("spokes", {}) as Dictionary).get("routes", []):
		var blocker: Dictionary = (entry as Dictionary).get("blocker", {})
		var carve: Dictionary = blocker.get("carve", {})
		if carve.is_empty():
			continue
		for route: Dictionary in routes:
			var hit := _route_enters_carve(route["points"], carve)
			if hit == Vector2.INF:
				continue
			failures.append(("severed spoke '%s' (%s, %.0fm deep) lies across the authored route '%s' " +
				"near (%.0f, %.0f) -- a blocker sized to sever its own road is cutting a road " +
				"the player is asked to walk") % [
				str((entry as Dictionary).get("id", "?")), str(blocker.get("kind", "?")),
				float(carve.get("depth", 0.0)), str(route["name"]), hit.x, hit.y])

	for entry in cfg.get("crossings", []):
		var carve: Dictionary = (entry as Dictionary).get("carve", {})
		if carve.is_empty():
			continue
		for route: Dictionary in routes:
			var hit := _route_enters_carve(route["points"], carve)
			if hit == Vector2.INF:
				continue
			var off := _distance_to_polyline(hit, (entry as Dictionary).get("road", []))
			if off <= CROSSING_ON_ROAD_M:
				continue
			print("  NOTE: route '%s' enters the %s gully at (%.0f, %.0f), %.1fm off that crossing's own road" % [
				str(route["name"]), str((entry as Dictionary).get("id", "?")), hit.x, hit.y, off])
			print("        -- the bridge is on the road; SPINE-LAYOUT owns re-aiming the trail at it.")


## How close a route has to pass to a crossing's own road to count as being on
## the bridge. `paths.width` is 3.0 with a 1.5m shoulder, so 3m either side of
## the road's centreline is generous rather than tight.
const CROSSING_ON_ROAD_M := 3.0


func _terrain_config() -> Dictionary:
	var f := FileAccess.open("res://data/config/terrain_playground.json", FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


## Every route the game asks a player to walk: the spine, the regional loops
## and the shortcuts. `river_ferry_landing` carries no `points` (it is a
## from/to pair), which is why the size guard is here and not assumed away.
func _authored_routes(cfg: Dictionary) -> Array:
	var trail: Dictionary = cfg.get("trail", {})
	var out: Array = []
	var spine: Array[Vector2] = []
	for band in trail.get("bands", []):
		for p in (band as Dictionary).get("points", []):
			var v := Vector2(float(p[0]), float(p[1]))
			if spine.is_empty() or spine[spine.size() - 1].distance_to(v) > 0.01:
				spine.append(v)
	if spine.size() >= 2:
		out.append({"name": "spine", "points": spine})
	for key in ["loops", "shortcuts"]:
		for entry in trail.get(key, []):
			var pts: Array[Vector2] = []
			for p in (entry as Dictionary).get("points", []):
				pts.append(Vector2(float(p[0]), float(p[1])))
			if pts.size() >= 2:
				out.append({"name": "%s:%s" % [key, str((entry as Dictionary).get("id", "?"))],
					"points": pts})
	return out


## Where a polyline first enters a carve's footprint, or `Vector2.INF`.
##
## The footprint is the rectangle outside which `playground_heightfield.gd::
## _prepared_carve_depth` returns exactly zero: |u| < half_length + end_fade
## along the carve's axis, |v| < half_width + rim across it. Clipping is
## Liang-Barsky in the carve's own frame -- exact, and cheap enough that every
## route against every carve is a few hundred microseconds.
func _route_enters_carve(points: Array, carve: Dictionary) -> Vector2:
	var raw: Array = carve.get("centre", [])
	if raw.size() < 2:
		return Vector2.INF
	var centre := Vector2(float(raw[0]), float(raw[1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var across := Vector2(-axis.y, axis.x)
	var half_u: float = float(carve.get("half_length", 0.0)) + float(carve.get("end_fade", 0.0))
	var half_v: float = float(carve.get("half_width", 0.0)) + float(carve.get("rim", 0.0))
	if half_u <= 0.0 or half_v <= 0.0:
		return Vector2.INF

	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var pa := Vector2((a - centre).dot(axis), (a - centre).dot(across))
		var pb := Vector2((b - centre).dot(axis), (b - centre).dot(across))
		var d := pb - pa
		var t0 := 0.0
		var t1 := 1.0
		var clipped := true
		for k in 2:
			var dk: float = d.x if k == 0 else d.y
			var pk: float = pa.x if k == 0 else pa.y
			var limit: float = half_u if k == 0 else half_v
			if absf(dk) < 0.000001:
				if pk < -limit or pk > limit:
					clipped = false
					break
				continue
			var lo := (-limit - pk) / dk
			var hi := (limit - pk) / dk
			if lo > hi:
				var swap := lo
				lo = hi
				hi = swap
			t0 = maxf(t0, lo)
			t1 = minf(t1, hi)
			if t0 > t1:
				clipped = false
				break
		if clipped:
			return a.lerp(b, (t0 + t1) * 0.5)
	return Vector2.INF


## Shortest distance from a point to a polyline, for the crossing note above.
func _distance_to_polyline(at: Vector2, raw: Array) -> float:
	var best := INF
	for i in range(raw.size() - 1):
		var a := Vector2(float(raw[i][0]), float(raw[i][1]))
		var b := Vector2(float(raw[i + 1][0]), float(raw[i + 1][1]))
		best = minf(best, at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b)))
	return best


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


## GATE-D5 REQUEST 2 / CHOKE-POINTS: the Sigil Gate, spec Band 4's last gate.
##
## Every other choke point in the chapter (South Bridge, Old Mill Crossing) is
## a deck over a fully carved channel, so a TERRAIN probe (`tools/
## _probe_crossings.gd`, run against the baked surface) can tell whether it is
## sealed on its own -- and did: SEALED at 45 and 60 degrees, everywhere. The
## Sigil Gate is different. `sigil_gate_gorge_west`/`_east` (terrain_
## playground.json) carve the flanking gorges, but deliberately leave a real,
## uncarved, walkable causeway between them (see those entries' own `_why`) --
## the gate at (63.6, 7400) is a `road_gate.gd` PROP standing on that open
## ground, not a deck over carved terrain. A terrain probe measures the gorges
## either side and correctly calls the causeway itself open; whether the
## PLAYER can actually get through it is entirely down to the gate's own
## `GateCollision` box, which no terrain probe has ever looked at.
##
## THE SUSPECT, found by measuring rather than assuming. `road_gate_leaf`
## (`building_prefabs.json`) is ~4.07m wide -- sized for the ~4.1m ROAD this
## same prefab shuts at the village gate (SA7), where flanking fence_run props
## do the actual work of blocking the shoulders. The Sigil Gate has no such
## flanking dressing: the gorges are its only flanking geometry, and they sit
## ~61m out along the causeway's own width, each reaching 54m back toward the
## gate -- a ~14m gap between them (`sigil_gate_gorge_west`'s own `_why`).
## A 4m leaf standing in the middle of a 14m gap, with nothing else in the
## world to stop a player, is "a gate inboard of that gap" in exactly the
## words `south_bridge.gd`'s own history warns about. `_sigil_causeway_gap`
## and the leaf's own live `box.size.x` below measure this instead of
## asserting it, and the walk at several points across that width is what
## actually decides it.
##
## Both directions matter for a different reason each: LOCKED has to hold
## (the reason this check exists at all), and UNLOCKED has to genuinely open
## -- a seal that also blocks the finale once the player has earned it would
## be a worse bug than the leak it replaced, and nothing else in the chapter
## re-tests this gate once it is open.
## No player strides this far in one physics frame. Anything larger is the
## kill volume returning a fallen body to spawn, which this walk must not score
## as forward progress -- see `_walk_at_the_sigil_gate`.
const STEP_SANITY_M := 5.0

const SIGIL_GATE_START_BACK := 12.0
const SIGIL_GATE_WALK_FRAMES := 420
## Same reasoning as BRIDGE_BLOCKED_M: a locked approach should stop at
## essentially zero penetration. A little slack for the capsule settling
## against the box before physics resolves the contact, not for a real gap.
const SIGIL_GATE_BLOCKED_M := 1.0
## Symmetric to BRIDGE_CROSSED_M / RIVER_CROSSED_M: comfortably past the
## leaf's own resting position so "reached the gate" cannot pass for "got
## through it".
const SIGIL_GATE_CROSSED_M := 8.0
## How far past the leaf's own measured half-width to test the "walked around
## it" approach. 1.0m clears the player's own 0.4m capsule radius with margin,
## so a pass here is a real gap next to the leaf, not the capsule grazing its
## edge.
const SIGIL_GATE_OFFSET_OUTSIDE_LEAF := 1.0
## How far inside the causeway's own true edge (see `_sigil_causeway_gap`) to
## test the widest plausible "walk around it" line, without putting the start
## point up on the gorge's own carved wall.
const SIGIL_GATE_OFFSET_NEAR_GORGE := 1.0


func _check_sigil_gate(world: Node, player: CharacterBody3D, failures: Array[String]) -> void:
	var gate: Node3D = world.get_node_or_null(^"SigilGate") as Node3D
	if gate == null:
		failures.append("no SigilGate in the scene; spec Band 4's last gate is not built")
		return
	var camera_rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if camera_rig == null:
		failures.append("no CameraRig in the scene; cannot aim a walk at the Sigil Gate")
		return
	var prompt: Node3D = gate.get_node_or_null(^"Interactable") as Node3D
	if prompt == null:
		failures.append("the Sigil Gate has no Interactable; it cannot be tried at all")
		return
	# Found BY TYPE, not by node path. `road_gate.gd` creates its shape with
	# `CollisionShape3D.new()` and never names it, so the auto-assigned name is
	# not reliably the literal "CollisionShape3D" a path assumes -- and the
	# earlier path-based lookup here reported "the Sigil Gate has no box
	# collider; nothing would ever stop a player at it" about a collider that is
	# present, enabled and correctly sited at (63.6, 7400).
	# `tools/_probe_sigil_gate_body.gd` measured it: GateCollision, BoxShape3D,
	# disabled=false, world-x 61.8..65.4. A test that says a real barrier is
	# absent is worse than no test, because the fix it invites is to build a
	# second one.
	var body: Node = gate.get_node_or_null(^"GateCollision")
	var shape: CollisionShape3D = null
	if body != null:
		for child in body.get_children():
			if child is CollisionShape3D:
				shape = child as CollisionShape3D
				break
	var box: BoxShape3D = shape.shape as BoxShape3D if shape != null else null
	if box == null:
		failures.append("the Sigil Gate has no box collider; nothing would ever stop a player at it")
		return
	if shape.disabled:
		failures.append("the Sigil Gate's collider is disabled before anyone opens it")
		return

	var game := root.get_node_or_null(^"Game")
	if game == null:
		failures.append("no Game autoload; the Sigil Gate has no inventory or flag store to read")
		return
	var inventory: RefCounted = game.get("inventory")
	var progression: RefCounted = game.get("progression")

	if bool(gate.call("is_open")):
		failures.append("the Sigil Gate started open on a fresh world; it is not a gate")
		return

	# Measured, not assumed: the leaf's real collider width against the real
	# gap the two gorges leave open, both read from the live node/config
	# rather than the numbers either script's own comments quote.
	var gate_xz := Vector2(gate.global_position.x, gate.global_position.z)
	var across := Vector2(gate.global_transform.basis.x.x, gate.global_transform.basis.x.z).normalized()
	var along := Vector2(-across.y, across.x)
	if along.y < 0.0:
		along = -along  # standardise "along" toward +z (the Hall side) so the prints below read consistently

	var leaf_half: float = box.size.x * 0.5
	# SIGIL-SEAL. The BARRIER is not only the leaf. `road_gate.gd` now fences
	# the causeway either side of the leaf out to its `seal_half_width`, and
	# those wings are separate StaticBody3D children (deliberately not children
	# of the swinging panel -- they are the wall, not the gate). Measuring the
	# leaf alone and calling the rest "open ground" was the proxy that made this
	# check fail against a causeway that is, in fact, sealed: the walk-past
	# probes below -- the real property -- all stop at the gate.
	#
	# So measure every collider the gate owns, projected onto the causeway's own
	# across-axis, and treat the widest CONTIGUOUS span through centre as the
	# barrier. Contiguous matters: three panels with a two-metre hole between
	# them are not a wall, and summing their widths would say they were.
	var spans: Array = []
	for child in gate.get_children():
		if not (child is StaticBody3D):
			continue
		for sub in (child as StaticBody3D).get_children():
			var cs := sub as CollisionShape3D
			if cs == null or cs.disabled:
				continue
			var cb := cs.shape as BoxShape3D
			if cb == null:
				continue
			var centre_x: float = (child as StaticBody3D).position.x + cs.position.x
			spans.append(Vector2(centre_x - cb.size.x * 0.5, centre_x + cb.size.x * 0.5))
	# Grow outward from centre through overlapping spans. Anything not reachable
	# without crossing a hole is not part of this barrier.
	var sealed_min := 0.0
	var sealed_max := 0.0
	for span: Vector2 in spans:
		if span.x <= 0.0 and span.y >= 0.0:
			sealed_min = span.x
			sealed_max = span.y
			break
	var grew := true
	while grew:
		grew = false
		for span: Vector2 in spans:
			if span.x <= sealed_max + 0.1 and span.y > sealed_max:
				sealed_max = span.y
				grew = true
			if span.y >= sealed_min - 0.1 and span.x < sealed_min:
				sealed_min = span.x
				grew = true
	var gap := _sigil_causeway_gap(gate_xz, across)
	if gap == Vector2.ZERO:
		failures.append("could not read the Sigil Gate's flanking gorges from terrain_playground.json; the causeway width is unknown")
		return
	print("  Sigil Gate: leaf collider half-width %.2fm; whole barrier seals %.2fm..%.2fm; open causeway runs %.2fm..%.2fm either side of centre (%.1fm total)" % [
		leaf_half, sealed_min, sealed_max, gap.x, gap.y, gap.y - gap.x])
	# A FAILURE, not a note. This was printed as an observation while the gap
	# was 13m and the leaf 3.6m -- which is precisely the defect, so observing
	# it was not enough. `south_bridge.gd`'s own history states the rule: "a
	# gate inboard of that gap gates nothing."
	#
	# Derived from the two flanking carves every run rather than compared
	# against a written-down width. An earlier version of this check carried
	# the measured causeway as constants (57.0..70.0) and went stale the moment
	# the carves were narrowed to close it -- the test then failed against a
	# causeway that no longer existed, which is a worse failure than the one it
	# was written to catch, because it looks like the fix did not work.
	if gap.x < sealed_min - 0.1 or gap.y > sealed_max + 0.1:
		failures.append(
			"the Sigil Gate barrier covers %.1fm of a %.1fm causeway -- %.1fm of open ground beside it, which a player walks around" % [
				sealed_max - sealed_min, gap.y - gap.x,
				maxf(0.0, sealed_min - gap.x) + maxf(0.0, gap.y - sealed_max)])

	var offsets: Array[float] = [
		0.0,
		leaf_half + SIGIL_GATE_OFFSET_OUTSIDE_LEAF, -(leaf_half + SIGIL_GATE_OFFSET_OUTSIDE_LEAF),
		gap.y - SIGIL_GATE_OFFSET_NEAR_GORGE, gap.x + SIGIL_GATE_OFFSET_NEAR_GORGE,
	]

	# --- locked: no Sigils in the satchel, and every approach across the
	# causeway's full width, from both sides, must be stopped. Both sides and
	# several offsets rather than one straight line for the same reason the
	# South Bridge's own OW5C seam bug demands it: a single fixed-x walk can
	# land exactly on a collision-shape-tile seam and report a false result
	# either way.
	for id: String in playground_world_gd().SIGIL_ITEM_IDS:
		var carried := int(inventory.call("count", id))
		if carried > 0:
			inventory.call("remove", id, carried)
	prompt.call("interaction_activate")
	await physics_frame
	if bool(gate.call("is_open")):
		failures.append("the Sigil Gate opened without any Sigils")
	await _dismiss_dialogue()
	if bool(progression.call("has", "hall_approach_open")):
		failures.append("trying the locked Sigil Gate set its open flag anyway")

	var worst_locked := -INF
	var worst_locked_label := ""
	for offset: float in offsets:
		for forward in [true, false]:
			var reached: float = await _walk_at_the_sigil_gate(world, player, camera_rig, gate_xz, across, along, offset, forward)
			var label := "%+.1fm off centre, %s" % [offset, "south->north" if forward else "north->south"]
			print("  Sigil Gate, locked, %s: reached %+.1fm past the gate" % [label, reached])
			if reached > worst_locked:
				worst_locked = reached
				worst_locked_label = label
	if worst_locked > SIGIL_GATE_BLOCKED_M:
		failures.append("the locked Sigil Gate can be walked past (%s, %.1fm past the gate) -- the causeway is not sealed" % [
			worst_locked_label, worst_locked])

	# --- unlocked: all three Sigils, and the gate must actually let the
	# player through its own centre. A seal that also blocks the finale is
	# worse than the leak it fixed.
	for id: String in playground_world_gd().SIGIL_ITEM_IDS:
		inventory.call("add", id, 1)
	prompt.call("interaction_activate")
	await physics_frame
	if not bool(gate.call("is_open")):
		failures.append("the Sigil Gate stayed shut with all three Sigils in the satchel")
		return
	await _dismiss_dialogue()
	for id: String in playground_world_gd().SIGIL_ITEM_IDS:
		if int(inventory.call("count", id)) != 0:
			failures.append("'%s' was not consumed opening the Sigil Gate" % id)
	if not bool(progression.call("has", "hall_approach_open")):
		failures.append("the open Sigil Gate did not set hall_approach_open; a reload would relock it")

	var best_open := -INF
	for forward in [true, false]:
		var reached: float = await _walk_at_the_sigil_gate(world, player, camera_rig, gate_xz, across, along, 0.0, forward)
		print("  Sigil Gate, unlocked, centre, %s: reached %+.1fm past the gate" % [
			"south->north" if forward else "north->south", reached])
		best_open = maxf(best_open, reached)
	if best_open < SIGIL_GATE_CROSSED_M:
		failures.append("could not cross the open Sigil Gate through its own centre (only %.1fm past the gate)" % best_open)
	if player.global_position.y < THROUGH_THE_FLOOR:
		failures.append("fell into a gorge while crossing the open Sigil Gate")


## Lazily loaded rather than a top-of-file `preload`: `playground_world.gd` is
## a large scene script and this test only needs the three Sigil item ids off
## it, read from the SAME constant `_build_sigil_gate()` configures the real
## gate with, so this cannot name a Sigil the gate does not actually require.
var _playground_world_script: GDScript = null


func playground_world_gd() -> GDScript:
	if _playground_world_script == null:
		_playground_world_script = load("res://scripts/world/playground_world.gd")
	return _playground_world_script


## The open, uncarved span either side of the gate's own centre, measured
## along `across` (the leaf's own width direction) from the two flanking
## gorge carves in terrain_playground.json -- `sigil_gate_gorge_west`'s and
## `_east`'s own reach (`half_length + end_fade`), not the `_wing` extensions,
## which pick up at the diagonals' own OUTWARD corners and cannot narrow this
## near-gate gap any further than the diagonals already do. Returns
## `(negative edge, positive edge)` of the open interval, or `Vector2.ZERO` if
## the config could not be read.
func _sigil_causeway_gap(gate_xz: Vector2, across: Vector2) -> Vector2:
	var cfg := _terrain_config()
	if cfg.is_empty():
		return Vector2.ZERO
	var by_id := {}
	for entry: Variant in cfg.get("crossings", []):
		by_id[str((entry as Dictionary).get("id", ""))] = entry
	var west: Dictionary = by_id.get("sigil_gate_gorge_west", {})
	var east: Dictionary = by_id.get("sigil_gate_gorge_east", {})
	if west.is_empty() or east.is_empty():
		return Vector2.ZERO
	var a := _carve_near_edge(west.get("carve", {}), gate_xz, across)
	var b := _carve_near_edge(east.get("carve", {}), gate_xz, across)
	if is_nan(a) or is_nan(b):
		return Vector2.ZERO
	return Vector2(minf(a, b), maxf(a, b))


## Where this one carve's own full-depth reach ends closest to the gate,
## projected onto `across`. Does not assume the carve's own axis matches
## `across` (it is expected to, per `sigil_gate_gorge_west`'s own `_why`, but
## this measures the actual overlap rather than trusting that) -- an
## authored carve on the wrong axis or the wrong side reports honestly rather
## than being silently folded into "whichever number is smaller".
func _carve_near_edge(carve: Dictionary, gate_xz: Vector2, across: Vector2) -> float:
	if carve.is_empty():
		return NAN
	var centre := Vector2(float(carve["centre"][0]), float(carve["centre"][1]))
	var axis := Vector2.RIGHT.rotated(deg_to_rad(float(carve.get("axis_deg", 0.0))))
	var reach: float = float(carve.get("half_length", 0.0)) + float(carve.get("end_fade", 0.0))
	var u := (centre - gate_xz).dot(across)
	var span := reach * absf(axis.dot(across))
	return u - signf(u) * span


## One walk at the Sigil Gate from a given lateral offset (along `across`,
## the leaf's own width direction) and a given side (`forward` = starting
## south of the gate and walking toward +z, the Hall side; false = the
## reverse). Returns how far past the gate's own centre, in the direction of
## travel, the player got -- the same "how far past the gap" convention
## `_walk_at_the_bridge` uses, so a positive number always means "got
## through" regardless of which side or offset produced it.
## Trying either gate SPEAKS -- `road_gate.gd::_try` calls `_say()`, which opens
## the dialogue panel -- and a modal panel captures input, so every
## `Input.action_press("move_forward")` after it does nothing.
##
## That is what made every Sigil walk report exactly its own start position
## while the South Bridge and Old Mill Crossing walks in the same run reached
## +22.8m and +23.6m. The gate was never blocking the player; the conversation
## was. Read as "the finale cannot be crossed", which is the most alarming thing
## a traversal test can say, and it was this file's own doing.
func _dismiss_dialogue() -> void:
	var panel := root.get_tree().get_first_node_in_group("dialogue_panel")
	if panel == null:
		return
	if bool(panel.call("is_open")):
		panel.call("close")
		await physics_frame


func _walk_at_the_sigil_gate(world: Node, player: CharacterBody3D, camera_rig: Node3D,
		gate_xz: Vector2, across: Vector2, along: Vector2, offset: float, forward: bool) -> float:
	var travel: Vector2 = along if forward else -along
	var start_xz: Vector2 = gate_xz + across * offset - travel * SIGIL_GATE_START_BACK
	var ground: float = float(world.call("ground_height_at", start_xz.x, start_xz.y))
	if is_nan(ground):
		return -INF
	# Starting inside a gorge measures the gorge, not the gate. With the
	# causeway narrowed to the leaf's own width, a start 12m along the gate's
	# axis can land in a trench -- and a walk that begins 11m down a hole
	# reports whatever the recovery does next.
	var gate_ground: float = float(world.call("ground_height_at", gate_xz.x, gate_xz.y))
	if not is_nan(gate_ground) and ground < gate_ground - 4.0:
		print("      (start %+.1fm off centre sits %.1fm below the gate -- inside a gorge, not on the causeway; skipped)" % [
			offset, gate_ground - ground])
		return -INF
	await _dismiss_dialogue()
	player.global_position = Vector3(start_xz.x, ground + 1.0, start_xz.y)
	player.velocity = Vector3.ZERO
	var outward := Vector3(travel.x, 0.0, travel.y)
	camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
	for i in 10:
		await physics_frame

	# A FALL IS NOT A CROSSING, and this walk could not tell the difference.
	#
	# Both gorges are 11m deep and the causeway between them is now barely
	# wider than the leaf, so a walk that drifts off it falls in -- and
	# `water_hazard`/the kill volume RETURNS A FALLEN PLAYER TO SPAWN. Spawn is
	# ~7.4km from this gate, so `travel.dot(here - gate_xz)` then reports
	# thousands of metres of "progress" and the check reads a fall as a player
	# strolling past a locked gate.
	#
	# The tell was that locked and unlocked runs reported the SAME +6466.6m.
	# A number that does not change with the thing under test is not measuring
	# the thing under test -- the same reasoning `south_bridge.gd`'s
	# `_comment_ow5c_seam` used when its walk stopped at 1.4m "regardless of
	# gate state" and the cause turned out to be a collision-tile seam.
	#
	# So progress is only counted while the player is still walking: a step
	# larger than STEP_SANITY_M in one physics frame is a teleport, not a
	# stride, and the walk stops there and keeps what it had.
	var best := -INF
	var previous := player.global_position
	Input.action_press("move_forward")
	for i in SIGIL_GATE_WALK_FRAMES:
		await physics_frame
		var here := player.global_position
		if here.distance_to(previous) > STEP_SANITY_M:
			print("      (walk abandoned at frame %d: the player moved %.0fm in one frame -- a fall and respawn, not a crossing)" % [
				i, here.distance_to(previous)])
			break
		previous = here
		var depth: float = travel.dot(Vector2(here.x, here.z) - gate_xz)
		best = maxf(best, depth)
	Input.action_release("move_forward")
	for i in 20:
		await physics_frame
	return best


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
	# BAND-SPLIT: the `nodes` array is per-band now (bands/<band>/harvest.json).
	# Counted through the same merge the world places from, so `wanted` cannot
	# drift to 0 and turn the check below into a no-op.
	for entry: Variant in BAND_CONTENT.load_config("res://data/config/harvest.json", "nodes").get("nodes", []):
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
##
## STRANDED-P3 CI investigation (2026-08-23): `verify-core-verb-shard` failed
## this exact walk at the Old Mill Crossing twice on GitHub's runners (+6.5m,
## then +8.5m past the gap, both short of `BRIDGE_CROSSED_M`), while the South
## Bridge (identical function, identical teleport-then-walk shape) passed on
## the same runs at its own historical margin. Root-caused, not guessed: a
## GATE-D3 wild-density cluster (`data/config/bands/band3_the_river_lock/
## spawns.json` order 3037, four `galecrest`) was centred close enough to the
## crossing, with a wide enough spawn/wander reach, that a creature could
## stand ON the deck -- reproduced directly with `tools/_probe_mill_stall.gd`,
## which caught the walk stalled at depth 7.06m, blocked by
## `get_slide_collision()` naming `Wild_galecrest_3037_1` as the collider. The
## fix is the spawn table (moved deeper onto the far bank, radius shrunk so
## even a full wander excursion stays clear of the crossing) -- see that
## entry's own `_comment_stranded_p3_deck_clearance` and
## `ralph/GATE_D_REMAINDERS.md` §8. Nothing in this walk needed to change; kept
## as it was before this investigation.
## BREADCRUMB-TELEPORT-RACE. This teleports the player straight to the bridge
## rather than walking them there, and `player_controller.gd`'s entombment
## failsafe (`_recover_if_entombed`/`_drop_breadcrumb`) only ever records a
## breadcrumb on a frame where the body is BOTH on the floor AND has moved
## more than `_unstick_progress_m` (8cm) since its last recorded anchor. A
## fresh teleport satisfies the second half every frame of the fall (each
## frame's position differs from the last-updated anchor by more than 8cm)
## but never the first half until the body actually lands -- and the anchor
## keeps sliding to match the falling position every one of those airborne
## frames, so by the exact frame landing happens the remaining delta from the
## just-updated anchor can easily be under 8cm again. When that race loses,
## the ONLY breadcrumb on record stays whatever real ground the player last
## walked away from under their own power somewhere else entirely in the
## world -- for this file, the perimeter cap-walk, kilometres away. Getting
## held at the still-locked gate for `unstick_after` seconds then recovers
## the player onto THAT breadcrumb instead of the bridge approach, which
## reads as having walked straight through the gate.
##
## A real player is never teleported, so this is a pure test-harness gap, not
## a production bug -- confirmed against `player_controller.gd`'s own header
## on `_recover_if_entombed`: "RECOVERY REWINDS, IT DOES NOT INVENT. The first
## choice is always a breadcrumb -- ground this body stood on and walked away
## from" is exactly what the entombment failsafe promises and is doing
## correctly; it has just never been told about a spot the harness placed the
## body at directly. Fixed here, not there: settle for real (wait for
## `is_on_floor()`, not a fixed frame count that may land mid-fall depending
## on the drop height) and then hand the controller a real breadcrumb at
## journey's start explicitly, the one production movement would have left
## walking up to the bridge for real.
func _walk_at_the_bridge(bridge: Node3D, player: CharacterBody3D, camera_rig: Node3D) -> float:
	var start: Vector2 = bridge.call("near_point", BRIDGE_START_BACK)
	var target: Vector2 = bridge.call("far_point", BRIDGE_START_BACK)
	var ground: float = float(bridge.get_parent().call("ground_height_at", start.x, start.y))
	player.global_position = Vector3(start.x, ground + 1.0, start.y)
	player.velocity = Vector3.ZERO
	var outward := Vector3(target.x - start.x, 0.0, target.y - start.y).normalized()
	camera_rig.set("yaw", Vector3(0.0, 0.0, -1.0).signed_angle_to(outward, Vector3.UP))
	for i in 90:
		await physics_frame
		if player.call("is_on_floor"):
			break
	# A few more frames once grounded, not just the first frame `is_on_floor()`
	# reads true: the landing can still be settling (a small bounce or slide)
	# for a frame or two, and `_drop_breadcrumb` is only asked once, so it
	# should record a position the body is actually resting at.
	for i in 10:
		await physics_frame
		if player.has_method("_drop_breadcrumb"):
			player.call("_drop_breadcrumb", player.global_position)

	# THE SETTLE-AND-BREADCRUMB ABOVE IS NECESSARY BUT NOT SUFFICIENT, and this
	# guard is the half that actually holds the check honest.
	#
	# `player_controller.gd::_recovery_position()` skips any breadcrumb closer
	# than `_unstick_min_distance_m` (`movement.json`'s
	# `min_recovery_distance_m`, 6.0m) -- correctly, since rewinding a metre
	# just re-enters the same hole. But the breadcrumb planted above is at the
	# spot the body was placed at, and when the body is entombed there it never
	# moves horizontally, so that breadcrumb is ALWAYS inside the skip radius
	# and can never be the one chosen. Recovery then falls back to the only
	# other thing on record -- the perimeter cap-walk, kilometres away -- and
	# `depth_past_crossing` scores the teleport as having strolled past a
	# locked gate. Observed 3/3 attempts, byte-identical: entombed at
	# (7.9, -3.4, 1319.0), recovered to (505.0, 8.2, 7678.4), reported
	# "+6348.4m past the gap" against an unlocked run's honest +22.9m.
	#
	# So progress is only counted while the player is still WALKING, exactly as
	# `_check_sigil_gate` already does for the same class of failure (a fall and
	# respawn there, an entombment recovery here -- both teleports, both scored
	# as progress by a walk that could not tell the difference). A step larger
	# than STEP_SANITY_M in one physics frame is not a stride: stop and keep
	# what was earned on foot.
	#
	# This deliberately does NOT touch the 6.0m skip radius. That rule is
	# production behaviour protecting real players from being rewound into the
	# hole they just fell in; a test that cannot describe its own teleports is
	# the thing that is wrong here.
	var best := -INF
	var previous := player.global_position
	Input.action_press("move_forward")
	for i in BRIDGE_WALK_FRAMES:
		await physics_frame
		var here := player.global_position
		if here.distance_to(previous) > STEP_SANITY_M:
			print("      (walk abandoned at frame %d: the player moved %.0fm in one frame -- an entombment recovery, not a crossing)" % [
				i, here.distance_to(previous)])
			break
		previous = here
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
