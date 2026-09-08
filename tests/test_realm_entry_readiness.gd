extends "res://tests/test_case.gd"

## PLAYABLE-FOUR-BIOME: realm transitions must remain pending, with the
## loading overlay above them, until a sliced destination world has mounted
## everything it considers part of its shell. These tests pin the pure
## readiness decision and the live `complete_realm_entry()` guard without
## booting Terrain3D or any production world.

const GAME := preload("res://autoload/game_state.gd")


class SlicedWorld extends Node:
	var realm := "cloudreach"
	var build_ready := false

	func world_realm() -> String:
		return realm

	func shell_build_complete() -> bool:
		return build_ready


class NullBudgetWorld extends Node:
	var realm := "cloudreach"

	func world_realm() -> String:
		return realm


class GameWithoutDisk extends "res://autoload/game_state.gd":
	var autosave_calls := 0

	# The unit fixture initializes explicitly before entering the tree. Do not
	# mount the production session/menu or touch user:// from this pure test.
	func _ready() -> void:
		pass

	func autosave_here() -> bool:
		autosave_calls += 1
		return true


class SessionProbe extends Node:
	var announcements: Array[Array] = []

	func announce_realm(from_realm: String, to_realm: String) -> void:
		announcements.append([from_realm, to_realm])

	func is_host() -> bool:
		return true


class SaveProbe extends RefCounted:
	var snapshots: Array[Dictionary] = []
	var succeed := true

	func save(game: Node, _slot: int) -> bool:
		snapshots.append({
			"realm": str(game.current_realm),
			"pending_entry": str(game.pending_realm_entry),
			"saved_pose": game.saved_player_pose.duplicate(true),
		})
		return succeed


func test_readiness_distinguishes_absent_wrong_sliced_and_null_budget_worlds() -> void:
	assert_false(GAME._realm_scene_ready(null, "cloudreach"),
		"no destination scene is not ready")

	var sliced := SlicedWorld.new()
	assert_false(GAME._realm_scene_ready(sliced, "stormwood"),
		"the outgoing/wrong realm cannot satisfy the destination")
	assert_false(GAME._realm_scene_ready(sliced, "cloudreach"),
		"an explicitly unfinished sliced build is not ready")
	sliced.build_ready = true
	assert_true(GAME._realm_scene_ready(sliced, "cloudreach"),
		"the same sliced world becomes ready only when its owner says so")
	sliced.free()

	var synchronous := NullBudgetWorld.new()
	assert_true(GAME._realm_scene_ready(synchronous, "cloudreach"),
		"a synchronous/null-budget realm remains ready once its root exists")
	synchronous.free()


func test_completion_decision_keeps_sliced_arrivals_pending_until_ready() -> void:
	var world := SlicedWorld.new()
	assert_false(GAME._realm_entry_can_complete(
		"cloudreach", "stormwood", world, true),
		"a callback for the wrong realm is always refused")
	assert_false(GAME._realm_entry_can_complete(
		"cloudreach", "cloudreach", world, true),
		"an early callback cannot complete a partial sliced realm")
	world.build_ready = true
	assert_true(GAME._realm_entry_can_complete(
		"cloudreach", "cloudreach", world, true),
		"the same arrival may complete once the destination shell is ready")
	world.free()

	var synchronous := NullBudgetWorld.new()
	assert_true(GAME._realm_entry_can_complete(
		"cloudreach", "cloudreach", synchronous, true),
		"a live null-budget world retains synchronous completion")
	synchronous.free()
	assert_true(GAME._realm_entry_can_complete(
		"cloudreach", "cloudreach", null, false),
		"a pure no-tree fixture retains the historical completion path")


func test_readiness_wait_is_bounded_but_a_ready_frame_wins_the_deadline() -> void:
	var sliced := SlicedWorld.new()
	var deadline := int(GAME.REALM_SCENE_READY_TIMEOUT_MSEC)
	assert_eq(GAME._realm_scene_wait_state(sliced, "cloudreach", deadline - 1),
		GAME.REALM_READY_WAITING)
	assert_eq(GAME._realm_scene_wait_state(sliced, "cloudreach", deadline),
		GAME.REALM_READY_TIMED_OUT,
		"an early-returning Water-style root cannot hold the overlay forever")
	sliced.build_ready = true
	assert_eq(GAME._realm_scene_wait_state(sliced, "cloudreach", deadline),
		GAME.REALM_READY,
		"completion during one long engine call is accepted on the deadline frame")
	sliced.free()


