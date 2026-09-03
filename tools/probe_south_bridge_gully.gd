extends SceneTree

## What is actually solid on the South Bridge's village-side approach.
##
##   godot --headless --path . --script tools/probe_south_bridge_gully.gd
##
## docs/CURRENT_STATE.md §3 (P1): a player capsule placed at (7.9, -3.4, 1319.0)
## -- 11m back from the South Bridge on the village-side approach, the same
## spot `tests/smoke_traversal.gd::_walk_at_the_bridge` starts its walk from --
## settles INSIDE geometry. All eight compass probes `player_controller.gd`'s
## own `_entombed_at` sweeps come back blocked, and `_clamp_runaway_velocity`
## fires hundreds of times on ~121 m/s depenetration while the physics server
## fights to push the capsule back out. `smoke_traversal.gd`'s own step-sanity
## guard (STEP_SANITY_M) stops that teleport being mis-scored as a crossing;
## it does not make the ground sound.
##
## This measures rather than argues: it places the real player body (the same
## `_entombed_at` predicate the production failsafe uses, not a raycast --
## D09) at the site plus a ring of 8 bearings x 3 radii around it, lets each
## placement settle under real physics, and reports where depenetration
## happened and whether the body ended up sealed. FAILS (exit 1) if any
## placement is sealed at rest.
##
## The site is read from `SouthBridge.near_point(BRIDGE_START_BACK)` --
## `south_bridge.gd`'s own accessor, the same one the smoke test uses -- so
## this probe tracks the crossing's actual authored geometry rather than a
## hardcoded coordinate that would silently stop meaning anything if the
## crossing ever moved.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const PLACEMENT_SETTLE_FRAMES := 150
const BRIDGE_START_BACK := 11.0
## Same predicate player_controller.gd::_entombed_at uses (movement.json's
## `unstick.probe_m` / STEP_HEIGHT) -- kept as literals here because the
## probe measures the game's own behaviour and must not silently drift if a
## future tune changes those numbers without this file noticing.
const PROBE_M := 0.45
const STEP_HEIGHT := 0.35
## Same threshold smoke_traversal.gd uses to tell a stride from a teleport.
## A single-frame jump past this is scored as a depenetration event.
const DEPENETRATION_STEP_M := 5.0
const RING_RADII := [2.0, 4.0, 6.0]
const RING_BEARINGS := 8


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	var bridge: Node3D = world.get_node_or_null(^"SouthBridge") as Node3D
	if bridge == null:
		print("PROBE: no SouthBridge node in the scene; nothing to probe")
		quit(1)
		return
	var player := _find(world, "locomotion_enabled") as CharacterBody3D
	if player == null:
		print("PROBE: no player body in the scene")
		quit(1)
		return

	var site: Vector2 = bridge.call("near_point", BRIDGE_START_BACK)
	print("site (SouthBridge.near_point(%.1f)): (%.2f, %.2f)" % [BRIDGE_START_BACK, site.x, site.y])

	var points: Array = [{"label": "SITE", "xz": site}]
	for ri in RING_RADII.size():
		var radius: float = RING_RADII[ri]
		for bi in RING_BEARINGS:
			var angle := TAU * float(bi) / float(RING_BEARINGS)
			var offset := Vector2(sin(angle), cos(angle)) * radius
			points.append({
				"label": "r=%.0fm bearing=%3d" % [radius, int(round(rad_to_deg(angle)))],
				"xz": site + offset,
			})

	var sealed_count := 0
	var no_ground_count := 0
	print("")
	print("%-24s %10s %10s  %-24s %8s %6s %s" % [
		"placement", "x", "z", "final (x, y, z)", "max_step", "depen", "sealed"])
	for entry: Variant in points:
		var p: Dictionary = entry
		var xz: Vector2 = p["xz"]
		var result := await _probe_point(world, player, xz)
		var flag := "SEALED" if result["sealed"] else "clear"
		if result["sealed"]:
			sealed_count += 1
		if result["no_ground"]:
			no_ground_count += 1
			flag = "NO GROUND"
		print("%-24s %10.2f %10.2f  (%7.2f, %6.2f, %7.2f) %8.2f %6d %s" % [
			p["label"], xz.x, xz.y,
			result["final"].x, result["final"].y, result["final"].z,
			result["max_step"], result["depenetration_events"], flag])

	print("")
	print("%d of %d placements sealed; %d had no ground at all" % [
		sealed_count, points.size(), no_ground_count])
	if sealed_count > 0 or no_ground_count > 0:
		print("PROBE: FAIL -- the South Bridge approach has unwalkable ground")
		quit(1)
		return
	print("PROBE: PASS -- every placement around the site settled clear")
	quit(0)


## Places `player` at `xz` (on the terrain's own reported ground, +1m), lets it
## settle under real physics for up to PLACEMENT_SETTLE_FRAMES, and reports
## what happened. No input is pressed, so the production entombment failsafe
## (`_recover_if_entombed`) never engages here -- it only accumulates while
## `_wanted_dir` is non-zero -- which is exactly what makes it safe to then
## ask the same `_entombed_at` predicate directly and trust the answer.
func _probe_point(world: Node, player: CharacterBody3D, xz: Vector2) -> Dictionary:
	var ground: float = float(world.call("ground_height_at", xz.x, xz.y))
	if is_nan(ground):
		return {
			"final": Vector3(xz.x, NAN, xz.y),
			"max_step": 0.0,
			"depenetration_events": 0,
			"sealed": false,
			"no_ground": true,
		}

	player.global_position = Vector3(xz.x, ground + 1.0, xz.y)
	player.velocity = Vector3.ZERO

	var previous := player.global_position
	var max_step := 0.0
	var depenetration_events := 0
	var stable_frames := 0
	for i in PLACEMENT_SETTLE_FRAMES:
		await physics_frame
		var here := player.global_position
		var step := here.distance_to(previous)
		max_step = maxf(max_step, step)
		if step > DEPENETRATION_STEP_M:
			depenetration_events += 1
		# Settled: on the floor and not still being shoved around.
		if player.call("is_on_floor") and step < 0.01:
			stable_frames += 1
			if stable_frames >= 10:
				break
		else:
			stable_frames = 0
		previous = here

	var sealed: bool = bool(player.call("_entombed_at", player.global_transform))
	return {
		"final": player.global_position,
		"max_step": max_step,
		"depenetration_events": depenetration_events,
		"sealed": sealed,
		"no_ground": false,
	}


func _find(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child: Node in node.get_children():
		var found := _find(child, method)
		if found != null:
			return found
	return null
