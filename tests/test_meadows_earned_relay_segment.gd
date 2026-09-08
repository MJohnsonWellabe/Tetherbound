extends "res://tests/test_case.gd"
const SEGMENT := preload("res://tests/helpers/meadows_earned_relay_segment.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

func test_missing_context_fails_without_receipts() -> void:
	var out: Dictionary = await SEGMENT.new().run(null, null, null)
	assert_false(out.passed)
	assert_false(out.completed)
	assert_eq(out.receipts, [])
	assert_false(out.failures.is_empty())

func test_current_route_follows_undertrail_arch_and_actual_mill_near_bank() -> void:
	var cfg := SEGMENT._read(SEGMENT.RELAY_CONFIG)
	var gate := SEGMENT.gate_path(cfg)
	assert_eq(gate.size(), 3)
	assert_almost_eq(gate[0].x, -23.4)
	assert_eq(gate[1], Vector2(-14, 0))
	assert_eq(gate[2], Vector2(-10.4, 0))
	assert_eq(SEGMENT.gate_path({}), [])
	var terrain := SEGMENT._read(SEGMENT.TERRAIN)
	var u := Vector2(0.565, -0.826).normalized()
	var p := Vector2(-u.y, u.x)
	var outside := Vector2(350, 3760) + u * gate[0].x + p * gate[0].y
	var approach := SEGMENT.approach_path(terrain, Vector2(-350, 2603), outside)
	assert_eq(approach[0], Vector2(-320, 2610))
	assert_true(approach.has(Vector2(-180, 2730)))
	assert_true(approach.has(Vector2(0, 3180)))
	assert_true(approach.has(Vector2(230, 3670)))
	assert_eq(approach[-1], Vector2(340, 3810))
	assert_false(approach.has(Vector2(350, 3760)), "do not cut through the compound front wall to the road centre")
	var onward := SEGMENT.mill_path(terrain, outside)
	assert_eq(onward[0], approach[-1])
	assert_true(onward.has(Vector2(130, 3980)))
	assert_eq(onward[-1], Vector2(-152, 4170), "stop on the near side before the closed crossing")
	assert_false(onward.has(Vector2(-152, 4235)))
	assert_eq(SEGMENT.approach_path({}, Vector2.ZERO, Vector2.ZERO), [])
	assert_eq(SEGMENT.mill_path({}, Vector2.ZERO), [])
	assert_true(SEGMENT.mill_config(terrain).has("channel"))

func test_deck_route_hands_off_inside_the_authored_gantry_pad_overlap() -> void:
	var cfg := SEGMENT._read(SEGMENT.RELAY_CONFIG)
	var route := SEGMENT.deck_path(cfg)
	assert_eq(route.size(), 5)
	assert_true(is_nan(route[0].y), "only the ramp foot uses live ground height")
	assert_eq(route[1], Vector3(-5.5, 10, -11.5))
	assert_eq(route[2], Vector3(-2, 10, -11))
	assert_eq(route[3], Vector3(2, 10, -11))
	assert_eq(route[4], Vector3(3, 10, -11))
	var disconnected := cfg.duplicate(true)
	disconnected.decks[1].at[0] += 1.0
	assert_eq(SEGMENT.deck_path(disconnected), [], "a gap must not become an invented crossing")
	var wrong_height := cfg.duplicate(true)
	wrong_height.decks[1].deck_y += 1.0
	assert_eq(SEGMENT.deck_path(wrong_height), [])
	var misses_ramp := cfg.duplicate(true)
	misses_ramp.ramps[0].to[0] = -8.0
	assert_eq(SEGMENT.deck_path(misses_ramp), [])
	assert_eq(SEGMENT.deck_path({}), [])

func test_captain_has_exact_current_team_and_no_captive_gear_reward() -> void:
	var spec: Dictionary = SEGMENT.TRAINERS.trainer(SEGMENT.CAPTAIN)
	var team: Array = SEGMENT.TRAINERS.team_of(spec)
	assert_eq(team.size(), 3)
	assert_eq([team[0].species, team[1].species, team[2].species], ["galecrest", "duskhush", "tuskroot"])
	assert_eq([team[0].level, team[1].level, team[2].level], [11.0, 11.0, 12.0])
	var items := SEGMENT.reward_items(spec.reward)
	assert_eq(items, {"coin": 60, "orb_greater": 3, "revive": 1})
	assert_false(items.has(SEGMENT.GEAR))
	var creature := CREATURE.new()
	creature.species_id = "galecrest"
	creature.level = 11
	assert_true(SEGMENT.opponent_matches(creature, team[0]))
	assert_false(SEGMENT.opponent_matches(creature, team[1]))
	creature.level = 10
	assert_false(SEGMENT.opponent_matches(creature, team[0]))
	assert_false(SEGMENT.opponent_matches(null, team[0]))
	assert_true(SEGMENT.captain_within_deadline(8999))
	assert_false(SEGMENT.captain_within_deadline(9000))
	assert_false(SEGMENT.captain_within_deadline(-1))

func test_rescue_and_mill_receipts_refuse_preowned_duplicate_or_unspent_gear() -> void:
	assert_true(SEGMENT.rescue_receipt(true, true, 1))
	assert_false(SEGMENT.rescue_receipt(false, true, 1))
	assert_false(SEGMENT.rescue_receipt(true, false, 1))
	assert_false(SEGMENT.rescue_receipt(true, true, 0))
	assert_false(SEGMENT.rescue_receipt(true, true, 2))
	assert_true(SEGMENT.mill_paid_receipt(0, true, true))
	assert_false(SEGMENT.mill_paid_receipt(1, true, true))
	assert_false(SEGMENT.mill_paid_receipt(0, false, true))
	assert_false(SEGMENT.mill_paid_receipt(0, true, false))
	var dialogue := SEGMENT._read("res://data/dialogue/relay.json")
	var effects: Array = []
	for line: Variant in dialogue.conversations.relay_captive_freed.lines:
		if line is Dictionary:
			effects.append_array(line.get("effects", []))
	assert_true(effects.has("give:mill_bridge_gear:1"))
	assert_true(effects.has("flag:captive_rescued"))

func test_xp_receipt_accumulates_per_kill_survivors_then_final_bonus_by_identity() -> void:
	var before := {11: 300, 12: 300, 13: 300, 14: 300, 15: 300}
	var expected := {11: 0, 12: 0, 13: 0, 14: 0, 15: 0}
	var cfg := SEGMENT.PROGRESSION.config()
	SEGMENT.accumulate_xp(expected, 11, [11, 12, 13, 14, 15], 11, 0, cfg)
	SEGMENT.accumulate_xp(expected, 12, [12, 13, 14, 15], 11, 0, cfg)
	SEGMENT.accumulate_xp(expected, 12, [12, 13, 14, 15], 12, 120, cfg)
	var award := SEGMENT.PROGRESSION.xp_award_for(11, cfg)
	assert_eq(expected[11], award, "fainted former active gets no later share or flat bonus")
	assert_eq(expected[12], SEGMENT.PROGRESSION.party_share(award, cfg) + award + SEGMENT.PROGRESSION.xp_award_for(12, cfg) + 120)
	var after := before.duplicate()
	for id: int in after:
		after[id] += expected[id]
	assert_true(SEGMENT.exact_captain_xp(before, after, expected))
	assert_false(SEGMENT.exact_captain_xp(before, before, expected))
	after[11] += 120
	assert_false(SEGMENT.exact_captain_xp(before, after, expected), "no bonus to a fainted member")
	after.erase(15)
	assert_false(SEGMENT.exact_captain_xp(before, after, expected))
