extends "res://tests/test_case.gd"

## F36#46 / F41#13 candidate: Fulgocobra olive scales with gold veins.
## OFF until a GPU verdict; when switched on it is the coat the table resolves.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const SOURCE := "res://assets/creatures/tetherbound/fulgocobra/candidate_owner1101/models/creature_fulgocobra_owner1101_Image_0.jpg"
const FLAG := "below6_fulgocobra_olive_veins"


func test_candidate_is_off_and_resolves_when_on() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var entry: Dictionary = (parsed.flags as Dictionary).get(FLAG, {})
	assert_false(bool(entry.get("enabled", true)), "candidate is OFF")
	var live: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_false(str(live.get("albedo", "")).ends_with("_olive.png"), "live coat is unchanged")
	entry["enabled"] = true
	var spec: Dictionary = BODY.parse_coat_flags(parsed).get(SOURCE, {})
	assert_true(str(spec.get("albedo", "")).ends_with("_Image_0_olive.png"))
	assert_true(str(spec.get("emission", "")).ends_with("_glow_vein_r1.png"))
	assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))))
	assert_true(ResourceLoader.exists(str(spec.get("emission", ""))))
