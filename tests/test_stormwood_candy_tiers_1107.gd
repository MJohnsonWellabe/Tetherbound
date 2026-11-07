extends "res://tests/test_case.gd"

## F41#14 (LANE-SW, 7 Nov 2026): per-tier Blender candy bodies for Stormwood.
## Ships OFF until judged; each tier builds its own mesh, and rarer candy is
## always fitted taller than the grade below it from the same body footprint.

const TIERS := preload("res://scripts/world/stormwood_candy_tiers.gd")


func test_tiers_ship_off() -> void:
	var cfg := TIERS.config()
	assert_false(cfg.is_empty(), "stormwood_candy_tiers_1107.json is declared")
	assert_false(bool(cfg.get("enabled", true)), "ships OFF until judged")


func test_rarer_candy_is_fitted_bigger_with_its_own_materials() -> void:
	var items: Dictionary = TIERS.config().get("items", {})
	var fit := AABB(Vector3(-0.5, 0.0, -0.3), Vector3(1.0, 0.6, 0.6))
	var heights: Array[float] = []
	for item: String in ["good_candy", "great_candy", "rare_candy"]:
		var tier: Dictionary = items.get(item, {})
		var built := TIERS.tier_mesh(str(tier.get("model", "")), fit, float(tier.get("height_mult", 1.0)))
		assert_true(built != null, "%s body builds" % item)
		if built == null:
			return
		assert_true(built.get_surface_count() >= 2, "%s keeps its body and wrapper surfaces" % item)
		var box := built.get_aabb()
		assert_almost_eq(box.position.y, 0.0, 0.001, "%s sits on the old body's base" % item)
		heights.append(box.size.y)
	assert_true(heights[0] < heights[1] and heights[1] < heights[2], "rarer reads bigger: %s" % str(heights))
	assert_true(float(items.rare_candy.get("glow_scale", 1.0)) < 1.0, "Rare's glow is reduced so it cannot bloom")
