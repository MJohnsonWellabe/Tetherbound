extends "res://tests/test_case.gd"

## Hard rule (red and oxblood are Team Tether only). Fulgocobra's copper collar
## plates ship as gunmetal slate: GPU High G-cw-collar-wardenring-r2, F36#46
## pose stage 5.29 -> 5.70 and world states 6.12 -> 6.54 (3/3 each), 0 red
## pixels on the arm. The coat is the earlier live coat with only its albedo
## changed.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/fulgocobra/candidate_owner1101/models/creature_fulgocobra_owner1101_Image_0.jpg"


func test_slate_collar_ships_on_and_cites_the_verdict() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = (parsed.flags as Dictionary).get("below6_fulgocobra_slate_collar", {})
	assert_true(bool(entry.get("enabled", false)), "ships ON")
	var why := str(entry.get("_why_on", ""))
	assert_true(why.contains("G-cw-collar-wardenring-r2.md"), "it cites its GPU verdict")
	assert_true(why.contains("5.29 -> 5.70"), "and its judged score")


func test_live_coat_is_the_slate_albedo_with_the_earlier_finish() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_Image_0_face_slate.png"), "the slate collar albedo is live")
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))))
	((parsed.flags as Dictionary).below6_fulgocobra_slate_collar as Dictionary)["enabled"] = false
	var earlier: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	for key: String in ["emission", "emission_energy", "rim", "rim_tint", "roughness", "specular"]:
		assert_eq(spec.get(key), earlier.get(key), "%s is unchanged" % key)
