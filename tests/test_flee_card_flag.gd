extends "res://tests/test_case.gd"
## F41#16: hud.json `flee_card_1114` frames the flee verdict as a result card.

const HUD := preload("res://scripts/ui/combat_hud.gd")

class Ally extends RefCounted:
	var display_name := "Sparkit"

class Manager extends Node:
	var _enemy_owned := false
	var ally: RefCounted = Ally.new()
	func active_creature() -> RefCounted: return ally


func _cfg() -> Dictionary:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	var cfg: Dictionary = parsed["flee_card_1114"].duplicate(true)
	cfg["enabled"] = true
	return cfg


func _hud() -> Array:
	var hud := HUD.new()
	var manager := Manager.new()
	hud._manager = manager
	var outcome := Label.new()
	hud._outcome = outcome
	hud._xp_line = Label.new()
	hud._go_text = Label.new()
	hud._prompt = RichTextLabel.new()
	return [hud, manager, outcome]


func _free(parts: Array) -> void:
	var hud: Node = parts[0]
	for node: Node in [hud._xp_line, hud._go_text, hud._prompt, parts[2], parts[1], hud]:
		node.free()


func test_flag_ships_off_and_flee_keeps_the_plain_line() -> void:
	assert_true(HUD.flee_card_config().is_empty(), "flee_card_1114 stays OFF until judged")
	var parts := _hud()
	parts[0]._on_exited("fled")
	assert_eq((parts[2] as Label).text, "You backed off.")
	assert_false(parts[0]._flee_card_up)
	_free(parts)


func test_card_names_the_creature_that_got_clear() -> void:
	var cfg := _cfg()
	var text := HUD.flee_card_text(cfg, "Sparkit")
	assert_true(text.begins_with(str(cfg["headline"]) + "\n"))
	assert_true(text.contains("Sparkit got clear"))
	assert_true(HUD.flee_card_text(cfg, "").ends_with(str(cfg["detail_generic"])))


func test_on_card_is_framed_large_in_the_upper_third_and_holds() -> void:
	var cfg := _cfg()
	var parts := _hud()
	var hud: Node = parts[0]
	var outcome: Label = parts[2]
	var before := Vector2(outcome.offset_left, outcome.offset_right)
	hud._on_exited("fled")
	hud._show_flee_card(cfg)
	assert_true(outcome.text.contains("Sparkit got clear"))
	assert_true(outcome.has_theme_stylebox_override("normal"), "the verdict draws on a framed plate")
	assert_eq(outcome.get_theme_font_size("font_size"), int(cfg["headline_px"]))
	assert_eq(outcome.offset_top, float(cfg["card_top"]))
	assert_eq(outcome.offset_right - outcome.offset_left, 2.0 * float(cfg["card_half_width"]))
	assert_true(hud._outcome_left >= float(cfg["seconds"]))
	assert_true(hud._flee_card_up, "the recall line stands down while the card holds")
	hud._outcome_left = 0.0
	hud._tick_outcome(0.1)
	assert_false(hud._flee_card_up)
	assert_false(outcome.has_theme_stylebox_override("normal"))
	assert_eq(Vector2(outcome.offset_left, outcome.offset_right), before, "band restored after the card")
	_free(parts)
