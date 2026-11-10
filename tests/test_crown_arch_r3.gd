extends "res://tests/test_case.gd"

## F41#17 close-out r3 Crown Arch (LANE-MESHY): ships ON (GPU +0.50, 10 Nov); ON swaps the model
## and hides the square footing mesh (collider kept), never the passage or yaw.

const LANDMARKS := preload("res://scripts/world/hero_landmarks_1101.gd")
const R3 := "res://assets/props/vl-1103/crown_arch/crown_arch_r3.glb"


func test_r3_ships_on_and_the_model_loads() -> void:
	var vl: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crown_arch_vl.json"))
	assert_true(bool(vl.r3_candidate.get("enabled", false)), "r3 ships ON after its judged gain")
	assert_true(str(vl.r3_candidate.get("_why_on", "")).contains("+0.50"), "the judged gain is recorded")
	assert_eq(str(vl.r3_candidate.model), R3)
	assert_true(ResourceLoader.exists(R3), "r3 model imported")
	var shipped := LANDMARKS.crown_arch_vl_overlay({"model": "base", "yaw_deg": 90.0})
	assert_eq(str(shipped.model), R3, "the shipped overlay uses the r3 model")
	assert_eq(float(shipped.yaw_deg), 90.0, "yaw unchanged")


func test_r3_on_swaps_only_the_model() -> void:
	var path := "res://data/config/crown_arch_vl.json"
	var text := FileAccess.get_file_as_string(path)
	var vl: Dictionary = JSON.parse_string(text)
	vl.r3_candidate.enabled = true
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(vl))
	f.close()
	var base := {"model": "base", "yaw_deg": 90.0, "slab_moss": {"tint": "#5d7462", "uv_per_m": 0.22}, "skirt": {"enabled": false, "out_m": 2.6}, "min_outer_width_m": 4.2}
	var on := LANDMARKS.crown_arch_vl_overlay(base)
	var g := FileAccess.open(path, FileAccess.WRITE)
	g.store_string(text)
	g.close()
	assert_eq(str(on.model), R3, "ON uses the r3 model")
	for key: String in ["yaw_deg", "min_outer_width_m"]:
		assert_eq(on[key], base[key], "%s unchanged" % key)
	assert_true(bool(on.get("hide_slab", false)), "the square footing mesh is hidden; r3's landing carries the feet")
	assert_false(bool(on.skirt.enabled), "no skirt sheet")
	assert_false(base.has("hide_slab"), "the base dict is not mutated")
