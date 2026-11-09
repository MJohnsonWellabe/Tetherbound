extends "res://tests/test_case.gd"

## Stale breakout card (F40#13 GPU frame 2, 9 Nov: "Pebbik broke free" still
## up while the next throw shows "100% CAPTURE CHANCE"). A failed throw raises
## the "X broke free" card for catch_card.breakout_seconds; hud.json
## catch_card.clear_on_release_1107 ends a breakout card when the next orb is
## released. A success card and every other message keep their own hold.

const HUD := preload("res://scripts/ui/combat_hud.gd")


func _shipped_row() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	var card: Dictionary = (parsed as Dictionary).get("catch_card", {})
	return card.get("clear_on_release_1107", {})


func test_clear_on_release_ships_on() -> void:
	var row := _shipped_row()
	assert_eq(row.get("enabled"), true)
	assert_eq(row.get("scope"), "client_presentation")
	assert_true(str(row.get("_why_on", "")).length() > 0)


func test_release_ends_a_breakout_card() -> void:
	var hud := HUD.new()
	hud._breakout_card_up = true
	hud._outcome_left = 1.8
	hud._catch_focus_left = 1.8
	hud._on_orb_released()
	assert_eq(hud._outcome_left, 0.0)
	assert_eq(hud._catch_focus_left, 0.0)
	hud.free()


func test_release_keeps_a_success_card_and_other_messages() -> void:
	var hud := HUD.new()
	hud._breakout_card_up = false
	hud._outcome_left = 2.4
	hud._catch_focus_left = 2.4
	hud._on_orb_released()
	assert_eq(hud._outcome_left, 2.4)
	assert_eq(hud._catch_focus_left, 2.4)
	hud.free()
