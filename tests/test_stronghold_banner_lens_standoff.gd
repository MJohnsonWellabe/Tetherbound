extends "res://tests/test_case.gd"

## LANE-THINGS, 13 Nov 2026 (GPU 3/3: Warden fight frame r10 near-black, the
## lens resting against the war banner's cloth). The banner model's
## camera-only occluder extends outward by `occluder_standoff_m`, so the fight
## camera's arm stops in front of the cloth instead of touching it.
const CONFIG := "res://data/config/stronghold.json"
const SCRIPT := "res://scripts/world/stronghold.gd"


func test_the_shipped_banner_keeps_the_lens_off_the_cloth() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_true(parsed is Dictionary)
	var banner: Dictionary = (parsed as Dictionary).get("banner_model_candidate", {})
	assert_true(bool(banner.get("enabled", false)), "the banner model is the shipped banner")
	var standoff := float(banner.get("occluder_standoff_m", 0.0))
	assert_true(standoff >= 0.5 and standoff <= 1.5, "a stand-off the lens can sit behind without crowding the arena (%.2f)" % standoff)


func test_the_standoff_only_extends_the_box_outward() -> void:
	var code := FileAccess.get_file_as_string(SCRIPT)
	assert_true(code.contains("occluder_box.size = Vector3(0.7 + extra_depth, height, width)"),
		"the box grows in depth only")
	assert_true(code.contains("Vector3(BANNER_CLOTH_T + standoff * 0.5, -height * 0.5 - 0.09, 0.0), width, height, standoff)"),
		"and its centre moves out by half the stand-off, so the wall side stays where it was")
	assert_true(code.contains("extra_depth: float = 0.0"), "the plain cloth banner keeps the old box")
