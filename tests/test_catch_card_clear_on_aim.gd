extends "res://tests/test_case.gd"

## F40#13 catch feedback (GPU High G-things-toys-ui, 12 Nov 2026: 6.88 -> 7.62,
## 3/3). hud.json catch_card.clear_on_aim_1112 takes a breakout card down as
## soon as the player enters aim (or releases the next orb), not on the next
## outcome tick. A success card and every other message keep their own hold.

const HUD := preload("res://scripts/ui/combat_hud.gd")


func _row() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	var card: Dictionary = (parsed as Dictionary).get("catch_card", {})
	return card.get("clear_on_aim_1112", {})


func test_clear_on_aim_ships_on_and_cites_the_verdict() -> void:
	var row := _row()
	assert_eq(row.get("enabled"), true)
	assert_eq(row.get("scope"), "client_presentation")
	assert_true(str(row.get("_why_on", "")).contains("G-things-toys-ui.md"), "cites its GPU verdict")
	assert_true(str(row.get("_why_on", "")).contains("6.88 -> 7.62"), "and its judged score")


func test_entering_aim_ends_a_breakout_card() -> void:
	var hud := HUD.new()
	hud._breakout_card_up = true
	hud._outcome_left = 1.8
	hud._catch_focus_left = 1.8
	hud._on_aim_entered()
	assert_eq(hud._outcome_left, 0.0)
	assert_eq(hud._catch_focus_left, 0.0)
	assert_false(hud._breakout_card_up)
	hud.free()


func test_entering_aim_keeps_a_success_card_and_other_messages() -> void:
	var hud := HUD.new()
	hud._breakout_card_up = false
	hud._outcome_left = 2.4
	hud._catch_focus_left = 2.4
	hud._on_aim_entered()
	assert_eq(hud._outcome_left, 2.4)
	assert_eq(hud._catch_focus_left, 2.4)
	hud.free()
