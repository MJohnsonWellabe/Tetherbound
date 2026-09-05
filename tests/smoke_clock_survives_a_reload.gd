extends SceneTree

## N14-ROUTED-FOLLOWUPS item 2, the half a unit test cannot reach.
##
## N13-NIGHT-RESUME §5 root-caused the owner's *"There is no night time"*: the
## clock had no memory of any kind. `world_look.gd::_ready()` ended in an
## unconditional `apply_time("day")`, `save_game.gd` had no clock key at all,
## and `game_state.gd::enter_realm()` rebuilt the scene from nothing -- so a
## Continue, a realm crossing and a title-screen Load each put the hour back to
## 08:00 and restarted the 350-second walk to nightfall. N13's own words:
## *"The harness always instantiates the world once and lets it run, which is
## exactly why every probe passes."*
##
## That last sentence is why this file exists rather than another unit test.
## `tests/test_save_format.gd` covers the FORMAT (the key round-trips, an old
## save migrates, a corrupt value falls back), but it runs against a fake game
## with no scene tree at all -- `Engine.get_main_loop()` is null for the whole
## life of `run_tests.gd`. The claim that actually matters to a player is
## "**rebuild the world and the hour is still there**", and proving it needs a
## real booted world, a real `Game` autoload, a real save file, and then a
## SECOND real world built from scratch.
##
##   godot --headless --path . --script tests/smoke_clock_survives_a_reload.gd
##
## Three phases, one per thing that used to lose the clock:
##   1. evening -> save -> a brand-new world reads the file back as evening
##   2. `enter_realm()`'s own sync carries the clock without a save file at all
##   3. New Game still opens at the authored morning

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const SLOT := 3

## 19:40. Late enough to be unmistakably not morning, and deliberately not a
## keyframe hour, so a "resume" that snapped to the nearest authored preset
## instead of restoring the real elapsed time would be caught here.
const EVENING_HOUR := 19.0 + 40.0 / 60.0
const HOUR_TOLERANCE := 0.05

var _failures: Array[String] = []
var _game: Node


func _init() -> void:
	_run()


func _run() -> void:
	var world := await _build_world()
	if world == null:
		_report()
		return

	var look := _look(world)
	var cycle: RefCounted = look.get("_cycle") if look != null else null
	if look == null or cycle == null:
		_fail("the booted world has no WorldLook with a live day_cycle")
		_report()
		return

	# ---- phase 1: evening, saved, and read back by a world built from nothing.
	var evening := float(cycle.call("elapsed_for_hour", EVENING_HOUR))
	look.call("resume_at_elapsed", evening)
	_expect_hour(look, EVENING_HOUR, "the live clock did not move to the evening at all")

	if not bool(_game.call("save_game", SLOT)):
		_fail("save_game(%d) refused" % SLOT)
		_report()
		return

	# Prove the number came out of the FILE, not out of the autoload it was
	# just written from: wipe the carried value before loading it back.
	_game.set("clock_elapsed_seconds", -1.0)
	world.queue_free()
	await process_frame
	if not bool(_game.call("load_game", SLOT)):
		_fail("load_game(%d) refused the slot it had just written" % SLOT)
		_report()
		return
	if float(_game.get("clock_elapsed_seconds")) < 0.0:
		_fail("the save file carried no clock; every Continue reopens at morning")

	var reloaded := await _build_world()
	if reloaded == null:
		_report()
		return
	var reloaded_look := _look(reloaded)
	if reloaded_look == null:
		_fail("the rebuilt world has no WorldLook")
		_report()
		return
	_expect_hour(reloaded_look, EVENING_HOUR,
		"a world rebuilt from a save reopened at the wrong hour -- this is the Continue defect")

	# ---- phase 2: a realm crossing carries the clock with no save file at all.
	# `enter_realm()` itself changes scene, which this harness cannot follow, so
	# the piece under test is its clock sync: the outgoing world's hour must be
	# on `Game` before the scene is torn down.
	var midnight := float(cycle.call("elapsed_for_hour", 23.5))
	reloaded_look.call("resume_at_elapsed", midnight)
	_game.set("clock_elapsed_seconds", -1.0)
	_game.call("_sync_clock_state")
	var carried := float(_game.get("clock_elapsed_seconds"))
	if carried < 0.0:
		_fail("the crossing sync read no clock off the live world")
	else:
		var carried_hour := float(cycle.call("hour_at", carried))
		if absf(carried_hour - 23.5) > HOUR_TOLERANCE:
			_fail("the crossing carried hour %.2f, not 23.50" % carried_hour)

	reloaded.queue_free()
	await process_frame

	# ---- phase 3: New Game still opens at the authored morning.
	_game.call("reset_for_new_game")
	if float(_game.get("clock_elapsed_seconds")) >= 0.0:
		_fail("New Game inherited the last run's clock")
	var fresh := await _build_world()
	if fresh == null:
		_report()
		return
	var fresh_look := _look(fresh)
	if fresh_look == null:
		_fail("the new-game world has no WorldLook")
	else:
		_expect_hour(fresh_look, 8.0, "New Game did not open at the authored morning")

	_report()


## Build a world and FREEZE its clock on the same line it starts running.
##
## `add_child` runs `_ready()` synchronously for the whole subtree, so the hour
## `world_look.gd` resumed at is on the node before a single frame has ticked --
## and `set_process(false)` there pins it. Without that pin this smoke measured
## 18.15 where it wanted 19.67: `_process(delta)` is fed WALL-CLOCK delta, a
## software-rendered world build in this container spends minutes inside a
## handful of frames, and 562 seconds of a 600-second day went past during the
## settle loop -- the clock had lapped and come back round. That drift is the
## engine working correctly; it just makes "what hour did this world OPEN at"
## unmeasurable a few hundred frames later, which is the only question here.
func _build_world() -> Node:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_fail("could not load %s" % SCENE)
		return null
	var world: Node = packed.instantiate()
	root.add_child(world)
	var look := _look(world)
	if look != null:
		look.set_process(false)
	for i in SETTLE_FRAMES:
		await physics_frame
	if _game == null:
		_game = root.get_node_or_null(^"Game")
	if _game == null:
		_fail("the world booted without the Game autoload")
		return null
	return world


func _look(world: Node) -> Node:
	return world.get_node_or_null(^"WorldLook")


func _expect_hour(look: Node, hour: float, message: String) -> void:
	var actual := float(look.call("hour"))
	if absf(actual - hour) > HOUR_TOLERANCE:
		_fail("%s (expected hour %.2f, got %.2f)" % [message, hour, actual])


func _fail(message: String) -> void:
	_failures.append(message)
	print("FAIL: %s" % message)


func _report() -> void:
	print("")
	if _failures.is_empty():
		print("clock-survives-a-reload smoke passed")
		quit(0)
		return
	for failure in _failures:
		print("  FAIL: %s" % failure)
	quit(1)
