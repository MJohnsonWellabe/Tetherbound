extends SceneTree

## STREAM-D: does distance-based wild activation actually cost less?
##
##   godot --headless --path . --script tools/_probe_wild_streaming.gd
##
## Follows `tests/smoke_aggression.gd`'s own pattern for loading the real
## `meadows_playground.tscn` and finding `EncounterDirector` on it
## (`_world.get_node_or_null(^"EncounterDirector")`) — this needs the real
## corridor terrain under the creatures, not a bare scene, so ground exists
## everywhere a synthetic spawn table might scatter one.
##
## Three passes, each a fresh boot (state does not carry between them):
##
##   1. TODAY'S DENSITY, forced all-active — what the meadow cost before this
##      change (every creature ticking, which is what `_physics_process()`
##      did unconditionally): `_activation_margin` is set absurdly large so
##      every cluster's own distance check always passes, through the SAME
##      `_tick_streaming()` code path production uses rather than a
##      reimplementation of "streaming off".
##   2. TODAY'S DENSITY, streaming on, player at the real spawn point — must
##      not regress: live creature count is unchanged, only how many of them
##      tick differs.
##   3. SYNTHETIC ~900-CREATURE DENSITY (~120 clusters of ~7-8, generated in
##      memory — never written to a band file, per this lane's contract),
##      streaming on, player parked near exactly one cluster — the density
##      the owner has asked for, with the fix in place.
##
## `average physics-frame time` is the WHOLE frame (terrain, player, every
## system in the tree), not an isolated measurement of creature cost alone —
## `await physics_frame` cannot see inside one frame, and that is what the
## engine actually spends. This machine runs five other Godot workloads on 4
## cores; treat the absolute milliseconds as noisy and read the CREATURE
## COUNTS (live vs. actually ticking) as the number contention cannot distort.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const SAMPLE_FRAMES := 180
## Real spawn pad, matching smoke_aggression.gd's own start point — open
## meadow, not inside the farmhouse.
const REAL_START := Vector3(40.0, 0.0, -62.0)
## Synthetic density: one cluster of this size, spread across roughly the
## corridor's real occupied width/length (data/config/bands/*/spawns.json
## entries sit within x in [-450, 300], z in [-40, 7000]) so every point
## lands on baked, walkable ground the same way the real table's own entries
## do (`docs/specs/MEADOWS_MACRO_LAYOUT.md` §2's corridor covers this whole span).
const SYNTH_CLUSTER_COUNT := 120
const SYNTH_PER_CLUSTER := 8
const SYNTH_RADIUS := 15.0
const SYNTH_SPECIES := "bramblebun"  # spawns.json's own "practice" role; always in species.json


func _init() -> void:
	await _run()


func _run() -> void:
	print("=== STREAM-D probe: %s ===" % Time.get_datetime_string_from_system())
	print("")

	var today_forced := await _boot_and_measure("1. TODAY'S DENSITY, all-active (pre-change baseline)", null, true)
	var today_streamed := await _boot_and_measure("2. TODAY'S DENSITY, streaming on (no regression check)", null, false)
	var synth_streamed := await _boot_and_measure(
		"3. SYNTHETIC ~%d-CREATURE DENSITY, streaming on" % (SYNTH_CLUSTER_COUNT * SYNTH_PER_CLUSTER),
		_synthetic_table(), false
	)
	var synth_forced := await _boot_and_measure(
		"4. SYNTHETIC DENSITY, all-active (what streaming is saving you from)",
		_synthetic_table(), true
	)

	print("")
	print("=== summary ===")
	print("%-46s %10s %10s %12s" % ["pass", "live", "ticking", "avg frame ms"])
	for row in [today_forced, today_streamed, synth_streamed, synth_forced]:
		print("%-46s %10d %10d %12.3f" % [row["label"], row["live"], row["ticking"], row["avg_ms"]])

	print("")
	print("today: forced-all-active vs streaming-on, ticking count %d -> %d (%.1f%% fewer creatures ticking)" % [
		today_forced["ticking"], today_streamed["ticking"],
		100.0 * (1.0 - float(today_streamed["ticking"]) / maxf(1.0, float(today_forced["ticking"])))
	])
	print("today: live creature count unchanged: %s (%d == %d)" % [
		today_forced["live"] == today_streamed["live"], today_forced["live"], today_streamed["live"]
	])
	print("synthetic density: forced-all-active vs streaming-on, ticking count %d -> %d (%.1f%% fewer creatures ticking)" % [
		synth_forced["ticking"], synth_streamed["ticking"],
		100.0 * (1.0 - float(synth_streamed["ticking"]) / maxf(1.0, float(synth_forced["ticking"])))
	])

	quit(0)


