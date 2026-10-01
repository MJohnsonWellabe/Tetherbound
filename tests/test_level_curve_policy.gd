extends "res://tests/test_case.gd"

## Detached data checks only. No scene, Session or production provider mounts
## this candidate, and the route/earning/solvency gates remain independent.
const POLICY := preload("res://scripts/creatures/level_curve_policy.gd")
const PATH := "res://data/config/water_alpha.json"


func _base(path: String = PATH) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(raw is Dictionary, path)
	return raw if raw is Dictionary else {}


func _enabled() -> Dictionary:
	var cfg := POLICY.config()
	assert_eq(cfg.get("runtime_enabled"), false)
	cfg["runtime_enabled"] = true
	return cfg


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
	assert_eq(POLICY.apply(PATH, base, true), before, "shipped candidate flag remains false")
	for value: Variant in [false, null, 0, 1, "true", [], {}]:
		assert_eq(POLICY.apply(PATH, base, value, _enabled()), before)
		var cfg := POLICY.config()
		cfg["runtime_enabled"] = value
		assert_eq(POLICY.apply(PATH, base, true, cfg), before)
	assert_eq(base, before)


func test_explicit_candidate_is_detached_and_preserves_nonlevel_data() -> void:
	var cfg := _enabled()
	for path: String in POLICY.PATHS:
		var base := _base(path)
		var before := base.duplicate(true)
		var next := POLICY.apply(path, base, true, cfg)
		assert_false(next.is_empty(), path)
		assert_eq(base, before, "opt-in cannot mutate a cached live config")
		assert_eq(_nonlevels(next), _nonlevels(base), "geometry, identity, rewards and guards survive opt-in")
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
