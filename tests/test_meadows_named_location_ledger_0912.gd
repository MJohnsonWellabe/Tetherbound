extends "res://tests/test_case.gd"

## Static derivation of the exact Meadows named-place review set. The source
## map has 22 rows, but two names are deliberately represented as both landmark
## and region. Three authored player destinations live outside that map list.
## This contract prevents the 23-place Meadows ledger being confused with the
## separate 24-destination Water ledger.

const MAP_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const TELEPORT_PATH := "res://data/config/debug_teleport_spots.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_meadows_review_ledger_is_exactly_twenty_three_unique_places() -> void:
	var map := _json(MAP_PATH)
	var landmarks := map.get("landmarks", []) as Array
	var regions := map.get("regions", []) as Array
	assert_eq(landmarks.size(), 9, "Meadows map landmark count drifted")
	assert_eq(regions.size(), 13, "Meadows named-region count drifted")

	var landmark_names := {}
	var region_names := {}
	var mapped_names := {}
	for raw: Variant in landmarks:
		var name := str((raw as Dictionary).get("display_name", ""))
		landmark_names[name] = true
		mapped_names[name] = true
	for raw: Variant in regions:
		var name := str((raw as Dictionary).get("display_name", ""))
		region_names[name] = true
		mapped_names[name] = true
	var duplicate_names: Array[String] = []
	for name: String in landmark_names:
		if region_names.has(name):
			duplicate_names.append(name)
	duplicate_names.sort()
	assert_eq(duplicate_names, ["Old Mill Crossing", "The Tether Relay"],
		"only the crossing and relay intentionally have landmark plus region rows")
	assert_eq(mapped_names.size(), 20,
		"22 raw map rows must resolve to 20 unique player-facing places")

	var route_labels := {}
	var paths := _json(TERRAIN_PATH).get("paths", {}) as Dictionary
	for raw: Variant in paths.get("routes", []):
		route_labels[str((raw as Dictionary).get("label", ""))] = true
	for external_name: String in ["The Inn", "Practice Meadow"]:
		assert_true(route_labels.has(external_name),
			"%s is no longer an authored terrain destination" % external_name)
		assert_false(mapped_names.has(external_name),
			"%s was double-counted after moving into the map list" % external_name)

	var stronghold_approach_found := false
	for biome_raw: Variant in _json(TELEPORT_PATH).get("biomes", []):
		var biome := biome_raw as Dictionary
		if str(biome.get("id", "")) != "meadows":
			continue
		for band_raw: Variant in biome.get("bands", []):
			for spot_raw: Variant in (band_raw as Dictionary).get("spots", []):
				if str((spot_raw as Dictionary).get("display_name", "")) == "Stronghold Approach":
					stronghold_approach_found = true
	assert_true(stronghold_approach_found,
		"Stronghold Approach is no longer an authored player destination")
	assert_false(mapped_names.has("Stronghold Approach"),
		"Stronghold Approach was double-counted after moving into the map list")

	var external_count := 3
	assert_eq(mapped_names.size() + external_count, 23,
		"canonical Meadows named-place ledger is 20 mapped plus 3 external")


func test_pending_polish_captures_name_their_serialized_rounds() -> void:
	var inn := FileAccess.get_file_as_string("res://tools/capture_inn.gd")
	var highfield := FileAccess.get_file_as_string(
		"res://tools/capture_highfield_hero_identity.gd")
	var rise := FileAccess.get_file_as_string("res://tools/capture_the_rise_identity.gd")
	assert_true(inn.contains("INN-COMMON-ROOM-R12"),
		"Inn material/night candidate has no distinct pending evidence round")
	assert_true(highfield.contains("HIGHFIELD-HERO-IDENTITY-R11"),
		"Highfield vertical-identity candidate has no distinct pending evidence round")
	assert_true(rise.contains("THE-RISE-IDENTITY-R5"),
		"Rise crown-sightline candidate has no distinct pending evidence round")
