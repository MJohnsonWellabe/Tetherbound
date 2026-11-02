extends "res://tests/test_case.gd"

## Group 3 (vis-meadows): meadows_look.json `light_candidate` overlays the
## Meadows look only when enabled. GPU-judged ON 2 Nov (CLOUD-JUDGE/MEADOWS-AB-1102,
## mapped Bar A 6.50 -> 6.71).

const LOOK := preload("res://scripts/world/meadows_look.gd")
const CONFIG := "res://data/config/meadows_look.json"


func test_candidate_ships_on_with_its_judged_score() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	assert_true(bool(cfg.light_candidate.get("enabled", false)), "light candidate ships ON after GPU judging")
	assert_true(str(cfg.light_candidate._why).contains("6.50 -> 6.71"), "the judged score is recorded with the flag")
	var base := {"sun": {"energy": 1.5}, "times": {"night": {"environment": {"ambient_energy": 1.5}}}}
	assert_eq(LOOK.light_candidate_look(base), LOOK.merged_look(base, cfg.light_candidate.look), "ON merges the candidate look")


func test_overlay_raises_night_fill_and_day_fog() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var look: Dictionary = cfg.light_candidate.look
	var base := {"sun": {"energy": 1.5, "pitch_deg": -38.0}, "environment": {"fog_density": 0.001},
		"times": {"night": {"environment": {"ambient_energy": 1.5, "exposure": 1.2}}}}
	var on := LOOK.merged_look(base, look)
	assert_true(float(on.environment.fog_density) > 0.001)
	assert_true(float(on.times.night.environment.ambient_energy) > 1.5)
	assert_eq(float(on.sun.pitch_deg), float(look.sun.pitch_deg))
