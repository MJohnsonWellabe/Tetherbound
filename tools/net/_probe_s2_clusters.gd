extends SceneTree

## Spike S2, question 2: host tick cost with several activation zones.
##
## Reference only — throwaway instrument for
## docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md Wave 0 lane 0.D, D-MP2's
## "clusters keyed on the union of occupants".
##
## Follows tools/_probe_wild_streaming.gd's own precedent for loading the real
## meadows_playground.tscn and driving EncounterDirector's real
## `_tick_streaming()` path (never a reimplementation of streaming), and for
## reading `_activation_margin`/`_clusters` as private state through
## `get()`/`call()` from outside the class.
##
## Passes, each a fresh boot:
##   a) one player, at the authored spawn.
##   b) one player, teleported to a dense band-1 spot.
##   c) simulate 2 occupants: activate every wild within radius of 2 authored
##      positions spread across bands 1-3 (the real player counts as the
##      first "occupant").
##   d) simulate 4 occupants: same, with 4 positions.
##
## "Activate" = call `_set_wild_active(wild, true)` directly for members of
## clusters within `centre.distance_to(occupant) <= radius + margin`, exactly
## the condition `_stream_clusters()` uses for the real player, so the frame
## cost measured is the real per-active-body cost, not a proxy for it.
##
##   godot --headless --path . --script tools/net/_probe_s2_clusters.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SAMPLE_FRAMES := 600
const REAL_START := Vector3(40.0, 0.0, -62.0)

## Authored positions pulled from data/config/bands/*/spawns.json sample
## centres (band1 ~z<600, band2 ~z 1400-2600, band3 ~z 3300-4200), so every
## point sits where real clusters already exist rather than an empty gap.
const OCCUPANT_POSITIONS := [
	Vector3(30.0, 0.0, -40.0),      # band 1, dense — same spot as pass (b)
	Vector3(150.0, 0.0, 1550.0),    # band 2
	Vector3(-90.0, 0.0, 3300.0),    # band 3
	Vector3(220.0, 0.0, 2010.0),    # band 2, second cluster
]


func _init() -> void:
	await _run()


func _run() -> void:
	print("=== S2 cluster-activation probe: %s ===" % Time.get_datetime_string_from_system())
	print("")

	var rows: Array[Dictionary] = []
	rows.append(await _boot_and_measure("(a) 1 occupant, spawn point", []))
	rows.append(await _boot_and_measure("(b) 1 occupant, dense band-1 spot", [OCCUPANT_POSITIONS[0]]))
	rows.append(await _boot_and_measure("(c) 2 occupant positions", OCCUPANT_POSITIONS.slice(0, 2)))
	rows.append(await _boot_and_measure("(d) 4 occupant positions", OCCUPANT_POSITIONS.slice(0, 4)))

	print("")
	print("=== summary ===")
	print("%-42s %8s %8s %10s %10s" % ["pass", "live", "active", "median ms", "p95 ms"])
	for row: Dictionary in rows:
		print("%-42s %8d %8d %10.3f %10.3f" % [
			row["label"], row["live"], row["active"], row["median_ms"], row["p95_ms"]
		])

	quit(0)


## One full boot: load the scene, let it settle, teleport the player to
## `occupant_positions[0]` if any (so the real player is itself one of the
## occupants when there is at least one), force every wild within radius of
## every position in `occupant_positions` active via the SAME
## `_set_wild_active()` production code, settle again, then sample.
func _boot_and_measure(label: String, occupant_positions: Array) -> Dictionary:
	print("--- %s ---" % label)

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)

	for i in SETTLE_FRAMES:
		await physics_frame

	var director: Node = world.get_node_or_null(^"EncounterDirector")
	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if director == null or player == null:
		push_error("no EncounterDirector or Player on the scene; probe cannot measure anything")
		world.queue_free()
		return {"label": label, "live": 0, "active": 0, "median_ms": 0.0, "p95_ms": 0.0}

	if not occupant_positions.is_empty():
		var start: Vector3 = occupant_positions[0]
		start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
		player.global_position = start
		player.velocity = Vector3.ZERO

	# Let the real streaming path react to the player's new position first —
	# this is the "1 occupant" cost for whichever position we just moved to.
	director.call("_tick_streaming")
	for i in 10:
		await physics_frame

	# Now layer in any EXTRA simulated occupants beyond the real player
	# (position 0, already handled above) by activating clusters directly —
	# a peer's trainer body is not simulated by this probe, only the
	# consequence D-MP2 asks about: which wild bodies the host would have to
	# tick because someone is near them.
	# IMPORTANT: this deliberately never touches `cluster["active"]`. The
	# director's own `_process()` calls `_tick_streaming()` every frame
	# (production code, not paused by this probe), and `_stream_clusters()`
	# only acts where `should_be_active != cluster["active"]`. If this probe
	# set `cluster["active"] = true` for a cluster the REAL player is nowhere
	# near, the very next automatic tick would see `should_be_active=false`
	# disagree with the flag it just set, "correct" it back to false, and
	# call `_set_wild_active(wild, false)` on every member -- silently
	# undoing this probe's own activation within a handful of frames. Found
	# by this probe's own first run: passes (c)/(d) read back the SAME
	# active count as (b), because exactly that happened. Leaving the flag
	# untouched means the real streaming system has nothing to "fix" and
	# this probe's direct `_set_wild_active()` calls are what stick.
	var margin: float = float(director.call("_activation_radius_margin"))
	var clusters: Array = director.get("_clusters")
	var extra_positions: Array = occupant_positions.slice(1) if occupant_positions.size() > 1 else []
	var activated_count := 0
	for cluster: Dictionary in clusters:
		var centre: Vector3 = cluster["centre"]
		var radius: float = cluster["radius"]
		var already_active: bool = bool(cluster["active"])
		var near_extra := false
		for occ: Vector3 in extra_positions:
			if centre.distance_to(occ) <= radius + margin:
				near_extra = true
				break
		if near_extra and not already_active:
			for wild: Node3D in (cluster["members"] as Array):
				director.call("_set_wild_active", wild, true)
				activated_count += 1

	for i in 10:
		await physics_frame

	var wild_all: Array = director.call("wild_creatures")
	var live := wild_all.size()
	var active := 0
	for w: Node in wild_all:
		if is_instance_valid(w) and w.is_physics_processing():
			active += 1

	var samples: Array[float] = []
	for i in SAMPLE_FRAMES:
		var t0 := Time.get_ticks_usec()
		await physics_frame
		var t1 := Time.get_ticks_usec()
		samples.append((t1 - t0) / 1000.0)

	samples.sort()
	var median_ms: float = samples[samples.size() / 2]
	var p95_index: int = int(float(samples.size()) * 0.95)
	if p95_index >= samples.size():
		p95_index = samples.size() - 1
	var p95_ms: float = samples[p95_index]

	print("  live wild:     %d" % live)
	print("  active wild:   %d (extra activated this pass: %d)" % [active, activated_count])
	print("  median frame:  %.3f ms" % median_ms)
	print("  p95 frame:     %.3f ms" % p95_ms)
	print("")

	world.queue_free()
	await process_frame

	return {"label": label, "live": live, "active": active, "median_ms": median_ms, "p95_ms": p95_ms}
