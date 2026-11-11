extends "res://tests/test_case.gd"

## F40#11 and F40#6 soft cloud sea (GPU High, G-newapproach-cloud-sea-only:
## F40#11 6.17 -> 6.97, F40#6 5.61 -> 6.33): the deck sheets draw with the
## integer-hash cloud-sea material instead of the faceting deck shader.

const SHADER := "res://shaders/cloudreach_cloud_sea_soft.gdshader"


func test_soft_sea_ships_on_with_its_verdict() -> void:
	var sea: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/cloudreach_visual.json")) as Dictionary).cloud_sea.soft_sea
	assert_true(sea.get("enabled") == true, "soft_sea ships ON")
	var why := str(sea.get("_why_on", ""))
	assert_true(why.contains("6.17 -> 6.97"), "soft_sea records the F40#11 verdict")
	assert_true(why.contains("5.61 -> 6.33"), "soft_sea records the F40#6 verdict")


func test_the_sea_material_keeps_its_gpu_stable_noise() -> void:
	assert_true(ResourceLoader.exists(SHADER), "the cloud-sea shader is installed")
	var code := FileAccess.get_file_as_string(SHADER)
	assert_true(code.contains("float cell_hash(ivec2 cell)"), "the lattice hash is an integer hash")
	# The deck shader's sin hash is what drew the faceted floor on the judging GPU.
	assert_false(code.contains("fract(sin(dot("), "no sin-based hash call in the sea material")
	var world := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(world.contains("cloudreach_cloud_sea_soft.gdshader"), "the world builds the sea material")
