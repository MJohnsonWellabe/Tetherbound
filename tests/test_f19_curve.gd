extends "res://tests/test_case.gd"

## F19#1: pin the inactive RD-10 authoring candidate separately from the live
## legacy providers. No candidate assertion grants earning or activation credit.
const CURVE := preload("res://scripts/creatures/chapter_curve.gd")
const ORDER := preload("res://scripts/data/biome_order.gd")
const BANDS := preload("res://scripts/data/band_content.gd")
const STORM := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const HEARTS := preload("res://autoload/realm_heart_state.gd")
const POLICY := preload("res://scripts/creatures/level_curve_policy.gd")


func _view(path: String, base: Dictionary) -> Dictionary:
	var authored := POLICY.config()
	assert_eq(authored.get("runtime_enabled"), false)
	if not (authored.get("overlays", {}) as Dictionary).has(path.trim_prefix("res://")):
		return base
	authored["runtime_enabled"] = true
	var next := POLICY.apply(path, base, true, authored)
	assert_false(next.is_empty(), "candidate refuses stale identity or level: " + path)
	return next


func _curve() -> Dictionary:
	return _view(CURVE.CONFIG_PATH, CURVE.config())


func _read(name: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/%s.json" % name))
	assert_true(parsed is Dictionary, name)
	return _view("res://data/config/%s.json" % name, parsed as Dictionary) if parsed is Dictionary else {}


func _levels(team: Array) -> Array:
	var out: Array = []
	for member: Dictionary in team:
		out.append(int(member.get("level", 0)))
	return out


## JSON numbers are floats in Godot. Compare exact integral values without
## truncating a fractional or malformed authored bound into a passing level.
func _assert_band(actual: Variant, expected: Array, context: String = "") -> void:
	assert_true(actual is Array, context)
	if not actual is Array:
		return
	assert_eq(actual.size(), expected.size(), context)
	if actual.size() != expected.size():
		return
	for index in expected.size():
		var value: Variant = actual[index]
		assert_true(value is int or value is float, context)
		if not (value is int or value is float):
			continue
		assert_true(is_finite(float(value)) and float(value) == floorf(float(value)), context)
		assert_eq(float(value), float(expected[index]), context)


func test_exact_four_biome_bands_and_advisory_levels() -> void:
	assert_eq(ORDER.ids(false), ["meadows", "tidewake", "cloudreach", "stormwood"])
	var expected: Dictionary = {
		"meadows": [[3, 22], [2, 20], [21, 22]],
		"tidewake": [[20, 33], [18, 32], [32, 33]],
		"cloudreach": [[31, 44], [29, 43], [43, 44]],
		"stormwood": [[42, 55], [40, 54], [54, 55]],
	}
	var biomes: Dictionary = _curve().get("biomes", {})
	for id: String in expected:
		var row: Dictionary = biomes.get(id, {})
		var bands: Array = expected[id]
		_assert_band(row.get("team", []), bands[0], id + " team")
		_assert_band(row.get("wild", []), bands[1], id + " wild")
		_assert_band(row.get("boss", []), bands[2], id + " boss")
		assert_eq(int(row.get("recommended_level", 0)), int(bands[0][0]), id + " sign recommendation")


func test_meadows_resolver_uses_authored_bounds_and_finishes_at_22() -> void:
	var cfg: Dictionary = _curve()
	var regions: Array = CURVE.regions(cfg)
	var start_z := 0.0
	for region: Dictionary in regions:
		assert_eq(CURVE.wild_band_at(start_z, cfg), region.get("wild_band", []), str(region.id))
		assert_eq(CURVE.team_band_at(start_z, cfg), [int(region.team.enter), int(region.team.exit)], str(region.id))
		start_z = float(region.z_to)
	assert_eq(CURVE.team_band_at(7400.0, cfg), [18, 22])
	_assert_band(CURVE.wild_band_at(7400.0, cfg), [16, 20])


func test_candidate_finale_teams_pin_each_authored_envelope() -> void:
	var warden_found := false
	var trainers: Array = []
	for band: String in BANDS.BANDS:
		trainers.append_array(_read("bands/%s/trainers" % band).get("trainers", []))
	for trainer: Dictionary in trainers:
		if str(trainer.get("id", "")) == "warden_aldis":
			warden_found = true
			assert_eq(_levels(trainer.get("team", [])), [21, 21, 21, 22, 22])
	assert_true(warden_found)
	var marrow_found := false
	for trainer: Dictionary in _read("stormwood_trainers").get("trainers", []):
		if str(trainer.get("id", "")) == "captain_marrow_dynamo_core":
			marrow_found = true
			assert_eq(_levels(trainer.get("party", [])), [54, 54, 54, 55, 55])
	assert_true(marrow_found)
	var nerissa_found := false
	for trainer: Dictionary in _read("water_characters").get("trainers", []):
		if str(trainer.get("id", "")) == "water_trainer_nerissa":
			nerissa_found = true
			assert_eq(_levels(trainer.get("team", [])), [32, 32, 33, 33])
	assert_true(nerissa_found)
	var veyra_found := false
	for trainer: Dictionary in _read("cloudreach_chapter").get("trainer_ladder", []):
		if str(trainer.get("id", "")) == "captain_veyra_storm_anchor":
			veyra_found = true
			var contract: Dictionary = trainer.get("team_contract", {})
			assert_eq(_levels(contract.get("slots", [])), [43, 43, 44])
	assert_true(veyra_found)


func test_unmounted_candidate_preserves_live_legacy_resolver_and_finales() -> void:
	_assert_band(CURVE.team_band_at(7400.0, CURVE.config()), [17, 21])
	_assert_band(CURVE.wild_band_at(7400.0, CURVE.config()), [14, 17])
	var warden_found := false
	for trainer: Dictionary in BANDS.load_config("res://data/config/trainers.json", "trainers").get("trainers", []):
		if str(trainer.get("id", "")) == "warden_aldis":
			warden_found = true
			assert_eq(_levels(trainer.get("team", [])), [18, 18, 19, 19, 20])
	assert_true(warden_found)
	var marrow_found := false
	for trainer: Dictionary in STORM.trainer_specs():
		if str(trainer.get("id", "")) == "captain_marrow_dynamo_core":
			marrow_found = true
			assert_eq(_levels(trainer.get("team", [])), [42, 43, 43, 44, 44])
	assert_true(marrow_found)


func test_relic_display_retains_runtime_water_identity_in_new_order() -> void:
	var state := HEARTS.new()
	assert_eq(state.ordered_realm_ids(), ["meadows", "water", "cloudreach", "stormwood"])
	assert_eq(state.earned_flag("water"), "realm_relic_water_earned")
	assert_eq(state.earned_flag("cloudreach"), "realm_heart_cloudreach_earned")
