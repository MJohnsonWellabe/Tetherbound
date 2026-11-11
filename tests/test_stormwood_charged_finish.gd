extends "res://tests/test_case.gd"

## VIS-STORMWOOD (5 Nov 2026), F41#13: creature_surface_finishes.charged_1105
## lifts Fulgocobra and Stormraven's accent glow and rim. Ships ON after GPU
## 1108 G-f41-13-charged (5.53 -> 6.14, 3/3); it only raises the two storm
## species' ordinary finishes.

func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/creature_surface_finishes.json"))


func test_charged_finish_ships_on_with_its_judged_score() -> void:
	assert_true(bool(_cfg().charged_1105.get("enabled", false)), "ships ON (GPU-judged gain)")
	assert_true(str(_cfg().charged_1105.get("_why_on", "")).contains("G-f41-13-charged"), "records its GPU round")


func test_charged_finish_lifts_only_the_storm_species() -> void:
	var cfg := _cfg()
	var rows: Dictionary = cfg.charged_1105.species
	assert_eq(rows.keys().size(), 2, "two storm species only")
	for species: String in rows:
		var base: Dictionary = cfg.species[species].ordinary
		assert_true(float(rows[species].accent_energy) > float(base.get("accent_energy", 0.0)), "%s glows brighter" % species)


## LANE-FLOOR2 (11 Nov 2026), G-floor2-storm-glow-lines (F41#13 +0.64, 3/3): the
## r2 Stormraven mask matched 94% of its feathers, so the whole body emitted
## ("a near-white ghost"). Both rows sit on the species' own accent mask at
## just above base energy; the glow maps carry the lines and eyes.
func test_charged_finish_glows_on_lines_not_the_whole_body() -> void:
	var cfg := _cfg()
	assert_true(str(cfg.charged_1105.get("_why_lines_1111", "")).contains("G-floor2-storm-glow-lines"), "records its GPU round")
	var rows: Dictionary = cfg.charged_1105.species
	var raven: Dictionary = rows.stormraven
	var raven_base: Dictionary = cfg.species.stormraven.ordinary
	assert_almost_eq(float(raven.accent_energy), 0.4, 0.0001)
	assert_almost_eq(float(raven.accent_value), 0.82, 0.0001)
	assert_almost_eq(float(raven.rim_amount), 0.25, 0.0001)
	assert_almost_eq(float(raven.accent_source_value), float(raven_base.accent_source_value), 0.0001, "the raven's own value mask")
	assert_almost_eq(float(raven.accent_source_saturation), float(raven_base.accent_source_saturation), 0.0001, "the raven's own saturation mask")
	var cobra: Dictionary = rows.fulgocobra
	var cobra_base: Dictionary = cfg.species.fulgocobra.ordinary
	assert_almost_eq(float(cobra.accent_energy), 0.46, 0.0001)
	assert_almost_eq(float(cobra.rim_amount), 0.3, 0.0001)
	assert_almost_eq(float(cobra.accent_source_value), float(cobra_base.accent_source_value), 0.0001, "the cobra's own value mask")
	for species: String in rows:
		assert_true(float(rows[species].accent_energy) < 1.0, "%s accent stays under bloom strength" % species)


func test_fulgocobra_vein_glow_ships_at_its_judged_strength() -> void:
	var flags: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/creature_coat_flags.json")).flags
	for flag: String in ["creatures_ralph_fulgocobra_goldvein", "lanekit_face_read_fulgocobra"]:
		assert_true(bool(flags[flag].enabled), "%s stays ON" % flag)
		assert_true(str(flags[flag].get("_why_emission_1111", "")).contains("G-floor2-storm-glow-lines"), "%s records its GPU round" % flag)
		for from_path: String in flags[flag].coats:
			assert_almost_eq(float(flags[flag].coats[from_path].emission_energy), 1.3, 0.0001, "%s vein glow" % flag)
