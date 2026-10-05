extends "res://tests/test_case.gd"

## Actual accepted hit, hosted director, Session retry and WorldSave disk row.
## Geometry/admission and flush scheduling are fixtures. Only the final OS
## exit is intercepted; readiness, source retention and persistence are real.
const DATA := preload("res://tests/test_foundation_resources.gd")
const SAVE := preload("res://tests/test_foundation_resource_save.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")

class ExitGame extends SAVE.FixtureGame:
	var ordinary_saves := 0
	var refusals: Array[String] = []
	func autosave_slot() -> int: return 0
	func save_game(_slot: int) -> bool:
		ordinary_saves += 1
		return save_system.call("save_world_prepared", self, "resource-slot") == true
	func show_process_exit_refusal(reason: String) -> void: refusals.append(reason)

class ExitSession extends SAVE.FixtureSession:
	var exits: Array[bool] = []
	func _authority_character(peer: int) -> String:
		return DATA.CHARACTER if peer == 2 else super._authority_character(peer)
	func _complete_process_exit(restart_graphics: bool) -> void: exits.append(restart_graphics)

class RecoveryGame extends "res://autoload/game_state.gd":
	var ordinary_saves := 0
	func save_game(_slot: int) -> bool:
		ordinary_saves += 1
		return false # The real recovery policy must never reach an ordinary save.

class DetachedShells extends "res://scripts/net/realm_shells.gd":
	func _game() -> Node: return null

## Test-local: these fixtures exercise the tracked (actor_vitals) path the
## director uses, independent of the shipped combat.json flag. The cached
## config is switched for each test and restored after it.
var _shipped_tracking: Variant = null

func before_each() -> void:
	_shipped_tracking = _track(true)

func _fixture(recovery: bool = false) -> Dictionary:
	var data := DATA.new()
	var directory := "user://test_process_exit_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	var game: Variant = RecoveryGame.new() if recovery else ExitGame.new()
	game.local = data._player()
	game.world = data._world()
	var session := ExitSession.new()
	session.fixture = game
	game.session = session
	var writer := SAVE.BoolWriter.new()
	writer.world_store = preload("res://scripts/save/world_save.gd").new(directory.path_join("worlds"))
	writer.character_store = preload("res://scripts/save/character_save.gd").new(directory.path_join("characters"))
	game.save_system = writer
	assert_true(writer.save_world_prepared(game, "resource-slot"))
	var rpc := SAVE.FixtureRpc.new()
	rpc.name = "LedgerRpc"
	rpc.fixture = game
	rpc.ledger = preload("res://scripts/net/world_ledger.gd").new(game.world)
	session.add_child(rpc)
	var shells := DetachedShells.new()
	session.set("_realms", shells)
	session.add_child(shells)
	var remote := Node3D.new()
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	remote.add_child(director)
	director.set("_session", session)
	director.call("_ensure_encounter_arbiters")
	shells.set("_shells", {"cloudreach": remote})
	var host: RefCounted = director.get("_encounter_host")
	var before := RECORD.portable_projection(game.local.save_data())
	var owned: Dictionary = before.party[0]
	var rec: Dictionary = host.open(2, "cloudreach", "wild", {"hp": 100.0, "hp_max": 100.0,
		"position": [2.0, 0.0, 0.0]}, owned.uid, DATA.CHARACTER)
	# With combat.json actor_vitals on, every encounter is tracked: the fixture
	# binds the actor as the director does before the move is published.
	var bound: Dictionary = host.bind_actor_body(rec.encounter_id, 2, DATA.CHARACTER, owned, 55)
	assert_true(bound.get("ok") == true, "fixture actor bound " + str(bound))
	var binding := {"character_id": DATA.CHARACTER, "creature_uid": owned.uid,
		"deployment_generation": 1, "body_instance_id": 55,
		"actor_generation": int(bound.get("vitals", {}).get("body_generation", 0))}
	var move := {"move_id": owned.move_quick, "slot": "quick", "range": 3.0, "cone_degrees": 100.0,
		"windup": 0.3, "recovery": 0.2, "wind_cost": 12.0,
		"mastery_context": {"world_namespace": "resource-namespace", "session_id": "resource-epoch"}}
	assert_true(host.authorize_move_start({"encounter_id": rec.encounter_id, "action": 1, "slot": "quick"},
		2, owned, binding, move, {"max": 100.0, "regen_per_second": 18.0}, 1000).ok)
	var start: Dictionary = host.move_commit(rec.encounter_id, 2, 1)
	assert_true(host.validate_strike({"encounter_id": rec.encounter_id, "action": 1, "slot": "quick",
		"move_id": owned.move_quick, "move": start.move, "facing": Vector3.RIGHT}, 2,
		{"now_ms": 1300, "origin": Vector3.ZERO, "bodies": [], "move_actor_binding": binding,
		"f22_actor_binding": binding}).ok)
	return {"game": game, "session": session, "writer": writer, "rpc": rpc, "shells": shells,
		"remote": remote, "director": director, "host": host, "record": rec, "start": start,
		"owned": owned, "directory": directory}

