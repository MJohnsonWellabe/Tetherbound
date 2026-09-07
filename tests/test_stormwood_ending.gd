extends "res://tests/test_case.gd"

## The world scene and network smoke own the physical ceremony. These focused
## contracts make the chapter order, unique recipient and authored seams fail
## loudly in the fast suite before a long Stormwood run is attempted.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")


func test_legendary_claim_requires_release_and_stays_with_one_character() -> void:
	assert_false(ENDING.claim_allowed([], "", "trainer-a"),
		"Marrow's captive cannot be claimed before the Dynamo releases it")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG], "", "trainer-a"),
		"the first character may accept the freed Stormheart's offer")
	assert_true(ENDING.claim_allowed([ENDING.FREED_FLAG], "trainer-a", "trainer-a"),
		"the reserved character may resume an interrupted ceremony")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG], "trainer-a", "trainer-b"),
		"a second character cannot duplicate the one legendary")
	assert_false(ENDING.claim_allowed([ENDING.FREED_FLAG, ENDING.OFFER_FLAG], "trainer-a", "trainer-a"),
		"a settled ceremony cannot reopen")


func test_waterward_waits_for_spark_placement_and_is_once_only() -> void:
	assert_false(ENDING.waterward_allowed([ENDING.FREED_FLAG, ENDING.OFFER_FLAG]),
		"freeing the Stormheart does not skip Lantern Hollow")
	assert_true(ENDING.waterward_allowed([ENDING.SPARK_PLACED_FLAG]),
		"placing the Spark unlocks the high-platform view")
	assert_false(ENDING.waterward_allowed([ENDING.SPARK_PLACED_FLAG, ENDING.WATERWARD_FLAG]),
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


func test_chapter_data_orders_release_offer_spark_and_waterward() -> void:
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
	assert_true((by_id["stormwood_spark_placed"].requires_flags as Array).has(
		"stormwood:legendary_offer_made"), "Spark placement follows the roster decision")
	assert_true((by_id["stormwood_waterward_revealed"].requires_flags as Array).has(
		"stormwood:spark_placed"), "Waterward follows Spark placement")
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
