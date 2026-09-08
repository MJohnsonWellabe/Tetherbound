extends "res://tests/test_case.gd"

const BRIDGE := preload("res://tests/helpers/meadows_earned_bridge_segment.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


class Admission extends Node:
	var active := false
	var id := ""
	func trainer_battle_active() -> bool:
		return active
	func trainer_battle_id() -> String:
		return id


func test_bridge_refuses_missing_live_context_and_cannot_claim_a_crossing() -> void:
	var observed: Dictionary = await BRIDGE.new().run(null, null, null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_true(not observed.failures.is_empty())


func test_authored_approach_stops_before_closed_gate_and_follows_updated_road() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BRIDGE.TERRAIN))
	var route := BRIDGE.approach_route(config)
	assert_true(route.size() > 10)
	assert_eq(route[0], Vector2(14, 20), "the live TrailGate road leaves the village")
	assert_true(route.has(Vector2(-430, 510)), "retain the authored pond bend")
	assert_eq(route[-1], Vector2(9, 1300), "the real gate approach replaces the old lateral spine bend")
	assert_false(route.has(Vector2(-40, 1310)))
	assert_false(route.has(Vector2(8, 1330)), "never navigate across the still-closed gate")
	var crossing := BRIDGE.crossing_config(config)
	crossing["road"][1] = [10.5, 1272.0]
	assert_true(BRIDGE.approach_route(config).has(Vector2(10.5, 1272.0)),
		"the helper must read the road rather than retain copied scenario coordinates")
	assert_eq(BRIDGE.approach_route({}), [])
	assert_eq(BRIDGE.crossing_config({}), {})


func test_guardian_admission_rejects_another_trainer_and_inactive_stale_id() -> void:
	var director := Admission.new()
	director.id = BRIDGE.GUARDIAN
	assert_false(BRIDGE.admitted_guardian(director))
	director.active = true
	assert_true(BRIDGE.admitted_guardian(director))
	director.id = "tournament_final_oskar"
	assert_false(BRIDGE.admitted_guardian(director))
	assert_false(BRIDGE.admitted_guardian(null))
	director.free()


func test_guardian_receipt_requires_exact_round_wins_real_hits_and_defeat() -> void:
	var team := TRAINERS.team_of(TRAINERS.trainer(BRIDGE.GUARDIAN)).size()
	assert_eq(team, 2)
	assert_true(BRIDGE.battle_receipt(team, 8, team, true))
	assert_false(BRIDGE.battle_receipt(team - 1, 8, team, true))
	assert_false(BRIDGE.battle_receipt(team + 1, 8, team, true))
	assert_false(BRIDGE.battle_receipt(team, 0, team, true))
	assert_false(BRIDGE.battle_receipt(team, 8, team, false))
	assert_false(BRIDGE.battle_receipt(0, 8, 0, true))


func test_guardian_deadline_rejects_victory_at_or_after_unchanged_physics_budget() -> void:
	assert_eq(BRIDGE.BATTLE_FRAMES, 9000)
	assert_true(BRIDGE.within_guardian_deadline(8999))
	assert_false(BRIDGE.within_guardian_deadline(9000))
	assert_false(BRIDGE.within_guardian_deadline(9002),
		"a final input that straddles the deadline cannot claim a late victory")
	assert_false(BRIDGE.within_guardian_deadline(-1))
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_bridge_segment.gd")
	var guardian_loop := source.get_slice("var start := Engine.get_physics_frames()", 1).get_slice("_guardian_active = false", 0)
	assert_true(guardian_loop.contains("await pilot._act(ally, foe)"))
	assert_false(guardian_loop.contains("await _win_fight()"),
		"the guardian deadline must be checked between decisions, not after an entire base-pilot fight")


func test_key_receipt_requires_new_reward_exact_spend_and_both_unlock_states() -> void:
	assert_eq(BRIDGE.reward_key_count(TRAINERS.trainer(BRIDGE.GUARDIAN)), 1)
	assert_true(BRIDGE.unlock_receipt(true, true, 0, 1, 0))
	assert_false(BRIDGE.unlock_receipt(false, true, 0, 1, 0))
	assert_false(BRIDGE.unlock_receipt(true, false, 0, 1, 0))
	assert_false(BRIDGE.unlock_receipt(true, true, 1, 1, 1), "a pre-existing key is not earned here")
	assert_false(BRIDGE.unlock_receipt(true, true, 0, 1, 1), "an unspent key is not a paid opening")
	assert_false(BRIDGE.unlock_receipt(true, true, 0, 0, 0), "no reward cannot prove a spend")


func test_crossing_receipt_requires_far_bank_and_same_five_unique_members() -> void:
	var ids: Array[int] = [1, 2, 3, 4, 5]
	assert_true(BRIDGE.physical_receipt(-11, 10, 9.4, ids, ids))
	assert_false(BRIDGE.physical_receipt(1, 10, 9.4, ids, ids))
	assert_false(BRIDGE.physical_receipt(-11, 2, 9.4, ids, ids), "centreline is not the far bank")
	assert_false(BRIDGE.physical_receipt(-11, 10, 9.4, ids, [1, 2, 3, 4, 6]))
	assert_false(BRIDGE.physical_receipt(-11, 10, 9.4, ids, [2, 1, 3, 4, 5]))
	assert_false(BRIDGE.physical_receipt(-11, 10, 9.4, [1, 2, 3, 4], [1, 2, 3, 4]))
	assert_false(BRIDGE.physical_receipt(-11, 10, 9.4, [1, 1, 1, 1, 1], [1, 1, 1, 1, 1]))


func test_source_contains_no_fixture_or_gameplay_callback_shortcuts() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_bridge_segment.gd")
	for forbidden: String in ["set_flag(", "inventory.add(", "party.add(", "set_level(",
		"take_damage(", "gain_xp(", "heal(", "revive(", "load_game(", "seed_save",
		"global_position =", "set_physics_process(", "set_process(", "rig.set(",
		"time_scale =", "_on_challenged\"", "begin_trainer_battle\"", "try_open\"",
		"_on_tried\"", "_try_auto_open\"", "_unlock\"", "_panel.call(\"start\""]:
		assert_false(source.contains(forbidden), "bridge must earn state through input: " + forbidden)
