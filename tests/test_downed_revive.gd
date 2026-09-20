extends "res://tests/test_case.gd"

const PROMPT_ARBITER := preload("res://scripts/world/prompt_arbiter.gd")


class CompetingProvider extends RefCounted:
	var activations := 0

	func interaction_offer(_from: Vector3) -> Dictionary:
		return PROMPT_ARBITER.offer("Use another world target", 0.0, 100, true)

	func interaction_activate() -> void:
		activations += 1


class DownedProbe extends "res://scripts/player/downed_state.gd":
	func _game() -> Node:
		return null

	func _sync_channel_provider() -> void:
		pass

	func _unregister_channel_provider() -> void:
		pass

	func _revive_refusal(_peer_id: int, _starting: bool = false) -> String:
		return ""

	func _registry_peer_ids() -> Array:
		return [1, 2]

	func _body_for(_peer_id: int) -> Node3D:
		return null


class AuthorityProbe extends DownedProbe:
	var notices: Array[Dictionary] = []
	var grants: Array[Dictionary] = []
	var registered: Array = [1, 2]
	var views := {
		1: {"valid": true, "position": Vector3.ZERO, "realm": "meadows", "body_id": 101},
		2: {"valid": true, "position": Vector3(1.0, 0.0, 0.0), "realm": "meadows", "body_id": 202},
		3: {"valid": true, "position": Vector3(1.5, 0.0, 0.0), "realm": "meadows", "body_id": 303},
	}

	func _is_host() -> bool:
		return true

	func _local_peer_id() -> int:
		return 1

	func _registered_peer(peer_id: int) -> bool:
		return registered.has(peer_id)

	func _host_views() -> Dictionary:
		return views

	func _send_revive_notice(_reviver: int, event: Dictionary) -> void:
		notices.append(event.duplicate(true))

	func _host_grant_revive(target: int, window: int) -> void:
		grants.append({"target": target, "window": window})

	func _broadcast_up() -> void:
		pass


class HostGuardProbe extends AuthorityProbe:
	var guard_reason := ""

	func _multi_peer() -> bool:
		return true

	func _revive_refusal(_peer_id: int, _starting: bool = false) -> String:
		return guard_reason


## The active channel is itself an arbiter provider. Its offer must beat a
## priority-100 competing world action, and activating the selected provider
## must cancel without calling the competitor. The two-peer smoke drives the
## corresponding selection through a real fresh input edge.
func test_active_channel_owns_cancel_over_competing_provider() -> void:
	var downed := DownedProbe.new()
	downed.set("_downed_peers", {2: "Friend"})
	downed.set("_progress_peer", 2)
	downed.set("_progress_s", 0.5)
	var competitor := CompetingProvider.new()
	var providers: Array = [competitor, downed]
	var offers: Array = [
		competitor.interaction_offer(Vector3.ZERO),
		downed.call("interaction_offer", Vector3.ZERO),
	]
	var winner := PROMPT_ARBITER.choose_index(offers)
	assert_eq(winner, 1, "the active revive channel owns cancel over a priority-100 offer")
	providers[winner].call("interaction_activate")

	assert_eq(int(downed.call("status").get("progress_peer", -1)), 0,
		"the fresh second tap cancels the active channel")
	assert_eq(competitor.activations, 0,
		"the cancel edge must not activate the competing world provider")
	downed.free()


## A released button is irrelevant once the tap has established state, but a
## client process clock cannot advance the authoritative channel. Historical
## aliases remain for probes that have not migrated yet.
func test_client_time_cannot_advance_authoritative_progress_and_aliases_match() -> void:
	var downed := DownedProbe.new()
	downed.set("_downed_peers", {2: "Friend"})
	downed.set("_progress_peer", 2)
	downed.set("_progress_s", 0.25)
	downed.call("_process", 0.5)
	var status: Dictionary = downed.call("status")
	assert_almost_eq(float(status.get("progress_s", 0.0)), 0.25, 0.001,
		"client process time cannot complete a revive")
	assert_eq(status.get("hold_s"), status.get("progress_s"),
		"historical hold_s now aliases proximity progress")
	assert_eq(status.get("hold_peer"), status.get("progress_peer"),
		"historical hold_peer now aliases the active progress target")
	assert_eq(status.get("revive_hold_s"), status.get("revive_progress_s"),
		"historical config/status duration remains compatible")
	downed.free()


func test_host_progress_notice_updates_presentation_for_the_current_attempt_only() -> void:
	var downed := DownedProbe.new()
	downed.set("_progress_peer", 2)
	downed.set("_progress_attempt", 4)
	downed.set("_progress_window", 7)
	downed.call("_apply_revive_notice", {"kind": "progress", "reviver": 1,
		"target": 2, "window": 7, "attempt": 4, "elapsed": 0.75, "reason": ""})
	assert_almost_eq(float(downed.call("status").get("progress_s", 0.0)), 0.75, 0.001)
	downed.call("_apply_revive_notice", {"kind": "progress", "reviver": 3,
		"target": 2, "window": 7, "attempt": 4, "elapsed": 2.5, "reason": ""})
	assert_almost_eq(float(downed.call("status").get("progress_s", 0.0)), 0.75, 0.001,
		"a notice for another reviver cannot move this player's UI")
	downed.call("_apply_revive_notice", {"kind": "progress", "reviver": 1,
		"target": 2, "window": 8, "attempt": 4, "elapsed": 2.6, "reason": ""})
	assert_almost_eq(float(downed.call("status").get("progress_s", 0.0)), 0.75, 0.001,
		"a notice for an old or future down window cannot move the current attempt")
	downed.free()


