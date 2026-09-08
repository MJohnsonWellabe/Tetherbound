extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/meadows_earned_warrens_segment.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")


func test_missing_live_context_cannot_claim_a_clear() -> void:
	var observed: Dictionary = await SEGMENT.new().run(null, null, null)
	assert_false(observed.passed)
	assert_false(observed.completed)
	assert_eq(observed.receipts, [])
	assert_true(not observed.failures.is_empty())


func test_current_band_trail_reaches_authored_quarry_before_undertrail() -> void:
	var terrain := SEGMENT._read(SEGMENT.TERRAIN)
	var road := SEGMENT.trail_points(terrain, "bands", "band2_stone_and_root")
	var undertrail := SEGMENT.trail_points(terrain, "loops", "warren_undertrail")
	var stops := SEGMENT.rootstone_stops(SEGMENT._read(SEGMENT.HARVEST))
	assert_eq(stops.size(), 7)
	assert_eq(stops[0].at, [394.0, 1797.0])
	assert_eq(stops[-1].at, [413.0, 1820.0], "include the current second quarry seam")
	assert_eq(road[0], Vector2(0, 1360), "continue from the physical bridge far bank")
	var quarry := SEGMENT.nearest_index(road, Vector2(400, 1800))
	var warrens := SEGMENT.nearest_index(road, undertrail[0])
	assert_eq(quarry, 4)
	assert_eq(warrens, 10)
	assert_eq(road[warrens], undertrail[0])
	assert_true(quarry < warrens)
	assert_eq(SEGMENT.nearest_index([], Vector2.ZERO), -1)
	assert_eq(SEGMENT.trail_points({}, "bands", "band2_stone_and_root"), [])
	assert_eq(SEGMENT.rootstone_stops({"nodes": [{"item": "stone", "amount": 5, "at": [0, 0]},
		{"order": 2, "item": "rootstone", "amount": 0, "at": [0, 0]}]}), [])
	var changed := {"nodes": [{"order": 30, "item": "rootstone", "amount": 2, "at": [5, 6]},
		{"order": 20, "item": "rootstone", "amount": 3, "at": [1, 2]}]}
	assert_eq(SEGMENT.rootstone_stops(changed)[0].at, [1, 2], "authored order, not copied coordinates or file order")


func test_guardian_route_uses_current_ungated_passages_and_refuses_a_closed_branch() -> void:
	var config := SEGMENT._read(SEGMENT.WARRENS)
	assert_eq(SEGMENT.passage_path(config, "mouth", "den"), ["mouth", "hall", "den"])
	assert_eq(SEGMENT.passage_path(config, "den", "mouth"), ["den", "hall", "mouth"])
	assert_eq(SEGMENT.passage_path(config, "mouth", "vault"), [], "the vault is physically gated until victory")
	assert_eq(SEGMENT.passage_path({}, "mouth", "den"), [])
	for edge: Dictionary in config.passages:
		if edge.to == "den":
			edge.gated = true
	assert_eq(SEGMENT.passage_path(config, "mouth", "den"), [], "never invent a shortcut through a closed connection")


func test_rotated_live_marker_approach_is_outside_and_never_projects_rooms_to_terrain() -> void:
	var entrance := Vector3(-355.5, 80, 2608.5)
	var mouth := entrance + Vector3(-8, 0, 8)
	var outside := SEGMENT.outside_approach(entrance, mouth, 8.0)
	assert_almost_eq(outside.distance_to(entrance), 8.0, 0.001)
	assert_true((outside - entrance).dot(mouth - entrance) < 0.0)
	assert_eq(outside.y, entrance.y)
	assert_true(outside.x > entrance.x and outside.z < entrance.z)
	assert_eq(SEGMENT.outside_approach(entrance, entrance, 8), Vector3.INF)
	assert_eq(SEGMENT.outside_approach(entrance, mouth, 0), Vector3.INF)
	var rotated := Basis(Vector3.UP, 1.1)
	assert_true(SEGMENT.outside_approach(rotated * entrance, rotated * mouth, 8).is_equal_approx(rotated * outside))
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_warrens_segment.gd")
	assert_true(source.contains('await _walk(_warrens.call("marker", chamber))'))
	assert_false(source.contains('_walk_ground(_warrens.call("marker"'))


