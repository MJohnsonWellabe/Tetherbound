extends "res://tests/test_case.gd"

## UI-R2 follow-up: menu.json `menu_text_floors` (scripts/ui/menu_text_floors.gd).
## Off by default and byte-for-byte the old sizes when off; on, secondary text
## sits on the UITokens floors in TEXT_SECONDARY and long control notes have a
## short twin.

const MENU_TEXT := preload("res://scripts/ui/menu_text_floors.gd")


func after_each() -> void:
	MENU_TEXT.reset_for_tests()


func test_the_flag_ships_off() -> void:
	MENU_TEXT.reset_for_tests()
	assert_false(MENU_TEXT.on(), "menu_text_floors must ship OFF until its GPU judging passes")


func test_off_keeps_every_authored_size() -> void:
	MENU_TEXT.reset_for_tests(false)
	assert_eq(MENU_TEXT.read_px(22), 22)
	assert_eq(MENU_TEXT.prompt_px(20), 20)
	var label := Label.new()
	MENU_TEXT.secondary(label, 20)
	assert_eq(label.get_theme_font_size("font_size"), 20)
	assert_false(label.has_theme_color_override("font_color"), "off must leave the tab's own colour")
	label.free()


func test_on_lifts_to_the_token_floors_and_keeps_larger_text() -> void:
	MENU_TEXT.reset_for_tests(true)
	assert_eq(MENU_TEXT.read_px(22), UITokens.FONT_READ)
	assert_eq(MENU_TEXT.prompt_px(24), UITokens.FONT_PROMPT)
	assert_eq(MENU_TEXT.read_px(40), 40, "larger authored text is never shrunk")
	var label := Label.new()
	MENU_TEXT.secondary(label, 20)
	assert_eq(label.get_theme_font_size("font_size"), UITokens.FONT_READ)
	assert_eq(label.get_theme_color("font_color"), UITokens.TEXT_SECONDARY)
	label.free()


func test_the_fighting_group_has_a_short_note() -> void:
	var menu: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/menu.json"))
	var group := _find_group(menu, "Fighting")
	assert_false(group.is_empty(), "menu.json must still carry the Fighting controls group")
	var compact := str(group.get("note_compact", ""))
	assert_false(compact.is_empty(), "Fighting needs a note_compact")
	assert_true(compact.length() * 2 < str(group.get("note", "")).length(),
		"the compact note must be well under half the full paragraph")


func _find_group(node: Variant, name: String) -> Dictionary:
	if node is Dictionary:
		if str((node as Dictionary).get("name", "")) == name and (node as Dictionary).has("actions"):
			return node as Dictionary
		for value: Variant in (node as Dictionary).values():
			var hit := _find_group(value, name)
			if not hit.is_empty():
				return hit
	elif node is Array:
		for value: Variant in node as Array:
			var hit := _find_group(value, name)
			if not hit.is_empty():
				return hit
	return {}
