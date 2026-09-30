extends "res://tests/test_case.gd"

const EFFECTS := preload("res://scripts/combat/utility_effects.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const ENCOUNTER_HOST := preload("res://scripts/net/encounter_host.gd")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")

func _host(action_id: String = "host-action-1") -> Dictionary:
	return {"action_id": action_id, "encounter_id": "fight-1", "generation": 3,
		"source_uid": "owned-1", "target_uid": "foe-1", "source_position": Vector3.ZERO,
		"target_position": Vector3(3, 0, 0), "target_point": Vector3(3, 0, 0),
		"source_hp": 50.0, "source_max_hp": 100.0, "target_hp": 100.0,
		"hostile": true, "geometry_connected": true, "target_is_boss": false}

func test_refresh_is_not_additive_and_replay_or_wrong_scope_never_mutates() -> void:
	var moves := MOVES.new()
	var state := EFFECTS.empty_state("fight-1", 3)
	var baseline := state.duplicate(true)
	var host := _host()
	host.target_is_boss = true
	var first := EFFECTS.stage_application(state, "snare", moves.move("snare"), host, 0, 10)
	assert_true(first.ok)
	assert_eq(state, baseline, "staging never publishes a status or action receipt")
	assert_eq(first.state.statuses["foe-1"].root.expires_at_ms, 500, "authored boss resistance")
	assert_eq(EFFECTS.movement_multiplier(first.state, "foe-1", Vector3(3,0,0), 499), 0.0)
	assert_eq(EFFECTS.movement_multiplier(first.state, "foe-1", Vector3(3,0,0), 500), 1.0)
	var second := EFFECTS.stage_application(first.state, "snare", moves.move("snare"), _host("host-action-2"), 300, 10)
	assert_true(second.ok)
	assert_eq(second.state.statuses["foe-1"].root.expires_at_ms, 1300, "refresh uses current maximum rather than adding old remaining duration")
	var after: Dictionary = second.state.duplicate(true)
	assert_false(EFFECTS.stage_application(second.state, "snare", moves.move("snare"), _host("host-action-2"), 301, 10).ok)
	for field: String in ["generation", "hostile", "geometry_connected", "target_hp"]:
		var bad := _host("refused-" + field)
		bad[field] = 4 if field == "generation" else (0.0 if field == "target_hp" else false)
		assert_false(EFFECTS.stage_application(second.state, "snare", moves.move("snare"), bad, 400, 10).ok)
	assert_eq(second.state, after, "all failures leave the complete receipt/status ledger intact")
	assert_false(EFFECTS.stage_application(second.state, "snare", moves.move("snare"), _host("new-action"), 500, 2).ok, "receipt saturation refuses without evicting replay protection")

func test_fields_use_frozen_foe_identity_and_trap_arms_and_triggers_once() -> void:
	var moves := MOVES.new()
	var state := EFFECTS.empty_state("fight-1", 3)
	var slow := EFFECTS.stage_application(state, "slow_field", moves.move("slow_field"), _host(), 0, 10)
	assert_true(slow.ok)
	assert_eq(EFFECTS.movement_multiplier(slow.state, "foe-1", Vector3(3,0,0), 100), 0.5)
	assert_eq(EFFECTS.movement_multiplier(slow.state, "other-owned", Vector3(3,0,0), 100), 1.0, "field cannot slow a teammate sharing its point")
	assert_eq(EFFECTS.movement_multiplier(slow.state, "foe-1", Vector3(6,0,0), 100), 1.0, "real field radius")
	var trap := EFFECTS.stage_application(slow.state, "bramble_trap", moves.move("bramble_trap"), _host("trap-action"), 0, 10)
	assert_true(trap.ok)
	assert_false(EFFECTS.stage_trap_trigger(trap.state, "owned-1", "foe-1", Vector3(3,0,0), true, 100.0, false, 499).ok)
	assert_false(EFFECTS.stage_trap_trigger(trap.state, "owned-1", "replacement-foe", Vector3(3,0,0), true, 100.0, false, 500).ok)
	assert_false(EFFECTS.stage_trap_trigger(trap.state, "owned-1", "foe-1", Vector3(3,0,0), false, 100.0, false, 500).ok)
	var triggered := EFFECTS.stage_trap_trigger(trap.state, "owned-1", "foe-1", Vector3(3,0,0), true, 100.0, true, 500)
	assert_true(triggered.ok)
	assert_eq(triggered.state.statuses["foe-1"].root.expires_at_ms, 900, "boss trap resistance comes from data")
	assert_false(EFFECTS.stage_trap_trigger(triggered.state, "owned-1", "foe-1", Vector3(3,0,0), true, 100.0, false, 501).ok)
	assert_false(trap.state.fields["owned-1"].trap.triggered, "trigger proposal is detached until owning host publishes")
	var far := _host("far-field")
	far.target_point = Vector3(7,0,0)
	assert_false(EFFECTS.stage_application(trap.state, "slow_field", moves.move("slow_field"), far, 500, 10).ok)

func test_heal_and_one_hit_buff_are_separate_from_damage_and_never_revive() -> void:
	var moves := MOVES.new()
	var state := EFFECTS.empty_state("fight-1", 3)
	var host := _host()
	host.target_uid = host.source_uid
	var healed := EFFECTS.stage_application(state, "heal_pulse", moves.move("heal_pulse"), host, 0, 10)
	assert_true(healed.ok)
	assert_eq(healed.receipt.hp_before, 50.0)
	assert_eq(healed.receipt.hp_after, 62.0)
	assert_false(healed.receipt.damaging, "successful healing is not a damage event or damaging mastery shortcut")
	assert_eq(healed.receipt.target_uid, "owned-1")
	for hp: float in [0.0, 100.0, INF, NAN]:
		var bad := host.duplicate(true)
		bad.source_hp = hp
		assert_false(EFFECTS.stage_application(state, "heal_pulse", moves.move("heal_pulse"), bad, 0, 10).ok)
	assert_false(EFFECTS.stage_application(state, "heal_pulse", moves.move("heal_pulse"), _host(), 0, 10).ok, "healing cannot select opponent")
	var buff := EFFECTS.stage_application(state, "hearten", moves.move("hearten"), host, 0, 10)
	assert_true(buff.ok)
	assert_eq(EFFECTS.power_multiplier(buff.state, "owned-1", 1), 1.15)
	var consumed := EFFECTS.stage_consume_next_hit(buff.state, "owned-1", 2)
	assert_true(consumed.ok)
	assert_eq(EFFECTS.power_multiplier(consumed.state, "owned-1", 3), 1.0)
	assert_false(EFFECTS.stage_consume_next_hit(consumed.state, "owned-1", 3).ok)
	assert_eq(EFFECTS.power_multiplier(buff.state, "owned-1", 3), 1.15, "failed hit/rollback keeps original buff until published")

func test_host_authorization_shares_action_lock_and_spends_once_without_hostile_self_hit() -> void:
	var moves := MOVES.new()
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"species_id": "bramblebun", "hp": 30.0, "hp_max": 30.0, "position": [3,0,0]})
	var id := str(record.encounter_id)
	var view := {"source_uid": "owned-1", "origin": Vector3.ZERO, "target_uid": "foe-1", "target_position": Vector3(3,0,0), "facing": Vector3.RIGHT, "now_ms": 1000}
	var profile := {"max": 100.0, "regen_per_second": 0.0}
	var intent := {"encounter_id": id, "action": 1, "origin": [9999,0,0], "target_point": [9999,0,0]}
	var accepted: Dictionary = host.validate_utility(intent, 1, view, moves.move("heal_pulse"), profile)
	assert_true(accepted.ok)
	assert_true(accepted.delta.hit, "self effect does not fake an opponent damage-geometry hit")
	assert_eq(accepted.delta.effect_scope, "self")
	assert_eq(accepted.delta.wind, 76.0)
	assert_eq(host.record(id).opponent.hp, 30.0, "authorization never performs foe HP damage or self healing")
	var baseline: Dictionary = host.record(id).duplicate(true)
	assert_false(host.validate_utility(intent, 1, view, moves.move("heal_pulse"), profile).ok)
	assert_eq(host.record(id), baseline, "same action cannot spend twice")
	var quick := {"encounter_id": id, "action": 2, "facing": [1,0,0], "move": {"range": 4.0, "cone_degrees": 90.0, "windup": 0.1, "recovery": 0.2, "cooldown": 0.4}}
	assert_eq(host.validate_strike(quick, 1, view).code, "cooldown", "quick cannot cancel the utility recovery")
	view.now_ms = 2000
	assert_true(host.validate_strike(quick, 1, view).ok, "utility's ten-second slot cooldown does not lock all ordinary attacks")
	intent.action = 3
	view.now_ms = 2500
	assert_false(host.validate_utility(intent, 1, view, moves.move("heal_pulse"), profile).ok, "same UID retains utility cooldown")
	view.source_uid = "owned-2"
	var second: Dictionary = host.validate_utility(intent, 1, view, moves.move("slow_field"), profile)
	assert_true(second.ok, "host-validated second creature has its own utility cooldown")
	assert_eq(second.delta.target_point, Vector3(3,0,0), "untrusted intent point/origin never authors field placement")
	intent.action = 4
	view.now_ms = 4000
	view.source_uid = "owned-3"
	host.commit_wind(id, 1, 3, profile, 100.0, 2500, 0.0, 0.0)
	# The direct call above is the same accepted action and intentionally cannot
	# re-spend. Spend a distinct earlier host ledger action to exhaust the pool.
	host.commit_wind(id, 1, 4, profile, 100.0, 3000, 0.0, 0.0)
	intent.action = 5
	var denied: Dictionary = host.validate_utility(intent, 1, view, moves.move("veil"), profile)
	assert_eq(denied.code, "insufficient_wind")
	assert_eq(host.record(id).participants[1].wind, 0.0)
	assert_eq(host.strike_authority_state(id, 1).last_action, 3, "unaffordable utility adds no action/cooldown")


