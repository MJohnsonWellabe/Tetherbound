extends "res://tests/test_case.gd"

## Hard rule (red is Team Tether only): Fulgocobra's copper collar plates move
## to slate. Candidate OFF until a GPU verdict; it is the live coat with only
## the albedo changed.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/fulgocobra/candidate_owner1101/models/creature_fulgocobra_owner1101_Image_0.jpg"


func test_candidate_is_off_and_only_changes_the_albedo() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = (parsed.flags as Dictionary).get("below6_fulgocobra_slate_collar", {})
	assert_false(bool(entry.get("enabled", true)), "candidate is OFF")
	var live: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	entry["enabled"] = true
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_Image_0_face_slate.png"))
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))))
	for key: String in ["emission", "emission_energy", "rim", "rim_tint", "roughness", "specular"]:
		assert_eq(spec.get(key), live.get(key), "%s is the live coat's" % key)
