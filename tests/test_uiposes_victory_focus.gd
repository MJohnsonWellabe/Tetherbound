extends "res://tests/test_case.gd"

## P2-103/P2-111 UIPOSES candidate: hud.json victory_focus ships OFF; when on,
## the listed persistent tiers yield while a Moment banner is up.

const HUD := preload("res://scripts/ui/playground_hud.gd")
const POLICY := preload("res://scripts/ui/hud_presentation_policy.gd")
const DELIVERY := preload("res://scripts/net/trainer_reward_delivery.gd")


func test_victory_focus_ships_on() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	assert_true(bool(parsed.victory_focus.enabled), "victory_focus ships ON (GPU 1108 section C, 5.61 -> 7.13, 3/3)")
	assert_true(DELIVERY.victory_receipt_routed(), "with victory_focus ON and route_trainer_receipts true, trainer receipts route to the victory Moment receipt")


func test_focus_hides_listed_tiers_only() -> void:
	var mode := POLICY.resolve("exploration", false, false, true)
	var focused := HUD.victory_focus_mode(mode, {"hide": ["hotbar", "party", "prompt", "exploration"]})
	for key: String in ["hotbar", "party", "prompt", "exploration"]:
		assert_true(bool(mode[key]), "%s is shown in plain exploration" % key)
		assert_false(bool(focused[key]), "%s yields to the victory moment" % key)
	assert_eq(focused.mode, mode.mode, "presentation mode itself is unchanged")
	assert_true(bool(mode.hotbar), "the policy's own result is not mutated")


func test_quiet_empty_slots_ships_off() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/hud.json"))
	assert_false(bool(parsed.quiet_empty_slots.enabled), "quiet_empty_slots defaults OFF")
	assert_true(float(parsed.quiet_empty_slots.glyph_alpha) > 0.0, "empty bindings stay visible")
