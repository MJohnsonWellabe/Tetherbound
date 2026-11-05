extends "res://tests/test_case.gd"

## v1/b23-b26 stage value lifts (creature_coat_flags.json): Stormbrush,
## Thundertunnel, Tuskroot, Cindercub, Stormraven, Reedwing, Paddlenewt and Shadelet. Judged gains, ship ON. Each maps its live albedo to a
## value-lifted copy; OFF leaves that albedo as before.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const ROOT := "res://assets/creatures/tetherbound/"
const SCORES := {"stormbrush": "6.42", "thundertunnel": "5.78", "tuskroot": "7.16", "cindercub": "7.38", "stormraven": "6.59", "reedwing": "6.70", "paddlenewt": "6.70", "shadelet": "6.26"}


func _parsed() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return parsed if parsed is Dictionary else {}


func _paths(species: String) -> Array:
	var dir := ROOT + "%s/candidate_owner1101/models/creature_%s_owner1101_" % [species, species]
	return [dir + "Image_0.jpg", dir + "Image_0_value_lift.png"]


func test_each_lift_ships_on_with_its_score() -> void:
	var flags: Dictionary = _parsed().get("flags", {})
	for species: String in SCORES:
		var entry: Dictionary = flags.get("creatures_ralph_%s_value_lift" % species, {})
		assert_true(bool(entry.get("enabled", false)), "%s value lift ships ON" % species)
		assert_true(str(entry.get("_why_on", "")).contains(SCORES[species]), "%s records its mapped score" % species)
		assert_true(FileAccess.file_exists(_paths(species)[1]), "%s lifted albedo is on disk" % species)


func test_on_resolves_the_lift_and_off_does_not() -> void:
	var on := BODY.parse_coat_flags(_parsed())
	for species: String in SCORES:
		var paths := _paths(species)
		assert_eq(str((on.get(paths[0], {}) as Dictionary).get("albedo", "")), paths[1], "ON: %s wears its lift" % species)
		var parsed := _parsed()
		(parsed.flags["creatures_ralph_%s_value_lift" % species] as Dictionary)["enabled"] = false
		var off := BODY.parse_coat_flags(parsed)
		assert_true(str((off.get(paths[0], {}) as Dictionary).get("albedo", "")) != paths[1], "OFF: %s keeps its earlier albedo" % species)
