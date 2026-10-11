extends "res://tests/test_case.gd"

## The Den/station panel never shows a raw host refusal code (coordinator
## 2026-10-11). Listed codes read as player text, other codes as the generic
## line, and sentences pass through unchanged.
const PANEL := preload("res://scripts/ui/craft_panel.gd")


func test_station_refusal_codes_read_as_player_text() -> void:
	var presentation: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/craft_presentation.json"))
	for code: String in ["already_groomed", "daily_care_cap"]:
		var text := PANEL.station_refusal_text(code, presentation)
		assert_eq(text, str(presentation.station_refusals[code]))
		assert_false(text.contains("_"), code + " reads as text")
	assert_eq(PANEL.station_refusal_text("owner_training_retry_refused", presentation), str(presentation.station_refusal_fallback))
	assert_eq(PANEL.station_refusal_text("Waiting for the original station transaction.", presentation),
		"Waiting for the original station transaction.")
