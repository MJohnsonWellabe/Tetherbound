extends "res://tests/test_case.gd"

## forest_layers_1113 (LANE-LAND-CS): ships ON (GPU High, 14 Nov 2026,
## G-land-cs-soiloff: F41#22 5.33 -> 6.03, F41#24 5.29 -> 6.23, both 3/3). It
## patches the Stormwood forest layers by name and drops the wet_soil discs.

const COVER := preload("res://scripts/world/stormwood_ground_cover.gd")


func _finish() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_ground_finish.json"))


func _names(layers: Array[Dictionary]) -> Array:
	var out: Array = []
	for layer: Dictionary in layers:
		out.append(str(layer.get("name", "")))
	return out


func test_ships_on_with_its_verdict() -> void:
	var finish := _finish()
	var flag: Dictionary = finish.forest_layers_1113
	assert_true(bool(flag.get("enabled", false)), "forest_layers_1113 ships ON")
	assert_true(str(flag.get("_why_on", "")).contains("G-land-cs-soiloff.md"), "ON cites its GPU verdict")
	assert_true(str(flag.get("_why_on", "")).contains("5.33 -> 6.03"), "and its judged score")
	assert_eq(_names(COVER.forest_layers(finish)), ["canopy_understory"], "the wet-soil discs are not built")


func test_off_keeps_the_shipped_layers() -> void:
	var finish := _finish()
	finish.forest_layers_1113.enabled = false
	var layers := COVER.forest_layers(finish)
	assert_eq(_names(layers), ["wet_soil", "canopy_understory"], "OFF keeps both layers in order")
	for index in layers.size():
		assert_eq(layers[index], finish.forest_layers[index], "OFF leaves layer %d unchanged" % index)


func test_on_drops_wet_soil_only() -> void:
	var finish := _finish()
	finish.forest_layers_1113.enabled = true
	var layers := COVER.forest_layers(finish)
	assert_eq(_names(layers), ["canopy_understory"], "ON drops the wet-soil discs")
	assert_eq(layers[0], finish.forest_layers[1], "the understory layer is untouched")


func test_on_patches_a_layer_by_name() -> void:
	var finish := _finish()
	finish.forest_layers_1113.enabled = true
	finish.forest_layers_1113.layers = {"wet_soil": {"item_size": 1.2}}
	var layers := COVER.forest_layers(finish)
	assert_eq(_names(layers), ["wet_soil", "canopy_understory"], "a patch without enabled false keeps the layer")
	assert_eq(float(layers[0].item_size), 1.2, "the patch value is applied")
	assert_eq(float(finish.forest_layers[0].item_size), 2.8, "the source config is not mutated")
