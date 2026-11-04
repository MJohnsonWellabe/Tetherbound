extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#2: presentation.building_glow_1104 gives the
## Building phase in-cloud sheet lightning. Ships OFF; ON changes only
## Building's presentation keys and never turns on strike `flashes`.

const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")


func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(RULES.PATH))


func test_building_glow_ships_off() -> void:
	assert_false(bool(_cfg().presentation.building_glow_1104.get("enabled", true)), "ships OFF until judged")


func test_building_glow_on_only_lifts_building_sheet_glow() -> void:
	var off := RULES.with_presentation_candidates(_cfg())
	var cfg := _cfg()
	cfg.presentation.building_glow_1104["enabled"] = true
	var on := RULES.with_presentation_candidates(cfg)
	var b_off: Dictionary = off.presentation.phases.building
	var b_on: Dictionary = on.presentation.phases.building
	assert_true(float(b_on.sheet_glow) > float(b_off.sheet_glow), "Building carries more sheet lightning")
	assert_false(bool(b_on.get("flashes", false)), "strike flashes stay Break-only")
	assert_eq(on.presentation.phases.calm, off.presentation.phases.calm, "Calm is unchanged")
	assert_eq(on.presentation.phases.break, off.presentation.phases.break, "Break is unchanged")


## r2: Building lowers the glow's sky edge; every other phase keeps the
## default 0.14 (unset), so their skies are unchanged.
func test_building_glow_r2_lowers_only_building_glow_edge() -> void:
	var cfg := _cfg()
	cfg.presentation.building_glow_1104["enabled"] = true
	var on := RULES.with_presentation_candidates(cfg)
	assert_true(float(on.presentation.phases.building.get("glow_low", 0.14)) < 0.14, "Building glow reaches lower sky")
	for phase: String in ["calm", "break", "fading"]:
		assert_false((on.presentation.phases[phase] as Dictionary).has("glow_low"), "%s keeps the default edge" % phase)
