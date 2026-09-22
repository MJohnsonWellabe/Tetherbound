extends "res://tests/test_case.gd"

## Static derivation of the exact Meadows named-place review set. The source
## map has 23 rows, but two names are deliberately represented as both landmark
## and region. Three authored player destinations live outside that map list.
## The herd discovery adds one place to the historical 23-place Meadows set.
## This current census is not visual acceptance of that new place, nor the
## separate 24-destination Water ledger.

const MAP_PATH := "res://data/config/map_landmarks.json"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const TELEPORT_PATH := "res://data/config/debug_teleport_spots.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func test_meadows_review_ledger_is_exactly_twenty_four_unique_places() -> void:
	var map := _json(MAP_PATH)
	var landmarks := map.get("landmarks", []) as Array
	var regions := map.get("regions", []) as Array
	assert_eq(landmarks.size(), 10, "Meadows map landmark count drifted")
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
	assert_true(landmark_names.has("Meadowhart Grazing Ground"),
		"the new companion discovery must be counted as its own fixed place")
	assert_eq(mapped_names.size(), 21,
		"23 raw map rows must resolve to 21 unique player-facing places")

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
	assert_eq(mapped_names.size() + external_count, 24,
		"canonical Meadows named-place ledger is 21 mapped plus 3 external")


func test_final_polish_locations_have_complete_accepted_evidence_rounds() -> void:
	var rounds := {
		"THE-RISE-IDENTITY-R33": "BLIND_REVIEW.md",
		"OLD-QUARRY-TERRACE-R55-DESKTOP-01": "independent-blind-review.md",
		"final-old-mill-63-desktop-01": "BLIND_REVIEW.md",
		"final-warrens-62-desktop-01": "BLIND_REVIEW.md",
	}
	for round_name: String in rounds:
		var root := "res://ralph/reports/MEADOWS-0912/" + round_name
		var manifest_path := root.path_join("manifest.json")
		assert_true(FileAccess.file_exists(manifest_path), "%s has no manifest" % round_name)
		var manifest := _json(manifest_path)
		assert_true(bool(manifest.get("complete", false)), "%s is not complete" % round_name)
		var review_path := root.path_join(str(rounds[round_name]))
		assert_true(FileAccess.file_exists(review_path), "%s has no independent review" % round_name)
		assert_true(FileAccess.get_file_as_string(review_path).contains("PASS"),
			"%s independent review records no PASS" % round_name)
