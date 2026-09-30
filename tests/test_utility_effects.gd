extends "res://tests/test_case.gd"

const EFFECTS := preload("res://scripts/combat/utility_effects.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")

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
	var after := second.state.duplicate(true)
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
