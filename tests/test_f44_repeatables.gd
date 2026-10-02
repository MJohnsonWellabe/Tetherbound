extends "res://tests/test_case.gd"

## Focused F44 logic batch. Run only through ROOT's engine queue. These are
## detached plans, not earned encounters, save/ACK or per-biome witnesses.
const REMATCH := preload("res://scripts/repeatables/rematch_rules.gd")
const ALPHA := preload("res://scripts/repeatables/alpha_respawns.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const BAG := preload("res://scripts/world/death_satchel_rules.gd")
const TRAITS := preload("res://scripts/creatures/traits.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const ALPHA_PRODUCER := preload("res://scripts/net/foundation_alphas.gd")

func _current(character: String = "character_a") -> Dictionary:
	return {"character_id": character, "inventory": BAG.slots(BAG.inventory_from([])),
		"redesign_character": STATE.defaults("character")}

func _intent(id: String = "relay_captain", tier: String = "r1", encounter: String = "encounter_1") -> Dictionary:
	return {"trainer_id": id, "tier": tier, "encounter_id": encounter}

func _context(character: String = "character_a", seconds: int = 100,
		id: String = "relay_captain", tier: String = "r1", encounter: String = "encounter_1") -> Dictionary:
	return {"character_id": character, "expected_revision": 0, "source_key": "rematch:" + id,
		"in_range": true, "validated_host_outcome": "win", "encounter_id": encounter,
		"trainer_id": id, "tier": tier, "participants": [character],
		"world_flags": ["defeated_warden", "water_captain_nerissa_defeated", "captain_veyra_defeated"],
		"personal_flags": ["regional_credits_seen"], "world_namespace": "world_a", "session_id": "session_a", "world_seconds": seconds}

func test_tiers_do_not_open_from_another_characters_credits() -> void:
	assert_false(REMATCH.available("relay_captain", "r1", [], []))
	assert_true(REMATCH.available("relay_captain", "r1", ["defeated_warden"], []))
	assert_true(REMATCH.available("relay_captain", "r1", [], ["defeated_warden"]))
	assert_false(REMATCH.available("officer_maren_verge_rod", "r1", ["stormwood:marrow_defeated"], []))
	assert_false(REMATCH.available("warden_aldis", "endgame", ["regional_credits_seen"], []))
	assert_true(REMATCH.available("warden_aldis", "endgame", [], ["regional_credits_seen"]))

func test_roster_identity_order_pattern_and_first_rewards_are_preserved_at_source() -> void:
	var original := {"id": "relay_captain", "defeat_flag": "defeated_relay_captain",
		"team": [{"species": "bramblebun", "level": 18, "combat": {"pattern_id": "paired_charge"}},
			{"species": "burrowback", "level": 18}], "reward": {"items": [{"id": "tidewake_portal_key", "count": 1}]},
		"victory_conversation": "story_only"}
	var spec := REMATCH.encounter_spec(original, "r1")
	assert_false(spec.is_empty())
	if spec.is_empty(): return
	assert_eq(spec.id, original.id)
	assert_eq(spec.team[0].species, original.team[0].species)
	assert_eq(spec.team[1].species, original.team[1].species)
	assert_eq(spec.team[0].combat, original.team[0].combat)
	assert_eq(spec.team[0].level, 33)
	assert_true(spec.reward.items.is_empty())
	assert_eq(spec.defeat_flag, "")
	assert_false(spec.has("victory_conversation"))
	assert_eq(original.team[0].level, 18)
	assert_eq(original.reward.items[0].id, "tidewake_portal_key")
	var creature := TRAINERS.creature_for(spec.team[0])
	assert_true(creature != null)
	if creature != null:
		assert_false(creature.move_utility.is_empty())
		assert_false(creature.move_ultimate.is_empty())
		assert_eq(creature.level, 33)

func test_unique_repeat_and_cooldown_win_are_atomic_and_replay_safe() -> void:
	var before := _current()
	var first := REMATCH.stage(before, 0, _intent(), _context())
	assert_true(first.get("ok", false))
	if first.get("ok") != true: return
	assert_true(first.unique_reward)
	assert_true(before.redesign_character.transaction_receipts.is_empty())
	assert_false(REMATCH.stage(first.state, 0, _intent(), _context()).ok)
	var early := REMATCH.stage(first.state, 0, _intent("relay_captain", "r1", "encounter_2"),
		_context("character_a", 1299, "relay_captain", "r1", "encounter_2"))
	assert_true(early.get("ok", false))
	if early.get("ok") != true: return
	assert_false(early.reward_paid)
	assert_eq(early.state.inventory, first.state.inventory)
	assert_eq(early.state.redesign_character.rematch_cooldowns, first.state.redesign_character.rematch_cooldowns)
	var due := REMATCH.stage(early.state, 0, _intent("relay_captain", "r1", "encounter_3"),
		_context("character_a", 1300, "relay_captain", "r1", "encounter_3"))
	assert_true(due.get("ok", false))
	if due.get("ok") != true: return
	assert_true(due.reward_paid)
	assert_false(due.unique_reward)
	assert_eq(due.state.redesign_character.rematch_cooldowns["world_a:relay_captain:r1"].next_eligible_seconds, 2500)
	var reloaded: Dictionary = JSON.parse_string(JSON.stringify(due.state))
	var state_errors := STATE.validate("character", reloaded.redesign_character)
	assert_true(state_errors.is_empty(), str(state_errors))
	assert_false(REMATCH.stage(reloaded, 0, _intent("relay_captain", "r1", "encounter_3"),
		_context("character_a", 1300, "relay_captain", "r1", "encounter_3")).ok)

func test_nonparticipant_loss_wrong_source_and_full_satchel_never_spend_win() -> void:
	var current := _current()
	for field: String in ["participants", "validated_host_outcome", "source_key", "world_seconds"]:
		var context := _context()
		context[field] = {"participants": ["character_b"], "validated_host_outcome": "loss", "source_key": "unregistered", "world_seconds": -1}[field]
		assert_false(REMATCH.stage(current, 0, _intent(), context).ok)
	var inventory := BAG.inventory_from([])
	for index: int in inventory.slot_count(): inventory.set_slot(index, {"id": "stone", "n": BAG.db().stack_size("stone")})
	current.inventory = BAG.slots(inventory)
	var full := REMATCH.stage(current, 0, _intent(), _context())
	assert_false(full.ok)
	assert_eq(full.code, "rematch_reward_pending_make_satchel_room")
	assert_true(current.redesign_character.transaction_receipts.is_empty())
	assert_false(current.redesign_character.has("rematch_cooldowns"))

func test_each_participant_has_own_receipt_and_master_remains_one_on_one() -> void:
	for character: String in ["character_a", "character_b"]:
		var context := _context(character)
		context.participants = ["character_a", "character_b"]
		var plan := REMATCH.stage(_current(character), 0, _intent(), context)
		assert_true(plan.get("ok", false))
		if plan.get("ok") == true: assert_true(plan.receipt.contains(character))
	var context := _context("character_a", 100, "master_t1")
	context.participants = ["character_a", "character_b"]
	assert_false(REMATCH.stage(_current(), 0, _intent("master_t1"), context).ok)

func test_real_encounter_ids_can_repeat_after_restart_without_resetting_cooldown() -> void:
	var first := REMATCH.stage(_current(), 0, _intent("relay_captain", "r1", "1:1"),
		_context("character_a", 100, "relay_captain", "r1", "1:1"))
	assert_true(first.get("ok", false))
	if first.get("ok") != true: return
	var context := _context("character_a", 200, "relay_captain", "r1", "1:1")
	context.session_id = "session_b"
	var restarted := REMATCH.stage(first.state, 0, _intent("relay_captain", "r1", "1:1"), context)
	assert_true(restarted.get("ok", false))
	if restarted.get("ok") == true:
		assert_false(restarted.reward_paid)
		assert_true(restarted.receipt != first.receipt)
		assert_eq(restarted.state.redesign_character.rematch_cooldowns, first.state.redesign_character.rematch_cooldowns)

func test_alpha_timer_waits_for_all_departures_and_retains_fresh_generation_on_reload() -> void:
	var before := STATE.defaults("world")
	var id := "hollows_alpha"
	assert_true(ALPHA.resolve(before, id, 1, 100, ["character_a"], "loss").is_empty())
	var resolved := ALPHA.resolve(before, id, 1, 100, ["character_a", "character_b"], "catch")
	assert_true(resolved.get("ok", false))
	if resolved.get("ok") != true: return
	assert_true(before.alpha_cycles.is_empty())
	assert_true(ALPHA.spawn(resolved.state, id, "world_a", 2000, false, false).is_empty())
	assert_true(ALPHA.depart(resolved.state, id, 1, "character_a", "glowmoss_hollows").is_empty())
	assert_true(ALPHA.depart(resolved.state, id, 2, "character_a", "meadows").is_empty())
	var left_a := ALPHA.depart(resolved.state, id, 1, "character_a", "meadows")
	assert_true(left_a.get("ok", false))
	if left_a.get("ok") != true: return
	assert_true(ALPHA.spawn(left_a.state, id, "world_a", 2000, false, false).is_empty())
	var left_b := ALPHA.depart(left_a.state, id, 1, "character_b", "meadows")
	assert_true(left_b.get("ok", false))
	if left_b.get("ok") != true: return
	assert_true(ALPHA.spawn(left_b.state, id, "world_a", 1899, false, false).is_empty())
	var born := ALPHA.spawn(left_b.state, id, "world_a", 1900, false, false)
	assert_true(born.get("ok", false))
	if born.get("ok") != true: return
	assert_eq(born.record.generation, 2)
	assert_true(STATE.validate("world", born.state).is_empty())
	var reload: Dictionary = JSON.parse_string(JSON.stringify(born.state))
	assert_eq(ALPHA.retained_spawn(reload, id), born.record.spawn_traits)
	assert_true(ALPHA.spawn(reload, id, "world_a", 5000, false, false).is_empty())
	assert_true(TRAITS.trait_state_errors(born.record.spawn_traits).is_empty())
	assert_eq(born.record.spawn_traits.captured_from.spawn_generation, 2)
	assert_true(ALPHA.resolve(reload, id, 1, 2000, ["character_a"], "defeat").is_empty())
	assert_true(ALPHA.resolve(reload, id, 2, 1800, ["character_a"], "defeat").is_empty())

func test_first_alpha_roll_is_durable_without_invented_resolution_and_rejects_foreign_world() -> void:
	var before := STATE.defaults("world")
	assert_true(before.alpha_cycles.is_empty(), "first population starts from the actual empty admitted carrier")
	var id := "hollows_alpha"
	var born := ALPHA.first_spawn(before, id, "world_a", true, true)
	assert_false(born.is_empty())
	if born.is_empty(): return
	assert_true(ALPHA.valid_plan(born, before, "world_a"))
	assert_false(ALPHA.valid_plan(born, before, "world_b"))
	assert_false(born.record.has("resolved_at_seconds"))
	assert_false(born.record.has("required_departures"))
	assert_true(STATE.validate("world", born.state, [], "world_a").is_empty())
	assert_false(STATE.validate("world", born.state, [], "world_b").is_empty())
	assert_false(STATE.validate("world", born.state, [], "").is_empty())
	assert_true(STATE.validate("world", before, [], "").is_empty())
	var reload: Dictionary = JSON.parse_string(JSON.stringify(born.state))
	assert_true(STATE.validate("world", reload, [], "world_a").is_empty())
	assert_eq(ALPHA.retained_spawn(reload, id), born.record.spawn_traits)
	assert_true(ALPHA.first_spawn(reload, id, "world_a", false, false).is_empty())
	var resolved := ALPHA.resolve(reload, id, 1, 100, ["character_a"], "catch")
	assert_false(resolved.is_empty())
	if not resolved.is_empty(): assert_true(STATE.validate("world", resolved.state, [], "world_a").is_empty())

func test_actual_clear_weather_metadata_does_not_choose_unusual_alpha_odds() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/weather.json"))
	assert_false(ALPHA_PRODUCER.unusual_weather({}))
	assert_false(ALPHA_PRODUCER.unusual_weather(config.presets.clear))
	assert_true(ALPHA_PRODUCER.unusual_weather(config.presets.rain))
	assert_true(ALPHA_PRODUCER.unusual_weather(config.presets.fog))

func test_alpha_cooldown_uses_three_saved_day_transitions() -> void:
	assert_eq(ALPHA_PRODUCER.day_seconds(0), -1)
	var resolved := ALPHA.resolve(STATE.defaults("world"), "hollows_alpha", 1,
		ALPHA_PRODUCER.day_seconds(4), ["character_a"], "defeat")
	assert_false(resolved.is_empty())
	if resolved.is_empty(): return
	var departed := ALPHA.depart(resolved.state, "hollows_alpha", 1, "character_a", "meadows")
	assert_false(departed.is_empty())
	if departed.is_empty(): return
	var reload: Dictionary = JSON.parse_string(JSON.stringify(departed.state))
	assert_true(ALPHA.spawn(reload, "hollows_alpha", "world_a", ALPHA_PRODUCER.day_seconds(6), false, false).is_empty())
	assert_false(ALPHA.spawn(reload, "hollows_alpha", "world_a", ALPHA_PRODUCER.day_seconds(7), false, false).is_empty())

func test_retained_alpha_normalizes_only_valid_integral_provenance_without_rewriting_world() -> void:
	var born := ALPHA.first_spawn(STATE.defaults("world"), "hollows_alpha", "world_a", false, false)
	assert_false(born.is_empty())
	if born.is_empty(): return
	var reload: Dictionary = JSON.parse_string(JSON.stringify(born.state))
	var before := reload.duplicate(true)
	assert_eq(ALPHA.retained_spawn(reload, "hollows_alpha"), born.record.spawn_traits)
	assert_eq(reload, before)
	reload.alpha_cycles.sites.hollows_alpha.spawn_traits.captured_from.spawn_generation = 1.5
	assert_true(ALPHA.retained_spawn(reload, "hollows_alpha").is_empty())
	reload.alpha_cycles.sites.hollows_alpha.spawn_traits.captured_from.spawn_generation = 2
	assert_true(ALPHA.retained_spawn(reload, "hollows_alpha").is_empty())
	reload.alpha_cycles.sites.hollows_alpha.spawn_traits.captured_from.spawn_generation = "1"
	assert_true(ALPHA.retained_spawn(reload, "hollows_alpha").is_empty())
