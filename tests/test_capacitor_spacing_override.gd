extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#3 P2-092: the capacitor_alpha named
## spacing override ships OFF; ON it gives only that fight the rendered-box
## footprint and swept correction, and every other pair keeps the defaults.

const SPACING := preload("res://scripts/combat/contact_spacing.gd")


func test_capacitor_override_ships_off_and_applies_only_to_its_fight() -> void:
	var cfg := SPACING.config().duplicate(true)
	var profile: Dictionary = cfg.named_overrides.capacitor_alpha
	assert_false(bool(profile.get("enabled", true)), "ships OFF until judged")
	var foe := Node.new()
	foe.set_meta("stormwood_named_encounter", "capacitor_alpha")
	var ally := Node.new()
	assert_eq(SPACING.config_for_pair(ally, foe, cfg), cfg, "OFF keeps the global spacing")
	profile["enabled"] = true
	var on := SPACING.config_for_pair(ally, foe, cfg)
	assert_eq(str(on.footprint_shape), "render_box", "ON uses the rendered box")
	assert_almost_eq(float(on.push_speed_mps), 28.0, 0.001, "ON uses the swept correction")
	var other := Node.new()
	other.set_meta("stormwood_named_encounter", "crown_guardian")
	assert_eq(SPACING.config_for_pair(ally, other, cfg), cfg, "another fight keeps the defaults")
	for node: Node in [foe, ally, other]:
		node.free()
