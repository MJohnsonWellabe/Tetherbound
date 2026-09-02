extends SceneTree

## OWNER-0902-DAYNIGHT-REGRESSION reproduction.
##
## tools/gate_f/probe_daynight_auto_advance.gd already exists and passes its
## check 1 by calling `look.call("_process", 1.0)` directly 1800 times --
## that exercises the SAME function body real gameplay uses, but bypasses
## the engine's own per-frame scheduling entirely. This probe instead drives
## the scene with REAL engine frames (`await process_frame`, no manual
## `_process()` calls) so any bug specific to how Godot actually delivers
## frames -- pause interactions, timing granularity, anything the synthetic
## drive can't see -- has a chance to show up.
##
## To keep this fast, WorldLook's day_length_seconds is shrunk to a few
## real seconds AFTER _ready() runs (by mutating the already-constructed
## day_cycle.gd instance in place), so several real day boundaries and a
## full night window pass within a real, observable amount of wall-clock
## time instead of requiring the full 600s configured in art.json.
##
##   godot --headless --path . --script tools/gate_f/probe_daynight_real_frames.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 60
const SHORT_DAY_SECONDS := 3.0

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _fail(message: String) -> void:
	_failures.append(message)
	print("  FAIL: %s" % message)


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await process_frame

	var game := root.get_node_or_null(^"Game")
	if game == null:
		print("PROBE FAIL: no Game autoload in the tree")
		quit(1)
		return
	var look := world.get_node_or_null(^"WorldLook")
	if look == null:
		print("PROBE FAIL: no WorldLook node in %s" % SCENE)
		quit(1)
		return

	var cycle: RefCounted = look.get("_cycle")
	if cycle == null:
		print("PROBE FAIL: WorldLook._cycle is null after _ready() -- art.json failed to load")
		quit(1)
		return

	print("real day_length_seconds from art.json: %.1f" % float(cycle.day_length_seconds))
	# Shrink the day in place so several boundaries pass in a few real seconds.
	cycle.day_length_seconds = SHORT_DAY_SECONDS
	look.set("_elapsed_seconds", 0.0)
	look.set("_auto_day_accum", 0.0)
	print("shrunk to day_length_seconds=%.1f for this probe" % SHORT_DAY_SECONDS)

	var day_start: int = int(game.get("day"))
	print("day at probe start: %d" % day_start)

	var sun_node: Node = look.get_node_or_null(look.get("sun_path"))
	var env_holder: Node = look.get_node_or_null(look.get("environment_path"))

	print("")
	print("--- driving REAL engine frames (no manual _process calls) ---")
	var start_ms := Time.get_ticks_msec()
	# 6 short days' worth of real time, plus slack, driven by ACTUAL frame
	# delivery -- this is the one thing the existing probe's check 1 never
	# does for the day-advance loop.
	var target_ms := start_ms + int(SHORT_DAY_SECONDS * 6.0 * 1000.0) + 2000
	var last_report_day := day_start
	var min_sun_energy := INF
	var min_ambient_energy := INF
	var saw_dark := false
	while Time.get_ticks_msec() < target_ms:
		await process_frame
		var cur_day: int = int(game.get("day"))
		if cur_day != last_report_day:
			print("t=%.2fs  Game.day %d -> %d  hour=%.2f" % [
				(Time.get_ticks_msec() - start_ms) / 1000.0, last_report_day, cur_day,
				float(look.call("hour"))])
			last_report_day = cur_day
		if bool(look.call("is_dark")):
			saw_dark = true
			if sun_node is DirectionalLight3D:
				min_sun_energy = minf(min_sun_energy, (sun_node as DirectionalLight3D).light_energy)
			if env_holder is WorldEnvironment and (env_holder as WorldEnvironment).environment != null:
				min_ambient_energy = minf(min_ambient_energy,
					(env_holder as WorldEnvironment).environment.ambient_light_energy)

	var day_end: int = int(game.get("day"))
	print("")
	print("day at probe end: %d (started at %d, ~6 short days should have advanced it by ~6)" % [day_end, day_start])
	if day_end <= day_start:
		_fail("Game.day never advanced across real engine frames even though the in-game clock had time for ~6 day boundaries")
	elif day_end - day_start < 4:
		_fail("Game.day advanced too slowly under real frame delivery: expected ~6, got %d" % (day_end - day_start))

	print("")
	print("--- darkness check across the same real-frame run ---")
	print("saw is_dark() true at any point: %s" % str(saw_dark))
	if not saw_dark:
		_fail("is_dark() was never true during a run that should have crossed a full night window")
	else:
		print("min sun.light_energy while dark: %s (art.json night preset authors ~0.55)" % str(min_sun_energy))
		print("min ambient_light_energy while dark: %s (art.json night preset authors ~1.5, day is 2.1)" % str(min_ambient_energy))
		# Day's own base ambient_energy is 2.1, sun energy 1.35. If darkness never
		# gets much below those, the sky is stopping at "dusk", not reaching night.
		if min_sun_energy > 1.0:
			_fail("sun.light_energy never dropped meaningfully while is_dark() was true (min %s, day baseline 1.35) -- night never really arrives, it holds around dusk brightness" % str(min_sun_energy))

	print("")
	if _failures.is_empty():
		print("PROBE PASS")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)