func _owned_vitals(uid: String = "owned-1", hp: float = 60.0) -> Dictionary:
	return {"uid": uid, "hp": hp, "max_hp": 100.0, "fainted": hp == 0.0}


func test_actor_vitals_stage_then_commit_rejects_stale_tampered_and_replayed_damage() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"hp": 30.0}, "owned-1", "character-1")
	var id := str(record.encounter_id)
	assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals(), 3).ok)
	var baseline: Dictionary = host.record(id).duplicate(true)
	var staged: Dictionary = host.stage_actor_vitals(id, 1, "owned-1", 3, 0, "hit-1", "damage", 20.0, 3)
	assert_true(staged.ok)
	assert_eq(host.record(id), baseline, "staging changes no live HP or receipt")
	var tampered: Dictionary = staged.duplicate(true)
	tampered.hp_after = 100.0
	assert_false(host.commit_actor_vitals(tampered).ok)
	assert_eq(host.record(id), baseline)
	assert_true(host.commit_actor_vitals(staged).ok)
	assert_eq(host.actor_vitals(id, 1, "owned-1", 3).hp, 40.0)
	assert_false(host.commit_actor_vitals(staged).ok)
	assert_false(host.stage_actor_vitals(id, 1, "owned-1", 3, 1, "hit-1", "damage", 20.0, 3).ok)
	assert_false(host.stage_actor_vitals(id, 1, "owned-1", 2, 1, "hit-2", "damage", 20.0, 3).ok)
	assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals("owned-1", 100.0), 4).ok)
	assert_eq(host.actor_vitals(id, 1, "owned-1", 4).hp, 40.0, "deployment cannot reseed old healthy HP")
	assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals("owned-2", 90.0), 5).ok)
	assert_true(host.actor_vitals(id, 1, "owned-1", 4).is_empty(), "inactive UID cannot take/heal a hit")
	assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals(), 6).ok)
	assert_eq(host.actor_vitals(id, 1, "owned-1", 6).hp, 40.0)
	var lethal: Dictionary = host.stage_actor_vitals(id, 1, "owned-1", 6, 1, "hit-2", "damage", 999.0, 3)
	assert_eq(lethal.hp_after, 0.0)
	assert_true(host.commit_actor_vitals(lethal).ok)
	assert_true(host.actor_vitals(id, 1, "owned-1", 6).fainted)
	assert_false(host.stage_actor_vitals(id, 1, "owned-1", 6, 2, "heal-1", "heal", 12.0, 3).ok, "HealPulse never revives")
	assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals("owned-1", 100.0), 7).ok)
	assert_eq(host.actor_vitals(id, 1, "owned-1", 7).hp, 0.0, "rebind cannot resurrect accepted faint")


