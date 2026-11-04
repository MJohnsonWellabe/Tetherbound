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


func test_f38_13_catch_arms_ship_on_with_their_cpu_score() -> void:
	var framed: Dictionary = _load("res://data/config/catching.json").get("framed_camera", {})
	assert_true(bool(framed.get("enabled", false)), "framed catch camera ON")
	var r2: Dictionary = framed.get("r2", {})
	assert_true(bool(r2.get("enabled", false)), "framed_camera r2 (oblique behind-trainer resolve) ON")
	assert_true(str(r2.get("_why_on", "")).contains("CPU 6.22 -> 7.19"), "r2 carries its CPU score")
	var orb: Dictionary = _load("res://data/config/camfx.json").get("catch_orb", {})
	assert_true(bool(orb.get("enabled", false)), "physical catch orb ON")
	var card: Dictionary = _load("res://data/config/hud.json").get("catch_card", {})
	assert_true(bool(card.get("enabled", false)), "catch result card ON")


func test_f38_20_yard_fill_reaches_the_whole_courtyard_with_its_score() -> void:
	var day: Dictionary = _load("res://data/config/stronghold.json").get("courtyard_daylight_candidate", {})
	assert_true(bool(day.get("enabled", false)), "courtyard daylight ON")
	var light: Dictionary = day.get("light", {})
	assert_true(float(light.get("range", 0.0)) >= 52.0, "the fill reaches the courtyard entrance")
	assert_true(float(light.get("attenuation", 1.0)) <= 0.22, "an even pool, not a steep peak")
	assert_true(str(day.get("_why_r3_yard_fill", "")).contains("CPU 4.71 -> 5.73"), "r3 records its CPU score")


func test_f38_20_keep_keeps_its_value_through_the_fog_with_its_score() -> void:
	var keep: Dictionary = (_load("res://data/config/stronghold.json").get("p2_003_candidate", {}) as Dictionary).get("keep", {})
	assert_true(bool(keep.get("fog_disable", false)), "the keep resists the depth fog")
	assert_eq(str(keep.get("albedo_tint", "")), "#b3ab9c", "lifted stone so it reads as shaded stone, not a black cut-out")
	assert_true(str(keep.get("_why_r4_fog", "")).contains("CPU 5.22 -> 5.70"), "r4 records its CPU score")
	var gate: Dictionary = preload("res://scripts/world/stronghold.gd").p2_003_gatehouse(_load("res://data/config/stronghold.json"))
	assert_true(bool(gate.get("fog_disable", false)), "the shipped gatehouse carries fog_disable")


func test_f38_20_courtyard_centre_dressing_ships_on_with_its_score() -> void:
	var centre := _cluster("res://data/config/bands/band5_stronghold_approach/props.json", "vm_stronghold_courtyard_centre")
	var candidate: Dictionary = centre.get("candidate", {})
	assert_true(bool(candidate.get("enabled", false)), "courtyard centre dressing ON")
	assert_true(str(candidate.get("_why_on", "")).contains("CPU 5.51 -> 5.75"), "records its CPU score")
	for prop: Variant in centre.get("props", []):
		assert_true(bool((prop as Dictionary).get("visual_only", false)), "visual only, so routes and NPC paths are unchanged")
		var x := float(((prop as Dictionary).get("at", [0, 0]) as Array)[0])
		assert_true(x < 6.5 or x > 9.5 or str((prop as Dictionary).get("model", "")) == "Torch_Metal", "the walking lane (x 6.5-9.5) stays clear")
