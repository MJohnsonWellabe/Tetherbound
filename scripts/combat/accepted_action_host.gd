extends "res://scripts/net/encounter_host.gd"

## F22 publication state lives in the inherited, sole strike authority. This
## class observes the existing damage writer; it never writes portable HP,
## resources, mastery, save receipts or owner acknowledgements.

func _init(host_peer_id: int = 1) -> void:
	super(host_peer_id)

static func _original(value: Variant) -> Variant:
	if value is Dictionary:
		var copy: Dictionary = value.duplicate(true)
		for key: Variant in copy: copy[key] = _original(copy[key])
		copy.make_read_only()
		return copy
	if value is Array:
		var copy: Array = value.duplicate(true)
		for index: int in copy.size(): copy[index] = _original(copy[index])
		copy.make_read_only()
		return copy
	return value


func _tracking_enabled() -> bool:
	return MATH.config().get("actor_vitals", {}).get("runtime_enabled") == true


func _tracking_enabled_for(id: String) -> bool:
	if _tracking_enabled(): return true
	var rec: Dictionary = encounters.get(id, {})
	var scope: Variant = rec.get("ordinary_combat_reward_owner")
	return preload("res://scripts/net/combat_round_reward.gd").scope_valid(scope) \
		and scope.encounter_id == id \
		and rec.get("kind") in ["trainer", "boss"] \
		and scope.trainer_id == rec.get("opponent", {}).get("owner_npc") \
		and scope.realm == preload("res://scripts/data/biome_order.gd").canonical_id(str(rec.get("realm", "")))


func _actions(id: String, peer: int) -> Dictionary:
	var state: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {})
	return state.get("accepted_actions", {}) as Dictionary


func _binding_current(id: String, peer: int, binding: Dictionary) -> bool:
	var character := str(binding.get("character_id", ""))
	var uid := str(binding.get("creature_uid", ""))
	if character.is_empty() or uid.is_empty() or int(binding.get("deployment_generation", 0)) <= 0 \
		or not actor_encounter_is_current(id, peer, character): return false
	var participant: Dictionary = _actor_participant(id, peer, character)
	var actor: Dictionary = (participant.get("actor_vitals", {}) as Dictionary).get(uid, {})
	return participant.get("actor_bound_uid") == uid and participant.get("creature_uid") == uid \
		and int(actor.get("body_generation", 0)) > 0 \
		and actor.get("body_generation") == binding.get("actor_generation") \
		and int(actor.get("body_instance_id", 0)) > 0 \
		and actor.get("body_instance_id") == binding.get("body_instance_id") \
		and actor.get("fainted") == false and float(actor.get("hp", 0.0)) > 0.0


func _action_id(id: String, peer: int, action: int, binding: Dictionary,
		target_uid: String, target_generation: int) -> String:
	for key: String in _actions(id, peer):
		var entry: Dictionary = _actions(id, peer)[key]
		if int(entry.admission.action) == action and entry.phase == "admitted" \
			and entry.admission.binding == binding and entry.admission.target_uid == target_uid \
			and entry.admission.target_generation == target_generation: return key
	return ""


func validate_strike(intent: Dictionary, peer_id: int, view: Dictionary) -> Dictionary:
	var id := str(intent.get("encounter_id", ""))
	if move_action_publication_pending(id):
		return _refuse("strike_intent", peer_id, "pending_action", "The original hit is still being published.")
	if not _tracking_enabled_for(id): return super.validate_strike(intent, peer_id, view)
	var binding: Dictionary = view.get("f22_actor_binding", {})
	if not _binding_current(id, peer_id, binding):
		return _refuse("strike_intent", peer_id, "stale_actor", "Your deployed creature is no longer current.")
	var actions := _actions(id, peer_id)
	var limit := int(MATH.config().get("utility_limits", {}).get("receipt_limit_per_encounter", 0))
	if limit < 1 or actions.size() >= limit:
		return _refuse("strike_intent", peer_id, "receipt_budget", "This encounter cannot accept another action safely.")
	var verdict: Dictionary = super.validate_strike(intent, peer_id, view)
	# The base validator replaces cooldown state. Restore the SAME originals,
	# including misses, before appending this first actual accepted decision.
	if (_strike_authority.get(id, {}) as Dictionary).has(peer_id):
		_strike_authority[id][peer_id]["accepted_actions"] = actions
	if verdict.get("ok") != true: return verdict
	var opponent: Dictionary = (encounters[id] as Dictionary).get("opponent", {})
	var target_uid := str(opponent.get("card", {}).get("uid", ""))
	var target_generation := int(opponent.get("body_generation", 0))
	var action_id := (_vitals_namespace + "|" + id + "|" + str(binding.character_id) + "|" \
		+ str(binding.creature_uid) + "|" + str(binding.actor_generation) + "|" \
		+ target_uid + "|" + str(target_generation) + "|" + str(intent.action) + "|" + str(actions.size() + 1)).sha256_text()
	var admission: Dictionary = {"encounter_id": id, "peer_id": peer_id, "action": int(intent.action),
		"action_id": action_id, "binding": binding, "move": view.get("move", intent.get("move", {})),
		"move_id": str(intent.get("move_id", "")), "slot": str(intent.get("slot", "quick")),
		"target_uid": target_uid, "target_generation": target_generation,
		"target_hp_at_admission": float(opponent.get("hp", 0.0)),
		"accepted_at_ms": int(view.get("now_ms", 0)), "verdict": verdict}
	actions[action_id] = {"phase": "admitted" if verdict.delta.get("hit") == true else "missed",
		"admission": _original(admission)}
	return verdict


