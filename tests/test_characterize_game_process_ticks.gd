extends "res://tests/test_case.gd"

## STAGE B 0.E — characterization fence for "buffs and nourishment tick only
## when the tree is not paused" (D-MP8's baseline: 2.D's session change is a
## DELIBERATE departure from this, recorded there; this file pins what solo
## does today so that departure is visible as a change, not a silent drift).
##
## `autoload/game_state.gd::_process()` calls `creature_instance.gd::
## tick_buffs()` and `creature_condition.gd::tick()` for every party member,
## every frame. Godot's engine, not this file's own code, is what stops
## `_process()` from firing while the SceneTree is paused -- `game_state.gd`
## sets no `process_mode` override on itself (only its mounted pause-menu
## child gets PROCESS_MODE_ALWAYS, so THAT keeps working while paused). So the
## actual claim under test is: Game inherits the default pause behaviour,
## which `Node.can_process()` reports synchronously without needing a real
## frame to elapse.
##
## THIS NEEDS A SMOKE, NOT A UNIT TEST, and here is the proof rather than an
## assumption: `Engine.get_main_loop()` is NULL for the entire life of
## `tests/run_tests.gd` (confirmed by running this file's own probe below,
## which is why it asserts `tree == null` rather than skipping quietly --
## `tests/test_party_seam.gd` and `tests/test_loft_bed_reachable.gd` already
## document the same fact for their own reasons: the unit harness runs every
## test body synchronously inside `_init()` with no `await process_frame`
## anywhere, so there is no live SceneTree, no physics space, and nothing to
## add a Node to at all -- not "a node's _process() never fires", but "there
## is no tree to check pause state against in the first place". Godot's own
## `Node.can_process()` would be the exact right synchronous, no-frame-needed
## check for the pause-gating claim (no `await` required, unlike watching for
## a real `_process()` side effect) -- it is simply unreachable from here.
## `tests/smoke_menu.gd` and `tests/smoke_post_modal_control.gd` already
## exercise paused-menu behaviour against the live game in a real engine main
## loop and are the right place for an end-to-end version of this claim.
##
## What IS fully unit-testable without a tree, and pinned below with real
## arithmetic: Game's own declared `process_mode` (the property that decides
## whether the pause-gating mechanism above would even apply to it), and the
## thing `_process()` calls once it runs, `creature_instance.gd`'s own
## `tick_buffs()`/`apply_buff()`.

const GAME := preload("res://autoload/game_state.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


func _creature() -> RefCounted:
	return CREATURE.from_species("terrapup", DEFINITION)


# --- the gating mechanism: Game sets no process_mode override --------------

func test_game_declares_no_process_mode_override_so_it_inherits_pause_behaviour() -> void:
	# A bare `.new()` never enters the tree, so `_ready()` (which mounts the
	# pause menu and sets ITS process_mode to ALWAYS) never runs -- this reads
	# Game's own declared default, before anything in _ready touches it.
	var game := GAME.new()
	assert_eq(game.process_mode, Node.PROCESS_MODE_INHERIT,
		"Game must inherit the tree's pause state by default -- if this ever " +
		"becomes PROCESS_MODE_ALWAYS on its own, buffs/nourishment would keep " +
		"ticking through a paused solo menu today, silently changing the " +
		"D-MP8 baseline before 2.D's Session ever exists")
	game.free()


func test_no_scene_tree_is_available_in_the_unit_harness_this_is_why_pause_gating_needs_a_smoke() -> void:
	# This is the proof for the file header's claim, kept as a real assertion
	# rather than a comment so a future engine/runner change that DOES give
	# `run_tests.gd` a live tree is caught here (an unexpected pass) instead
	# of the header quietly going stale. If this ever fails, the pause-gating
	# check above stops being smoke-only and belongs here as a real
	# `can_process()` assertion.
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree == null,
		"Engine.get_main_loop() was expected to be null for the whole life of " +
		"tests/run_tests.gd (per test_party_seam.gd/test_loft_bed_reachable.gd's " +
		"own notes) -- if this is no longer true, move the can_process()-based " +
		"pause-gating check into a real test here instead of leaving it to a smoke")


# --- what _process() actually calls: tick_buffs()/apply_buff() arithmetic --

func test_apply_buff_refuses_garbage_and_leaves_existing_buffs_untouched() -> void:
	var c := _creature()
	assert_false(c.apply_buff("", "attack", 1.5, 10.0), "empty id refused")
	assert_false(c.apply_buff("tonic", "", 1.5, 10.0), "empty stat refused")
	assert_false(c.apply_buff("tonic", "attack", 0.0, 10.0), "zero scale refused")
	assert_false(c.apply_buff("tonic", "attack", -1.0, 10.0), "negative scale refused")
	assert_false(c.apply_buff("tonic", "attack", 1.5, 0.0), "zero duration refused")
	assert_eq(c.active_buffs.size(), 0, "every refused call must add nothing")


func test_apply_buff_refreshes_rather_than_stacks_the_same_id() -> void:
	var c := _creature()
	assert_true(c.apply_buff("tonic_a", "attack", 1.5, 10.0))
	assert_true(c.apply_buff("tonic_a", "attack", 2.0, 30.0), "re-drinking refreshes, never adds a second entry")
	assert_eq(c.active_buffs.size(), 1)
	assert_almost_eq(float(c.active_buffs[0].get("scale", 0.0)), 2.0, 0.001, "the refresh replaces the scale")
	assert_almost_eq(float(c.active_buffs[0].get("remaining_s", 0.0)), 30.0, 0.001, "the refresh replaces the clock")
	assert_almost_eq(c.buff_scale("attack"), 2.0, 0.001, "the OLD 1.5x must not still be multiplied in")


func test_tick_buffs_ages_down_and_expires_exactly_at_zero() -> void:
	var c := _creature()
	c.apply_buff("tonic_a", "attack", 1.5, 5.0)
	c.tick_buffs(3.0)
	assert_eq(c.active_buffs.size(), 1, "not expired yet")
	assert_almost_eq(float(c.active_buffs[0].get("remaining_s", 0.0)), 2.0, 0.001)
	c.tick_buffs(2.0)
	assert_eq(c.active_buffs.size(), 0, "remaining_s hitting exactly 0.0 must expire the buff (<=0.0 check)")


func test_tick_buffs_on_an_empty_list_is_a_safe_no_op() -> void:
	var c := _creature()
	c.tick_buffs(999.0)
	assert_eq(c.active_buffs.size(), 0)


func test_buff_scale_multiplies_every_live_buff_on_the_same_stat_and_ignores_others() -> void:
	var c := _creature()
	assert_almost_eq(c.buff_scale("attack"), 1.0, 0.001, "no buffs -> the do-nothing default")
	c.apply_buff("food", "attack", 1.2, 60.0)
	c.apply_buff("tonic", "attack", 1.5, 60.0)
	c.apply_buff("speed_tonic", "speed", 2.0, 60.0)
	assert_almost_eq(c.buff_scale("attack"), 1.2 * 1.5, 0.001, "two attack buffs multiply together")
	assert_almost_eq(c.buff_scale("speed"), 2.0, 0.001)
	assert_almost_eq(c.buff_scale("defence"), 1.0, 0.001, "an untouched stat stays at 1.0")
