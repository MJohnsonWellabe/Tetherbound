extends SceneTree

const SOURCE := "res://tests/fixtures/realm_transition_source.tscn"
const TARGET := "res://tests/fixtures/realm_transition_target.tscn"

class Hearts extends RefCounted:
	func scene_for_realm(realm: String) -> String: return SOURCE if realm == "meadows" else TARGET
	func realm(_realm: String) -> Dictionary: return {"display_name": "fixture"}

class Coordinator extends Node:
	var epoch := 1
	var events: Array[String] = []
	var cancel_begin := false
	var fail_rollback_admission := false
	var replace_ready_scene := false
	var begin_outcome := ""
	var game: Node
	func begin_client(_from: String, _to: String) -> bool:
		events.append("begin_client")
		var duplicate: bool = await game.enter_realm("water", "", true)
		events.append("duplicate_refused" if not duplicate else "duplicate_allowed")
		await get_tree().process_frame
		if cancel_begin: epoch += 1
		return begin_outcome.is_empty()
	func begin_failure_outcome() -> String: return begin_outcome
	func owns_announcement(from: String, to: String) -> bool:
		events.append("retarget:" + from + ":" + to)
		return true
	func begin_host(_from: String, _to: String) -> bool:
		events.append("begin_host")
		await get_tree().process_frame
		return true
	func end_host() -> void: events.append("end_host")
	func clear_local() -> void: events.append("clear_local")
	func prepare_rollback(realm: String) -> bool:
		events.append("rollback:" + realm)
		return true
	func finish_client(realm: String) -> bool:
		events.append("admit:" + realm)
		await get_tree().process_frame
		if replace_ready_scene:
			get_tree().change_scene_to_file(SOURCE)
			await get_tree().scene_changed
		return not (fail_rollback_admission and realm == "meadows")

class SessionProbe extends Node:
	var realm_transition: Node
	var active := true
	var hosting := false
	func is_active() -> bool: return active
	func is_host() -> bool: return hosting
	func announce_realm(from: String, to: String) -> void:
		realm_transition.events.append("announce:" + from + ":" + to)

class FailingSave extends RefCounted:
	var calls := 0
	func save(_game: Node, _slot: int) -> bool:
		calls += 1
		return false

class GameProbe extends "res://autoload/game_state.gd":
	var cancel_ready := false
	var fail_target := false
	var cancel_overlay := false
	func _ready() -> void: pass
	func autosave_here() -> bool: return true
	func _sync_clock_state() -> void:
		if cancel_overlay: _cancel_after_frame()
	func _cancel_after_frame() -> void:
		await get_tree().process_frame
		session.realm_transition.epoch += 1
	func _await_realm_scene_ready(tree: SceneTree, realm: String, context: Dictionary = {}) -> bool:
		var ready := await super._await_realm_scene_ready(tree, realm, context)
		session.realm_transition.events.append("ready:" + realm)
		if cancel_ready:
			session.realm_transition.epoch += 1
		if fail_target and realm == "water": return false
		return ready

var checks := 0
var failed := false

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	print("GAME LIFECYCLE %s %s" % ["PASS" if value else "FAIL", message])
	if not value: failed = true