func _land_unsaved_hit(f: Dictionary) -> void:
	f.host.credit_move_hit(f.record.encounter_id, 2, 1, 12.0, "remote-opponent", 100.0)
	f.writer.refuse_world = true
	assert_false(f.session.foundation_combat_mastery(f.director, f.record.encounter_id, 2, 1).durable)
	assert_eq(f.host.pending_move_mastery().size(), 1)
	assert_true(f.game.world.reward_deliveries.is_empty())

func _assert_original_saved_once(f: Dictionary) -> void:
	assert_true(f.host.pending_move_mastery().is_empty())
	assert_eq(f.game.world.reward_deliveries.size(), 1)
	var event: Dictionary = f.game.world.reward_deliveries.values()[0]
	assert_eq(event.duties[0].context.outcome.action_id, f.start.action_id)
	assert_eq(event.duties[0].context.outcome.applied_damage, 12.0)
	var loaded: Dictionary = f.writer.world_store.call("read", "resource-slot")
	assert_true(E._equivalent(loaded.reward_deliveries[event.delivery_id], event))
	assert_eq(int(f.game.local.party.at(0).move_mastery_uses.get(f.owned.move_quick, 0)), 0,
		"durable replay permits exit before any owner award or ACK")

func _close(f: Dictionary) -> void:
	f.shells.set("_shells", {})
	if is_instance_valid(f.remote): f.remote.free()
	f.session.free()
	f.game.free()
	preload("res://tests/helpers/split_save_fixture.gd").wipe(f.directory)

func test_failed_first_hit_write_refuses_restart_then_same_original_allows_exit() -> void:
	var f := _fixture()
	_land_unsaved_hit(f)
	var original: Dictionary = f.host.move_mastery_outcome(f.record.encounter_id, 2, 1)
	var reason: String = f.session.call("request_process_exit", true, true)
	assert_false(reason.is_empty())
	assert_eq(f.game.refusals, [reason])
	assert_true(f.session.exits.is_empty())
	assert_false(f.session.get("_process_exit_in_flight"), "failure releases the exit button for retry")
	assert_eq(f.game.ordinary_saves, 0, "an unrelated snapshot cannot substitute for the original")
	assert_eq(f.host.move_mastery_outcome(f.record.encounter_id, 2, 1), original)
	assert_true(f.shells.has_shell("cloudreach"))
	assert_false(f.remote.is_queued_for_deletion())
	f.writer.refuse_world = false
	assert_eq(f.session.call("request_process_exit", true, true), "")
	assert_eq(f.session.exits, [true])
	_assert_original_saved_once(f)
	assert_true(f.session.prepare_process_exit().ok)
	_assert_original_saved_once(f)
	_close(f)

