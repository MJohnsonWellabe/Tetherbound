extends SceneTree

## OWNER-0902-DAYNIGHT-REGRESSION reproduction, continued.
##
## probe_daynight_real_frames.gd already proved the automatic clock is sound
## end to end (real engine frames, no manual _process calls) for an
## UNINTERRUPTED session. The one production code path that hasn't been
## exercised with real engine execution yet is an actual rest --
## scripts/world/night_rest.gd::pass_the_night(), which calls
## Game.advance_day() AND WorldLook.reset_to_morning() together. If a real
## rest ever left the automatic accumulator unable to fire again afterward,
## that would explain "day advances once, then gets stuck" without the bug
## showing up in a rest-free run.
##
##   godot --headless --path . --script tools/gate_f/probe_daynight_after_rest.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NIGHT_REST := preload("res://scripts/world/night_rest.gd")
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
	var look := world.get_node_or_null(^"WorldLook")
	if game == null or look == null:
		print("PROBE FAIL: missing Game or WorldLook")
		quit(1)
		return

	var cycle: RefCounted = look.get("_cycle")
	cycle.day_length_seconds = SHORT_DAY_SECONDS
	look.set("_elapsed_seconds", 0.0)
	look.set("_auto_day_accum", 0.0)

	print("day at start: %d" % int(game.get("day")))

	# Run partway into the first short day, then rest for real -- the
	# production call, not a synthetic one.
	var start_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_ms < int(SHORT_DAY_SECONDS * 1000.0 * 0.5):
		await process_frame

	print("day just before rest: %d, hour=%.2f" % [int(game.get("day")), float(look.call("hour"))])
	var day_from_rest: int = NIGHT_REST.pass_the_night(world, game)
	print("pass_the_night() returned day=%d; Game.day now=%d; hour now=%.2f" % [
		day_from_rest, int(game.get("day")), float(look.call("hour"))])

	if int(game.get("day")) != day_from_rest:
		_fail("Game.day (%d) does not match what pass_the_night() reported (%d)" % [int(game.get("day")), day_from_rest])

	var day_after_rest_start: int = int(game.get("day"))

	# Now keep running real frames well past several more short-day boundaries
	# and confirm the AUTOMATIC accumulator still fires normally after a real
	# rest reset it.
	print("")
	print("--- driving real frames after the rest, watching for auto-advance ---")
	start_ms = Time.get_ticks_msec()
	var target_ms := start_ms + int(SHORT_DAY_SECONDS * 5.0 * 1000.0) + 2000
	var last_day := day_after_rest_start
	while Time.get_ticks_msec() < target_ms:
		await process_frame
		var cur_day: int = int(game.get("day"))
		if cur_day != last_day:
			print("t=%.2fs  Game.day %d -> %d  hour=%.2f" % [
				(Time.get_ticks_msec() - start_ms) / 1000.0, last_day, cur_day,
				float(look.call("hour"))])
			last_day = cur_day

	var day_end: int = int(game.get("day"))
	print("")
	print("day at probe end: %d (was %d right after the rest; ~5 more short days should have passed)" % [day_end, day_after_rest_start])
	if day_end - day_after_rest_start < 3:
		_fail("Game.day stopped auto-advancing after a real rest: only advanced by %d in a window sized for ~5" % (day_end - day_after_rest_start))

	print("")
	if _failures.is_empty():
		print("PROBE PASS")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)
