extends TestCase

const CAPTURE := preload("res://tools/gate_f/capture_four_biome_road_creatures.gd")


func test_launch_args_parse_out_and_only_as_independent_options() -> void:
	var parsed: Dictionary = CAPTURE.parse_launch_args([
		"--out=shots/diagnostics/road-forward-water/", "--only=WaTeR",
	])
	assert_eq(parsed.out_dir, "res://shots/diagnostics/road-forward-water")
	assert_eq(parsed.only_realm, "water")

	var reversed: Dictionary = CAPTURE.parse_launch_args([
		"--only=stormwood", "--out=res://shots/diagnostics/road-forward-stormwood",
	])
	assert_eq(reversed.out_dir, "res://shots/diagnostics/road-forward-stormwood")
	assert_eq(reversed.only_realm, "stormwood")


func test_launch_args_keep_defaults_when_options_are_absent() -> void:
	var parsed: Dictionary = CAPTURE.parse_launch_args([])
	assert_eq(parsed.out_dir, "res://shots/road-creatures")
	assert_eq(parsed.only_realm, "")