func test_late_hit_at_final_flush_retains_live_host_until_original_is_durable() -> void:
	var f := _fixture()
	assert_true(f.session.prepare_process_exit().ok, "initial exit check precedes the accepted hit")
	f.session.set("_mode", "host")
	f.session.set("_process_exit_in_flight", true)
	f.session.set("_closing_frames", 1)
	f.session.set("_closing_reason", "graphics_restart")
	_land_unsaved_hit(f)
	var original: Dictionary = f.host.move_mastery_outcome(f.record.encounter_id, 2, 1)
	f.session.call("_finish_closing")
	assert_true(f.session.is_active(), "the final flush cannot destroy the unsaved source")
	assert_false(str(f.session.get("_process_exit_refusal")).is_empty())
	assert_eq(f.session.get("_closing_frames"), 0)
	assert_true(f.session.exits.is_empty())
	assert_true(f.shells.has_shell("cloudreach"))
	assert_false(f.remote.is_queued_for_deletion())
	assert_eq(f.host.move_mastery_outcome(f.record.encounter_id, 2, 1), original)
	# The waiting request releases this latch on refusal; fixture scheduling
	# resumes at that same boundary without inventing a settlement or an ACK.
	f.session.set("_process_exit_in_flight", false)
	f.writer.refuse_world = false
	assert_eq(f.session.call("request_process_exit", true, true), "")
	assert_false(f.session.is_active(), "successful retry permits real transport teardown")
	assert_eq(f.session.exits, [true])
	_assert_original_saved_once(f)
	_close(f)

func test_active_host_recovery_preserves_autosave_but_requires_original_journal() -> void:
	var f := _fixture(true)
	f.game.set("_realm_transition_recovery", {"reason": "compensating_save_failed"})
	f.session.set("_mode", "host")
	_land_unsaved_hit(f)
	# WM close would normally request an ordinary save; actual Game recovery
	# policy overrides that request while keeping the original-hit requirement.
	var reason: String = f.session.call("request_process_exit", false, true)
	assert_false(reason.is_empty())
	assert_true(f.session.is_active())
	assert_true(f.session.exits.is_empty())
	assert_eq(f.game.ordinary_saves, 0)
	assert_true(f.shells.has_shell("cloudreach"))
	assert_eq(f.host.pending_move_mastery().size(), 1)
	f.writer.refuse_world = false
	assert_eq(f.session.call("request_process_exit", false, true), "")
	assert_eq(f.session.exits, [false])
	assert_eq(f.game.ordinary_saves, 0, "neither leave nor shell autosave overwrites recovery")
	assert_true(f.shells.has_shell("cloudreach"), "normal tree exit owns cleanup, as before")
	_assert_original_saved_once(f)
	_close(f)

func test_recovery_prompt_establishes_policy_before_any_detailed_snapshot() -> void:
	var game := RecoveryGame.new()
	assert_false(game.process_exit_preserves_autosave())
	game.call("_show_realm_recovery", null, "Unable to restore the prior region safely.")
	assert_true(game.process_exit_preserves_autosave())
	game.set("_realm_transition_recovery", {"reason": "compensating_save_failed", "prior": {"realm": "meadows"}})
	game.call("_show_realm_recovery", null, "Recovery save failed.")
	assert_eq(game.get("_realm_transition_recovery"), {"reason": "compensating_save_failed", "prior": {"realm": "meadows"}})
	game.free()

func test_ordinary_save_refusal_keeps_quit_retryable() -> void:
	var f := _fixture()
	f.writer.refuse_world = true
	var reason: String = f.session.call("request_process_exit", false, true)
	assert_false(reason.is_empty())
	assert_eq(f.game.refusals, [reason])
	assert_eq(f.game.ordinary_saves, 1)
	assert_true(f.session.exits.is_empty())
	f.writer.refuse_world = false
	assert_eq(f.session.call("request_process_exit", false, true), "")
	assert_eq(f.session.exits, [false])
	_close(f)

func test_empty_title_exit_needs_no_world_or_owner_write() -> void:
	var game := ExitGame.new()
	var session := ExitSession.new()
	session.fixture = game
	game.session = session
	assert_eq(session.call("request_process_exit"), "")
	assert_eq(session.exits, [false])
	assert_eq(game.ordinary_saves, 0)
	assert_true(game.refusals.is_empty())
	session.free()
	game.free()


func after_each() -> void:
	_track(_shipped_tracking)


func _track(value: Variant) -> Variant:
	var vitals: Dictionary = preload("res://scripts/combat/combat_math.gd").config().get("actor_vitals", {})
	var shipped: Variant = vitals.get("runtime_enabled")
	vitals["runtime_enabled"] = value
	return shipped
