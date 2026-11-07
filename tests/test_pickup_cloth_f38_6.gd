extends "res://tests/test_case.gd"

## F38#6 (LANE-MS, 7 Nov): the rare-candy pickup ships its Blender cloth
## reskin (blue velvet); judged CPU 6.50 -> 6.76.

const VISUALS := preload("res://scripts/world/meshy_item_visuals.gd")


func test_rare_candy_cloth_reskin_ships_on_with_its_score() -> void:
	var spec: Dictionary = VISUALS.spec_for("rare_candy", "meadows")
	assert_true(str(spec.get("model", "")).ends_with("model_candy_rare_cloth_r1/candy_rare_cloth_r1.glb"))
	assert_true(str(spec.get("_why_on", "")).contains("6.50 -> 6.76"))
	assert_true(ResourceLoader.exists(str(spec.model)), "the reskin is imported")
	assert_eq(float(spec.get("height_m", 0.0)), 0.9, "same fitted size as the shipping model")
