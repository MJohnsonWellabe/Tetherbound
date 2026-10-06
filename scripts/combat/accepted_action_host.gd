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


## The director supplies the admitted owner's next healthy creature and both
## host-frozen quick profiles. A request carries only the existing command ID.
## Retain its parent here before presentation; spend and body mutation belong
## to the synchronous arrival commit, never to preparation or a guest packet.
func prepare_tether_tag_command(request: Dictionary, peer: int, binding: Dictionary,
		view: Dictionary, frozen_moves: Array, now_ms: int) -> Dictionary:
	var commands := preload("res://scripts/combat/tether_commands.gd")
	if not commands.enabled() or not commands.valid_intent(request) or request.command_id != "tag_combo":
		return {"ok":false, "code":"invalid_request"}
	var id: String = request.encounter_id
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	if not _tracking_enabled_for(id) or encounters.get(id, {}).get("phase") != "active" \
		or not _binding_current(id, peer, binding) or binding.get("deployment_generation") != request.generation \
		or participant.get("character_id") != view.get("actor", {}).get("character_id") \
		or binding.get("creature_uid") != view.get("actor", {}).get("creature_uid") \
		or view.get("actor", {}).get("generation") != request.generation \
		or not participant.get("tether_commands") is Dictionary or frozen_moves.size() != 2 \
		or not pending_tether_items(id).is_empty() or move_action_publication_pending(id):
		return {"ok":false, "code":"stale_actor"}
	var parent := "command:%s:%s:%d:%d" % [id, participant.character_id, int(request.generation), int(request.sequence)]
	var actions := _actions(id, peer)
	var existing: Dictionary = actions.get(parent, {})
	if not existing.is_empty():
		return {"ok":true, "duplicate":true, "original":existing.admission.duplicate(true)} \
			if existing.get("phase") == "admitted" and existing.admission.get("request") == request \
			and existing.admission.get("binding") == binding else {"ok":false, "code":"replayed"}
	for retained: Dictionary in actions.values():
		if retained.get("admission", {}).get("kind") == "tag_combo" and retained.get("phase") == "admitted":
			return {"ok":false, "code":"pending_action"}
	var limit := int(MATH.config().get("utility_limits", {}).get("receipt_limit_per_encounter", 0))
	if limit < 1 or actions.size() >= limit: return {"ok":false, "code":"receipt_budget"}
	var host := view.duplicate(true)
	host.merge({"peer_id":peer, "owner_admitted":true, "encounter_active":true, "unlocked_commands":["tag_combo"],
		"accepted_receipt":{"action_id":parent, "character_id":participant.character_id, "encounter_id":id,
			"attacker_uid":binding.creature_uid, "generation":request.generation, "sequence":request.sequence,
			"command_id":"tag_combo", "command_committed":false}}, true)
	var plan: Dictionary = commands.stage_command(participant.tether_commands, request, host, now_ms)
	if plan.get("ok") != true: return plan
	# Validate both frozen profiles/attributions now, without accepting their
	# predicted damage as a live debit or changing either creature's resources.
	var joint: Dictionary = commands.stage_joint_attack(plan.effect, frozen_moves, host, MATH.config())
	if joint.get("ok") != true: return joint
	var admission := {"kind":"tag_combo", "encounter_id":id, "peer_id":peer,
		"action":-int(request.sequence), "action_id":parent, "request":request, "binding":binding,
		"target_uid":plan.effect.target_uid, "target_generation":plan.effect.target_generation,
		"incoming":host.incoming, "moves":frozen_moves, "plan":plan,
		"command_before":participant.tether_commands, "accepted_at_ms":now_ms}
	if not _strike_state_for(id).has(peer): _strike_authority[id][peer] = {}
	_strike_authority[id][peer]["accepted_actions"] = actions
	actions[parent] = {"phase":"admitted", "admission":_original(admission)}
	return {"ok":true, "duplicate":false, "original":admission.duplicate(true)}


