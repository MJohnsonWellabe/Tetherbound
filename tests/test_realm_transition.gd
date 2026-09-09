extends "res://tests/test_case.gd"

const TRANSITION := preload("res://scripts/net/realm_transition.gd")
const SCOPE := preload("res://scripts/net/realm_replication_scope.gd")

func test_retarget_retains_abandoned_target_until_matching_readiness() -> void:
	var transition := _make()
	var tx := _transaction("loading")
	tx["target_deny"] = ""
	transition.transactions["token"] = tx
	transition.history.retire(20, "meadows", "token")
	assert_true(transition._prepare_retarget("token", "meadows"))
	var abandoned: String = transition.history.token_for(20, "water")
	assert_false(abandoned.is_empty())
	assert_false(transition.admission_allowed("water", 20, 20), "still-live owner body cannot enter absent target")
	assert_false(transition.outgoing_allowed(20, "water", 20))
	assert_false(transition.scene_rpc_allowed("water", 20))
	assert_true(transition.admission_allowed("water", 30, 20), "unrelated recipient keeps baseline")
	assert_false(transition._prepare_retarget("token", "meadows"), "duplicate retarget has no side effects")
	assert_eq(transition.history.token_for(20, "water"), abandoned)
	transition.transactions.clear()
	assert_false(transition.admission_allowed("water", 20, 20), "completion cannot reopen abandoned target")
	assert_false(transition.history.admit_ready(20, "water", "older", transition.history.epoch))
	assert_true(transition.history.admit_ready(20, "water", abandoned, transition.history.epoch))
	assert_true(transition.admission_allowed("water", 20, 20), "later exact readiness reopens target")
	transition.get_parent().free()

func test_stale_retarget_cannot_replace_newer_denial_or_admitted_phase() -> void:
	var transition := _make()
	var tx := _transaction("loading")
	tx["target_deny"] = "captured"
	transition.transactions["token"] = tx
	transition.history.retire(20, "meadows", "token")
	transition.history.retire(20, "water", "newer")
	assert_false(transition._prepare_retarget("token", "meadows"))
	assert_eq(transition.history.token_for(20, "water"), "newer")
	tx.target_deny = "newer"
	tx.phase = "admitted"
	assert_false(transition._prepare_retarget("token", "meadows"))
	assert_eq(tx.to, "water")
	transition.get_parent().free()

func test_cancel_settlement_matches_epoch_request_token_and_is_terminal() -> void:
	var transition := _make(20)
	transition._local = {"request": 7, "token": "current", "phase": "draining", "settling": true}
	transition._cancel_settled(7, transition.epoch - 1, "current", "aborted")
	transition._cancel_settled(6, transition.epoch, "current", "aborted")
	transition._cancel_settled(7, transition.epoch, "old", "aborted")
	assert_false(transition._local.has("begin_outcome"), "stale identity cannot settle a new request")
	transition._cancel_settled(7, transition.epoch, "current", "aborted")
	assert_eq(transition.begin_failure_outcome(), "aborted")
	transition.clear_local()
	assert_true(transition._local.is_empty(), "acknowledged abort permits another request")
	transition._cancel_settled(7, transition.epoch, "current", "recovery_required")
	assert_true(transition._local.is_empty(), "late receipt cannot recreate local state")
	transition.get_parent().free()

func test_loading_settlement_and_unsettled_timeout_keep_gates() -> void:
	var transition := _make(20)
	transition._local = {"request": 7, "token": "current", "phase": "draining", "settling": true}
	transition._cancel_settled(7, transition.epoch, "current", "recovery_required")
	assert_false(transition._local.has("begin_outcome"), "loading must actually be installed")
	transition.transactions["current"] = _transaction("loading")
	transition._local.phase = "loading"
	transition._cancel_settled(7, transition.epoch, "current", "recovery_required")
	assert_eq(transition.begin_failure_outcome(), "recovery_required")
	transition.clear_local()
	assert_true(transition.transactions.has("current") and not transition._local.is_empty())
	transition._local.begin_outcome = "settlement_timeout"
	transition._cancel_settled(7, transition.epoch, "current", "aborted")
	assert_eq(transition.begin_failure_outcome(), "settlement_timeout", "late receipt cannot dismiss recovery")
	transition.clear_local()
	assert_false(transition._local.is_empty())
	transition.reset()
	transition._local = {"request": 8, "phase": "waiting", "settling": true}
	transition._cancel_settled(7, transition.epoch - 1, "current", "aborted")
	assert_false(transition._local.has("begin_outcome"), "reset/new session remains independent")
	transition._cancel_settled(8, transition.epoch, "", "refused")
	transition.clear_local()
	assert_true(transition._local.is_empty(), "traffic-free acknowledged refusal permits retry")
	transition.get_parent().free()

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
	var kicked: Array[int] = []
	func kick(id: int) -> bool:
		kicked.append(id)
		return true
	func realm_of(_peer: int) -> String:
		return "water"
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

