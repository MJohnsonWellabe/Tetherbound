extends "res://tests/test_case.gd"

## Shipped reward routing and personal staging, including the deferred first
## ceremony answer. These are transaction regressions, not earned-route proof.
const REWARDS := preload("res://scripts/net/encounter_rewards.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const BAGS := preload("res://scripts/world/death_satchel_rules.gd")
const BOSSES := {
	"warden_aldis": ["meadows", "meadows", "tidewake_portal_key"],
	"water_trainer_nerissa": ["water", "tidewake", "cloudreach_portal_key"],
	"captain_veyra_storm_anchor": ["cloudreach", "cloudreach", "stormwood_portal_key"],
	"captain_marrow_dynamo_core": ["stormwood", "stormwood", "fifth_portal_key"],
}

func _current(character: String = "character-a") -> Dictionary:
	return {"character_id": character, "inventory": [], "redesign_character": STATE.defaults("character")}

func _intent(boss: String) -> Dictionary:
	return {"trainer_id": boss, "biome": BOSSES[boss][1], "encounter_id": "earned-fight-1"}

func _context(boss: String, settled: bool = true) -> Dictionary:
	var row := REWARDS.chapter_hand_off(boss, BOSSES[boss][0])
	var flags: Array = row.get("delivery_requires_world_flags", []).duplicate() if settled else []
	if settled and boss == "captain_marrow_dynamo_core": flags.append("stormwood:legendary_resolution:refused:character-b")
	return {"source_key": "boss:" + boss, "realm": BOSSES[boss][0],
		"validated_host_outcome": "win", "encounter_id": "earned-fight-1",
		"participants": ["character-a", "character-b"],
		"boss_settlement_world_flags": flags}

func test_all_four_shipped_bosses_resolve_canonical_keys_and_personal_relics() -> void:
	for boss: String in BOSSES:
		var want: Array = BOSSES[boss]
		var row := REWARDS.chapter_hand_off(boss, want[0])
		assert_false(row.is_empty(), "production reader must find " + boss)
		assert_eq(row.get("relic_biome"), want[1])
		assert_eq(row.get("portal_key_item"), want[2])
		assert_eq(REWARDS.chapter_hand_off(boss, "wrong_realm"), {})
		for character: String in ["character-a", "character-b"]:
			var current := _current(character)
			var result := ACTIONS._relic(current, "boss_relic", _intent(boss), _context(boss))
			assert_true(result.get("ok", false), boss + ":" + character)
			if not result.get("ok", false): continue
			assert_eq(current.redesign_character.relics_held, [], "staging never mutates the baseline")
			assert_eq(result.state.redesign_character.relics_held, [want[1]])
			assert_eq(BAGS.inventory_from(result.state.inventory).count(want[2]), 1)
			assert_eq(ACTIONS._relic(result.state, "boss_relic", _intent(boss), _context(boss)).get("code"), "reconcile_original_decision")
		assert_eq(ACTIONS._relic(_current("spectator"), "boss_relic", _intent(boss), _context(boss)).get("code"), "actual_boss_participant_required")
	assert_eq(REWARDS.chapter_hand_off("ordinary_trainer", "meadows"), {})

func test_ceremony_rewards_wait_for_first_settlement_and_never_for_every_participant() -> void:
	for boss: String in BOSSES:
		var row := REWARDS.chapter_hand_off(boss, BOSSES[boss][0])
		var immediate := boss in ["warden_aldis", "captain_veyra_storm_anchor"]
		assert_eq(REWARDS.chapter_delivery_ready(row, []), immediate)
		var pending := ACTIONS._relic(_current(), "boss_relic", _intent(boss), _context(boss, false))
		assert_eq(pending.get("ok", false), immediate)
		if not immediate:
			assert_eq(pending.get("code"), "boss_ceremony_pending")
			assert_false(REWARDS.chapter_delivery_ready(row, ["legendary_offer_displayed"]))
		assert_true(REWARDS.chapter_delivery_ready(row, _context(boss).boss_settlement_world_flags))
		# The second character can resolve the same owed reward with only the
		# shared first-answer marker, after disconnect/rejoin or host restart.
		assert_true(ACTIONS._relic(_current("character-b"), "boss_relic", _intent(boss), _context(boss)).get("ok", false))

func test_full_inventory_retains_the_entire_reward_until_room_exists() -> void:
	var current := _current()
	var bag := BAGS.inventory_from([])
	for index: int in bag.slot_count():
		bag.set_slot(index, {"id": "wood", "n": 99})
	current.inventory = BAGS.slots(bag)
	var before := current.duplicate(true)
	assert_eq(ACTIONS._relic(current, "boss_relic", _intent("warden_aldis"), _context("warden_aldis")).get("code"), "boss_handoff_make_satchel_room")
	assert_eq(current, before, "no key, relic or receipt is lost on capacity refusal")
	current.inventory[0] = null
	assert_true(ACTIONS._relic(current, "boss_relic", _intent("warden_aldis"), _context("warden_aldis")).get("ok", false))

func test_boss_obligation_preserves_both_stable_characters_across_world_reload() -> void:
	var world := WORLD.new()
	world.world_id = "world-a"
	world.reward_delivery_namespace = "namespace-a"
	for boss: String in BOSSES:
		var duties: Array = []
		for character: String in ["character-a", "character-b"]:
			duties.append({"character_id": character, "action": "boss_relic", "intent": _intent(boss), "context": _context(boss, false)})
		var row := EVENT.make(world, "session-a", "boss:" + boss + ":earned-fight-1", duties)
		assert_false(row.is_empty(), "shipping handoff must pass retained-event validation")
		if row.is_empty(): continue
		world.reward_deliveries[row.delivery_id] = row
	var restored := WORLD.new()
	restored.load_data(world.save_data())
	assert_eq(restored.reward_deliveries, world.reward_deliveries)
	assert_eq(restored.reward_deliveries.size(), 4)
	for row: Dictionary in restored.reward_deliveries.values():
		assert_true(EVENT.valid(row, restored.reward_delivery_namespace, restored.world_id))
		assert_eq(row.duties.map(func(duty: Dictionary) -> String: return duty.character_id), ["character-a", "character-b"])

func test_malformed_or_drifting_authored_handoff_fails_closed() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REWARDS.CHAPTER_REWARDS_PATH))
	for edit: Dictionary in [{"next_biome": "stormwood"}, {"key_item": "stormwood_portal_key"},
		{"relic_biome": "cloudreach"}, {"delivery_phase": "unvalidated_client_offer"},
		{"delivery_requires_world_flags": ["fake", "fake"]}]:
		var malformed := config.duplicate(true)
		malformed.boss_handoffs.warden_aldis.merge(edit, true)
		assert_eq(REWARDS.chapter_hand_off("warden_aldis", "meadows", malformed), {})

