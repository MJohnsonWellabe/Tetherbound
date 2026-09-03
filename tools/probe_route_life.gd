extends SceneTree

## WORLD-LIFE-0903. Walks the real Band 1 route -- village to South Bridge --
## under real player input, and measures whether the meadow actually reads as
## alive along the way.
##
##   godot --headless --path . --script tools/probe_route_life.gd
##
## BAND1_ROUTE_INVESTIGATION.md's finding was that ~230 wild creatures exist
## along this route but nothing about them is VISIBLE from the road: every
## wild stays within 7m of its own spawn for life, notices the player only at
## 9-14m, and most clusters sit 20-40m off the road. This probe is the
## acceptance check for the fix -- `wander_radius` widened per cluster
## (`data/config/bands/band1_lower_meadows/spawns.json`), applied in
## `wild_creature.gd`, plumbed through `encounter_director.gd` -- by walking
## the actual route the player walks and counting what a player would
## actually see, not what the spawn table says exists.
##
## Headless, matching `tools/_probe_ow5_walk.gd`'s own precedent and stated
## reason: this renders nothing, so a walk this long under xvfb + software GL
## would cost 25x the wall clock for zero additional evidence. "Headed" tools
## in this repo are for captures a human has to look at; this is arithmetic
## over a real, physics-driven walk.
##
## Route: `terrain_playground.json` `trail.bands[0].points` -- the same
## 2,421m polyline BAND1_ROUTE_CONTRACT.md measures arc-length against,
## already prefixed with the village square and the road_gate waypoint, so
## walking it start to finish IS "village to South Bridge".
##
## Per-100m leg: the MAX number of alive, visible wild creatures within 25m of
## the player at any sampled frame in that leg (a peak, not a snapshot -- a
## herd crossing the road for three seconds and gone again is exactly the
## life this pass is trying to make visible, and a single point-sample could
## miss it), and the cumulative distinct species seen within 25m anywhere on
## the walk so far. Target, per the task brief: at least one creature within
## 25m in every 100m leg, and at least 6 distinct species seen by the time the
## Pond leg (arc ~900-1200) ends.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_CONFIG := "res://data/config/terrain_playground.json"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

## The world's own deferred build passes (village, vegetation scatter, the
## full ~230-creature wild population with its per-cluster ground placement)
## need real settle time before anything here is meaningful -- same reasoning
## `tools/_probe_ow5_walk.gd` and `tools/_capture_life.gd` give for their own
## settle windows, generous here because this world's wild population is the
## largest thing either of them waits on.
const SETTLE_FRAMES := 420

## Sighting radius the task asks for.
const SIGHT_RADIUS := 25.0
## One bucket per 100m of REAL walked distance -- not arc-length along the
## authored polyline, because a detour or a stall genuinely walks further,
## and this probe is measuring what a real walk produces, not re-deriving the
## config.
const LEG_METRES := 100.0
## Arc-length window BAND1_ROUTE_CONTRACT.md names for the Pond pocket. Used
## only to mark which leg the "6 species by the Pond" target checks against.
const POND_END_ARC := 1200.0

## Per-waypoint travel budget, generous: `stick_navigator.gd` already handles
## stalls and detours on its own clock, so this only has to be long enough
## that a real detour is not cut off mid-escape. 12 frames/metre is 2x
## `movement.json`'s own walk_speed at 60Hz; x4 again for detour overhead.
const BUDGET_PER_METRE := 48
const MIN_BUDGET := 1200

var _world: Node3D
var _player: CharacterBody3D
var _rig: Node3D
var _director: Node = null
var _nav = null