func test_actor_vitals_survive_peer_change_and_teardown_waits_for_latest_durable_handoff() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"hp": 30.0}, "owned-1", "character-1")
	var id := str(record.encounter_id)
	host.join(id, 2, "other-owned", "character-2")
	host.bind_actor_vitals(id, 1, "character-1", _owned_vitals(), 3)
	var first: Dictionary = host.stage_actor_vitals(id, 1, "owned-1", 3, 0, "hit-1", "damage", 35.0, 10)
	assert_true(host.commit_actor_vitals(first).ok)
	assert_true(host.leave(id, 1).ok)
	assert_eq(host.participant_count(id), 1, "departed actor does not inflate active scaling/targets")
	assert_eq(host.pending_actor_vitals(id).size(), 1)
	host.forget(id)
	assert_false(host.record(id).is_empty(), "failed/unavailable durable handoff retains absolute HP")
	assert_true(host.join(id, 22, "owned-1", "character-1").ok)
	assert_false(host.join(id, 33, "owned-1", "character-1").ok, "one character cannot be duplicated into another active row")
	assert_true(host.bind_actor_vitals(id, 22, "character-1", _owned_vitals("owned-1", 100.0), 4).ok)
	assert_eq(host.actor_vitals(id, 22, "owned-1", 4).hp, 25.0)
	assert_true(host.actor_vitals(id, 1, "owned-1", 3).is_empty())
	var second: Dictionary = host.stage_actor_vitals(id, 22, "owned-1", 4, 1, "hit-2", "damage", 5.0, 10)
	assert_true(host.commit_actor_vitals(second).ok, "pending owner save does not freeze later host damage")
	assert_false(host.acknowledge_actor_vitals(id, "character-1", "owned-1", 1, first.settlement_receipt), "old ACK cannot clear newer pending damage")
	assert_eq(host.pending_actor_vitals(id).size(), 1)
	assert_false(host.remove_actor_vitals(id, 22, "owned-1"), "release cannot discard unsettled HP")
	assert_true(host.acknowledge_actor_vitals(id, "character-1", "owned-1", 2, second.settlement_receipt))
	assert_eq(host.pending_actor_vitals(id).size(), 0)
	host.leave(id, 22)
	host.leave(id, 2)
	assert_eq(host.phase(id), "done", "last-leaver policy remains unchanged")
	host.forget(id)
	assert_true(host.record(id).is_empty())