func authorize_move_start(intent: Dictionary, peer: int, owned: Dictionary,
		binding: Dictionary, move: Dictionary, wind_profile: Dictionary, now_ms: int) -> Dictionary:
	if move_action_publication_pending(str(intent.get("encounter_id", ""))):
		return _refuse("move_start", peer, "pending_action", "The original hit is still being published.")
	return super.authorize_move_start(intent, peer, owned, binding, move, wind_profile, now_ms)


## Called immediately before the existing host damage writer, from actual
## arrival state. A duplicate callback cannot invoke that writer twice.
func begin_move_action_resolution(id: String, peer: int, action: int,
		binding: Dictionary, target_uid: String, target_generation: int) -> Dictionary:
	if not _tracking_enabled_for(id): return {"ok": true, "tracked": false}
	var action_id := _action_id(id, peer, action, binding, target_uid, target_generation)
	if action_id.is_empty() or move_action_publication_pending(id): return {"ok": false, "code": "not_arrivable"}
	var entry: Dictionary = _actions(id, peer)[action_id]
	var admission: Dictionary = entry.admission
	var opponent: Dictionary = (encounters.get(id, {}) as Dictionary).get("opponent", {})
	if binding != admission.binding or not _binding_current(id, peer, binding) \
		or target_uid != admission.target_uid or target_generation != admission.target_generation \
		or target_uid != str(opponent.get("card", {}).get("uid", "")) \
		or target_generation != int(opponent.get("body_generation", 0)):
		entry["phase"] = "cancelled"
		return {"ok": false, "code": "stale_arrival"}
	entry["arrival"] = _original({"target_hp_before": float(opponent.hp),
		"target_hp_max": float(opponent.hp_max), "binding": binding,
		"target_uid": target_uid, "target_generation": target_generation})
	entry["phase"] = "resolving"
	return {"ok": true, "tracked": true, "action_id": action_id}


## Record only the debit produced by the existing damage/body writer and
## committed by set_opponent_hp. A mismatch stays pending for reconciliation.
func record_move_action_outcome(id: String, peer: int, action_id: String,
		rolled: Dictionary, verdict: Dictionary) -> bool:
	var entry: Dictionary = _actions(id, peer).get(action_id, {})
	if entry.get("phase") != "resolving": return false
	var opponent: Dictionary = (encounters.get(id, {}) as Dictionary).get("opponent", {})
	var before := float(entry.arrival.target_hp_before)
	var after := float(opponent.get("hp", NAN))
	if not is_finite(after) or after < 0.0 or after > before \
		or after != float(rolled.get("hp", NAN)) \
		or float(opponent.get("hp_max", NAN)) != float(entry.arrival.target_hp_max): return false
	entry["outcome"] = _original({"action_id": action_id, "actual_hp_debit": before - after,
		"target_hp_before": before, "target_hp_after": after, "rolled": rolled, "verdict": verdict})
	entry["phase"] = "body_publication_pending"
	return true


func acknowledge_move_action_publication(id: String, peer: int, action_id: String, verdict: Dictionary) -> bool:
	var entry: Dictionary = _actions(id, peer).get(action_id, {})
	if entry.get("phase") != "body_publication_pending" or entry.outcome.verdict != verdict: return false
	entry["phase"] = "published"
	return true


