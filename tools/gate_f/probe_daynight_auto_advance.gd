extends SceneTree

## OWNER-0901-DAYNIGHT-CYCLE. Reproduces (and, once the fix lands, disproves)
## the 2026-09-01 owner playtest defect: `Game.day` never advanced across a
## whole real-time session because nothing tied it to `day_length_seconds`
## (autoload/game_state.gd::advance_day() was only ever called from a manual
## camp/bed rest), and WorldLook's own clock silently stopped whenever the
## pause menu was open even though its own comment says it shouldn't.
##
##   godot --headless --path . --script tools/gate_f/probe_daynight_auto_advance.gd
##
## Two checks:
##   1. Simulate a 30-real-minute session with no sleep (day_length_seconds is
##      600.0 in data/config/art.json, so a healthy clock should cross three
##      day boundaries) and confirm Game.day actually reaches 4.
##   2. Confirm WorldLook keeps ticking while the tree is paused (the state
##      game_menu.gd puts it in for every menu tab), instead of freezing the
##      instant a menu opens.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 60

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
		await physics_frame

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

	print("--- check 1: 30 simulated real minutes, no sleep ---")
	print("day at session start: %s (expected 1)" % str(game.get("day")))
	if int(game.get("day")) != 1:
		_fail("expected day 1 at session start, got %s" % str(game.get("day")))

	# day_length_seconds is 600.0 in data/config/art.json today; 1800 simulated
	# seconds (30 real minutes, matching the owner's session) should cross
	# three day boundaries (1->2 at 600s, 2->3 at 1200s, 3->4 at 1800s).
	const TOTAL_SECONDS := 1800
	const CHECKPOINT_STEP := 300
	var next_checkpoint := CHECKPOINT_STEP
	for elapsed in range(1, TOTAL_SECONDS + 1):
		look.call("_process", 1.0)
		if elapsed >= next_checkpoint:
			# CHECKPOINT_STEP (300s) is deliberately NOT a multiple of
			# day_length_seconds (600s) alone -- every other checkpoint lands
			# mid-cycle so the hour column visibly moves instead of only ever
			# being sampled once per period, which would read as "frozen" by
			# coincidence rather than by the defect this probe is checking for.
			print("t=%ds  day=%s  hour=%.2f" % [elapsed, str(game.get("day")), float(look.call("hour"))])
			next_checkpoint += CHECKPOINT_STEP

	var day_after: int = int(game.get("day"))
	print("day after 1800 simulated seconds: %d (expected 4)" % day_after)
	if day_after != 4:
		_fail("day did not auto-advance with elapsed time: expected 4 after 1800s, got %d" % day_after)

	print("")
	print("--- check 2: WorldLook keeps ticking while the tree is paused ---")
	var hour_before_pause: float = float(look.call("hour"))
	paused = true
	# Real engine-driven frames, not a direct call -- this is what actually
	# exercises process_mode, unlike check 1's manual _process() calls above.
	for i in 120:
		await process_frame
	var hour_after_pause: float = float(look.call("hour"))
	paused = false
	print("hour before pause: %.4f, hour after 120 paused frames: %.4f" % [hour_before_pause, hour_after_pause])
	if is_equal_approx(hour_before_pause, hour_after_pause):
		_fail("WorldLook's clock did not move at all across 120 paused frames -- it is still stopping when the menu opens")

	print("")
	if _failures.is_empty():
		print("PROBE PASS: Game.day auto-advances with real elapsed time at the configured "
			+ "day_length_seconds cadence, and WorldLook's clock keeps moving while the tree "
			+ "is paused (menus open).")
		quit(0)
	else:
		print("PROBE FOUND PROBLEMS (%d):" % _failures.size())
		for line in _failures:
			print("  - %s" % line)
		quit(1)
