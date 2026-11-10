extends "res://tests/test_case.gd"

## F38#27 (LANE-MESHY): `controls_scan.readability_1110` in menu.json. OFF
## until judged; when on, rows sit on opaque bands and binding cells read as
## filled, bordered buttons with near-white text.

const TAB := preload("res://scripts/ui/tab_settings.gd")


func _menu() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/menu.json"))


func test_arm_declared_off_with_readable_values() -> void:
	var read: Dictionary = _menu().controls_scan.readability_1110
	assert_false(bool(read.get("enabled", true)), "OFF until judged")
	assert_true(Color(str(read.cell_fill)).get_luminance() < 0.35, "cell fill stays a dark button")
	assert_true(Color(str(read.header_colour)).get_luminance() > 0.75, "headers near-white, not grey")
	assert_true(Color(str(read.note_colour)).get_luminance() > 0.75, "notes near-white, not grey")
	for key: String in ["cell_fill", "cell_border", "band_odd", "band_even", "header_colour", "note_colour"]:
		var c := Color(str(read[key]))
		assert_false(c.r > c.g + 0.2 and c.r > c.b + 0.2, "%s is not red" % key)


func test_readability_reads_only_when_enabled() -> void:
	var tab: Node = TAB.new()
	tab.set("_controls_scan", {"readability_1110": {"enabled": false, "cell_font_px": 30}})
	assert_true((tab.call("_readability") as Dictionary).is_empty(), "off: no readability styling")
	tab.set("_controls_scan", {"readability_1110": {"enabled": true, "cell_font_px": 30}})
	assert_eq(int((tab.call("_readability") as Dictionary).get("cell_font_px", 0)), 30, "on: its values")
	var box: StyleBoxFlat = tab.call("_readable_cell_style", {"cell_fill": "#24404a", "cell_border": "#4e7480", "cell_border_px": 1})
	assert_eq(box.border_width_left, 1, "bordered cell")
	tab.free()


## F38#27 close-out: keycap chips stand alone (no "[1] 1"), the shortened
## reset legend ships, and the losing readability arm stays OFF.
func test_keyboard_chip_only_ships_on_and_readability_stays_off() -> void:
	var scan: Dictionary = _menu().controls_scan
	assert_true(scan.get("keyboard_chip_only") == true, "keycap chips stand alone")
	assert_false(bool(scan.readability_1110.get("enabled", true)), "readability_1110 judged -0.13, OFF")
	var source := FileAccess.get_file_as_string("res://scripts/ui/tab_settings.gd")
	assert_true(source.contains("for 1.5 s: reset all controls"), "shortened reset legend")
	assert_false(source.contains("for a second and a half: reset every control"), "long legend gone")
