extends "res://tests/test_case.gd"

## FOUR-BIOME-BUILD: the player-facing Settings teleport must expose every
## shipped realm and every named region/island, not stop at Cloudreach. The
## production scene swaps themselves remain in smoke_realm_teleport.gd; these
## fast checks pin the complete menu catalogue and its authored entry anchors.

const GAME := preload("res://autoload/game_state.gd")
const TAB_SETTINGS := preload("res://scripts/ui/tab_settings.gd")
const SPOTS_PATH := "res://data/config/debug_teleport_spots.json"
const FLY := preload("res://scripts/player/fly_controller.gd")


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

const EXPECTED_REALM_DISPLAY_NAMES := {
	"meadows": "Meadows",
	"cloudreach": "Cloudreach Cliffs",
	"stormwood": "The Stormwood",
	"water": "Tidewake",
}


class TeleportGameDouble extends Node:
	var current_realm := "menu_test_source"
	var calls: Array[Dictionary] = []

	func debug_teleport_to(x: float, z: float, realm_id: String = "", entry_id: String = "",
			view_heading_deg: Variant = null) -> bool:
		calls.append({"x": x, "z": z, "realm": realm_id, "entry_id": entry_id,
			"view_heading_deg": view_heading_deg})
		return true


class TeleportMenuDouble extends Node:
	var game: Node = null
	var close_count := 0

	func close() -> void:
		close_count += 1


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
		assert_eq(str(biome.get("display_name", "")), EXPECTED_REALM_DISPLAY_NAMES.get(realm_id, ""),
			"%s must use the realm's player-facing display name" % realm_id)
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


func test_menu_relocation_resets_the_real_fly_controller_anchor() -> void:
	var game := GAME.new()
	var player := Node3D.new()
	var fly := FLY.new()
	fly.name = "FlyController"
	player.add_child(fly)
	fly.safe_anchor = Vector3(900, 1020, 2700)
	fly.safe_realm = "cloudreach"
	game.call("_clear_debug_teleport_recovery_anchor", player)
	assert_eq(fly.safe_anchor, Vector3.INF, "the teleport helper must discard the old high landing")
	assert_eq(fly.safe_realm, "")
	player.free()
	game.free()


func test_every_realm_resolves_its_authored_arrival_anchor() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	for realm_id: String in EXPECTED_ENTRY_IDS:
		assert_eq(str(game.call("_debug_teleport_entry_id_for", realm_id)), EXPECTED_ENTRY_IDS[realm_id],
			"%s must use its authored scene-arrival anchor" % realm_id)
	game.free()


func test_settings_tab_resolves_every_curated_row_to_a_realm_and_entry() -> void:
	var game := GAME.new()
	game.reset_for_new_game()
	var tab := TAB_SETTINGS.new()
	var destinations: Array = tab.call("_read_debug_teleport_spots", game)
	var expected_count := 0
	for group_ids: Array in EXPECTED_GROUPS.values():
		expected_count += group_ids.size() * 2
	assert_eq(destinations.size(), expected_count,
		"Settings must flatten every curated two-per-region destination")
	for entry_value: Variant in destinations:
		assert_true(entry_value is Dictionary)
		if not entry_value is Dictionary:
			continue
		var entry := entry_value as Dictionary
		var realm_id := str(entry.get("realm", ""))
		assert_true(EXPECTED_ENTRY_IDS.has(realm_id),
			"Settings row has no shipped realm: %s" % entry)
		if EXPECTED_ENTRY_IDS.has(realm_id):
			assert_eq(str(entry.get("entry_id", "")), EXPECTED_ENTRY_IDS[realm_id],
				"%s must carry its authored scene-arrival anchor" % entry.get("display_name", "?"))
	tab.free()
	game.free()


