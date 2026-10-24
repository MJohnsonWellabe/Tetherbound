extends "res://tests/test_case.gd"

## F17#6 GPU pass: the great hall's additive daylight shafts and arch rune rims
## are judged soft on Compatibility (CPU r9 6.84) but drew as hard white bars
## and neon rims on Forward+ (GPU 5.83). Compatibility keeps both at full
## weight; Forward+ and Mobile take the config's weaker weights.

const GREAT_HALL := preload("res://scripts/world/crossing_hall_great_hall.gd")
const CONFIG := "res://data/config/crossing_hall.json"


func test_compatibility_keeps_the_judged_shafts_and_rims() -> void:
	assert_eq(GREAT_HALL.renderer_scale({}, "gl_compatibility"), Vector2.ONE)
	var row := {"forward_plus_shaft_scale": 0.5, "forward_plus_arch_rim_scale": 0.2}
	assert_eq(GREAT_HALL.renderer_scale(row, "gl_compatibility"), Vector2.ONE)


func test_forward_plus_and_mobile_drop_the_shafts_and_dim_the_rims() -> void:
	assert_eq(GREAT_HALL.renderer_scale({}, "forward_plus"), Vector2(0.0, 0.35))
	assert_eq(GREAT_HALL.renderer_scale({}, "mobile"), Vector2(0.0, 0.35))
	var row := {"forward_plus_shaft_scale": 0.5, "forward_plus_arch_rim_scale": 0.2}
	assert_eq(GREAT_HALL.renderer_scale(row, "forward_plus"), Vector2(0.5, 0.2))


func test_shipping_config_turns_the_shafts_off_off_compatibility() -> void:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary)["hall_great_hall"]
	var weights := GREAT_HALL.renderer_scale(cfg, "forward_plus")
	assert_eq(weights.x, 0.0, "shafts are not built on Forward+")
	assert_true(weights.y > 0.0 and weights.y < 1.0, "arch rims stay, dimmed")
	assert_false((cfg.get("shafts", []) as Array).is_empty(), "the Compatibility shafts are still authored")