func test_actor_vitals_fail_closed_on_shapes_capacity_and_receipt_budget() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"hp": 30.0}, "owned-1", "character-1")
	var id := str(record.encounter_id)
	assert_false(host.join(id, 2, "another-uid", "character-1").ok,
		"duplicate stable character refuses before either actor row is seeded")
	assert_eq(host.participant_count(id), 1)
	var baseline: Dictionary = host.record(id).duplicate(true)
	for key: String in ["uid", "hp", "max_hp", "fainted"]:
		var bad := _owned_vitals()
		bad[key] = {} if key != "fainted" else "false"
		assert_false(host.bind_actor_vitals(id, 1, "character-1", bad, 3).ok)
	assert_eq(host.record(id), baseline)
	assert_false(host.bind_actor_vitals(id, 1, "other-character", _owned_vitals(), 3).ok)
	for i: int in range(5):
		assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals("owned-" + str(i)), i + 1).ok)
	assert_false(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals("sixth"), 6).ok)
	var staged: Dictionary = host.stage_actor_vitals(id, 1, "owned-4", 5, 0, "heal-1", "heal", 1000.0, 1)
	assert_eq(staged.hp_after, 100.0, "healing clamps actual host maximum")
	assert_true(host.commit_actor_vitals(staged).ok)
	assert_false(host.stage_actor_vitals(id, 1, "owned-4", 5, 1, "hit-1", "damage", 20.0, 1).ok, "bound refuses instead of evicting replay protection")
	assert_false(host.stage_actor_vitals(id, 1, "owned-4", 5, 1, "heal-1", "heal", 1.0, 1).ok)
	var corrupt: Dictionary = staged.duplicate(true)
	corrupt.amount = {}
	assert_false(host.commit_actor_vitals(corrupt).ok, "host API refuses malformed proposal without conversion crash")


