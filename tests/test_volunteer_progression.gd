extends "res://tests/test_case.gd"

const RULES := preload("res://scripts/creatures/breakthrough.gd")
const STATE := preload("res://scripts/data/redesign_state.gd")
const TRAINER := preload("res://scripts/world/trainer_npc.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const AUTHORITY := preload("res://scripts/net/character_authority.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")

class OwnerGame extends RefCounted:
	var local: RefCounted

func _card(species: String, level: int) -> Dictionary:
	return CODEC.encode_record_card(TRAINER.creature_for({"species": species, "level": level}))

func _claim(before: Dictionary, card: Dictionary, kept := true) -> Dictionary:
	var uids: Array = []
	for member: Dictionary in before.party: uids.append(member.uid)
	return {"creature": card, "kept": kept, "party_uids": uids}

func test_new_volunteers_keep_their_level_and_receive_only_the_lower_tier_prefix() -> void:
	for species: String in ["veridian", "water_abyssal_guardian", "solmane", "fulgocobra"]:
		for level: int in [10, 11, 20, 33, 44, 55, 60]:
			var card := _card(species, level)
			assert_false(card.is_empty())
			var original := card.duplicate(true)
			var personal := STATE.defaults("character")
			var initialized := RULES.initialize_volunteer(personal, card)
			assert_false(initialized.is_empty())
			if initialized.is_empty(): continue
			var row: Dictionary = initialized.creatures[card.uid]
			assert_eq(row.breakthroughs, RULES.caught_tiers(level))
			assert_true(int(row.cap_level) >= level)
			assert_eq(row.evolution_choices, {}, "no retroactive evolution choice")
			assert_eq(card, original, "authored identity, level, XP and moves unchanged")
			assert_false(personal.creatures.has(card.uid), "detached initialization")

func test_initializer_refuses_existing_history_and_non_volunteers() -> void:
	var card := _card("fulgocobra", 55)
	var personal := RULES.initialize_volunteer(STATE.defaults("character"), card)
	var original := personal.duplicate(true)
	assert_eq(RULES.initialize_volunteer(personal, card), {}, "existing history is not inferred again")
	assert_eq(personal, original)
	assert_eq(RULES.initialize_volunteer(STATE.defaults("character"), _card("terrapup", 10)), {})

func test_stormheart_admission_has_cap_sixty_and_replay_preserves_saved_history() -> void:
	var before: Dictionary = DATA.new()._before()
	var card := _card("fulgocobra", 55)
	var claim := _claim(before, card)
	var result := AUTHORITY.stormwood_answer_proposal(before, claim, "")
	assert_true(result.get("ok", false), str(result))
	if result.get("ok") != true: return
	assert_eq(result.state.redesign_character.creatures[card.uid].cap_level, 60)
	assert_eq(result.state.redesign_character.creatures[card.uid].breakthroughs, [1, 2, 3, 4, 5])
	assert_eq(result.state.party.back().level, 55)
	var replay := AUTHORITY.stormwood_answer_proposal(result.state, claim, "")
	assert_true(replay.get("duplicate", false))
	assert_eq(replay.state, result.state)
	# Existing pre-fix saves are sealed, never silently migrated by acceptance.
	var legacy: Dictionary = result.state.duplicate(true)
	legacy.redesign_character.transaction_receipts.erase(result.receipt)
	legacy.redesign_character.creatures[card.uid].cap_level = 10
	legacy.redesign_character.creatures[card.uid].breakthroughs = []
	var sealed := AUTHORITY.stormwood_answer_proposal(legacy, _claim(legacy, card), "")
	assert_true(sealed.get("ok", false), str(sealed))
	if sealed.get("ok") == true:
		assert_eq(sealed.state.redesign_character.creatures, legacy.redesign_character.creatures)

func test_refusal_does_not_grant_a_creature_or_tiers() -> void:
	var before: Dictionary = DATA.new()._before()
	var card := _card("fulgocobra", 55)
	var result := AUTHORITY.stormwood_answer_proposal(before, _claim(before, card, false), "")
	assert_true(result.get("ok", false), str(result))
	if result.get("ok") == true:
		assert_eq(result.state.party, before.party)
		assert_eq(result.state.redesign_character.creatures, before.redesign_character.creatures)

func test_full_party_requires_one_release_and_initializes_only_the_newcomer() -> void:
	var player: RefCounted = DATA.new()._player()
	for species: String in ["bramblebun", "brooktail", "mudsnout", "trailpup"]:
		player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn(species))
	var before: Dictionary = preload("res://scripts/net/character_record_rules.gd").portable_projection(player.save_data())
	var card := _card("fulgocobra", 55)
	var claim := _claim(before, card)
	assert_false(AUTHORITY.stormwood_answer_proposal(before, claim, "").get("ok", false))
	var result := AUTHORITY.stormwood_answer_proposal(before, claim, str(before.party[0].uid))
	assert_true(result.get("ok", false), str(result))
	if result.get("ok") != true: return
	assert_eq(result.state.party.size(), 5)
	assert_eq(result.state.redesign_character.creatures[card.uid].cap_level, 60)
	for member: Dictionary in before.party.slice(1):
		assert_eq(result.state.redesign_character.creatures[member.uid], before.redesign_character.creatures[member.uid])

