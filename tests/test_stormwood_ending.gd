extends "res://tests/test_case.gd"

## The world scene and network smoke own the physical ceremony. These focused
## contracts make the chapter order, per-participant offers and authored seams fail
## loudly in the fast suite before a long Stormwood run is attempted. The
## Stormheart follows the owner's per-participant legendary rule.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")


func test_every_participant_gets_their_own_once_only_offer() -> void:
	var fought := ["trainer-a", "trainer-b"]
	assert_false(ENDING.claim_allowed([], fought, "trainer-a", false),
		"Marrow's captive cannot be claimed before the Dynamo releases it")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "trainer-a", false),
		"a participant may answer the freed Stormheart")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG, ENDING.OFFER_FLAG], fought, "trainer-b", false),
		"a second participant keeps their own offer after the first has settled")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "trainer-c", false),
		"a character who did not fight for the release receives nothing")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "trainer-a", true),
		"a character who already answered cannot be offered again")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG], [], "solo", false),
		"a solo freeing records no other participant; the only player may answer")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], fought, "", false))


func test_claims_are_kept_per_character_and_legacy_saves_migrate() -> void:
	var state := {"participants": ["trainer-a", "trainer-b"], "claims": {
		"trainer-a": {"creature": {"species_id": "fulgocobra"}, "settled": true, "kept": true},
		"trainer-b": {"creature": {"species_id": "fulgocobra"}, "settled": false, "kept": false}}}
	assert_true(ENDING.claim_for_character(state, "trainer-a").is_empty(), "A settled claim is not resent")
	assert_false(ENDING.claim_for_character(state, "trainer-b").is_empty(), "Each character's own claim waits")
	assert_true(ENDING.claim_for_character(state, "trainer-c").is_empty())
	var legacy := {"recipient_character_id": "trainer-a", "creature": {"species_id": "fulgocobra"},
		"settled": false, "kept": false}
	var migrated := ENDING.migrate_state(legacy)
	assert_false(migrated.has("recipient_character_id"))
	assert_eq(migrated.participants, ["trainer-a"],
		"Only the legacy recipient is known to have fought; no one else may claim a fresh Stormheart")
	assert_eq((migrated.claims as Dictionary).keys(), ["trainer-a"])
	assert_false(ENDING.claim_for_character(migrated, "trainer-a").is_empty(),
		"An interrupted single-recipient ceremony resumes for its character")
	assert_eq(ENDING.migrate_state(migrated), migrated, "Migration is idempotent")


func test_waterward_waits_for_the_roster_decision_and_is_once_only() -> void:
	assert_false(ENDING.waterward_allowed([ENDING.FREED_FLAG]),
		"freeing the Stormheart does not skip its roster decision")
	assert_true(ENDING.waterward_allowed([ENDING.OFFER_FLAG]),
		"resolving the Stormheart offer unlocks the high-platform view")
	assert_false(ENDING.waterward_allowed([ENDING.OFFER_FLAG, ENDING.WATERWARD_FLAG]),
		"the durable Waterward reveal cannot be farmed")


func test_production_wires_the_existing_five_slot_and_story_transports() -> void:
	var ending := FileAccess.get_file_as_string("res://scripts/world/stormwood_ending.gd")
	var hub := FileAccess.get_file_as_string("res://scripts/world/stormwood_encounter_hub.gd")
	var world := FileAccess.get_file_as_string("res://scripts/world/stormwood_world.gd")
	assert_true(ending.contains('game.set("pending_catch", _local_creature)'),
		"a full belt must enter the one shipped five-slot ceremony")
	assert_true(ending.contains('"kind": "ending_settled"'),
		"the party owner must acknowledge its personal decision to the host")
	assert_true(ending.contains('call("set_flag", PERSONAL_RECEIPT_FLAG)'),
		"an interrupted character must resume after its saved ceremony decision")
	assert_true(ending.contains('_chapter.call("emit_event", "dynamo:release")'),
		"release must grant chapter flags through the host-led ledger adapter")
	assert_true(ending.contains('_chapter.call("emit_event", "aftermath:waterward_view")'),
		"the Water key and route reveal must come from the authored objective event")
	assert_false(ending.contains('"ending_commit_offer"') or ending.contains('"ending_commit_waterward"'),
		"the host shell must commit ending flags itself, not delegate authority to a client")
	assert_true(hub.contains('kind.begins_with("ending_")'),
		"ending intents must use Stormwood's reliable host channel")
	assert_true(world.contains('ending.mount(self)'),
		"the production Stormwood scene must mount the ending controller")


