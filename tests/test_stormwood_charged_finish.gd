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