func test_meadows_occluded_landmarks_use_authored_approach_arrivals() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPOTS_PATH))
	var spots := {}
	for biome_value: Variant in parsed.get("biomes", []):
		if biome_value is Dictionary and str((biome_value as Dictionary).get("id", "")) == "meadows":
			for band_value: Variant in (biome_value as Dictionary).get("bands", []):
				for spot_value: Variant in (band_value as Dictionary).get("spots", []):
					if spot_value is Dictionary:
						spots[str((spot_value as Dictionary).get("display_name", ""))] = spot_value
	var warrens: Dictionary = spots.get("The Burrow Warrens", {})
	assert_eq(warrens.get("position", []), [-328.7, 2581.7])
	assert_almost_eq(float(warrens.get("view_heading_deg", NAN)), -45.0, 0.001)
	assert_almost_eq(Vector2(-328.7, 2581.7).distance_to(Vector2(-357.0, 2610.0)), 40.0, 0.05,
		"Warrens arrival must remain on the proven exterior approach, not inside the mouth")
	var approach: Dictionary = spots.get("Stronghold Approach", {})
	assert_eq(approach.get("position", []), [0.0, 7000.0])
	assert_almost_eq(float(approach.get("view_heading_deg", NAN)), 0.0, 0.001)
	assert_true(Vector2(0.0, 7000.0).distance_to(Vector2(-40.0, 7010.0)) > 40.0,
		"Stronghold arrival must not overlap the first pylon")


func test_cloudreach_overlook_uses_the_canonical_stormward_name() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPOTS_PATH))
	var names: Array[String] = []
	for biome_value: Variant in parsed.get("biomes", []):
		if biome_value is Dictionary and str((biome_value as Dictionary).get("id", "")) == "cloudreach":
			for band_value: Variant in (biome_value as Dictionary).get("bands", []):
				for spot_value: Variant in (band_value as Dictionary).get("spots", []):
					if spot_value is Dictionary:
						names.append(str((spot_value as Dictionary).get("display_name", "")))
	assert_true(names.has("Stormward Overlook"),
		"Settings must use cloudreach_world.json's canonical player-facing overlook name")
	assert_false(names.has("Waterward Overlook"),
		"the superseded pre-Stormwood overlook name must not remain player-facing")


func test_every_settings_row_calls_the_existing_cross_realm_teleport_seam() -> void:
	var resolver := GAME.new()
	resolver.reset_for_new_game()
	var tab := TAB_SETTINGS.new()
	var destinations: Array = tab.call("_read_debug_teleport_spots", resolver)
	resolver.free()

	var fake_game := TeleportGameDouble.new()
	var fake_menu := TeleportMenuDouble.new()
	fake_menu.game = fake_game
	tab.menu = fake_menu
	for entry_value: Variant in destinations:
		var entry := entry_value as Dictionary
		var before_calls := fake_game.calls.size()
		var before_closes := fake_menu.close_count
		# Exercise the row's real pressed callback, rather than calling the tab's
		# handler directly. This pins the closure that must preserve realm/entry.
		var button := tab.call("_build_teleport_row", entry) as Button
		tab.add_child(button)
		assert_true(button.text.contains(str(EXPECTED_REALM_DISPLAY_NAMES[str(entry.realm)])),
			"every visible teleport destination must identify its biome")
		button.emit_signal("pressed")
		assert_eq(fake_game.calls.size(), before_calls + 1,
			"pressing %s must call debug_teleport_to once" % entry.get("display_name", "?"))
		if fake_game.calls.size() != before_calls + 1:
			continue
		var call := fake_game.calls.back() as Dictionary
		var position: Vector2 = entry.get("position", Vector2.ZERO)
		assert_almost_eq(float(call.get("x", NAN)), position.x, 0.0001)
		assert_almost_eq(float(call.get("z", NAN)), position.y, 0.0001)
		assert_eq(str(call.get("realm", "")), str(entry.get("realm", "")),
			"the menu row must preserve its destination realm")
		assert_eq(str(call.get("entry_id", "")), str(entry.get("entry_id", "")),
			"the menu row must preserve its authored arrival id")
		assert_eq(call.get("view_heading_deg", null), entry.get("view_heading_deg", null),
			"the menu row must preserve its optional authored view heading")
		assert_eq(fake_menu.close_count, before_closes + 1,
			"a successful debug teleport must close the menu")

	tab.free()
	fake_menu.free()
	fake_game.free()


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