func test_chapter_data_orders_release_offer_and_waterward_before_home_placement() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_chapter.json"))
	assert_true(parsed is Dictionary, "Stormwood chapter JSON must parse")
	if not parsed is Dictionary:
		return
	var objectives: Array = []
	for act: Dictionary in (parsed as Dictionary).get("acts", []):
		objectives.append_array(act.get("objectives", []))
	var by_id: Dictionary = {}
	for objective: Dictionary in objectives:
		by_id[str(objective.get("id", ""))] = objective
	assert_eq(str(by_id["stormwood_legendary_freed"].completion_event), "dynamo:release")
	assert_true((by_id["stormwood_legendary_freed"].grants_flags as Array).has(
		"realm_heart_stormwood_earned"), "release awards the Spark")
	assert_false(by_id.has("stormwood_spark_placed"),
		"Spark placement belongs to the Meadows home circle, not the remote chapter")
	assert_true((by_id["stormwood_waterward_revealed"].requires_flags as Array).has(
		"stormwood:legendary_offer_made"), "Waterward follows the roster decision")
	for flag: String in ["realm_key_water", "waterward_route_revealed", "stormwood:chapter_complete"]:
		assert_true((by_id["stormwood_waterward_revealed"].grants_flags as Array).has(flag),
			"Waterward reveal must grant %s" % flag)


func test_livewire_is_the_single_active_cooldown_power() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/realm_hearts.json"))
	assert_true(parsed is Dictionary, "realm heart config must parse")
	if not parsed is Dictionary:
		return
	var heart: Dictionary = (parsed as Dictionary).hearts.stormwood
	assert_eq(str(heart.display_name), "Spark of the Stormwood")
	assert_eq(str(heart.power.display_name), "Livewire")
	assert_almost_eq(float(heart.power.cooldown_multiplier), 0.75, 0.0001,
		"Livewire shortens move cooldowns by exactly twenty-five percent")
	var shrine := FileAccess.get_file_as_string("res://scripts/world/realm_heart_shrine.gd")
	assert_true(shrine.contains("Only one relic power can be active."),
		"the physical shrine must explain the single-active replacement rule")


func test_ceremony_receipt_is_player_owned_despite_the_stormwood_world_prefix() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/progression/flag_scopes.json"))
	assert_true((parsed.player.ids as Array).has(ENDING.PERSONAL_RECEIPT_FLAG),
		"the party owner's decision must persist in that character, not the shared world")


func test_offer_asks_an_explicit_yes_or_no_and_receipts_each_answer() -> void:
	var dialogue: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/stormwood.json")) as Dictionary).conversations
	var lines: Array = dialogue[ENDING.OFFER_CONVERSATION].lines
	var last: Variant = lines.back()
	assert_true(last is Dictionary and str((last as Dictionary).get("confirm_effect", "")) != "",
		"the offer ends on a Yes/No consent line, so accepting with room is a choice, not a silent grant")
	assert_eq(ENDING.resolution_flag(true, "trainer-a"), "stormwood:legendary_resolution:accepted:trainer-a")
	assert_eq(ENDING.resolution_flag(false, "trainer-a"), "stormwood:legendary_resolution:refused:trainer-a")
	assert_eq(PROGRESSION_STATE.scope_of(ENDING.resolution_flag(false, "trainer-a")), "world",
		"the per-character answer receipt is a world fact every peer sees")