func test_new_attempt_progress_is_not_suppressed_by_old_attempt_throttle() -> void:
	var downed := AuthorityProbe.new()
	downed.call("_route_authority_event", {"kind": "progress", "reviver": 1,
		"target": 2, "window": 7, "attempt": 1, "elapsed": 2.8, "reason": ""})
	downed.call("_route_authority_event", {"kind": "cancelled", "reviver": 1,
		"target": 2, "window": 7, "attempt": 1, "elapsed": 2.8, "reason": "moved"})
	downed.call("_route_authority_event", {"kind": "started", "reviver": 1,
		"target": 2, "window": 8, "attempt": 2, "elapsed": 0.0, "reason": ""})
	downed.call("_route_authority_event", {"kind": "progress", "reviver": 1,
		"target": 2, "window": 8, "attempt": 2, "elapsed": 0.05, "reason": ""})
	var progress_count := 0
	for event: Dictionary in downed.notices:
		if str(event.get("kind", "")) == "progress":
			progress_count += 1
	assert_eq(progress_count, 2,
		"a new attempt's first progress notice must not inherit the old elapsed throttle")
	downed.free()


func test_host_start_validates_sender_window_and_duplicate_completion_grants_once() -> void:
	var downed := AuthorityProbe.new()
	downed.revive_progress_s = 0.2
	downed.call("_configure_authority")
	var authority: RefCounted = downed.get("_authority")
	assert_true(bool(authority.call("note_down", 2, 7, "meadows", 45.0)))

	var wrong_sender: Dictionary = downed.call("_host_start_revive", 3, 2, 7, 1)
	assert_eq(str(wrong_sender.get("kind", "")), "rejected")
	assert_eq(str(wrong_sender.get("reason", "")), "invalid_peer")
	var wrong_window: Dictionary = downed.call("_host_start_revive", 1, 2, 8, 1)
	assert_eq(str(wrong_window.get("kind", "")), "rejected")
	assert_eq(str(wrong_window.get("reason", "")), "invalid_window")

	var started: Dictionary = downed.call("_host_start_revive", 1, 2, 7, 2)
	assert_eq(str(started.get("kind", "")), "started")
	var duplicate: Dictionary = downed.call("_host_start_revive", 1, 2, 7, 2)
	assert_eq(str(duplicate.get("kind", "")), "duplicate")
	downed.call("_tick_authority", 0.25)
	downed.call("_tick_authority", 0.25)
	assert_eq(downed.grants, [{"target": 2, "window": 7}],
		"duplicate starts and ticks after resolution cannot grant twice")
	downed.free()


func test_local_grant_requires_current_window_and_is_idempotent() -> void:
	var downed := AuthorityProbe.new()
	downed.set("_local_downed", true)
	downed.set("_local_window", 9)
	assert_false(bool(downed.call("_grant_local_revive", 8)),
		"a host grant for an old window cannot revive the current down")
	assert_true(bool(downed.call("_grant_local_revive", 9)))
	assert_false(bool(downed.call("_grant_local_revive", 9)),
		"a duplicate host grant is a no-op")
	assert_eq(int(downed.call("status").get("revived", 0)), 1)
	downed.free()


func test_non_host_rpc_sender_cannot_notice_or_grant() -> void:
	var downed := DownedProbe.new()
	downed.set("_progress_peer", 2)
	downed.set("_progress_attempt", 4)
	downed.set("_progress_window", 9)
	downed.set("_progress_s", 0.25)
	downed.set("_local_downed", true)
	downed.set("_local_window", 9)
	downed.call("_rpc_revive_notice", {"kind": "progress", "reviver": 1,
		"target": 2, "window": 9, "attempt": 4, "elapsed": 2.5, "reason": ""})
	downed.call("_rpc_revive_grant", 9)
	assert_almost_eq(float(downed.call("status").get("progress_s", 0.0)), 0.25, 0.001)
	assert_true(bool(downed.call("status").get("local_downed", false)),
		"a direct call has sender 0 and cannot impersonate host peer 1")
	downed.free()


func test_local_damage_guard_cancels_before_host_completion_tick() -> void:
	var downed := HostGuardProbe.new()
	downed.revive_progress_s = 0.2
	downed.call("_configure_authority")
	var authority: RefCounted = downed.get("_authority")
	assert_true(bool(authority.call("note_down", 2, 7, "meadows", 45.0)))
	assert_eq(str((authority.call("start", 1, 2, 7, 1, downed.views) as Dictionary).get("kind", "")),
		"started")
	downed.set("_downed_peers", {2: "Friend"})
	downed.set("_peer_windows", {2: 7})
	downed.set("_progress_peer", 2)
	downed.set("_progress_attempt", 1)
	downed.set("_progress_window", 7)
	downed.guard_reason = "Revive cancelled: you took damage."
	downed.call("_process", 0.25)
	assert_true(downed.grants.is_empty(),
		"the host-local continuation guard must cancel before the completing authority tick")
	assert_true((authority.call("record_for", 1) as Dictionary).is_empty())
	downed.free()