var _walked_total := 0.0
var _prev_pos := Vector3.ZERO
var _leg_max_nearby: Dictionary = {}       ## int leg -> int max creatures within SIGHT_RADIUS
var _leg_species_this_leg: Dictionary = {} ## int leg -> Dictionary[String,bool]
var _species_seen_cumulative: Dictionary = {}  ## String species -> bool
var _leg_cumulative_species_at_end: Dictionary = {}  ## int leg -> int
var _samples := 0
var _last_leg_logged := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== probe_route_life ===")
	var boot_start := Time.get_ticks_msec()
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	print("world booted and settled in %.1fs" % ((Time.get_ticks_msec() - boot_start) / 1000.0))

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_director = _world.get_node_or_null(^"EncounterDirector")
	if _player == null or _rig == null or _director == null:
		print("PROBE FAIL: scene is missing Player, CameraRig or EncounterDirector")
		quit(1)
		return

	var population: Array = _director.call("wild_creatures")
	print("wild population at boot: %d creatures" % population.size())

	var points := _route_points()
	if points.size() < 2:
		print("PROBE FAIL: band1_lower_meadows trail has fewer than 2 points")
		quit(1)
		return
	print("route: %d authored points, village square to South Bridge" % points.size())

	var start := Vector3(points[0].x, 0.0, points[0].y)
	start.y = float(_world.call("ground_height_at", start.x, start.z)) + 1.0
	_player.global_position = start
	_player.velocity = Vector3.ZERO
	_rig.global_position = start
	for i in 90:
		await physics_frame
	_prev_pos = _player.global_position

	_nav = NAVIGATOR.new(self, _player, _rig, Callable(self, "_drive_stick"))

	for i in range(1, points.size()):
		var target_xz := points[i]
		var target := Vector3(target_xz.x, _player.global_position.y, target_xz.y)
		var leg_len := Vector2(_player.global_position.x, _player.global_position.z).distance_to(target_xz)
		var budget := maxi(MIN_BUDGET, int(leg_len * BUDGET_PER_METRE))
		var arrived: bool = await _nav.walk_to(target, budget, 1.5)
		if not arrived:
			print("  waypoint %d/%d NOT reached from %s toward (%.0f, %.0f) -- teleporting past it "
				+ "(this distance is walked, not skipped, in the leg accounting, since the body "
				+ "already covered ground getting stuck; only the final short hop is not sampled)" % [
				i, points.size() - 1, str(_player.global_position), target_xz.x, target_xz.y])
			_player.global_position = target
			_player.velocity = Vector3.ZERO
			_prev_pos = _player.global_position
			for f in 30:
				await physics_frame

	print("\nwalked %.1fm of real path over %d sampled frames" % [_walked_total, _samples])
	_report()
	quit(0)


## The authored band1 spine, verbatim -- already prefixed with the village
## square and `road_gate`, per BAND1_ROUTE_CONTRACT.md's own header.
func _route_points() -> Array[Vector2]:
	var f := FileAccess.open(TERRAIN_CONFIG, FileAccess.READ)
	var out: Array[Vector2] = []
	if f == null:
		return out
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		return out
	var trail: Dictionary = (parsed as Dictionary).get("trail", {})
	for band: Variant in trail.get("bands", []):
		if str((band as Dictionary).get("id", "")) == "band1_lower_meadows":
			for p: Variant in (band as Dictionary).get("points", []):
				out.append(Vector2(float((p as Array)[0]), float((p as Array)[1])))
			return out
	return out


## `stick_navigator.gd`'s drive callback: pushes the real move_* actions,
## exactly `tools/_play_t5_walk_build_route.gd`'s own shape. The sighting
## sample rides along here because this is the navigator's one hook.
func _drive_stick(x: float, y: float) -> void:
	Input.action_press(&"move_right", clampf(x, 0.0, 1.0))
	Input.action_press(&"move_left", clampf(-x, 0.0, 1.0))
	Input.action_press(&"move_back", clampf(y, 0.0, 1.0))
	Input.action_press(&"move_forward", clampf(-y, 0.0, 1.0))
	_sample()


func _sample() -> void:
	var now := _player.global_position
	var step := Vector2(now.x - _prev_pos.x, now.z - _prev_pos.z).length()
	# Same 1mm floor / teleport ceiling `_probe_ow5_walk.gd` uses: a body
	# standing still against something jitters, and a CarveFailsafe-style
	# recovery is not a stride, so neither should move the leg bucket.
	if step > 0.001 and step < 2.0:
		_walked_total += step
	_prev_pos = now
	_samples += 1

	var leg := int(_walked_total / LEG_METRES)
	if leg != _last_leg_logged:
		_last_leg_logged = leg
		print("  [leg %d starts] walked=%.1fm real position=(%.1f, %.1f)" % [leg, _walked_total, now.x, now.z])
	var nearby := 0
	var here := Vector2(now.x, now.z)
	for w: Variant in (_director.call("wild_creatures") as Array):
		var wild: Node3D = w
		if not is_instance_valid(wild) or not wild.visible:
			continue
		if not bool(wild.call("is_alive")):
			continue
		var flat := Vector2(wild.global_position.x, wild.global_position.z)
		if here.distance_to(flat) > SIGHT_RADIUS:
			continue
		nearby += 1
		var species := str(wild.get("species_id"))
		_species_seen_cumulative[species] = true
		if not _leg_species_this_leg.has(leg):
			_leg_species_this_leg[leg] = {}
		(_leg_species_this_leg[leg] as Dictionary)[species] = true

	_leg_max_nearby[leg] = maxi(int(_leg_max_nearby.get(leg, 0)), nearby)
	_leg_cumulative_species_at_end[leg] = _species_seen_cumulative.size()