func test_movement_lease_is_owner_scoped_and_duplicate_cannot_extend_or_resurrect_root() -> void:
	var body := CREATURE_BODY.new()
	assert_false(body.apply_combat_movement_status("owned-1", 3, 1, 0.0, 1.0), "unbound body cannot receive a status")
	assert_true(body.bind_combat_movement_owner("owned-1", 3))
	assert_true(body.apply_combat_movement_status("owned-1", 3, 1, 0.0, 1.0))
	var expiry := int(body.get("_combat_movement_status").expires_at_ms)
	assert_eq(body.combat_movement_multiplier(expiry - 1), 0.0)
	assert_eq(body.combat_movement_multiplier(expiry), 1.0, "expiry returns ordinary locomotion without granting immunity")
	assert_true(body.apply_combat_movement_status("owned-1", 3, 1, 0.0, 60.0))
	assert_eq(body.get("_combat_movement_status").expires_at_ms, expiry, "duplicate may not extend the deadline")
	assert_eq(body.combat_movement_multiplier(expiry + 1), 1.0)
	assert_false(body.apply_combat_movement_status("owned-2", 3, 2, 0.0, 1.0))
	assert_false(body.apply_combat_movement_status("owned-1", 2, 2, 0.0, 1.0))
	assert_false(body.apply_combat_movement_status("owned-1", 3, 0, 1.15, 1.0))
	assert_false(body.apply_combat_movement_status("owned-1", 3, 2, NAN, 1.0))
	assert_false(body.apply_combat_movement_status("owned-1", 3, 2, 1.15, INF))
	assert_false(body.bind_combat_movement_owner("replacement-uid", 3))
	assert_true(body.bind_combat_movement_owner("owned-1", 4))
	assert_eq(body.combat_movement_multiplier(), 1.0, "new body generation clears stale root")
	assert_false(body.apply_combat_movement_status("owned-1", 3, 99, 0.0, 1.0))
	assert_true(body.apply_combat_movement_status("owned-1", 4, 2, 1.15, 1.0))
	body.reset_combat_movement_owner()
	assert_eq(body.combat_movement_multiplier(), 1.0)
	assert_false(body.apply_combat_movement_status("owned-1", 4, 99, 0.0, 1.0))
	body.free()


func test_actual_body_object_ids_map_to_monotonic_private_actor_generations() -> void:
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"hp": 30.0}, "owned-1", "character-1")
	var id := str(record.encounter_id)
	var body := CREATURE_BODY.new()
	var replacement := CREATURE_BODY.new()
	var first: Dictionary = host.bind_actor_body(id, 1, "character-1", _owned_vitals(), body.get_instance_id())
	assert_true(first.ok)
	assert_eq(first.vitals.body_generation, 1, "wire generation is not a potentially64-bit ObjectID")
	assert_false(first.vitals.has("body_instance_id"))
	assert_eq(host.bind_actor_body(id, 1, "character-1", _owned_vitals("owned-1", 100.0), body.get_instance_id()).vitals.body_generation, 1)
	var hit: Dictionary = host.stage_actor_vitals(id, 1, "owned-1", 1, 0, "hit-1", "damage", 20.0, 10)
	assert_true(host.commit_actor_vitals(hit).ok)
	var changed: Dictionary = host.bind_actor_body(id, 1, "character-1", _owned_vitals("owned-1", 100.0), replacement.get_instance_id())
	assert_eq(changed.vitals.body_generation, 2)
	assert_eq(changed.vitals.hp, 40.0)
	assert_eq(host.bind_actor_body(id, 1, "character-1", _owned_vitals("owned-2"), replacement.get_instance_id()).vitals.body_generation, 3)
	assert_eq(host.bind_actor_body(id, 1, "character-1", _owned_vitals(), replacement.get_instance_id()).vitals.body_generation, 4, "pooled-body UID switch renews generation")
	var public: Dictionary = ENCOUNTER_HOST.presentation_snapshot(host.record(id))
	assert_false(public.participants[1].has("actor_generation"))
	assert_false(public.participants[1].actor_vitals["owned-1"].has("body_instance_id"))
	assert_false(public.participants[1].actor_vitals["owned-1"].has("receipts"))
	assert_false(public.participants[1].actor_vitals["owned-1"].has("settlement_receipt"))
	public.participants[1].actor_vitals["owned-1"].hp = 100.0
	assert_eq(host.actor_vitals(id, 1, "owned-1", 4).hp, 40.0, "wire projection cannot mutate authoritative HP")
	assert_false(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals(), 2147483648).ok)
	body.free()
	replacement.free()


