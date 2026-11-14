extends "res://tests/test_case.gd"

## F40#17 `master_floor_1114` (LANE-LAND-CS): OFF until judged. On, Master arena
## floors take a longer soil tile and a muted tint; the shader default keeps the
## shipped 0.48 tile for every other worn-ground yard.


func test_ships_off_with_values() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var block: Dictionary = cfg.master_floor_1114
	assert_false(bool(block.get("enabled", true)), "master_floor_1114 ships OFF until judged")
	assert_true(float(block.soil_scale) < 0.48, "a longer tile than the shipped 0.48 per metre")
	var tint := Color(str(block.soil_tint))
	assert_true(tint.s < Color("#9b805f").s, "a less saturated earth than the shipped tint")
	assert_true(tint.r - tint.g < 0.1, "no red or orange lean")


func test_shader_default_is_the_shipped_tile() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/cloudreach_worn_ground.gdshader")
	assert_true(code.contains("uniform float soil_scale=0.48;"), "default tile unchanged")
	assert_false(code.contains("world_at.xz*0.48"), "the tile is read from the uniform")
	var world := FileAccess.get_file_as_string("res://scripts/world/cloudreach_world.gd")
	assert_true(world.contains("_visual_config.get(\"master_floor_1114\""), "applied in dress_master_site only")
