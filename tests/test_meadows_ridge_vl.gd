extends "res://tests/test_case.gd"

## Visual lane (3 Nov), F38#24 / P2-014: the Blender Meadows ridge ring ships
## ON since 10 Nov (GPU judged), OFF leaves the horizon rings exactly as
## configured, and ON replaces only the named procedural layers with a
## render-only ridge.

const RIDGE := preload("res://scripts/world/meadows_ridge_vl.gd")
const HORIZON_CONFIG := "res://data/config/meadows_horizon.json"
const HORIZON := preload("res://scripts/world/horizon_ranges.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _with_off() -> Dictionary:
	var config := RIDGE.settings().duplicate(true)
	config["enabled"] = false
	return config


func _with_on() -> Dictionary:
	var config := RIDGE.settings().duplicate(true)
	config["enabled"] = true
	return config


func test_ships_on_with_a_declared_scope() -> void:
	var config := RIDGE.settings()
	assert_false(config.is_empty(), "meadows_ridge_vl.json parses")
	assert_eq(str(config.get("scope", "")), "client_presentation", "the new flag declares scope")
	assert_true(RIDGE.enabled(), "the ridge ships ON after its judged gain")
	assert_true(str(config.get("_why_on", "")).contains("+0.75"), "the judged gain is recorded")
	assert_true(FileAccess.file_exists(str(config.get("model", ""))), "the ridge GLB is in the tree")


func test_off_leaves_the_horizon_rings_unchanged() -> void:
	var off := _with_off()
	assert_eq(RIDGE.replaced_layers(off), [], "OFF replaces no procedural layer")
	var parent := Node3D.new()
	assert_eq(RIDGE.build(parent, off), null, "OFF builds nothing")
	assert_eq(parent.get_child_count(), 0, "OFF adds no node under HorizonRanges")
	parent.free()
	var horizon_script: Script = HORIZON
	assert_true(horizon_script.can_instantiate(), "horizon_ranges.gd still parses with the ridge hook")
	var horizon := _json(HORIZON_CONFIG)
	var names: Array = []
	for layer: Dictionary in horizon.get("layers", []):
		names.append(str(layer.get("name", "")))
	assert_eq(names, ["FarRanges", "Foothills"], "the landed rings are still both configured")
	assert_false(bool((horizon.get("hero_model", {}) as Dictionary).get("enabled", false)),
		"the ridge candidate does not switch the old hero summit on")


func test_on_replaces_only_the_named_rings() -> void:
	var on := _with_on()
	var replaced := RIDGE.replaced_layers(on)
	assert_eq(replaced, ["FarRanges", "Foothills"], "ON replaces exactly the two procedural rings")
	var horizon := _json(HORIZON_CONFIG)
	for layer: Dictionary in horizon.get("layers", []):
		assert_true(replaced.has(str(layer.get("name", ""))), "each replaced name is a real layer")
	assert_eq(float(on.get("sink_m", -1.0)) >= 0.0, true, "the ridge never rises above its ring base")
	assert_true((on.get("shader", {}) as Dictionary).has("fog_keep"), "ON keeps a declared share of the live fog")
