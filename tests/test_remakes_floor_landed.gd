extends "res://tests/test_case.gd"

## F36#86 Voltarach and F36#61 Ribbonray (LANE-BELOW6 landing, 11 Nov 2026).
## GPU High G-remakes-floor1: Voltarach 5.15 -> 6.50, Ribbonray 5.02 -> 6.90,
## 3/3 each. G-below6-abyssal-matte: Abyssal Guardian 5.22 -> 5.77, 3/3. The
## three coat grades and Ribbonray's grounded hit ship ON and cite their verdicts.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const COAT_PATH := "res://data/config/creature_coat_flags.json"
const CLIP_PATH := "res://data/config/creature_clip_flags.json"
const VERDICT := "G-remakes-floor1-ribbonray-voltarach.md"


func _flags(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_judged_coats_ship_on_and_cite_the_verdict() -> void:
	var flags := _flags(COAT_PATH)
	for flag in ["remakes_floor_voltarach", "remakes_floor_ribbonray"]:
		var entry: Dictionary = flags.get(flag, {})
		assert_true(bool(entry.get("enabled", false)), "%s ships ON (judged gain)" % flag)
		assert_true(str(entry.get("_why_on", "")).contains(VERDICT), "%s cites its GPU verdict" % flag)
		for from_path: String in entry.get("coats", {}):
			var spec: Dictionary = (entry.coats as Dictionary)[from_path]
			assert_true(ResourceLoader.exists(str(spec.get("albedo", ""))), "%s graded albedo exists" % flag)
	assert_true(str((flags["remakes_floor_voltarach"] as Dictionary).get("_why_on", "")).contains("5.15 -> 6.50"))
	assert_true(str((flags["remakes_floor_ribbonray"] as Dictionary).get("_why_on", "")).contains("5.02 -> 6.90"))


func test_live_coat_table_carries_both_grades() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var resolved: Dictionary = BODY.parse_coat_flags(parsed)
	var voltarach: Dictionary = resolved.get(
		"res://assets/creatures/tetherbound/voltarach/candidate/models/creature_voltarach_native_Image_0.jpg", {})
	assert_true(str(voltarach.get("albedo", "")).ends_with("_floor1.png"), "Voltarach wears the charcoal floor1 coat")
	assert_true(str(voltarach.get("emission", "")).ends_with("_floor1_glow.png"), "Voltarach's eyes and cracks are lit")
	var ribbonray: Dictionary = resolved.get(
		"res://assets/creatures/tetherbound/ribbonray/candidate_owner1101/models/creature_ribbonray_owner1101_Image_0.jpg", {})
	assert_true(str(ribbonray.get("albedo", "")).ends_with("_floor1.png"), "Ribbonray wears the navy floor1 coat")


func test_ribbonray_grounded_hit_ships_on() -> void:
	var entry: Dictionary = _flags(CLIP_PATH).get("remakes_floor_ribbonray_hit", {})
	assert_true(bool(entry.get("enabled", false)), "the grounded hit ships ON")
	assert_true(str(entry.get("_why_on", "")).contains(VERDICT), "it cites its GPU verdict")
	var hit: Dictionary = ((entry.get("species", {}) as Dictionary).get("ribbonray", {}) as Dictionary).get("hit", {})
	assert_eq(float(hit.get("rotation", 1.0)), 0.4)
	assert_eq(float(hit.get("position", 1.0)), 0.5)


func test_abyssal_matte_hide_ships_on() -> void:
	var entry: Dictionary = _flags(COAT_PATH).get("remakes_floor_abyssal_guardian", {})
	assert_true(bool(entry.get("enabled", false)), "the Abyssal Guardian matte hide ships ON (judged gain)")
	var why := str(entry.get("_why_on", ""))
	assert_true(why.contains("G-below6-abyssal-matte.md"), "it cites its GPU verdict")
	assert_true(why.contains("5.22 -> 5.77"), "and the land form's judged score")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COAT_PATH))
	var resolved: Dictionary = BODY.parse_coat_flags(parsed)
	var land: Dictionary = resolved.get(
		"res://assets/creatures/tetherbound/abyssal_guardian/candidate_owner1101/models/creature_abyssal_guardian_owner1101_Image_0.jpg", {})
	assert_true(str(land.get("albedo", "")).ends_with("_floor1.png"), "the land form wears the matte floor1 hide")
	assert_eq(float(land.get("roughness", 0.0)), 0.86)