## Only the exact committed killing original may publish its terminal phase
## while body delivery is pending. Generic lifecycle changes stay fenced.
func publish_move_action_terminal(id: String, peer: int, action_id: String, next_phase: String) -> bool:
	var entry: Dictionary = _actions(id, peer).get(action_id, {})
	if entry.get("phase") != "body_publication_pending" or next_phase not in ["done", "resolving"] \
		or entry.outcome.rolled.get("killed") != true or float(entry.outcome.target_hp_after) != 0.0: return false
	var before: Dictionary = (_strike_authority.get(id, {}) as Dictionary).duplicate()
	super.set_phase(id, next_phase)
	_cancel_admitted(before)
	_retain_originals(id, before)
	return true


func move_action_publication_pending(id: String) -> bool:
	for state: Dictionary in (_strike_authority.get(id, {}) as Dictionary).values():
		for entry: Dictionary in (state.get("accepted_actions", {}) as Dictionary).values():
			if entry.get("phase") in ["resolving", "body_publication_pending"]: return true
	return false


func move_action_original(id: String, peer: int, action_id: String) -> Dictionary:
	return (_actions(id, peer).get(action_id, {}) as Dictionary).duplicate(true)


func _retain_originals(id: String, before: Dictionary) -> void:
	var has_originals := false
	for state: Dictionary in before.values():
		if not (state.get("accepted_actions", {}) as Dictionary).is_empty(): has_originals = true
		if not (state.get("move_starts", {}) as Dictionary).is_empty(): has_originals = true
	if not has_originals: return
	var current := _strike_state_for(id)
	for key: Variant in before:
		var actions: Dictionary = (before[key] as Dictionary).get("accepted_actions", {})
		var starts: Dictionary = (before[key] as Dictionary).get("move_starts", {})
		if actions.is_empty() and starts.is_empty(): continue
		if not current.has(key): current[key] = {}
		current[key]["accepted_actions"] = actions
		current[key]["move_starts"] = starts


func _cancel_admitted(before: Dictionary) -> void:
	for state: Dictionary in before.values():
		for entry: Dictionary in (state.get("accepted_actions", {}) as Dictionary).values():
			if entry.phase == "admitted": entry["phase"] = "cancelled"


func set_phase(id: String, next_phase: String) -> void:
	if move_action_publication_pending(id): return
	var before: Dictionary = (_strike_authority.get(id, {}) as Dictionary).duplicate()
	super.set_phase(id, next_phase)
	_cancel_admitted(before)
	_retain_originals(id, before)


func set_opponent(id: String, opponent: Dictionary) -> bool:
	if move_action_publication_pending(id): return false
	var before: Dictionary = (_strike_authority.get(id, {}) as Dictionary).duplicate()
	var changed: bool = super.set_opponent(id, opponent)
	if changed: _cancel_admitted(before)
	_retain_originals(id, before)
	return changed


func close(id: String) -> void:
	if move_action_publication_pending(id): return
	var before: Dictionary = (_strike_authority.get(id, {}) as Dictionary).duplicate()
	super.close(id)
	_cancel_admitted(before)
	_retain_originals(id, before)


func forget(id: String) -> void:
	if move_action_publication_pending(id): return
	for state: Dictionary in (_strike_authority.get(id, {}) as Dictionary).values():
		for started: Dictionary in state.get("move_starts", {}).values():
			if started.get("mastery_pending") == true: return
	super.forget(id)


func leave(id: String, peer: int) -> Dictionary:
	if move_action_publication_pending(id):
		return _refuse("disengage", peer, "pending_action", "The original hit is still being published.")
	var character := str((_actor_participant(id, peer) as Dictionary).get("character_id", ""))
	var actions := _actions(id, peer)
	for entry: Dictionary in actions.values():
		if entry.phase == "admitted": entry["phase"] = "cancelled"
	var verdict: Dictionary = super.leave(id, peer)
	if not character.is_empty() and not actions.is_empty():
		var retained := _strike_state_for(id)
		if not retained.has(character): retained[character] = {}
		retained[character]["accepted_actions"] = actions
	return verdict


func join(id: String, peer: int, uid: String = "", character: String = "") -> Dictionary:
	if move_action_publication_pending(id):
		return _refuse("engage", peer, "pending_action", "The original hit is still being published.")
	var actions := _actions(id, peer)
	var retained: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(character, {})
	if actions.is_empty(): actions = retained.get("accepted_actions", {})
	var verdict: Dictionary = super.join(id, peer, uid, character)
	if verdict.get("ok") == true and not actions.is_empty():
		var current := _strike_state_for(id)
		if not current.has(peer): current[peer] = {}
		current[peer]["accepted_actions"] = actions
		if current.has(character): (current[character] as Dictionary).erase("accepted_actions")
	return verdict


