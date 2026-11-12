extends "res://tests/test_case.gd"

## F41#1 (LANE-BELOW6, 12 Nov 2026): approach-stand overrides in
## capture_stands.json ship ON for the two Stormheart approach views (GPU High
## 5.10 -> 6.81), are read only for the identities they name, and reject
## malformed entries.

const LOCATIONS := preload("res://tools/phase2_capture_locations.gd")
const CONFIG := "res://data/config/capture_stands.json"


func _write(data: Dictionary) -> String:
	var path := "user://test_capture_approach_overrides.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	return path


func test_stormheart_approach_stand_ships_on_with_its_verdict() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var block: Dictionary = (parsed as Dictionary).get("approach_overrides", {})
	assert_true(bool(block.get("enabled", false)), "approach_overrides ships ON (judged gain)")
	var why := str(block.get("_why_on", ""))
	assert_true(why.contains("G-below6-stormheart-approach.md"), "it cites its GPU verdict")
	assert_true(why.contains("5.10 -> 6.81"), "and its judged score")
	for identity in ["stormwood__dynamo__12__the_stormheart_tree", "stormwood__landmark__dynamo_core"]:
		var spec: Dictionary = LOCATIONS.approach_override_for(CONFIG, identity)
		assert_eq(spec.get("position", []), [-100.0, 5300.0], "%s looks from the road" % identity)
		assert_eq(float(spec.get("heading_deg", -1.0)), 0.0)
	assert_true(LOCATIONS.approach_override_for(CONFIG, "stormwood__landmark__somewhere_else").is_empty(),
		"no other destination is moved")


func test_enabled_override_applies_only_to_named_destinations() -> void:
	var path := _write({"approach_overrides": {"enabled": true, "destinations": {
		"a": {"position": [-100.0, 5300.0], "heading_deg": 0.0},
		"bad_position": {"position": [1.0], "heading_deg": 0.0},
		"bad_heading": {"position": [1.0, 2.0]},
	}}})
	var spec: Dictionary = LOCATIONS.approach_override_for(path, "a")
	assert_eq(spec.get("position", []), [-100.0, 5300.0])
	assert_eq(float(spec.get("heading_deg", -1.0)), 0.0)
	assert_true(LOCATIONS.approach_override_for(path, "other").is_empty(), "unnamed destinations keep their stands")
	assert_true(LOCATIONS.approach_override_for(path, "bad_position").is_empty(), "a malformed position is rejected")
	assert_true(LOCATIONS.approach_override_for(path, "bad_heading").is_empty(), "a missing heading is rejected")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
