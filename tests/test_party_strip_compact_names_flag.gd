extends "res://tests/test_case.gd"

## F39#19 candidate: creature names on the fight roster's compact rows.
## OFF until a GPU verdict; with it off the compact strip is unchanged.
const PARTY_STRIP := preload("res://scripts/ui/party_strip.gd")


func test_flag_is_off_and_the_compact_strip_is_unchanged() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/combat_roster_visual.json"))
	var block: Dictionary = cfg["compact_names_1113"]
	assert_false(bool(block.get("enabled", true)))
	assert_true(float(block.get("row_width", 0.0)) > PARTY_STRIP.COMPACT_ROW_WIDTH, "the candidate widens the rows for a name")
	assert_false(PARTY_STRIP.compact_names_enabled())
	assert_eq(PARTY_STRIP.compact_row_width(), PARTY_STRIP.COMPACT_ROW_WIDTH)


func _with_names_on(body: Callable) -> void:
	var saved_cfg: Dictionary = PARTY_STRIP._compact_names_cfg
	var saved_loaded: bool = PARTY_STRIP._compact_names_loaded
	PARTY_STRIP._compact_names_cfg = {"enabled": true, "row_width": 348.0, "name_min_width": 160.0}
	PARTY_STRIP._compact_names_loaded = true
	body.call()
	PARTY_STRIP._compact_names_cfg = saved_cfg
	PARTY_STRIP._compact_names_loaded = saved_loaded


func test_off_the_camera_sees_the_strip_itself() -> void:
	var strip: Control = PARTY_STRIP.new()
	strip.set("compact", true)
	assert_true(strip.call("camera_footprint") == strip)
	strip.free()


func test_on_the_camera_keeps_the_old_compact_width() -> void:
	_with_names_on(func() -> void:
		var strip: Control = PARTY_STRIP.new()
		strip.set("compact", true)
		strip.size = Vector2(348.0, 400.0)
		var footprint: Control = strip.call("camera_footprint")
		assert_true(footprint != strip, "a separate footprint")
		assert_eq(footprint.size, Vector2(PARTY_STRIP.COMPACT_ROW_WIDTH, 400.0))
		assert_eq(footprint.position, Vector2.ZERO)
		strip.free())


func test_on_the_fight_roster_does_not_start_its_fade_when_unpinned() -> void:
	_with_names_on(func() -> void:
		var strip: Control = PARTY_STRIP.new()
		strip.set("compact", true)
		strip.call("set_pinned", false)
		assert_eq(float(strip.get("_fade_timer")), 0.0, "no fade countdown")
		strip.free())


func test_on_repeated_pin_calls_never_restart_the_reveal() -> void:
	_with_names_on(func() -> void:
		var strip: Control = PARTY_STRIP.new()
		strip.set("compact", true)
		strip.visible = true
		strip.modulate.a = 1.0
		for pinned: bool in [true, false, true, false]:
			strip.call("set_pinned", pinned)
			assert_eq(strip.modulate.a, 1.0, "a showing roster stays fully opaque")
			assert_eq(float(strip.get("_fade_timer")), 0.0)
		strip.free())
