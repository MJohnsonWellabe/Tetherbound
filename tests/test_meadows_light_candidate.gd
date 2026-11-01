extends "res://tests/test_case.gd"

## Group 3 (vis-meadows, OFF until GPU-judged): meadows_look.json
## `light_candidate` overlays the Meadows look only when enabled.

const LOOK := preload("res://scripts/world/meadows_look.gd")
const CONFIG := "res://data/config/meadows_look.json"


func test_candidate_ships_off_and_off_returns_base() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_false(bool(cfg.light_candidate.get("enabled", true)), "light candidate ships OFF")
	var base := {"sun": {"energy": 1.5}, "times": {"night": {"environment": {"ambient_energy": 1.5}}}}
	assert_eq(LOOK.light_candidate_look(base), base)


func test_overlay_raises_night_fill_and_day_fog() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var look: Dictionary = cfg.light_candidate.look
	var base := {"sun": {"energy": 1.5, "pitch_deg": -38.0}, "environment": {"fog_density": 0.001},
		"times": {"night": {"environment": {"ambient_energy": 1.5, "exposure": 1.2}}}}
	var on := LOOK.merged_look(base, look)
	assert_true(float(on.environment.fog_density) > 0.001)
	assert_true(float(on.times.night.environment.ambient_energy) > 1.5)
	assert_eq(float(on.sun.pitch_deg), float(look.sun.pitch_deg))
