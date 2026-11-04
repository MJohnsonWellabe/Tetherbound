extends "res://tests/test_case.gd"

## VIS-MEADOWS (4 Nov 2026): Meadows arms that a CPU code-blind A/B judged as a
## gain ship ON (owner 4 Nov: "If it's an improvement move it to main").
## Each ON flag carries its CPU score in `_why_on`.
## Verdict: ralph/reports/LANES/VIS-MEADOWS/r1a/VERDICT.md.


func _load(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, path + " parses")
	return parsed if parsed is Dictionary else {}


func _cluster(path: String, name: String) -> Dictionary:
	for cluster: Variant in _load(path).get("clusters", []):
		if cluster is Dictionary and str((cluster as Dictionary).get("name", "")) == name:
			return cluster
	return {}


func test_f38_20_stronghold_arms_ship_on_with_their_cpu_score() -> void:
	var stronghold := _load("res://data/config/stronghold.json")
	var keep: Dictionary = stronghold.get("p2_003_candidate", {})
	assert_true(bool(keep.get("enabled", false)), "P2-003 keep candidate ON")
	assert_true(str(keep.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "keep carries its CPU score")
	assert_true(bool((stronghold.get("approach_pylons", {}) as Dictionary).get("p2_003_unlit_candidate_enabled", false)),
		"P2-003 unlit approach pylons ON")
	var courtyard := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "wd_stronghold_courtyard")
	var candidate: Dictionary = courtyard.get("candidate", {})
	assert_true(bool(candidate.get("enabled", false)), "courtyard dressing ON")
	assert_true(str(candidate.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "courtyard carries its CPU score")


func test_f38_22_mill_and_settlement_arms_ship_on_with_their_cpu_score() -> void:
	var clearings: Dictionary = _load("res://data/config/meadows_hero_pieces.json").get("clearings_wd", {})
	assert_true(bool(clearings.get("enabled", false)), "trail-camp clearings ON")
	assert_true(str(clearings.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "clearings carries its CPU score")
	var seat := _load("res://data/config/meadows_doorstep_seat.json")
	assert_true(bool(seat.get("doorstep_seat_enabled", false)), "doorstep seat ON")
	assert_true(str(seat.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "doorstep seat carries its CPU score")
	var market := _cluster("res://data/config/bands/band1_lower_meadows/props.json", "wd_village_market")
	var candidate: Dictionary = market.get("candidate", {})
	assert_true(bool(candidate.get("enabled", false)), "village market ON")
	assert_true(str(candidate.get("_why_on", "")).contains("CPU 5.67 -> 6.38"), "market carries its CPU score")