func authorize_burst(id: String, peer: int, intent: Dictionary, profile: Dictionary,
		cost: float, now_ms: int, distance: float, duration: float, regen_delay_seconds: float) -> Dictionary:
	if move_action_publication_pending(id):
		return _refuse("burst_intent", peer, "pending_action", "The original hit is still being published.")
	var before: Dictionary = (_strike_authority.get(id, {}) as Dictionary).duplicate()
	var verdict: Dictionary = super.authorize_burst(id, peer, intent, profile, cost, now_ms, distance, duration, regen_delay_seconds)
	_retain_originals(id, before)
	return verdict


func _authorize_actor_self_heal(intent: Dictionary, peer: int, view: Dictionary,
		move: Dictionary, wind_profile: Dictionary) -> Dictionary:
	var id := str(intent.get("encounter_id", ""))
	if move_action_publication_pending(id): return {"ok": false, "code": "pending_action"}
	var before: Dictionary = (_strike_authority.get(id, {}) as Dictionary).duplicate()
	var verdict: Dictionary = super._authorize_actor_self_heal(intent, peer, view, move, wind_profile)
	_retain_originals(id, before)
	return verdict


func commit_actor_vitals(proposal: Dictionary) -> Dictionary:
	if move_action_publication_pending(str(proposal.get("encounter_id", ""))):
		return {"ok": false, "code": "pending_action"}
	return super.commit_actor_vitals(proposal)


## Session supplies only the director's original active, host-staged hit.
## Terminal publication may precede a failed disk retry; it cannot restage a
## fresh hit, change the original actor, or import any snapshot fields.
func verify_original_actor_vitals(proposal: Dictionary, original: Dictionary) -> bool:
	var id: String = str(proposal.get("encounter_id", ""))
	var peer: int = int(proposal.get("peer_id", 0))
	var uid: String = str(proposal.get("creature_uid", ""))
	var rec: Dictionary = encounters.get(id, {})
	if proposal.get("kind") != "damage" or original.get("encounter_id") != id \
		or not preload("res://scripts/net/combat_round_reward.gd").scope_valid(rec.get("ordinary_combat_reward_owner")) \
		or rec.get("kind") not in ["trainer", "boss"] \
		or original.get("phase") != "active" or rec.get("phase") not in ["active", "resolving", "done"] \
		or not _tracking_enabled_for(id) or move_action_publication_pending(id) \
		or rec.get("realm") != original.get("realm") \
		or rec.get("ordinary_combat_reward_owner") != original.get("ordinary_combat_reward_owner") \
		or rec.get("opponent", {}).get("card", {}).get("uid") != original.get("opponent", {}).get("card", {}).get("uid") \
		or rec.get("opponent", {}).get("body_generation") != original.get("opponent", {}).get("body_generation"):
		return false
	var source: Dictionary = original.get("participants", {}).get(peer, {})
	var member: Dictionary = rec.get("participants", {}).get(peer, {})
	if member.is_empty(): member = rec.get("retained_actor_participants", {}).get(source.get("character_id"), {})
	var before: Dictionary = source.get("actor_vitals", {}).get(uid, {})
	var current: Dictionary = member.get("actor_vitals", {}).get(uid, {})
	if source.get("character_id") != member.get("character_id") or source.get("actor_bound_uid") != uid \
		or member.get("actor_bound_uid") != uid or int(before.get("body_instance_id", 0)) <= 0 \
		or before.is_empty() or current != before: return false
	var trial: Variant = get_script().new(_host_peer_id)
	trial.encounters[id] = original.duplicate(true)
	trial._vitals_namespace = _vitals_namespace
	var verified: Dictionary = trial.call("stage_actor_vitals", id, peer, uid,
		int(proposal.get("body_generation", -1)), int(proposal.get("expected_revision", -1)),
		str(proposal.get("action_id", "")), "damage", float(proposal.get("amount", NAN)),
		int(proposal.get("receipt_limit", 0)))
	return verified.get("ok") == true and verified == proposal


func commit_original_actor_vitals(proposal: Dictionary, original: Dictionary) -> Dictionary:
	if not verify_original_actor_vitals(proposal, original): return {"ok": false, "code": "stale_original_actor"}
	var rec: Dictionary = encounters[str(proposal.encounter_id)]
	var source: Dictionary = original.participants[int(proposal.peer_id)]
	var member: Dictionary = rec.get("participants", {}).get(int(proposal.peer_id), {})
	if member.is_empty(): member = rec.get("retained_actor_participants", {}).get(source.character_id, {})
	var current: Dictionary = member.actor_vitals[str(proposal.creature_uid)]
	current["hp"] = proposal.hp_after
	current["fainted"] = proposal.fainted
	current["revision"] = proposal.revision
	current["settlement_receipt"] = proposal.settlement_receipt.duplicate(true)
	current.receipts[str(proposal.action_id)] = true
	seq += 1
	rec["seq"] = seq
	return {"ok": true, "vitals": _actor_vitals_view(current)}


