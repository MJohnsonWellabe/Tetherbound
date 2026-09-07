extends "res://tests/test_case.gd"
## Pure host state and real catch arbitration only. No network transport,
## player combat loop, shoreline movement or reward persistence is proven here.
const ALPHA := preload("res://scripts/combat/water_alpha_state.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const ARBITER := preload("res://scripts/net/catch_arbiter.gd")
const PEER_B := 1369099083

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
