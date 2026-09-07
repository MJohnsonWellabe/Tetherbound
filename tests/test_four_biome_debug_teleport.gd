extends "res://tests/test_case.gd"

## FOUR-BIOME-BUILD: the player-facing Settings teleport must expose every
## shipped realm and every named region/island, not stop at Cloudreach. The
## production scene swaps themselves remain in smoke_realm_teleport.gd; these
## fast checks pin the complete menu catalogue and its authored entry anchors.

const GAME := preload("res://autoload/game_state.gd")
const SPOTS_PATH := "res://data/config/debug_teleport_spots.json"

const EXPECTED_GROUPS := {
	"meadows": ["band1_lower_meadows", "band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood", "band5_stronghold_approach"],
	"cloudreach": ["gate_lower_cliffs", "broken_causeways", "windscar_ravine", "high_roost_sky_shrine", "upper_cloudreach", "summit_final_stronghold"],
	"stormwood": ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"],
	"water": ["first_shore", "reedhaven", "brine_steps", "shellwatch", "tidal_cradle", "salt_crown", "sluice_isle", "veilfall", "lantern_cove", "gull_rest", "drowned_garden", "deep_watch"],
}

const EXPECTED_ENTRY_IDS := {
	"meadows": "meadows_cloudreach_gate_return",
	"cloudreach": "cloudreach_arrival_from_meadows",
	"stormwood": "stormwood_arrival_from_cloudreach",
	"water": "water_arrival_from_stormwood",
}


func test_curated_menu_has_two_destinations_in_every_named_region() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPOTS_PATH))
	assert_true(parsed is Dictionary, "debug_teleport_spots.json must parse")
	if not parsed is Dictionary:
		return
	var biomes: Array = (parsed as Dictionary).get("biomes", [])
	assert_eq(biomes.size(), EXPECTED_GROUPS.size(), "all four shipped biomes must be in Settings")
	var seen: Array[String] = []
	for biome_value: Variant in biomes:
		assert_true(biome_value is Dictionary)
		if not biome_value is Dictionary:
			continue
		var biome := biome_value as Dictionary
		var realm_id := str(biome.get("id", ""))
		seen.append(realm_id)
		assert_true(EXPECTED_GROUPS.has(realm_id), "unknown biome in teleport catalogue: %s" % realm_id)
		var groups: Array = biome.get("bands", [])
		var expected_group_ids: Array = EXPECTED_GROUPS.get(realm_id, [])
		assert_eq(groups.size(), expected_group_ids.size(),
			"%s must cover every named band/region/island" % realm_id)
		var seen_group_ids: Array[String] = []
		for group_value: Variant in groups:
			assert_true(group_value is Dictionary)
			if not group_value is Dictionary:
				continue
			var group := group_value as Dictionary
			var group_id := str(group.get("id", ""))
			seen_group_ids.append(group_id)
			assert_true(expected_group_ids.has(group_id), "%s has an unknown group: %s" % [realm_id, group_id])
			var spots: Array = group.get("spots", [])
			assert_eq(spots.size(), 2, "%s/%s must have exactly two test destinations" % [realm_id, group.get("id", "?")])
			for spot_value: Variant in spots:
				assert_true(spot_value is Dictionary)
				if not spot_value is Dictionary:
					continue
				var spot := spot_value as Dictionary
				var position: Variant = spot.get("position", [])
				assert_true(not str(spot.get("display_name", "")).is_empty())
				assert_true(position is Array and (position as Array).size() == 2,
					"%s/%s has no finite x/z pair" % [realm_id, group.get("id", "?")])
				if position is Array and (position as Array).size() == 2:
					assert_true(is_finite(float(position[0])) and is_finite(float(position[1])),
						"%s/%s has a non-finite x/z pair" % [realm_id, group_id])
		for expected_group_id: String in expected_group_ids:
			assert_true(seen_group_ids.has(expected_group_id), "%s/%s is missing from Settings" % [realm_id, expected_group_id])
	for realm_id: String in EXPECTED_GROUPS:
		assert_true(seen.has(realm_id), "%s is missing from the Settings teleport" % realm_id)


func test_every_realm_resolves_its_authored_arrival_anchor() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	for realm_id: String in EXPECTED_ENTRY_IDS:
		assert_eq(str(game.call("_debug_teleport_entry_id_for", realm_id)), EXPECTED_ENTRY_IDS[realm_id],
			"%s must use its authored scene-arrival anchor" % realm_id)
	game.free()


func test_runtime_destinations_offer_all_other_shipped_realms_without_story_keys() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	for source_realm: String in EXPECTED_GROUPS:
		game.current_realm = source_realm
		var destinations: Array = game.debug_teleport_destinations()
		for destination_realm: String in EXPECTED_GROUPS:
			if destination_realm == source_realm:
				continue
			var found := false
			for entry_value: Variant in destinations:
				if entry_value is Dictionary and str((entry_value as Dictionary).get("realm", "")) == destination_realm:
					found = true
					assert_eq(str((entry_value as Dictionary).get("entry_id", "")), EXPECTED_ENTRY_IDS[destination_realm])
					break
			assert_true(found, "%s must offer a no-key debug crossing to %s" % [source_realm, destination_realm])
	game.free()