func test_failed_transition_restores_realm_map_pending_pose_announcement_and_save() -> void:
	var game := GameWithoutDisk.new()
	game.reset_for_new_game()
	game.current_realm = "meadows"
	game.pending_realm_entry = "prior_entry"
	game.saved_player_pose = {"realm":"meadows", "position":[4.0, 5.0, 6.0]}
	var original_map := game.map
	var snapshot: Dictionary = game._realm_transition_snapshot("meadows")
	var session := SessionProbe.new()
	var saver := SaveProbe.new()
	game.session = session
	game.save_system = saver

	game.announce_realm("meadows", "cloudreach")
	game.current_realm = "cloudreach"
	game.bind_realm_map()
	game.pending_realm_entry = "cloudreach_arrival"
	game.saved_player_pose = {}
	game._deferred_realm_entry_completion = "cloudreach"
	assert_true(game._restore_realm_transition_state(snapshot))

	assert_eq(game.current_realm, "meadows")
	assert_true(game.map == original_map, "rollback re-selects the exact prior realm map")
	assert_eq(game.pending_realm_entry, "prior_entry")
	assert_eq(game.saved_player_pose, {"realm":"meadows", "position":[4.0, 5.0, 6.0]})
	assert_eq(game._deferred_realm_entry_completion, "")
	assert_eq(session.announcements,
		[["meadows", "cloudreach"], ["cloudreach", "meadows"]])
	assert_eq(saver.snapshots.size(), 1)
	assert_eq(saver.snapshots[0], {
		"realm":"meadows",
		"pending_entry":"prior_entry",
		"saved_pose":{"realm":"meadows", "position":[4.0, 5.0, 6.0]},
	})
	session.free()
	game.free()


func test_failed_compensating_save_restores_durable_destination_and_records_both_sides() -> void:
	var game := GameWithoutDisk.new()
	game.reset_for_new_game()
	game.current_realm = "meadows"
	game.saved_player_pose = {"realm":"meadows", "position":[1.0, 2.0, 3.0]}
	var prior := game._realm_transition_snapshot("meadows")
	var session := SessionProbe.new()
	var saver := SaveProbe.new()
	saver.succeed = false
	game.session = session
	game.save_system = saver

	game.current_realm = "water"
	game.pending_realm_entry = "from_stormwood"
	game.saved_player_pose = {}
	var failed := game._realm_transition_snapshot("water")
	assert_false(game._compensate_realm_transition(prior, failed))

	assert_eq(game.current_realm, "water",
		"memory returns to the destination represented by the existing autosave")
	assert_eq(game.pending_realm_entry, "from_stormwood")
	assert_eq(game.saved_player_pose, {})
	assert_eq(session.announcements,
		[["water", "meadows"], ["meadows", "water"]],
		"a failed compensation also compensates its Session announcement")
	assert_eq(game._realm_transition_recovery.reason, "compensating_save_failed")
	assert_eq(game._realm_transition_recovery.prior.realm, "meadows")
	assert_eq(game._realm_transition_recovery.failed.realm, "water")
	assert_false(GAME._rollback_overlay_may_dismiss(false, false, OK),
		"a failed compensating save must retain the recovery overlay")
	session.free()
	game.free()


func test_failed_prior_scene_request_keeps_the_recovery_overlay() -> void:
	assert_true(GAME._rollback_overlay_may_dismiss(true, false, OK),
		"an immediate destination request failure can dismiss after state rollback")
	assert_true(GAME._rollback_overlay_may_dismiss(true, true, OK),
		"a ready prior scene can dismiss after state rollback")
	assert_false(GAME._rollback_overlay_may_dismiss(true, true, OK, false),
		"an accepted request cannot dismiss before the prior scene is actually ready")
	assert_false(GAME._rollback_overlay_may_dismiss(true, true, ERR_CANT_OPEN),
		"a failed prior-scene request must not expose mixed scene and realm state")


func test_no_tree_completion_keeps_the_existing_behavior() -> void:
	var detached := GameWithoutDisk.new()
	detached.reset_for_new_game()
	detached.current_realm = "cloudreach"
	detached.pending_realm_entry = "fixture_entry"
	assert_true(detached.complete_realm_entry("cloudreach"),
		"a pure no-tree caller retains the pre-readiness synchronous behavior")
	assert_eq(detached.autosave_calls, 1)
	detached.free()