## One parent enters resolution once. Recompute arrival geometry from the
## host's current bodies; keep both accepted move profiles and child IDs.
func begin_tether_tag_resolution(id: String, peer: int, parent: String,
		binding: Dictionary, view: Dictionary) -> Dictionary:
	var entry: Dictionary = _actions(id, peer).get(parent, {})
	if entry.get("phase") != "admitted" or entry.get("admission", {}).get("kind") != "tag_combo" \
		or move_action_publication_pending(id): return {"ok":false, "code":"not_arrivable"}
	var original: Dictionary = entry.admission
	var rec: Dictionary = encounters.get(id, {})
	var participant: Dictionary = rec.get("participants", {}).get(peer, {})
	var target: Dictionary = view.get("target", {})
	if rec.get("phase") != "active" or binding != original.binding or not _binding_current(id, peer, binding) \
		or participant.get("tether_commands") != original.command_before \
		or view.get("incoming_is_next_owned") != true or view.get("incoming") != original.incoming \
		or target.get("uid") != original.target_uid or target.get("generation") != original.target_generation \
		or target.get("uid") != rec.get("opponent", {}).get("card", {}).get("uid") \
		or target.get("generation") != rec.get("opponent", {}).get("body_generation") \
		or target.get("hp") != rec.get("opponent", {}).get("hp"):
		entry["phase"] = "cancelled"
		return {"ok":false, "code":"stale_arrival"}
	var joint: Dictionary = preload("res://scripts/combat/tether_commands.gd").stage_joint_attack(
		original.plan.effect, original.moves, view, MATH.config())
	if joint.get("ok") != true:
		entry["phase"] = "cancelled"
		return joint
	entry["arrival"] = _original(joint)
	entry["phase"] = "resolving"
	return {"ok":true, "action_id":parent, "original":original.duplicate(true), "joint":joint}


## Observe the ordinary writer's two results after the real incoming actor
## has been bound. Claimed damage never substitutes for chained actual HP.
func record_tether_tag_outcome(id: String, peer: int, parent: String,
		incoming_binding: Dictionary, written: Array, now_ms: int) -> Dictionary:
	var entry: Dictionary = _actions(id, peer).get(parent, {})
	if entry.get("phase") != "resolving" or entry.get("admission", {}).get("kind") != "tag_combo" \
		or written.size() != 2 or now_ms < 0: return {"ok":false, "code":"not_resolving"}
	var original: Dictionary = entry.admission
	var participant: Dictionary = encounters.get(id, {}).get("participants", {}).get(peer, {})
	var opponent: Dictionary = encounters.get(id, {}).get("opponent", {})
	if incoming_binding.get("character_id") != original.binding.character_id \
		or incoming_binding.get("creature_uid") != original.incoming.creature_uid \
		or incoming_binding.get("deployment_generation") != original.incoming.generation \
		or not _binding_current(id, peer, incoming_binding) \
		or participant.get("tether_commands") != original.command_before \
		or opponent.get("card", {}).get("uid") != original.target_uid \
		or opponent.get("body_generation") != original.target_generation: return {"ok":false, "code":"stale_outcome"}
	var before := float(entry.arrival.hp_before)
	var maximum := float(opponent.get("hp_max", NAN))
	var hp := before
	var outcomes: Array = []
	var strikes: Array = []
	for index: int in 2:
		var rolled: Variant = written[index]
		if not rolled is Dictionary or not (rolled.get("hp") is int or rolled.get("hp") is float) \
			or not is_finite(float(rolled.hp)) or float(rolled.hp) < 0.0 or float(rolled.hp) > hp \
			or rolled.get("hp_max") != maximum: return {"ok":false, "code":"invalid_debit"}
		var strike: Dictionary = entry.arrival.strikes[index].duplicate(true)
		strike["target_hp_before"] = hp
		strike["actual_hp_debit"] = hp - float(rolled.hp)
		strike["target_hp_after"] = float(rolled.hp)
		strike["landed"] = float(strike.actual_hp_debit) > 0.0
		strikes.append(strike)
		if strike.landed:
			outcomes.append({"binding":original.binding.duplicate(true) if index == 0 else incoming_binding.duplicate(true),
				"context":original.moves[index].get("mastery_context", {}).duplicate(true),
				"outcome":{"action_id":strike.action_id, "move_id":strike.move_id,
					"attacker_uid":strike.attacker_uid, "target_uid":original.target_uid,
					"target_hp_before":hp, "applied_damage":strike.actual_hp_debit}})
		hp = float(rolled.hp)
	if not is_finite(maximum) or maximum <= 0.0 or opponent.get("hp") != hp:
		return {"ok":false, "code":"uncommitted_debit"}
	var state: Dictionary = original.plan.state.duplicate(true)
	state["switch_until_ms"] = now_ms + int(float(TETHER_COMMANDS.config().switch_lockout_s) * 1000)
	state["last_receipt"] = original.plan.receipt.duplicate(true)
	var effect: Dictionary = original.plan.effect.duplicate(true)
	effect["strikes"] = strikes
	var verdict := {"ok":true, "kind":"tether_command", "peer":peer, "code":"accepted", "pending":false,
		"reason":"", "encounter_id":id, "command_generation":original.request.generation,
		"command_request":original.request.duplicate(true),
		"delta":{"tether_commands":state.duplicate(true), "effect":effect,
			"switched_to_uid":original.incoming.creature_uid, "switch_lockout_s":TETHER_COMMANDS.config().switch_lockout_s}}
	participant["tether_commands"] = state
	entry["outcome"] = _original({"action_id":parent, "actual_hp_debit":before - hp,
		"target_hp_before":before, "target_hp_after":hp, "rolled":written[1], "verdict":verdict,
		"joint_mastery":outcomes})
	entry["mastery_pending"] = not outcomes.is_empty()
	entry["phase"] = "body_publication_pending"
	seq += 1
	encounters[id]["seq"] = seq
	return verdict


