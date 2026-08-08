extends "res://tests/test_case.gd"

## WHEN a save happens, not how.
##
## `test_save_manager.gd` pins the envelope: what a domain gets back, what a
## version mismatch does, what one contributor can do to another. None of that
## was ever the problem. The problem was that the running game never called any
## of it, so every one of those tests passed while a player who closed the window
## lost their party and their stronghold.
##
## These pin the schedule: the interval, the coalescing, the two guards that stop
## a save landing on a half-restored world, and the quit notification. The
## director is driven directly — `tick()` a frame at a time against a stand-in
## manager — because `run_tests.gd` does all its work inside `_init()` and there
## is no scene, no autoload and no clock at that point. The half that DOES need a
## world is `tests/smoke_persistence.gd`, and it needs a whole one.

const DIRECTOR := preload("res://scripts/world/save_director.gd")


## Stands in for SaveManager. Records rather than writes, so a failing test
## cannot touch the owner's slot 0, and can be told to fail on demand — which is
## the case a real manager will not perform to order.
class FakeManager extends RefCounted:
	var saves: Array[int] = []
	var loads: Array[int] = []
	var registered: Dictionary = {}
	var slot_exists: bool = false
	var save_succeeds: bool = true
	var load_succeeds: bool = true
	## Called from inside `save()`, to reproduce a contributor that emits a signal
	## something else saves on.
	var during_save: Callable = Callable()

	func has_slot(slot: int) -> bool:
		return slot_exists

	func save(slot: int) -> bool:
		saves.append(slot)
		if during_save.is_valid():
			during_save.call()
		return save_succeeds

	func load_slot(slot: int) -> bool:
		loads.append(slot)
		return load_succeeds

	func register(domain: String, contributor: Object) -> void:
		registered[domain] = contributor


var director: Node = null
var manager: FakeManager = null


func before_each() -> void:
	manager = FakeManager.new()
	director = DIRECTOR.new()
	director.call("bind", manager)


func after_each() -> void:
	if is_instance_valid(director):
		# A Node, never in a tree — nothing else will ever free it.
		director.free()
	director = null
	manager = null


## Run `seconds` of gameplay through the scheduler at 60fps.
func _run_for(seconds: float) -> void:
	var step := 1.0 / 60.0
	for _i in int(seconds / step):
		director.call("tick", step)


# --- boot -----------------------------------------------------------------

func test_an_empty_slot_is_a_new_game_not_a_failure() -> void:
	# The first run must not look like an error, and must not disturb anything.
	manager.slot_exists = false
	assert_false(bool(director.call("restore")), "an empty slot claimed to restore something")
	assert_eq(manager.loads.size(), 0, "an empty slot was still handed to load_slot")


func test_a_slot_that_is_there_is_restored() -> void:
	manager.slot_exists = true
	assert_true(bool(director.call("restore")), "a present slot did not restore")
	assert_eq(manager.loads, [0] as Array[int], "the wrong slot was loaded")


func test_a_slot_that_refuses_to_load_leaves_the_game_running() -> void:
	# A wrong-version file. SaveManager has already refused it whole and left the
	# world untouched; the director must not then treat the world as restored.
	manager.slot_exists = true
	manager.load_succeeds = false
	assert_false(bool(director.call("restore")), "a refused file claimed to restore")


# --- nothing writes before boot has finished ------------------------------

func test_nothing_is_written_before_begin() -> void:
	# The window between "the world is standing up" and "boot has decided" is when
	# the contributors are still registering. A save in it would write an envelope
	# missing whichever domain had not got there yet, over the file boot is about
	# to read.
	director.call("request_save", "too early")
	_run_for(600.0)
	assert_eq(manager.saves.size(), 0, "a save was written before boot finished")
	assert_false(bool(director.call("has_pending")), "a pre-boot request was queued up")


