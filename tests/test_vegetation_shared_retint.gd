extends "res://tests/test_case.gd"

const VEGETATION := preload("res://scripts/world/vegetation.gd")
const MODEL := "res://shared_tree.gltf"


func test_stormwood_canopies_share_identical_retint_inputs() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/stormwood_vegetation.json"))
	assert_eq(VEGETATION.shared_retint_conflicts(cfg.layers), [])
	assert_eq(cfg.layers.storm_canopy.models, cfg.layers.giant_canopy.models)
	for model: String in cfg.layers.storm_canopy.models:
		assert_eq(VEGETATION.retint_policy(model, cfg.layers.storm_canopy),
			VEGETATION.retint_policy(model, cfg.layers.giant_canopy))


func test_each_conflicting_retint_input_is_reported() -> void:
	var base := {"models": [MODEL]}
	var mutations := [
		{"retint": {"Leaves": "#123456"}},
		{"variant_retint": {MODEL: {"Leaves": "#123456"}}},
		{"retexture": {"Leaves": "res://other.png"}},
		{"retexture_adjust": {"Leaves": {"saturation": 0.5}}},
		{"colour_jitter": 0.1},
	]
	for mutation: Dictionary in mutations:
		var changed := base.duplicate(true)
		changed.merge(mutation, true)
		assert_eq(VEGETATION.shared_retint_conflicts({"first": base, "second": changed}),
			[{"model": MODEL, "owner": "first", "layer": "second"}], str(mutation))


func test_conflicts_stay_bound_to_first_layer_in_three_layer_chain() -> void:
	var first := {"models": [MODEL], "retint": {"Leaves": "#123456"}}
	var different := {"models": [MODEL], "retint": {"Leaves": "#abcdef"}}
	assert_eq(VEGETATION.shared_retint_conflicts({
		"first": first, "second": different, "third": first.duplicate(true)}),
		[{"model": MODEL, "owner": "first", "layer": "second"}])
	assert_eq(VEGETATION.shared_retint_conflicts({
		"first": first, "second": different, "third": different.duplicate(true)}),
		[{"model": MODEL, "owner": "first", "layer": "second"},
		 {"model": MODEL, "owner": "first", "layer": "third"}])


func test_variant_replaces_layer_tints_and_overlay_merges_without_mutating_config() -> void:
	var layer := {"retint": {"Bark": "#111111"},
		"variant_retint": {MODEL: {"Leaves": "#222222"}},
		"retexture": {"Bark": "res://bark.png", "Leaves": "res://old.png"},
		"retexture_adjust": {"Bark": {"saturation": 0.5}}, "colour_jitter": 0.1}
	var overlay := {"variant_retint": {MODEL: {"Leaves": "#333333", "Flower": "#444444"}},
		"retexture": {"Leaves": "res://new.png"}}
	var before_layer := layer.duplicate(true)
	var before_overlay := overlay.duplicate(true)
	assert_eq(VEGETATION.retint_policy(MODEL, layer, overlay), {
		"tints": {"Leaves": "#333333", "Flower": "#444444"},
		"swaps": {"Bark": "res://bark.png", "Leaves": "res://new.png"},
		"adjusts": {"Bark": {"saturation": 0.5}}, "needs_instance_colour": true})
	assert_eq(layer, before_layer)
	assert_eq(overlay, before_overlay)
	assert_eq(VEGETATION.retint_policy("res://other.gltf", layer).tints, layer.retint)


func test_overlay_resolves_only_the_inputs_it_replaces() -> void:
	var first := {"models": [MODEL], "retint": {"Leaves": "#111111"}}
	var second := {"models": [MODEL], "retint": {"Leaves": "#222222"}}
	var overlay := {"variant_retint": {MODEL: {"Leaves": "#333333"}}}
	assert_eq(VEGETATION.shared_retint_conflicts({"a": first, "b": second}, overlay), [])
	second["retexture"] = {"Leaves": "res://different.png"}
	assert_eq(VEGETATION.shared_retint_conflicts({"a": first, "b": second}, overlay),
		[{"model": MODEL, "owner": "a", "layer": "b"}])


func test_non_material_fields_and_unrelated_variants_do_not_conflict() -> void:
	var first := {"models": [MODEL], "colour_jitter": 0.1}
	var second := {"models": [MODEL], "colour_jitter": 0.2, "scale": [6, 7.5],
		"lod_range": 1200, "harvest_amount": 6,
		"variant_retint": {"res://another.gltf": {"Leaves": "#123456"}}}
	assert_eq(VEGETATION.shared_retint_conflicts({
		"_comment": "ignored", "a": first, "b": second}), [])