## One full boot: load the real scene, optionally inject a synthetic spawn
## table before `_spawn_creatures()` runs, force or leave the real streaming
## activation state, then sample. Returns a Dictionary row for the summary
## table. Frees the whole world before returning, so passes do not interfere.
func _boot_and_measure(label: String, synthetic_spawns: Variant, force_all_active: bool) -> Dictionary:
	print("--- %s ---" % label)
	var t_boot_start := Time.get_ticks_msec()

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	# `EncounterDirector._ready()` has run synchronously up to its own
	# `await get_tree().process_frame` by the time `add_child()` returns —
	# `_spawn_creatures()` has not been called yet, so overriding its spawn
	# table here lands before the first creature is ever built. Read by
	# `spawns_config()`, which returns `_spawns_cfg` directly once it is
	# non-empty.
	var director: Node = world.get_node_or_null(^"EncounterDirector")
	if director == null:
		push_error("no EncounterDirector on the scene; probe cannot measure anything")
		world.queue_free()
		return {"label": label, "live": 0, "ticking": 0, "avg_ms": 0.0}
	if synthetic_spawns != null:
		director.set("_spawns_cfg", synthetic_spawns)

	for i in SETTLE_FRAMES:
		await physics_frame

	var t_spawn_done := Time.get_ticks_msec()

	var player: CharacterBody3D = world.get_node_or_null(^"Player") as CharacterBody3D
	if player != null:
		var start := REAL_START if synthetic_spawns == null else _first_synth_centre(synthetic_spawns)
		start.y = float(world.call("ground_height_at", start.x, start.z)) + 1.0
		player.global_position = start
		player.velocity = Vector3.ZERO

	if force_all_active:
		# Same code path production uses (`_tick_streaming()`), forced to
		# treat every cluster as in range — not a reimplementation of "no
		# streaming", the actual one with an absurd margin.
		director.set("_activation_margin", 1.0e9)
	director.call("_tick_streaming")
	# One more settle window so the just-applied activation state (and, in
	# the forced-active pass, every creature's `_physics_process()` actually
	# running again) is what the sample below measures, not the transition.
	for i in 10:
		await physics_frame

	var wild: Array = director.call("wild_creatures")
	var live := wild.size()
	var ticking := 0
	for w: Node in wild:
		if is_instance_valid(w) and w.is_physics_processing():
			ticking += 1

	var t0 := Time.get_ticks_usec()
	for i in SAMPLE_FRAMES:
		await physics_frame
	var t1 := Time.get_ticks_usec()
	var avg_ms := (float(t1 - t0) / 1000.0) / float(SAMPLE_FRAMES)

	print("  live creatures:     %d" % live)
	print("  ticking (active):   %d" % ticking)
	print("  boot+spawn time:    %d ms" % (t_spawn_done - t_boot_start))
	print("  avg physics frame:  %.3f ms (over %d frames)" % [avg_ms, SAMPLE_FRAMES])
	print("")

	world.queue_free()
	# One frame for the free to actually take, so the next pass's node names
	# ("Player", "EncounterDirector", ...) are not still resolving against a
	# tree mid-teardown.
	await process_frame

	return {"label": label, "live": live, "ticking": ticking, "avg_ms": avg_ms}


## Deterministic synthetic table -- not `randomize()`d, same promise
## `_spawn_creatures()`'s own comment makes, though determinism matters less
## here than reproducibility of the MEASUREMENT run to run.
func _synthetic_table() -> Dictionary:
	var spawns: Array = []
	var order := 900000  # far outside every real band's reserved range (see ralph/GATE_D_LANE_CONTRACT.md)
	for i in SYNTH_CLUSTER_COUNT:
		# Walk a grid across the corridor's real occupied span rather than a
		# single line, so clusters are not all equidistant from any one point
		# -- x cycles across the width, z advances the length.
		var x := -420.0 + fmod(float(i) * 47.0, 720.0)
		var z := -20.0 + float(i) * 58.0
		spawns.append({
			"species": SYNTH_SPECIES, "centre": [x, 0.0, z],
			"radius": SYNTH_RADIUS, "count": SYNTH_PER_CLUSTER, "order": order + i,
		})
		order += 1
	return {"spawns": spawns, "respawn_seconds": 45.0, "roles": {"practice": SYNTH_SPECIES}}


func _first_synth_centre(table: Dictionary) -> Vector3:
	var spawns: Array = table.get("spawns", [])
	if spawns.is_empty():
		return Vector3.ZERO
	var centre: Array = (spawns[0] as Dictionary).get("centre", [0.0, 0.0, 0.0])
	return Vector3(float(centre[0]), 0.0, float(centre[2]))