## A leg with zero samples (the walk teleported past a stuck waypoint and
## crossed it without `_sample()` ever running inside it) would otherwise be
## silently absent from `_leg_max_nearby` instead of counting as a real
## failure -- an unwalked leg is not evidence of life, it is a gap in the
## walk. Filled to 0 nearby / 0 leg-species, with the cumulative species
## count carried forward from the last leg actually sampled.
func _fill_leg_gaps() -> void:
	var max_leg := int(_walked_total / LEG_METRES)
	var running_species := 0
	for l in range(max_leg + 1):
		if _leg_max_nearby.has(l):
			running_species = int(_leg_cumulative_species_at_end.get(l, running_species))
			continue
		_leg_max_nearby[l] = 0
		_leg_species_this_leg[l] = {}
		_leg_cumulative_species_at_end[l] = running_species
		print("  NOTE: leg %d had no sampled frames at all (walked straight through, likely a " % l
			+ "teleport past a stuck waypoint) -- counted as 0 creatures, not omitted")


func _report() -> void:
	_fill_leg_gaps()
	var legs: Array = _leg_max_nearby.keys()
	legs.sort()
	print("\n=== per-100m leg report ===")
	print("%6s  %14s  %10s  %12s  %10s" % ["leg", "arc(m)", "max@25m", "leg species", "cum species"])
	var failing_legs: Array = []
	for leg: Variant in legs:
		var l := int(leg)
		var arc_lo := l * int(LEG_METRES)
		var arc_hi := arc_lo + int(LEG_METRES)
		var max_nearby := int(_leg_max_nearby[l])
		var leg_species: int = (_leg_species_this_leg.get(l, {}) as Dictionary).size()
		var cum_species := int(_leg_cumulative_species_at_end.get(l, 0))
		print("%6d  %6d - %5d  %10d  %12d  %10d" % [l, arc_lo, arc_hi, max_nearby, leg_species, cum_species])
		if max_nearby < 1:
			failing_legs.append(l)

	print("\ntotal distinct species seen within %.0fm anywhere on the walk: %d" % [
		SIGHT_RADIUS, _species_seen_cumulative.size()])
	var species_list: Array = _species_seen_cumulative.keys()
	species_list.sort()
	print("species: %s" % ", ".join(species_list))

	# The Pond target: cumulative species count at the leg that CONTAINS
	# POND_END_ARC's walked-distance equivalent. Real walked distance is not
	# identical to arc-length, so this reports the leg whose arc window is
	# closest to the contract's own 900-1200m Pond pocket rather than
	# assuming metre-for-metre equivalence.
	var pond_leg := int(POND_END_ARC / LEG_METRES) - 1
	if not _leg_cumulative_species_at_end.has(pond_leg) and not legs.is_empty():
		# The walk never reached this far (stopped short at an unrecoverable
		# wedge, or the real walked distance fell short of the Pond's arc
		# window) -- report against the furthest leg actually reached rather
		# than a leg that was never sampled, and say so plainly.
		var furthest: int = legs[legs.size() - 1]
		print("\nNOTE: the walk's own pacing only reached leg %d; the Pond's arc window (leg %d) "
			+ "was never sampled. Reporting against the furthest leg actually reached instead." % [
			furthest, pond_leg])
		pond_leg = furthest
	var pond_species := int(_leg_cumulative_species_at_end.get(pond_leg, 0))

	print("\n=== VERDICT ===")
	if failing_legs.is_empty():
		print("PASS: every 100m leg had at least one creature within %.0fm of the player." % SIGHT_RADIUS)
	else:
		print("FAIL: %d leg(s) had zero creatures within %.0fm: %s" % [
			failing_legs.size(), SIGHT_RADIUS, str(failing_legs)])

	if pond_species >= 6:
		print("PASS: %d distinct species seen by leg %d (arc ~%.0fm, the Pond's own window) -- target is >=6." % [
			pond_species, pond_leg, POND_END_ARC])
	else:
		print("FAIL: only %d distinct species seen by leg %d (arc ~%.0fm, the Pond's own window) -- target is >=6." % [
			pond_species, pond_leg, POND_END_ARC])