func test_guest_generic_flag_rpc_cannot_release_or_clear_boss_settlement() -> void:
	var world := WORLD.new()
	var ledger := LEDGER.new(world)
	for boss: String in ["water_trainer_nerissa", "captain_marrow_dynamo_core"]:
		var row := REWARDS.chapter_hand_off(boss, BOSSES[boss][0])
		for flag: String in row.delivery_requires_world_flags:
			assert_true(REWARDS.is_chapter_settlement_flag(flag))
			for value: bool in [true, false]:
				var before := world.save_data()
				var result := ledger.commit({"kind": "set_world_flag", "realm": row.runtime_realm, "id": flag, "value": value}, 2)
				assert_eq(result.get("code"), "host_boss_settlement_required")
				assert_eq(world.save_data(), before)
			assert_true(ledger.commit({"kind": "set_world_flag", "realm": row.runtime_realm, "id": flag}, 1).get("ok", false))
			assert_true(world.flags.has(flag))
	assert_false(REWARDS.is_chapter_settlement_flag("ordinary_story_flag"))
	for flag: String in ["stormwood:legendary_resolution:accepted:character-a", "stormwood:legendary_resolution:refused:character-b"]:
		assert_true(REWARDS.is_chapter_settlement_flag(flag))
		assert_eq(ledger.commit({"kind": "set_world_flag", "realm": "stormwood", "id": flag}, 2).get("code"), "host_boss_settlement_required")

func test_stormwood_display_and_non_owed_visit_do_not_release_a_boss_drop() -> void:
	var row := REWARDS.chapter_hand_off("captain_marrow_dynamo_core", "stormwood")
	var shown := ["stormwood:legendary_offer_made"]
	assert_false(REWARDS.chapter_delivery_ready(row, shown))
	for invalid: String in ["stormwood:legendary_resolution:accepted:", "stormwood:legendary_resolution:refused:", "stormwood:legendary_resolution:shown:character-a"]:
		assert_false(REWARDS.chapter_delivery_ready(row, shown + [invalid]))
	for answer: String in ["accepted", "refused"]:
		assert_true(REWARDS.chapter_delivery_ready(row, shown + ["stormwood:legendary_resolution:" + answer + ":character-b"]))