func test_guardian_items_require_exact_configured_deltas_not_just_preowned_stock() -> void:
	var config := SEGMENT._read(SEGMENT.WARRENS)
	var reward: Dictionary = config.clear.reward
	var expected := SEGMENT.reward_items(reward)
	assert_eq(expected, {"coin": 90, "rootstone": 5, "orb_greater": 2, "revive": 1, "hide_vest": 1})
	var before := {"coin": 200, "rootstone": 10, "orb_greater": 2, "revive": 3, "hide_vest": 0}
	var after := before.duplicate()
	for id: String in expected:
		after[id] += expected[id]
	assert_true(SEGMENT.exact_item_reward(before, after, reward))
	assert_false(SEGMENT.exact_item_reward(before, before, reward), "a durable flag or existing stock is insufficient")
	for id: String in expected:
		var short := after.duplicate()
		short[id] -= 1
		assert_false(SEGMENT.exact_item_reward(before, short, reward), "missing configured item: " + id)
	var extra := after.duplicate()
	extra.rootstone += 5
	assert_false(SEGMENT.exact_item_reward(before, extra, reward), "a duplicate payout must fail")
	var incomplete := after.duplicate()
	incomplete.erase("revive")
	assert_false(SEGMENT.exact_item_reward(before, incomplete, reward))


func test_guardian_xp_tracks_instance_identity_survival_and_level_rollover() -> void:
	var cfg := PROGRESSION.config()
	var cost := PROGRESSION.xp_to_next(5, cfg)
	assert_eq(SEGMENT.total_xp(5, cost - 1, cfg) + 2, SEGMENT.total_xp(6, 1, cfg))
	var before := {11: 300, 12: 300, 13: 300, 14: 300, 15: 300}
	var after := before.duplicate()
	var award := PROGRESSION.xp_award_for(14, cfg)
	var share := PROGRESSION.party_share(award, cfg)
	# The repeated species/labels are intentionally irrelevant: identities 12,
	# 13 and 14 remain distinct, and fainted 13 receives neither XP payment.
	var survivors: Array[int] = [11, 12, 14, 15]
	for id: int in survivors:
		after[id] += 140 + (award if id == 14 else share)
	assert_true(SEGMENT.exact_xp_reward(before, after, 14, survivors, 14, 140, cfg))
	assert_false(SEGMENT.exact_xp_reward(before, after, 12, survivors, 14, 140, cfg), "wrong killing-hit pilot")
	assert_false(SEGMENT.exact_xp_reward(before, after, 13, survivors, 14, 140, cfg), "fainted cannot be the winning pilot")
	var too_much := after.duplicate()
	too_much[13] += 140
	assert_false(SEGMENT.exact_xp_reward(before, too_much, 14, survivors, 14, 140, cfg))
	var missing := after.duplicate()
	missing[12] -= 140
	assert_false(SEGMENT.exact_xp_reward(before, missing, 14, survivors, 14, 140, cfg))
	var substituted := after.duplicate()
	substituted[16] = substituted[12]
	substituted.erase(12)
	assert_false(SEGMENT.exact_xp_reward(before, substituted, 14, survivors, 14, 140, cfg))


func test_real_battle_deadline_and_same_five_are_strict() -> void:
	assert_eq(SEGMENT.BATTLE_FRAMES, 7200)
	assert_true(SEGMENT.within_battle_deadline(7199))
	assert_false(SEGMENT.within_battle_deadline(7200))
	assert_false(SEGMENT.within_battle_deadline(7202), "a press straddling the deadline cannot claim a late win")
	assert_false(SEGMENT.within_battle_deadline(-1))
	assert_true(SEGMENT.retained_five([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]))
	assert_false(SEGMENT.retained_five([1, 2, 3, 4, 5], [1, 2, 3, 4, 6]))
	assert_false(SEGMENT.retained_five([1, 2, 3, 4, 5], [2, 1, 3, 4, 5]))
	assert_false(SEGMENT.retained_five([1, 1, 3, 4, 5], [1, 1, 3, 4, 5]))
	assert_false(SEGMENT.retained_five([1, 2, 3, 4], [1, 2, 3, 4]))


func test_reachable_source_uses_input_and_observation_without_fixture_callbacks() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/meadows_earned_warrens_segment.gd")
	for forbidden: String in ["set_flag(", "inventory.add(", "party.add(", "set_level(",
		"take_damage(", "gain_xp(", "heal(", "revive(", "load_game(", "seed_save",
		"global_position =", "set_physics_process(", "set_process(", "rig.set(",
		"time_scale =", "fight_to_the_end(", 'call("grant_clear_reward"', 'call("craft"',
		'call("begin_encounter"', 'call("spawn_wild"', 'call("gather"']:
		assert_false(source.contains(forbidden), "earned Warrens may not use " + forbidden)
	assert_true(source.contains("await pilot._act(ally, foe)"))
	assert_true(source.contains('connect("entered", _on_entered)'))
	assert_true(source.contains('connect("hit_landed", _on_hit)'))
	assert_true(source.contains('_combat.call("enemy_body") == _guardian'))
