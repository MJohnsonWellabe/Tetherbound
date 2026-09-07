extends "res://tests/test_case.gd"

## Pure policy coverage only. Runtime weather, strike presentation, persistence,
## and damage delivery need their own scene/host evidence.
const SURGE := preload("res://scripts/world/stormwood_surge_rules.gd")
const CHAPTER_CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

var rules: RefCounted


func before_each() -> void:
	rules = SURGE.new()


func test_cycle_boundaries_and_rod_aftermath_timing() -> void:
	for sample: Dictionary in [
		{"at": 0.0, "phase": "calm"}, {"at": 239.99, "phase": "calm"},
		{"at": 240.0, "phase": "building"}, {"at": 329.99, "phase": "building"},
		{"at": 330.0, "phase": "break"}, {"at": 449.99, "phase": "break"},
		{"at": 450.0, "phase": "fading"}, {"at": 509.99, "phase": "fading"},
		{"at": 510.0, "phase": "calm"},
	]:
		assert_eq(str(rules.phase_at(float(sample.at), "conductor_run").phase), str(sample.phase))
	var normal: Dictionary = rules.phase_at(0.0, "deepwood")
	var disabled: Dictionary = rules.phase_at(0.0, "deepwood", true)
	assert_true(float(disabled.duration) > float(normal.duration), "disabled rod lengthens Calm")
	var normal_break: Dictionary = rules.phase_at(330.0, "deepwood")
	var disabled_break: Dictionary = rules.phase_at(float(disabled.duration) + 90.0, "deepwood", true)
	assert_true(float(disabled_break.duration) < float(normal_break.duration), "disabled rod shortens Break")
	var aftermath_calm: Dictionary = rules.phase_at(0.0, "deepwood", false, true)
	var aftermath_break: Dictionary = rules.phase_at(float(aftermath_calm.duration) + 45.0, "deepwood", false, true)
	assert_true(float(aftermath_calm.duration) > float(normal.duration) and float(aftermath_break.duration) < float(normal_break.duration),
		"aftermath is mostly Calm with rare Breaks")


func test_shelter_and_gentle_ground_policy() -> void:
	for region: String in ["cinder_verge", "glowmoss_hollows"]:
		assert_false(rules.eligible_ground(Vector3(9000, 0, 9000), region, false),
			"gentle regions only strike marked clearings")
	assert_true(rules.eligible_ground(Vector3(-610, 0, 755), "cinder_verge", false))
	assert_true(rules.sheltered(Vector3.ZERO, "hollow_crown", false), "Crown is always safe")
	assert_true(rules.sheltered(Vector3(-160, 0, 2700), "conductor_run", false), "Still Grove is safe")
	for zone: Dictionary in rules.config.safe_zones:
		var at := Vector3(float(zone.at[0]), 0, float(zone.at[1]))
		assert_true(rules.sheltered(at, "deepwood", false), "%s is surge-safe" % str(zone.id))
	assert_true(rules.sheltered(Vector3(12, 0, 0), "deepwood", false, [Vector3.ZERO]), "rod protects its full 12m radius")
	assert_false(rules.sheltered(Vector3(12.01, 0, 0), "deepwood", false, [Vector3.ZERO]))
	assert_true(rules.sheltered(Vector3(999, 0, 999), "deepwood", true), "canopy is safe")


func test_insulation_charge_windows_and_nonlethal_entry_hp() -> void:
	var bare: Dictionary = rules.strike_effect("dynamo", 1000.0, 0)
	var partial: Dictionary = rules.strike_effect("dynamo", 1000.0, 2)
	var full: Dictionary = rules.strike_effect("dynamo", 1000.0, 4)
	assert_true(float(bare.damage) > float(partial.damage) and float(partial.damage) > 0.0,
		"lower insulation is graded")
	assert_eq(float(full.damage), 0.0)
	assert_eq(float(full.static_seconds), 0.0)
	assert_true(bool(full.stagger), "full insulation leaves the stagger")
	assert_false(rules.charged_nodes_open("calm"))
	assert_false(rules.charged_nodes_open("building"))
	assert_true(rules.charged_nodes_open("break"))
	assert_true(rules.charged_nodes_open("fading"))
	for sample: Dictionary in _stormwood_entry_samples():
		var creature: RefCounted = CREATURE.from_species(str(sample.species), SPECIES.definition(str(sample.species)))
		creature.set_level(int(sample.level), PROGRESSION.config())
		var effect: Dictionary = rules.strike_effect(str(sample.region), float(creature.max_hp), 0)
		assert_true(float(effect.damage) < float(creature.max_hp),
			"%s strike is below full %s HP at entry level %d" % [sample.region, sample.species, int(sample.level)])


func _stormwood_entry_samples() -> Array[Dictionary]:
	# §16 entry levels, read through the chapter-curve interface rather than a
	# hand-computed HP table; creature HP remains the shipped species calculation.
	var curve := {"regions": [
		{"z_to": 1.0, "team": {"enter": 33}}, {"z_to": 2.0, "team": {"enter": 35}},
		{"z_to": 3.0, "team": {"enter": 37}}, {"z_to": 4.0, "team": {"enter": 39}},
		{"z_to": 5.0, "team": {"enter": 40}}, {"z_to": 6.0, "team": {"enter": 42}},
	]}
	var ids := ["cinder_verge", "glowmoss_hollows", "conductor_run", "hollow_crown", "deepwood", "dynamo"]
	var species := ["sparkit", "bramblebun", "stormtrail", "mosshell", "tuskroot", "galecrest"]
	var samples: Array[Dictionary] = []
	for i in ids.size():
		var team := CHAPTER_CURVE.team_band_at(float(i), curve)
		samples.append({"region": ids[i], "species": species[i], "level": int(team[0])})
	return samples