## A separate disclosed harness source may heal one alive damaged actor to
## its existing maximum. Session authenticates the actual PeerRunner provider;
## this pure replay never authorizes a fresh source in a terminal encounter.
func verify_original_fixture_actor_topup(proposal: Dictionary, original: Dictionary) -> bool:
	var id: String = str(proposal.get("encounter_id", ""))
	var peer: int = int(proposal.get("peer_id", 0))
	var uid: String = str(proposal.get("creature_uid", ""))
	var rec: Dictionary = encounters.get(id, {})
	var scope: Dictionary = rec.get("ordinary_combat_reward_owner", {})
	if proposal.get("kind") != "heal" or original.get("encounter_id") != id \
		or not preload("res://scripts/net/combat_round_reward.gd").scope_valid(scope) \
		or scope.trainer_id != "warden_aldis" or rec.get("kind") != "boss" \
		or original.get("phase") != "active" or rec.get("phase") not in ["active", "resolving", "done"] \
		or not _tracking_enabled_for(id) or move_action_publication_pending(id) \
		or rec.get("realm") != original.get("realm") \
		or rec.get("ordinary_combat_reward_owner") != original.get("ordinary_combat_reward_owner") \
		or rec.get("opponent", {}).get("card", {}).get("uid") != original.get("opponent", {}).get("card", {}).get("uid") \
		or rec.get("opponent", {}).get("body_generation") != original.get("opponent", {}).get("body_generation"):
		return false
	var source: Dictionary = original.get("participants", {}).get(peer, {})
	var member: Dictionary = rec.get("participants", {}).get(peer, {})
	if member.is_empty(): member = rec.get("retained_actor_participants", {}).get(source.get("character_id"), {})
	var before: Dictionary = source.get("actor_vitals", {}).get(uid, {})
	var current: Dictionary = member.get("actor_vitals", {}).get(uid, {})
	if before.is_empty() or source.get("character_id") != member.get("character_id") \
		or source.get("actor_bound_uid") != uid or member.get("actor_bound_uid") != uid \
		or int(before.get("body_instance_id", 0)) <= 0 or current != before \
		or before.get("fainted") != false or float(before.get("hp", 0.0)) <= 0.0 \
		or float(before.hp) >= float(before.max_hp) \
		or proposal.get("amount") != float(before.max_hp) - float(before.hp): return false
	var trial: Variant = get_script().new(_host_peer_id)
	trial.encounters[id] = original.duplicate(true)
	trial._vitals_namespace = _vitals_namespace
	var verified: Dictionary = trial.call("stage_actor_vitals", id, peer, uid,
		int(proposal.get("body_generation", -1)), int(proposal.get("expected_revision", -1)),
		str(proposal.get("action_id", "")), "heal", float(before.max_hp) - float(before.hp),
		int(proposal.get("receipt_limit", 0)))
	return verified.get("ok") == true and verified == proposal


func commit_original_fixture_actor_topup(proposal: Dictionary, original: Dictionary) -> Dictionary:
	if not verify_original_fixture_actor_topup(proposal, original): return {"ok": false, "code": "stale_original_fixture_actor"}
	var rec: Dictionary = encounters[str(proposal.encounter_id)]
	var source: Dictionary = original.participants[int(proposal.peer_id)]
	var member: Dictionary = rec.get("participants", {}).get(int(proposal.peer_id), {})
	if member.is_empty(): member = rec.get("retained_actor_participants", {}).get(source.character_id, {})
	var current: Dictionary = member.actor_vitals[str(proposal.creature_uid)]
	current["hp"] = proposal.hp_after
	current["fainted"] = proposal.fainted
	current["revision"] = proposal.revision
	current["settlement_receipt"] = proposal.settlement_receipt.duplicate(true)
	current.receipts[str(proposal.action_id)] = true
	seq += 1
	rec["seq"] = seq
	return {"ok": true, "vitals": _actor_vitals_view(current)}


func bind_actor_body(id: String, peer: int, character: String, owned: Dictionary, body_id: int) -> Dictionary:
	if move_action_publication_pending(id): return {"ok": false, "code": "pending_action"}
	return super.bind_actor_body(id, peer, character, owned, body_id)


func bind_actor_vitals(id: String, peer: int, character: String, owned: Dictionary, generation: int) -> Dictionary:
	if move_action_publication_pending(id): return {"ok": false, "code": "pending_action"}
	return super.bind_actor_vitals(id, peer, character, owned, generation)