func test_the_quit_notification_before_boot_writes_nothing() -> void:
	director.call("notification", Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(manager.saves.size(), 0, "quitting during boot wrote a save")


# --- the interval ---------------------------------------------------------

func test_the_autosave_timer_fires_on_the_interval_and_not_before() -> void:
	director.call("begin")
	_run_for(DIRECTOR.AUTOSAVE_SECONDS - 1.0)
	assert_eq(manager.saves.size(), 0, "the autosave fired early")
	_run_for(2.0)
	assert_eq(manager.saves.size(), 1, "the autosave did not fire on the interval")
	assert_eq(str(director.call("last_reason")), "autosave")


func test_the_interval_restarts_after_any_write_not_just_a_timed_one() -> void:
	# Otherwise a game saved by an event at t=119 is saved again at t=120, which
	# is two writes for one unchanged world.
	director.call("begin")
	_run_for(DIRECTOR.AUTOSAVE_SECONDS - 10.0)
	director.call("request_save", "placed a wall")
	_run_for(1.0)
	assert_eq(manager.saves.size(), 1, "the event save did not happen")
	_run_for(11.0)
	assert_eq(manager.saves.size(), 1, "the timer fired again straight after an event save")
	_run_for(DIRECTOR.AUTOSAVE_SECONDS)
	assert_eq(manager.saves.size(), 2, "the timer never came back round")


# --- coalescing -----------------------------------------------------------

func test_a_burst_of_events_becomes_one_write() -> void:
	# Laying a floor grid places a piece a second. One file write per wall is a
	# stutter the player reads as the building system being slow.
	director.call("begin")
	# The first request after boot is written at once; the burst is what follows.
	director.call("request_save", "placed 1")
	_run_for(0.1)
	assert_eq(manager.saves.size(), 1, "the first change after boot was not saved promptly")

	for i in range(2, 12):
		director.call("request_save", "placed %d" % i)
		_run_for(0.3)
	assert_eq(manager.saves.size(), 1, "a burst inside the gap wrote more than once")

	_run_for(DIRECTOR.MIN_WRITE_GAP)
	assert_eq(manager.saves.size(), 2, "the coalesced request was dropped rather than delayed")
	assert_eq(str(director.call("last_reason")), "placed 11", "the last change of the burst was not the one saved")


func test_a_request_inside_the_gap_is_delayed_never_dropped() -> void:
	director.call("begin")
	director.call("save_now", "boot")
	director.call("request_save", "placed a wall")
	assert_true(bool(director.call("has_pending")), "the request was not remembered")
	_run_for(DIRECTOR.MIN_WRITE_GAP + 0.1)
	assert_false(bool(director.call("has_pending")), "the request was never flushed")
	assert_eq(manager.saves.size(), 2)


# --- the two guards -------------------------------------------------------

func test_a_save_cannot_start_while_a_load_is_running() -> void:
	# A half-restored world written over the file it is being restored from is the
	# one failure that destroys a save rather than merely losing a session.
	# `load_slot` is where the contributors are mid-restore: half of them holding
	# the file's state and half still holding the world's.
	var attempt := {"allowed": true}
	var reentrant := FakeManagerReentrant.new(func() -> void:
		attempt["allowed"] = bool(director.call("save_now", "from inside the load"))
	)
	reentrant.slot_exists = true
	director.call("bind", reentrant)
	# Booted, so that what refuses the save is the load guard and not the boot one.
	director.call("begin")

	assert_true(bool(director.call("restore")), "the load itself did not run")
	assert_false(bool(attempt["allowed"]), "a save was allowed to start during a load")
	assert_eq(reentrant.saves.size(), 0, "a save was written from inside a load")


func test_a_save_cannot_start_inside_another_save() -> void:
	director.call("begin")
	var nested := 0
	manager.during_save = func() -> void:
		if bool(director.call("save_now", "nested")):
			nested += 1
	assert_true(bool(director.call("save_now", "outer")))
	assert_eq(nested, 0, "a save started inside another save")
	assert_eq(manager.saves.size(), 1, "the nested save reached the manager")


# --- failure --------------------------------------------------------------

func test_a_failed_write_is_reported_and_does_not_stop_the_next_one() -> void:
	# A full disk must not end the session, and must not silently end saving
	# either. Expect an ERROR line above this test; that is the point of it.
	director.call("begin")
	manager.save_succeeds = false
	assert_false(bool(director.call("save_now", "autosave")), "a failed write claimed success")
	assert_eq(int(director.call("writes")), 0, "a failed write was counted")

	manager.save_succeeds = true
	assert_true(bool(director.call("save_now", "autosave")), "the director gave up after one failure")
	assert_eq(int(director.call("writes")), 1)


func test_no_manager_at_all_degrades_instead_of_crashing() -> void:
	# A scene opened without the autoload — a tool script, an isolated harness.
	var orphan: Node = DIRECTOR.new()
	orphan.call("begin")
	assert_false(bool(orphan.call("save_now", "quit")), "saving with no manager claimed success")
	assert_false(bool(orphan.call("restore")), "restoring with no manager claimed success")
	orphan.call("notification", Node.NOTIFICATION_WM_CLOSE_REQUEST)
	orphan.free()


# --- quit -----------------------------------------------------------------

func test_the_window_close_request_writes_immediately() -> void:
	# Not queued, not coalesced, not waiting for the gap. There is no next frame.
	director.call("begin")
	director.call("save_now", "autosave")
	director.call("notification", Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_eq(manager.saves.size(), 2, "the close request did not write, or waited for the gap")
	assert_eq(str(director.call("last_reason")), "quit")


func test_the_back_button_saves_the_same_way_as_a_window_close() -> void:
	director.call("begin")
	director.call("notification", Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(manager.saves.size(), 1, "a go-back request did not save")


## A manager whose `load_slot` runs arbitrary code while the load is in flight,
## which is where a contributor's `load_data` lives.
class FakeManagerReentrant extends RefCounted:
	var saves: Array[int] = []
	var slot_exists: bool = false
	var _during_load: Callable

	func _init(during_load: Callable) -> void:
		_during_load = during_load

	func has_slot(_slot: int) -> bool:
		return slot_exists

	func save(slot: int) -> bool:
		saves.append(slot)
		return true

	func load_slot(_slot: int) -> bool:
		_during_load.call()
		return true

	func register(_domain: String, _contributor: Object) -> void:
		pass