func test_shared_meadows_cloudreach_owner_cut_initializes_only_an_owned_live_volunteer() -> void:
	var climax := preload("res://scripts/world/stronghold_climax.gd")
	for species: String in ["veridian", "solmane"]:
		for count: int in [1, 5]:
			var game := OwnerGame.new()
			game.local = DATA.new()._player()
			for index in range(1, count):
				game.local.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("bramblebun"))
			var newcomer: RefCounted = TRAINER.creature_for({"species": species, "level": 44})
			assert_false(climax._initialize_volunteer_owner(game, newcomer), "not owned yet")
			if count == 5: game.local.party.remove_at(2)
			assert_true(game.local.party.add(newcomer))
			assert_true(climax._initialize_volunteer_owner(game, newcomer))
			assert_eq(game.local.redesign_character.creatures[newcomer.uid].cap_level, 50)
			var saved: Dictionary = game.local.redesign_character.duplicate(true)
			assert_true(climax._initialize_volunteer_owner(game, newcomer))
			assert_eq(game.local.redesign_character, saved, "retry leaves saved history intact")

func test_tidewake_guardian_saves_tiers_with_receipt_and_rolls_them_back_on_failure() -> void:
	var fixture := preload("res://tests/test_water_capture_transaction.gd").new()
	var transaction := preload("res://scripts/save/water_capture_transaction.gd")
	for count: int in [2, 5]:
		var game: RefCounted = fixture.fixture(count)
		game.pending_catch = TRAINER.creature_for({"species": "water_abyssal_guardian", "level": 33})
		var claim: Dictionary = fixture.claim()
		claim.source = "guardian"
		var before: Dictionary = game.local.redesign_character.duplicate(true)
		var members: Array = game.local.party.members()
		game.save_system.fail = true
		assert_false(transaction.settle(game, claim, game.pending_catch, 1).ok)
		assert_eq(game.local.redesign_character, before)
		assert_eq(game.local.party.members(), members)
		game.save_system.fail = false
		assert_true(transaction.settle(game, claim, game.pending_catch, 1).ok)
		var snapshot: Dictionary = game.save_system.snapshots.back()
		assert_eq(snapshot.redesign_character.creatures[game.pending_catch.uid].cap_level, 40)
		assert_true(snapshot.flags.flags.has("water_capture_receipt:" + str(claim.id)))
		var accepted: Dictionary = game.local.redesign_character.duplicate(true)
		assert_true(transaction.settle(game, claim, null).already)
		assert_eq(game.local.redesign_character, accepted)
	var declined: RefCounted = fixture.fixture(5)
	declined.pending_catch = TRAINER.creature_for({"species": "water_abyssal_guardian", "level": 33})
	var refusal: Dictionary = fixture.claim()
	refusal.source = "guardian"
	var personal: Dictionary = declined.local.redesign_character.duplicate(true)
	assert_true(transaction.settle(declined, refusal, declined.pending_catch, 5).ok)
	assert_eq(declined.local.redesign_character, personal, "refusal grants no tiers")