func move_mastery_outcome(id: String, peer: Variant, action: int) -> Dictionary:
	if action >= 0: return super.move_mastery_outcome(id, peer, action)
	for entry: Dictionary in (_strike_authority.get(id, {}) as Dictionary).get(peer, {}).get("accepted_actions", {}).values():
		if entry.get("mastery_pending") == true and entry.get("admission", {}).get("kind") == "tag_combo" \
			and entry.admission.action == action:
			return {"encounter_id":id, "peer":peer, "action":action, "action_id":entry.admission.action_id,
				"outcomes":entry.outcome.joint_mastery.duplicate(true)}
	return {}


func acknowledge_move_mastery(id: String, peer: Variant, action: int, action_id: String) -> bool:
	if action >= 0: return super.acknowledge_move_mastery(id, peer, action, action_id)
	var entry: Dictionary = (_strike_authority.get(id, {}) as Dictionary).get(peer, {}).get("accepted_actions", {}).get(action_id, {})
	if entry.get("mastery_pending") != true or entry.get("admission", {}).get("kind") != "tag_combo" \
		or entry.admission.action != action: return false
	entry["mastery_pending"] = false
	return true


func pending_move_mastery() -> Array[Dictionary]:
	var pending: Array[Dictionary] = super.pending_move_mastery()
	for id: String in _strike_authority:
		for peer: Variant in _strike_authority[id]:
			for entry: Dictionary in _strike_authority[id][peer].get("accepted_actions", {}).values():
				if entry.get("mastery_pending") == true and entry.get("admission", {}).get("kind") == "tag_combo":
					pending.append({"encounter_id":id, "peer":peer, "action":int(entry.admission.action)})
	return pending


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
	for pending: Dictionary in pending_move_mastery():
		if pending.encounter_id == id: return
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
	# F27: a guest's actor in a canonical wild fight is owned by its own
	# encounter scope (wild_actor_scope.gd), never a trainer round scope.
	var wild: bool = preload("res://scripts/net/wild_actor_scope.gd").owns(rec.get("wild_actor_owner"), rec, id) \
		and rec.get("wild_actor_owner") == original.get("wild_actor_owner")
	if proposal.get("kind") != "damage" or original.get("encounter_id") != id \
		or not (wild or (preload("res://scripts/net/combat_round_reward.gd").scope_valid(rec.get("ordinary_combat_reward_owner")) \
			and rec.get("kind") in ["trainer", "boss"])) \
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
	if move_action_publication_pending(id):
		var uid := str(owned.get("uid", ""))
		var participant: Dictionary = _actor_participant(id, peer, character)
		var current: Dictionary = participant.get("actor_vitals", {}).get(uid, {})
		if not _tag_incoming_binding_allowed(id, peer, character, uid) \
			or (participant.get("actor_bound_uid") == uid and current.get("body_instance_id") != body_id):
			return {"ok": false, "code": "pending_action"}
	return super.bind_actor_body(id, peer, character, owned, body_id)


func bind_actor_vitals(id: String, peer: int, character: String, owned: Dictionary, generation: int) -> Dictionary:
	if move_action_publication_pending(id):
		var uid := str(owned.get("uid", ""))
		var participant: Dictionary = _actor_participant(id, peer, character)
		var current: Dictionary = participant.get("actor_vitals", {}).get(uid, {})
		if not _tag_incoming_binding_allowed(id, peer, character, uid) \
			or (participant.get("actor_bound_uid") == uid and current.get("body_generation") != generation):
			return {"ok": false, "code": "pending_action"}
	return super.bind_actor_vitals(id, peer, character, owned, generation)


## Only the same parent's accepted incoming actor may replace its outgoing
## body during the synchronous Tag arrival. Unrelated publication stays held.
func _tag_incoming_binding_allowed(id: String, peer: int, character: String, uid: String) -> bool:
	for entry: Dictionary in _actions(id, peer).values():
		if entry.get("phase") != "resolving" or entry.get("admission", {}).get("kind") != "tag_combo": continue
		return entry.admission.binding.character_id == character and entry.admission.incoming.creature_uid == uid
	return false