func test_status_commit_refuses_stale_or_unsupported_effect_before_spend_and_miss_costs_once() -> void:
	var moves := MOVES.new()
	var host := ENCOUNTER_HOST.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {"hp": 30.0, "hp_max": 30.0}, "owned-1", "character-1")
	var id := str(record.encounter_id)
	assert_true(host.bind_actor_vitals(id, 1, "character-1", _owned_vitals(), 3).ok)
	var view := {"source_uid": "owned-1", "source_generation": 3, "origin": Vector3.ZERO,
		"target_uid": "foe-1", "target_position": Vector3(3,0,0), "facing": Vector3.RIGHT, "now_ms": 1000}
	var profile := {"max": 100.0, "regen_per_second": 0.0}
	var intent := {"encounter_id": id, "action": 1, "target_point": [9999,0,0]}
	var accepted: Dictionary = host.commit_status_utility(intent, 1, view, "hearten", moves.move("hearten"), profile)
	assert_true(accepted.ok)
	assert_eq(accepted.delta.wind, 76.0)
	assert_eq(EFFECTS.power_multiplier(host.utility_state(id), "owned-1", 1001), 1.15)
	assert_eq(host.record(id).opponent.hp, 30.0, "self buff never damages or heals opponent")
	assert_eq(host.actor_vitals(id, 1, "owned-1", 3).hp, 60.0, "status never changes actual actor HP")
	var baseline: Dictionary = host.record(id).duplicate(true)
	assert_false(host.commit_status_utility(intent, 1, view, "hearten", moves.move("hearten"), profile).ok)
	assert_eq(host.record(id), baseline, "same action cannot spend or extend buff twice")
	intent.action = 2
	view.now_ms = 12000
	view.source_generation = 2
	assert_false(host.commit_status_utility(intent, 1, view, "hearten", moves.move("hearten"), profile).ok)
	assert_eq(host.record(id), baseline, "stale actual body generation advances no clock or cost")
	view.source_generation = 3
	assert_false(host.commit_status_utility(intent, 1, view, "heal_pulse", moves.move("heal_pulse"), profile).ok)
	assert_false(host.commit_status_utility(intent, 1, view, "snare", moves.move("snare"), profile).ok)
	assert_eq(host.record(id), baseline, "healing and damaging utilities cannot use status-only door")
	view.facing = Vector3.LEFT
	var miss: Dictionary = host.commit_status_utility(intent, 1, view, "sap", moves.move("sap"), profile)
	assert_true(miss.ok)
	assert_false(miss.delta.hit)
	assert_eq(miss.delta.wind, 52.0, "valid whiff spends authored cost exactly once")
	assert_false(miss.delta.has("utility_receipt"))
	assert_eq(EFFECTS.damage_taken_multiplier(host.utility_state(id), "foe-1", 12001), 1.0)
	intent.action = 3
	view.now_ms = 23000
	view.facing = Vector3.RIGHT
	var sap: Dictionary = host.commit_status_utility(intent, 1, view, "sap", moves.move("sap"), profile)
	assert_true(sap.ok)
	assert_eq(sap.delta.wind, 28.0)
	assert_eq(EFFECTS.damage_taken_multiplier(host.utility_state(id), "foe-1", 23001), 1.1)
	assert_false(ENCOUNTER_HOST.presentation_snapshot(host.record(id)).has("utility_state"), "authority state never leaks into snapshot")
	var detached := host.utility_state(id)
	detached.statuses.clear()
	assert_eq(EFFECTS.damage_taken_multiplier(host.utility_state(id), "foe-1", 23001), 1.1)
	var lethal: Dictionary = host.stage_actor_vitals(id, 1, "owned-1", 3, 0, "actual-hit", "damage", 999.0, 10)
	assert_true(host.commit_actor_vitals(lethal).ok)
	baseline = host.record(id).duplicate(true)
	intent.action = 4
	view.now_ms = 34000
	assert_false(host.commit_status_utility(intent, 1, view, "hearten", moves.move("hearten"), profile).ok)
	assert_eq(host.record(id), baseline, "retained faint cannot cast using old healthy portable seed")
