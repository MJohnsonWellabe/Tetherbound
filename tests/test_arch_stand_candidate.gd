extends "res://tests/test_case.gd"

## F40#3 `approach_overrides.candidates_1113` (LANE-LAND-CS): the broken skyroad
## arch stand, ON (re-baseline G-lcs-archstand: 6.37 vs 5.74, 3/3). Both arch
## frames search from the arch centre toward the south rim of its small island.

const LOCATIONS := preload("res://tools/phase2_capture_locations.gd")
const CONFIG := "res://data/config/capture_stands.json"
const IDS := ["cloudreach__landmark__broken_skyroad_arch", "cloudreach__broken_causeways__04__broken_skyroad_arch"]


func test_ships_on_with_its_verdict_and_resolves_both_frames() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var block: Dictionary = cfg.approach_overrides.candidates_1113
	assert_true(bool(block.get("enabled", false)), "candidates_1113 is ON")
	assert_true(str(block.get("_why_on", "")).contains("G-lcs-archstand.md"), "ON cites its GPU verdict")
	for id: String in IDS:
		var spec := LOCATIONS.approach_override_for(CONFIG, id)
		assert_eq(spec.get("position", []), [350.0, 1940.0], id + " searches from the arch centre")


func test_on_resolves_both_arch_frames() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	cfg.approach_overrides.candidates_1113.enabled = true
	var path := "user://test_arch_stand_candidate.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(cfg))
	file.close()
	for id: String in IDS:
		var spec := LOCATIONS.approach_override_for(path, id)
		assert_eq(spec.get("position", []), [350.0, 1940.0], id + " searches from the arch centre")
		assert_eq(float(spec.get("heading_deg", -1.0)), 0.0, id + " faces north from the south rim")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