func test_joined_receiver_ready_requires_live_permit_phase_and_realm() -> void:
	var transition := _make()
	transition.origins.create("origin", "water", 20, [])
	transition.origins.begin_receiver(40, "permit", 1)
	transition._joining[40] = {"permit": "permit", "phase": "policy"}
	assert_false(transition._accept_joined_receiver(40, "permit", "water"), "policy receipt is not world readiness")
	transition._joining[40].phase = "receiver"
	assert_false(transition._accept_joined_receiver(40, "old", "water"))
	assert_false(transition._accept_joined_receiver(40, "permit", "meadows"))
	assert_false(transition.origins.allowed("origin", 40))
	assert_true(transition._accept_joined_receiver(40, "permit", "water"))
	assert_true(transition.origins.allowed("origin", 40))
	assert_true(transition._joining.is_empty())
	assert_false(transition._accept_joined_receiver(40, "permit", "water"), "duplicate ready has no side effects")
	transition.get_parent().free()

func test_policy_refresh_keeps_receiver_generation_and_original_deadline() -> void:
	var transition := _make()
	transition.origins.create("origin", "water", 20, [])
	var first: Dictionary = transition._prepare_joined_policy(40, 100)
	var deadline: int = transition._joining[40].deadline
	transition._prepare_joined_policy(50, 110)
	var revision: int = transition._policy_revision
	var refreshed: Dictionary = transition._prepare_joined_policy(40, 120)
	assert_true(first.fresh)
	assert_false(refreshed.fresh)
	assert_eq(refreshed.permit, first.permit)
	assert_eq(transition._joining[40].deadline, deadline)
	assert_eq(transition._policy_revision, revision, "snapshot refresh does not churn policy generations")
	assert_eq(transition._joining[40].revision, revision)
	transition.get_parent().free()

func test_policy_ack_binds_exact_refreshed_revision_and_unlocks_only_once() -> void:
	var transition := _make()
	var first: Dictionary = transition._prepare_joined_policy(40, 100)
	var old_revision: int = transition._joining[40].revision
	var deadline: int = transition._joining[40].deadline
	transition._policy_revision += 1
	transition._prepare_joined_policy(40, 200)
	assert_false(transition._accept_joined_policy(40, str(first.permit), old_revision), "old applied ACK cannot unlock refreshed snapshot")
	assert_eq(transition._joining[40].phase, "policy")
	assert_eq(transition._joining[40].permit, first.permit)
	assert_eq(transition._joining[40].deadline, deadline)
	assert_true(transition._accept_joined_policy(40, str(first.permit), transition._policy_revision))
	assert_eq(transition._joining[40].phase, "receiver")
	assert_false(transition._accept_joined_policy(40, str(first.permit), transition._policy_revision), "duplicate exact ACK cannot unlock twice")
	transition.get_parent().free()

func test_joined_receiver_timeout_ends_existing_session_path_and_cleans_pending_state() -> void:
	var transition := _make()
	transition.origins.create("origin", "water", 20, [])
	transition.origins.begin_receiver(40, "permit", 1)
	transition._joining[40] = {"permit": "permit", "phase": "receiver", "deadline": 100}
	transition._expire_joined_receivers(99)
	assert_true(transition.get_parent().kicked.is_empty())
	transition._expire_joined_receivers(100)
	assert_eq(transition.get_parent().kicked, [40])
	assert_true(transition._joining.is_empty() and transition.origins.pending_receivers.is_empty())
	assert_false(transition.origins.allowed("origin", 40), "failed readiness never opens invisible receiver")
	transition._expire_joined_receivers(101)
	assert_eq(transition.get_parent().kicked.size(), 1, "timeout cleanup is idempotent")
	transition.get_parent().free()

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
