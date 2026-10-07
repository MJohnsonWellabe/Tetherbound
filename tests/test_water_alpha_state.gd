extends "res://tests/test_case.gd"
## Host state, real catch arbitration, and the Water runtime's outbound strike
## envelope. No network process, shoreline movement or reward persistence is
## proven here; the production Alpha smoke covers the local combat loop.
const ALPHA := preload("res://scripts/combat/water_alpha_state.gd")
const ALPHA_RUNTIME := preload("res://scripts/combat/water_alpha.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ARBITER := preload("res://scripts/net/catch_arbiter.gd")
const PEER_B := 1369099083

class RecordingTransport:
	extends Node
	var intents: Array[Dictionary] = []

	func submit(intent: Dictionary) -> Dictionary:
		intents.append(intent.duplicate(true))
		return {"ok": true}

func _enemy() -> RefCounted:
	var enemy := SPECIES.spawn("water_aquaryn")
	enemy.level = 49
	return enemy

func _opened() -> RefCounted:
	var state := ALPHA.new()
	state.engage(1, "character-A", "creature-A", _enemy())
	state.engage(PEER_B, "character-B", "creature-B", state.enemy)
	return state

func _throw(state: RefCounted, roll: float) -> Dictionary:
	return {"kind": state.record().kind, "phase": state.record().phase,
		"opponent_fainted": state.enemy.fainted, "species_id": state.enemy.species_id,
		"hp_fraction": state.enemy.hp / state.enemy.max_hp, "body_radius": 2.0,
		"target_position": Vector3.ZERO, "launch_point": Vector3(0,0,-4),
		"direction": Vector3(0,0,1), "orb_id": "orb_prime", "roll": roll}

func test_runtime_transport_stamps_monotonic_strike_actions() -> void:
	var alpha := ALPHA_RUNTIME.new()
	var transport := RecordingTransport.new()
	alpha.transport = transport
	alpha.submit_encounter_intent({"kind": "strike_intent", "slot": "quick"})
	alpha.submit_encounter_intent({"kind": "strike_intent", "slot": "quick"})
	alpha.submit_encounter_intent({"kind": "strike_intent", "slot": "quick", "action": 9})
	alpha.submit_encounter_intent({"kind": "strike_intent", "slot": "quick"})
	alpha.submit_encounter_intent({"kind": "catch_attempt"})
	alpha.submit_encounter_intent({"kind": "move_start", "slot": "utility"})
	alpha.submit_encounter_intent({"kind": "strike_intent", "slot": "utility", "action": 11})
	assert_eq(transport.intents[0].action, 1)
	assert_eq(transport.intents[1].action, 2)
	assert_eq(transport.intents[2].action, 9)
	assert_eq(transport.intents[3].action, 10)
	assert_false(transport.intents[4].has("action"), "Non-strike intents retain their protocol shape")
	assert_eq(transport.intents[5].action, 11, "Move starts share the actual monotonic action sequence")
	assert_eq(transport.intents[6].action, 11, "Arrival preserves its original start")
	assert_true(alpha.supports_host_move_start())
	alpha.free()
	transport.free()

func test_accepted_terminal_preserves_alpha_resolution_and_real_opponent_identity() -> void:
	var state := _opened()
	assert_eq(state.host.get_script(), preload("res://scripts/combat/accepted_action_host.gd"))
	assert_eq(state.record().get("opponent", {}).get("card", {}).get("uid", ""), state.enemy.uid)
	assert_eq(state.record().opponent.body_generation, 1)
	state.enemy.take_damage(state.enemy.max_hp)
	state.host.set_phase(state.encounter_id, "done")
	var original: Dictionary = state.synchronise_damage()
	assert_eq(original.outcome, "defeated")
	assert_eq(original.eligible_character_ids, ["character-A", "character-B"])
	assert_eq(state.record().phase, "done", "Accepted terminal publication remains terminal")
	assert_eq(state.record().opponent.hp, 0.0)
	assert_true(state.synchronise_damage().is_empty(), "No second Alpha resolution")
	assert_eq(state.resolution, original)

func test_persistent_damage_adapter_binds_same_body_without_an_ai_or_arena() -> void:
	var opponent := preload("res://scripts/creatures/wild_creature.gd").new()
	opponent.instance = _enemy()
	var alpha := ALPHA_RUNTIME.new()
	var resolver := preload("res://scripts/combat/shared_wild_host_fight.gd").new()
	resolver.bind_persistent_opponent(opponent, alpha, "alpha-actions", 1)
	assert_eq(resolver.body(), opponent)
	assert_eq(resolver.get("_wild"), opponent)
	assert_eq(resolver.get("_enemy"), opponent.instance)
	assert_eq(resolver.authority_link, alpha)
	assert_eq(resolver.body_generation, 1)
	assert_eq(resolver.encounter_id(), "alpha-actions")
	assert_eq(resolver.get("_arena"), null)
	assert_false(opponent.strike_ready.is_connected(Callable(resolver, "_on_enemy_strike")))
	resolver.free()
	alpha.free()
	opponent.free()

func test_two_participants_join_the_same_wounded_enemy_without_reset() -> void:
	var state := ALPHA.new()
	var enemy := _enemy()
	enemy.hp = enemy.max_hp * 0.6
	var hp: float = enemy.hp
	var first := state.engage(1, "character-A", "creature-A", enemy)
	var encounter_id: String = first.encounter_id
	state.advance(0.1)
	var joined := state.engage(PEER_B, "character-B", "creature-B", enemy)
	assert_eq(joined.encounter_id, encounter_id)
	assert_eq(joined.participants.size(), 2)
	assert_eq(joined.participants[1].character_id, "character-A")
	assert_eq(joined.participants[PEER_B].character_id, "character-B")
	assert_eq(joined.opponent.hp, hp)
	assert_eq(enemy.hp, hp)
	assert_eq(state.enemy, enemy)
	assert_eq(state.phase().id, "tidal_run")
	assert_eq(state.eligible_characters.size(), 2)
	assert_true(state.engage(42, "outsider", "other", _enemy()).is_empty())
	assert_eq(state.enemy, enemy)
	assert_eq(state.eligible_characters.size(), 2)

func test_alpha_pending_ledgers_fence_results_and_leave_without_primary_prerequisites() -> void:
	var alpha := ALPHA_RUNTIME.new()
	alpha.authority = _opened()
	alpha.set("_encounter_host", alpha.authority.host)
	var id: String = alpha.authority.encounter_id
	assert_false(alpha._alpha_results_pending(id))
	var proposals: Dictionary = alpha.get("_ordinary_actor_vitals_proposals")
	proposals["saved-original"] = {"encounter_id":id, "presented":false}
	assert_true(alpha.ordinary_actor_vitals_pending(id), "the Alpha's retained original fences even without a primary trainer registry")
	assert_true(alpha._alpha_results_pending(id))
	var before := alpha.authority.eligible_characters.duplicate(true)
	assert_eq(alpha._leave_alpha(1, true).get("code"), "pending_vitals")
	assert_eq(alpha.authority.eligible_characters, before, "a declined leave cannot erase eligibility before settlement")
	assert_false(alpha.realm_transition_alpha_results_settled())
	proposals["saved-original"]["presented"] = true
	assert_false(alpha.ordinary_actor_vitals_pending(id))
	# Disclosed unit-only ledger rows exercise the existing publication and
	# mastery fences; they do not claim an accepted runtime action or award.
	var authority_rows: Dictionary = alpha.authority.host.get("_strike_authority")
	authority_rows[id] = {1:{"accepted_actions":{"original":{"phase":"body_publication_pending"}}}}
	assert_true(alpha._alpha_results_pending(id))
	authority_rows[id][1].accepted_actions.original["phase"] = "resolved"
	authority_rows[id][1]["move_starts"] = {1:{"mastery_pending":true, "action":1}}
	assert_true(alpha._alpha_results_pending(id))
	authority_rows[id][1].move_starts[1]["mastery_pending"] = false
	assert_false(alpha._alpha_results_pending(id))
	assert_true(alpha.realm_transition_alpha_results_settled())
	alpha.free()

func test_repeated_peer_cannot_add_a_different_character_entitlement() -> void:
	var state := _opened()
	state.engage(1, "character-A", "creature-A", state.enemy)
	assert_eq(state.eligible_characters.size(), 2, "Retry must be idempotent")
	assert_true(state.engage(1, "wrong-character", "creature-A", state.enemy).is_empty())
	assert_false(state.eligible_characters.has("wrong-character"), "No entitlement outside the participant identity record")
	assert_eq(state.record().participants[1].character_id, "character-A")

func test_phase_thresholds_are_monotonic_and_do_not_reset_on_healing() -> void:
	var state := _opened()
	state.enemy.hp = state.enemy.max_hp * 0.701
	assert_false(state.advance(2.0))
	assert_eq(state.phase().id, "shore_crest")
	state.enemy.hp = state.enemy.max_hp * 0.7
	assert_true(state.advance(1.0))
	assert_eq(state.phase().id, "tidal_run")
	assert_eq(state.phase_elapsed, 0.0)
	state.enemy.hp = state.enemy.max_hp * 0.351
	assert_false(state.advance(1.0))
	assert_eq(state.phase().id, "tidal_run")
	state.enemy.hp = state.enemy.max_hp * 0.35
	assert_true(state.advance(1.0))
	assert_eq(state.phase().id, "broken_wake")
	state.enemy.hp = state.enemy.max_hp
	assert_false(state.advance(2.0))
	assert_eq(state.phase().id, "broken_wake")
	assert_eq(state.phase_elapsed, 2.0)

func test_only_live_enemy_zero_hp_resolves_defeat_once() -> void:
	var state := _opened()
	state.host.set_opponent_hp(state.encounter_id, 0.0, state.enemy.max_hp)
	assert_true(state.synchronise_damage().is_empty(), "A stale record cannot defeat the live enemy")
	assert_eq(state.record().opponent.hp, state.enemy.hp)
	state.enemy.hp = 0.01
	assert_true(state.synchronise_damage().is_empty())
	state.enemy.hp = 0.0
	var result: Dictionary = state.synchronise_damage()
	assert_eq(result.outcome, "defeated")
	assert_eq(result.catcher_peer_id, 0)
	assert_eq(result.eligible_character_ids.size(), 2)
	assert_true("character-A" in result.eligible_character_ids)
	assert_true("character-B" in result.eligible_character_ids)
	assert_eq(state.record().phase, "resolving")
	assert_true(state.synchronise_damage().is_empty())
	assert_true(state.engage(42, "late", "creature-C", _enemy()).is_empty())
	result.eligible_character_ids.append("tampered-copy")
	assert_false("tampered-copy" in state.resolution.eligible_character_ids)

func test_catch_uses_stored_claimant_decision_rejects_outsider_and_replay() -> void:
	var state := _opened()
	var arbiter := ARBITER.new()
	state.enemy.hp = state.enemy.max_hp * 0.1
	state.synchronise_damage()
	assert_true(state.finish_catch(PEER_B, arbiter, 10001).is_empty(), "No stored decision means no catch")
	var attempt := arbiter.attempt(state.encounter_id, PEER_B, _throw(state, 0.0), 10000)
	assert_true(attempt.ok)
	assert_true(arbiter.decision_for(state.encounter_id, PEER_B).caught)
	state.host.set_phase(state.encounter_id, "catching")
	assert_true(state.finish_catch(99, arbiter, 10001).is_empty())
	assert_true(state.finish_catch(1, arbiter, 10001).is_empty(), "Another participant cannot finish the winning claim")
	assert_true(state.resolution.is_empty())
	assert_eq(arbiter.owner_of(state.encounter_id, 10001), PEER_B)
	var result: Dictionary = state.finish_catch(PEER_B, arbiter, 10001)
	assert_eq(result.outcome, "caught")
	assert_eq(result.catcher_peer_id, PEER_B)
	assert_eq(result.eligible_character_ids.size(), 2)
	assert_true(arbiter.decision_for(state.encounter_id, PEER_B).is_empty())
	assert_true(state.finish_catch(PEER_B, arbiter, 10001).is_empty())
	assert_true(state.synchronise_damage().is_empty())

func test_breakout_restores_active_fight_without_unlocking() -> void:
	var state := _opened()
	var arbiter := ARBITER.new()
	var attempt := arbiter.attempt(state.encounter_id, 1, _throw(state, 0.999999), 10000)
	assert_true(attempt.ok)
	assert_false(arbiter.decision_for(state.encounter_id, 1).caught)
	state.host.set_phase(state.encounter_id, "catching")
	var result: Dictionary = state.finish_catch(1, arbiter, 10001)
	assert_eq(result.outcome, "escaped")
	assert_false(result.caught)
	assert_true(state.resolution.is_empty())
	assert_eq(state.record().phase, "active")
	assert_eq(arbiter.owner_of(state.encounter_id, 10001), 0)
	assert_true(state.finish_catch(1, arbiter, 10001).is_empty())

func test_abandoned_fight_cannot_replace_the_original_wounded_opponent() -> void:
	var state := _opened()
	var enemy: RefCounted = state.enemy
	enemy.hp = enemy.max_hp * 0.2
	state.synchronise_damage()
	state.host.leave(state.encounter_id, 1)
	state.host.leave(state.encounter_id, PEER_B)
	assert_eq(state.record().phase, "done")
	assert_true(state.engage(1, "character-A", "creature-A", _enemy()).is_empty(), "Leaving cannot reset Alpha through a new instance")
	assert_eq(state.enemy, enemy)
	var reopened: Dictionary = state.engage(1, "character-A", "creature-A", enemy)
	assert_false(reopened.is_empty(), "Returning to the same living enemy remains possible")
	assert_eq(reopened.opponent.hp, enemy.hp)
	assert_eq(state.phase().id, "broken_wake")

func test_expired_catch_cannot_resolve_or_cancel_a_new_claim() -> void:
	var state := _opened()
	var arbiter := ARBITER.new()
	assert_eq(arbiter._window_ms(), 6000, "Exercise the actual production arbitration lease")
	state.enemy.hp = state.enemy.max_hp * 0.1
	var first: Dictionary = arbiter.attempt(state.encounter_id, 1, _throw(state, 0.0), 10000)
	assert_true(first.ok)
	assert_true(arbiter.decision_for(state.encounter_id, 1).caught)
	state.host.set_phase(state.encounter_id, "catching")
	assert_true(state.finish_catch(1, arbiter, 16001).is_empty(), "Expired successful decision cannot unlock Alpha")
	assert_true(state.resolution.is_empty())
	assert_eq(arbiter.owner_of(state.encounter_id, 16001), 0)
	var second: Dictionary = arbiter.attempt(state.encounter_id, PEER_B, _throw(state, 0.0), 16001)
	assert_true(second.ok, "Another participant can claim after the lease expires")
	assert_eq(arbiter.owner_of(state.encounter_id, 16002), PEER_B)
	assert_true(state.finish_catch(1, arbiter, 16002).is_empty(), "Late former claimant cannot finish the replacement claim")
	assert_eq(arbiter.owner_of(state.encounter_id, 16002), PEER_B, "Late acknowledgement must not release another player's claim")
	var result: Dictionary = state.finish_catch(PEER_B, arbiter, 16002)
	assert_eq(result.outcome, "caught")
	assert_eq(result.catcher_peer_id, PEER_B)