func _run() -> void:
	for mode: String in ["client", "begin_refused", "begin_aborted", "begin_recovery", "begin_unsettled", "cancel_begin", "cancel_overlay", "cancel_ready", "replace_ready_scene", "rollback", "recovery", "host_save_failure", "host", "solo"]:
		change_scene_to_file(SOURCE)
		await scene_changed
		_check(current_scene != null and current_scene.scene_file_path == SOURCE \
			and str(current_scene.call("world_realm")) == "meadows", mode + " actual source installed before permit")
		if failed: break
		var game := GameProbe.new()
		game.reset_for_new_game()
		game.realm_hearts = Hearts.new()
		game.save_system = null
		var failing_save := FailingSave.new()
		if mode in ["client", "host_save_failure"]: game.save_system = failing_save
		var session := SessionProbe.new()
		var coordinator := Coordinator.new()
		coordinator.game = game
		session.realm_transition = coordinator
		session.add_child(coordinator)
		game.session = session
		game.add_child(session)
		root.add_child(game)
		game.set_process(false)
		coordinator.cancel_begin = mode == "cancel_begin"
		coordinator.fail_rollback_admission = mode == "recovery"
		coordinator.replace_ready_scene = mode == "replace_ready_scene"
		coordinator.begin_outcome = {"begin_refused": "refused", "begin_aborted": "aborted",
			"begin_recovery": "recovery_required", "begin_unsettled": "settlement_timeout"}.get(mode, "")
		game.cancel_overlay = mode == "cancel_overlay"
		game.cancel_ready = mode == "cancel_ready"
		game.fail_target = mode in ["rollback", "recovery"]
		session.hosting = mode in ["host", "host_save_failure", "solo"]
		session.active = mode != "solo"
		var other_overlay := CanvasLayer.new()
		other_overlay.name = "UnrelatedOverlay"
		root.add_child(other_overlay)
		print("GAME LIFECYCLE CASE " + mode)
		var result: bool = await game.enter_realm("water", "", true)
		var events: Array[String] = coordinator.events
		print("GAME LIFECYCLE EVENTS %s %s" % [mode, JSON.stringify(events)])
		_check(result == (mode in ["client", "host", "solo"]), mode + " result")
		_check(is_instance_valid(other_overlay), mode + " preserves unrelated overlay")
		if mode in ["recovery", "begin_unsettled"]:
			var recovery := root.get_node_or_null("LoadingOverlay")
			_check(recovery != null and recovery.has_node("RecoveryExit"), "bounded recovery exposes exit action")
			if recovery != null:
				var exit_button := recovery.get_node("RecoveryExit") as Button
				_check(exit_button.has_focus() and not exit_button.disabled, "recovery exit is controller-focusable and enabled")
				_check(root.get_visible_rect().encloses(exit_button.get_global_rect()), "recovery exit actual global rectangle is inside viewport")
				recovery.free()
		else:
			_check(root.get_node_or_null("LoadingOverlay") == null, mode + " owns loading-overlay cleanup")
		_check(game._realm_crossing_owner == 0, mode + " releases local owner")
		if mode == "client":
			_check(failing_save.calls == 0, "drained client never enters host world-save failure branch")
			_check(events.has("duplicate_refused"), "overlapping fire-and-forget entry refused")
			_check(events.find("ready:water") < events.find("admit:water"), "client readiness precedes admission")
			_check(str(current_scene.call("world_realm")) == "water", "client actual scene swap")
		elif mode.begins_with("begin_"):
			_check(current_scene.scene_file_path == SOURCE, mode + " retains actual source root")
			_check(not events.has("admit:water"), mode + " never admits destination")
			if mode == "begin_recovery":
				_check(events.find("ready:meadows") < events.find("admit:meadows"), "begin recovery source ready before admission")
				_check(events.has("retarget:water:meadows"), "begin recovery explicitly reverses host membership")
			else:
				_check(not events.has("admit:meadows"), mode + " does not silently reopen admission")
		elif mode in ["cancel_begin", "cancel_overlay"]:
			_check(str(current_scene.call("world_realm")) == "meadows", mode + " never swaps source scene")
			_check(not events.has("admit:water"), mode + " cannot admit")
		elif mode == "cancel_ready":
			_check(not events.has("rollback:meadows") and not events.has("admit:water"), "stale readiness cannot rollback or admit")
		elif mode == "replace_ready_scene":
			_check(not events.has("rollback:meadows"), "replaced ready scene cannot trigger stale rollback")
			_check(str(current_scene.call("world_realm")) == "meadows", "unexpected replacement scene is left untouched")
		elif mode == "rollback":
			_check(str(current_scene.call("world_realm")) == "meadows", "rollback rebuilds actual source")
			_check(events.find("ready:meadows") < events.find("admit:meadows"), "rollback source ready before admission")
			_check(not events.has("admit:water"), "failed destination never admitted")
		elif mode == "host":
			_check(events.has("begin_host") and events.has("end_host") and not events.has("begin_client"), "host finite permit released")
		elif mode == "host_save_failure":
			_check(failing_save.calls == 1 and str(game.current_realm) == "meadows", "failed host save restores old realm")
			_check(str(current_scene.call("world_realm")) == "meadows", "failed host save never detaches old scene")
			_check(events.has("announce:water:meadows") and events.has("end_host"), "failed host save reverses announcement and releases permit")
		elif mode == "solo":
			_check(not events.has("begin_host") and not events.has("begin_client"), "solo has no network permit")
		other_overlay.free()
		game.free()
		if failed: break
	if not failed:
		var session := SessionProbe.new()
		session.hosting = true
		var coordinator := preload("res://scripts/net/realm_transition.gd").new()
		session.add_child(coordinator)
		root.add_child(session)
		coordinator.set_process(false)
		coordinator.transactions["occupied"] = {"from": "meadows", "to": "water"}
		_reset_host_wait(coordinator)
		var permitted: bool = await coordinator.begin_host("meadows", "water")
		_check(not permitted and coordinator._host_move.is_empty(), "actual host interlock await cannot grant across Session reset")
		_check(coordinator._local.is_empty(), "reset leaves new-session local state usable")
		session.free()
	print("GAME LIFECYCLE RESULT checks=%d failed=%s" % [checks, str(failed)])
	quit(1 if failed else 0)

func _reset_host_wait(coordinator: Node) -> void:
	await process_frame
	coordinator.reset()
