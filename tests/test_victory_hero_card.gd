extends "res://tests/test_case.gd"

## F39#21 / F41#21 hero beat: hud.json victory_focus.hero_card centres and
## enlarges the victory receipt plate (playground_hud.gd hero_card_rect).

const HUD := preload("res://scripts/ui/playground_hud.gd")


func _focus() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	return (parsed as Dictionary).get("victory_focus", {})


func test_hero_card_is_declared_and_needs_victory_focus() -> void:
	var hero: Dictionary = _focus().get("hero_card", {})
	assert_true(hero.has("enabled"), "hero_card declares its flag")
	assert_false(HUD.hero_card_enabled({}), "no hero beat without victory_focus")
	assert_true(HUD.hero_card_enabled({"enabled": true, "hero_card": {"enabled": true}}))
	assert_false(HUD.hero_card_enabled({"enabled": true, "hero_card": {"enabled": false}}))


func test_hero_rect_is_centred_in_the_upper_third_at_both_capture_sizes() -> void:
	var hero: Dictionary = _focus().get("hero_card", {})
	for canvas: Vector2 in [Vector2(1920, 1080), Vector2(1280, 720), Vector2(1280, 800)]:
		var rect: Rect2 = HUD.hero_card_rect(canvas, hero)
		assert_true(absf(rect.get_center().x - canvas.x * 0.5) < 1.0, "centred at %s" % canvas)
		assert_true(rect.size.x >= canvas.x * 0.4, "large enough to read as a beat at %s" % canvas)
		assert_true(rect.position.y >= 0.0 and rect.end.y <= canvas.y * 0.45, "upper part of the screen at %s" % canvas)
		assert_true(rect.position.x >= canvas.x * 0.05, "inside the safe area at %s" % canvas)


func test_hero_rect_clamps_bad_config() -> void:
	var rect: Rect2 = HUD.hero_card_rect(Vector2(1920, 1080), {"width_fraction": 5.0, "top_fraction": -1.0})
	assert_true(rect.size.x <= 1920 * 0.9 + 0.01)
	assert_true(rect.position.y >= 0.0)
