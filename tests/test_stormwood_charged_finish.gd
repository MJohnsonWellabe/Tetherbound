extends "res://tests/test_case.gd"

## VIS-STORMWOOD (5 Nov 2026), F41#13: creature_surface_finishes.charged_1105
## lifts Fulgocobra and Stormraven's accent glow and rim. Ships OFF; ON it
## only raises the two storm species' ordinary finishes.

func _cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/creature_surface_finishes.json"))


func test_charged_finish_ships_off() -> void:
	assert_false(bool(_cfg().charged_1105.get("enabled", true)), "ships OFF until judged")


func test_charged_finish_lifts_only_the_storm_species() -> void:
	var cfg := _cfg()
	var rows: Dictionary = cfg.charged_1105.species
	assert_eq(rows.keys().size(), 2, "two storm species only")
	for species: String in rows:
		var base: Dictionary = cfg.species[species].ordinary
		assert_true(float(rows[species].accent_energy) > float(base.get("accent_energy", 0.0)), "%s glows brighter" % species)
