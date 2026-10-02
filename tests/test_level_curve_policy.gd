extends "res://tests/test_case.gd"

## Live RD-10 data and strict repeat-application checks. Runtime route, earning,
## save and solvency proofs remain independent of this authored data regression.
const POLICY := preload("res://scripts/creatures/level_curve_policy.gd")
const PATH := "res://data/config/water_alpha.json"


func _base(path: String = PATH) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(raw is Dictionary, path)
	return raw if raw is Dictionary else {}


func _enabled() -> Dictionary:
	var cfg := POLICY.config()
	assert_eq(cfg.get("runtime_enabled"), true)
	return cfg


func _legacy(path: String) -> Dictionary:
	var data := _base(path)
	for row: Dictionary in POLICY.config().overlays[path.trim_prefix("res://")]:
		var node: Variant = data
		for index in row.at.size() - 1:
			var part: Variant = int(row.at[index]) if node is Array else row.at[index]
			node = node[part]
		var field: Variant = int(row.at[-1]) if node is Array else row.at[-1]
		if row.legacy == null:
			node.erase(field)
		else:
			node[field] = row.legacy
	return data


func _nonlevels(raw: Variant, parent: String = "") -> Variant:
	if raw is Dictionary:
		var out: Dictionary = {}
		for key: String in raw:
			if key in ["level", "ace_level", "level_ceiling", "warden_level", "wild_band",
					"trainer_levels", "level_range", "level_band", "biomes"] \
					or (parent == "team" and key in ["enter", "exit"]):
				continue
			out[key] = _nonlevels(raw[key], key)
		return out
	if raw is Array:
		var out: Array = []
		for value: Variant in raw:
			out.append(_nonlevels(value, parent))
		return out
	return raw


func test_default_and_malformed_activation_leave_live_data_unchanged() -> void:
	var base := _base()
	var before := base.duplicate(true)
	assert_eq(POLICY.apply(PATH, base), before)
	assert_eq(POLICY.apply(PATH, base, true), before, "the shipped RD-10 table is already materialized")
	for value: Variant in [false, null, 0, 1, "true", [], {}]:
		assert_eq(POLICY.apply(PATH, base, value, _enabled()), before)
		var cfg := POLICY.config()
		cfg["runtime_enabled"] = value
		assert_eq(POLICY.apply(PATH, base, true, cfg), before)
	assert_eq(base, before)


func test_template_and_live_tables_converge_once_without_nonlevel_mutations() -> void:
	var cfg := _enabled()
	for path: String in POLICY.PATHS:
		var base := _base(path)
		var before := base.duplicate(true)
		var next := POLICY.apply(path, base, true, cfg)
		assert_false(next.is_empty(), path)
		assert_eq(next, before, "a repeat application cannot distort live levels")
		assert_eq(base, before, "validation cannot mutate a cached live config")
		var legacy := _legacy(path)
		assert_eq(POLICY.apply(path, legacy, true, cfg), before, "the preserved template produces the shipped levels")
		assert_eq(_nonlevels(next), _nonlevels(legacy), "geometry, identity, rewards and guards survive activation")
		if not next.is_empty():
			next["detached_probe"] = true
			assert_false(base.has("detached_probe"))


func test_stale_identity_value_and_malformed_rows_refuse_without_partial_change() -> void:
	var base := _base()
	var before := base.duplicate(true)
	var changed := base.duplicate(true)
	changed["level"] = float(base.level) + 1.0
	assert_eq(POLICY.apply(PATH, changed, true, _enabled()), {})
	for value: Variant in [false, null, 0, 1.5, INF, "26", [], {}]:
		var cfg := _enabled()
		cfg.overlays[PATH.trim_prefix("res://")][0].value = value
		assert_eq(POLICY.apply(PATH, base, true, cfg), {})
	var duplicate := _enabled()
	duplicate.overlays[PATH.trim_prefix("res://")].append(duplicate.overlays[PATH.trim_prefix("res://")][0].duplicate(true))
	assert_eq(POLICY.apply(PATH, base, true, duplicate), {})
	var unknown := _enabled()
	unknown.overlays[PATH.trim_prefix("res://")][0].at = ["clock"]
	assert_eq(POLICY.apply(PATH, base, true, unknown), {}, "non-level mutation is never an overlay")
	var bad_anchor := _enabled()
	bad_anchor.overlays[PATH.trim_prefix("res://")][0].anchors = [{"at": ["species_id"], "value": "another_creature"}]
	assert_eq(POLICY.apply(PATH, base, true, bad_anchor), {})
	assert_eq(base, before)
