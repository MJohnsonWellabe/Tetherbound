extends "res://tests/test_case.gd"

const TRANSITION := preload("res://scripts/net/realm_transition.gd")
const SCOPE := preload("res://scripts/net/realm_replication_scope.gd")

func test_automatic_public_aggregation_respects_departure_owner_and_receiver() -> void:
	var transition := _make()
	var recipients := PackedInt32Array([20, 30])
	var retained_policy := func(peer: int) -> bool: return transition.admission_allowed("meadows", peer, 1)
	assert_true(SCOPE.public_or_recipient_allowed(0, recipients, retained_policy))
	transition.transactions["token"] = _transaction("draining")
	assert_false(SCOPE.public_or_recipient_allowed(0, recipients, retained_policy))
	assert_false(SCOPE.public_or_recipient_allowed(20, recipients, retained_policy))
	assert_true(SCOPE.public_or_recipient_allowed(30, recipients, retained_policy))
	var mover_policy := func(peer: int) -> bool: return transition.admission_allowed("meadows", peer, 20)
	assert_false(SCOPE.public_or_recipient_allowed(0, recipients, mover_policy))
	assert_false(SCOPE.public_or_recipient_allowed(30, recipients, mover_policy))
	var state_policy := func(peer: int) -> bool: return transition.outgoing_allowed(1, "meadows", peer)
	assert_false(SCOPE.public_or_recipient_allowed(0, recipients, state_policy))
	assert_true(SCOPE.public_or_recipient_allowed(30, recipients, state_policy))
	transition.get_parent().free()

class SessionStub extends Node:
	var peer := 1
	func is_active() -> bool:
		return true
	func is_host() -> bool:
		return peer == 1
	func local_peer_id() -> int:
		return peer

func _make(peer: int = 1) -> Node:
	var parent := SessionStub.new()
	parent.peer = peer
	var transition := TRANSITION.new()
	parent.add_child(transition)
	return transition

func _transaction(phase: String) -> Dictionary:
	return {"mover": 20, "from": "meadows", "to": "water", "phase": phase}

func test_no_transaction_preserves_unrelated_and_unknown_peer_policy() -> void:
	var transition := _make()
	assert_true(transition.outgoing_allowed(20, "meadows", 30))
	assert_true(transition.admission_allowed("water", 999, 20))
	assert_true(transition.scene_rpc_allowed("meadows", 30))
	transition.get_parent().free()

func test_quiescence_closes_departing_sender_without_stopping_other_players() -> void:
	var transition := _make()
	transition.transactions["token"] = _transaction("requests_closed")
	assert_false(transition.outgoing_allowed(20, "meadows", 30))
	assert_false(transition.outgoing_allowed(30, "meadows", 20))
	assert_true(transition.outgoing_allowed(30, "meadows", 1))
	assert_true(transition.outgoing_allowed(1, "meadows", 30))
	assert_true(transition.admission_allowed("meadows", 20, 30), "despawn waits for request and response fences")
	assert_false(transition.admission_allowed("water", 20, 30))
	assert_true(transition.scene_rpc_allowed("meadows", 20), "earlier request responses still have a receiver")
	transition.transactions["token"].phase = "closed"
	assert_false(transition.scene_rpc_allowed("meadows", 20))
	assert_true(transition.scene_rpc_allowed("meadows", 30))
	transition.get_parent().free()

func test_only_committed_mover_completion_can_finish_during_request_closure() -> void:
	var transition := _make(20)
	transition.transactions["token"] = _transaction("requests_closed")
	assert_false(transition.scene_rpc_allowed("meadows", 1))
	assert_true(transition.scene_rpc_allowed("meadows", 1, true))
	transition.transactions["token"].phase = "closed"
	assert_false(transition.scene_rpc_allowed("meadows", 1, true))
	transition.get_parent().free()

func test_actual_drain_retires_mover_body_and_receiver_but_keeps_staying_viewer() -> void:
	var transition := _make()
	transition.transactions["token"] = _transaction("draining")
	assert_false(transition.admission_allowed("meadows", 20, 30))
	assert_false(transition.admission_allowed("meadows", 30, 20))
	assert_true(transition.admission_allowed("meadows", 30, 1))
	transition.history.retire(20, "meadows", "1:20:1")
	transition.transactions.clear()
	assert_false(transition.admission_allowed("meadows", 20, 30))
	assert_false(transition.outgoing_allowed(30, "meadows", 20))
	assert_true(transition.admission_allowed("meadows", 30, 1))
	transition.get_parent().free()

func test_stale_finish_cannot_replace_current_receiver_history() -> void:
	var transition := _make()
	transition.history.retire(20, "meadows", "1:20:2")
	transition._finish_local("1:20:1", {})
	assert_eq(transition.history.token_for(20, "meadows"), "1:20:2")
	transition.get_parent().free()

func test_reset_rejects_old_epoch_without_poisoning_new_session_request() -> void:
	var transition := _make(20)
	var old_epoch: int = transition.epoch
	transition._local = {"phase": "cancelled", "error": "old_refusal"}
	transition.reset()
	assert_false(transition.context_valid(old_epoch))
	assert_true(transition._local.is_empty())
	var next_epoch: int = transition.epoch
	transition._local = {"phase": "waiting", "request": 9}
	transition.reset()
	assert_false(transition.context_valid(next_epoch))
	assert_true(transition.context_valid(transition.epoch))
	assert_true(transition._local.is_empty(), "repeated resets cannot retain a stale refusal")
	transition.get_parent().free()

func test_rollback_preparation_requires_live_unadmitted_source_token() -> void:
	var transition := _make(20)
	transition._local = {"token": "t", "from": "meadows", "to": "water",
		"phase": "loading", "error": "timeout"}
	transition.transactions["t"] = _transaction("loading")
	transition.history.retire(20, "meadows", "t")
	assert_false(transition.prepare_rollback("water"))
	assert_true(transition._local.has("error"))
	assert_true(transition.prepare_rollback("meadows"))
	assert_false(transition._local.has("error"))
	assert_eq(transition.history.token_for(20, "meadows"), "t", "preparation cannot reopen receiver admission")
	transition._local.phase = "admitted"
	assert_false(transition.prepare_rollback("meadows"), "an admitted target needs a fresh drain, not blind rollback")
	transition._local.phase = "loading"
	transition.transactions.clear()
	assert_false(transition.prepare_rollback("meadows"))
	transition.get_parent().free()
