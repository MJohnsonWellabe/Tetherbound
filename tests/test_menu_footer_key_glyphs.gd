extends "res://tests/test_case.gd"

## F38#27: keyboard tab keys in the menu footer draw as keycap glyphs when one
## is installed, and fall back to the bracketed key name otherwise.

const GLYPH := preload("res://scripts/ui/input_glyph.gd")


func test_installed_keycaps_draw_as_images() -> void:
	for action: String in ["menu_tab_left", "menu_tab_right"]:
		var text := GLYPH.key_glyph_for_action(action, 40)
		var name := GLYPH.key_name_for_action(action)
		if ResourceLoader.exists(GLYPH.DIR + "keyboard_%s.png" % name.to_lower()):
			assert_true(text.begins_with("[img=40x40]"), "%s (%s) draws a keycap" % [action, name])
		else:
			assert_eq(text, "[%s]" % name)


func test_tab_keycap_is_installed() -> void:
	assert_true(ResourceLoader.exists(GLYPH.DIR + "keyboard_tab.png"), "the Tab keycap ships with the prompts")


func test_unknown_action_falls_back_to_text() -> void:
	assert_eq(GLYPH.key_glyph_for_action("no_such_action_xyz", 40), "[no_such_action_xyz]")
