extends "res://tests/test_case.gd"

## An ironwood harvest node built from a twisted-tree form the grove layer does
## not list must still lose the pack's crimson leaves (red is Team Tether's).

const HARVEST := preload("res://scripts/world/harvest_node.gd")
const NATURE := "res://assets/environment/stylized_nature/"


func _layers() -> Dictionary:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/vegetation.json"))
	return doc.get("layers", {})


func test_unlisted_twisted_trees_take_the_grove_leaf_swap() -> void:
	for form: String in ["TwistedTree_1.gltf", "TwistedTree_3.gltf", "TwistedTree_5.gltf"]:
		var fix: Dictionary = HARVEST.sibling_fixups(_layers(), NATURE + form)
		var swap := str((fix.get("retexture", {}) as Dictionary).get("Leaves_TwistedTree", ""))
		assert_true(swap.contains("Leaves_NormalTree"), "%s swaps its crimson leaf sheet for the green one" % form)
		assert_true((fix.get("retint", {}) as Dictionary).has("Leaves_TwistedTree"), "%s takes the layer's leaf tint" % form)


func test_family_is_the_path_without_its_number() -> void:
	assert_eq(HARVEST.model_family(NATURE + "TwistedTree_3.gltf"), NATURE + "TwistedTree_")
	assert_eq(HARVEST.model_family(NATURE + "Bush_Common.gltf"), "", "no trailing number, no family")
	assert_true(HARVEST.sibling_fixups(_layers(), NATURE + "Bush_Common.gltf").is_empty(), "no family, no borrowed fixup")


func test_every_meadows_harvest_tree_now_resolves_a_leaf_fixup() -> void:
	for band: String in ["band2_stone_and_root", "band3_the_river_lock", "band4_upper_meadows_ironwood"]:
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/bands/%s/harvest.json" % band))
		var text := JSON.stringify(doc)
		for form: String in ["TwistedTree_1.gltf", "TwistedTree_2.gltf", "TwistedTree_3.gltf", "TwistedTree_4.gltf"]:
			if not text.contains(form):
				continue
			var listed := false
			for layer_name: String in _layers():
				if _layers()[layer_name] is Dictionary and ((_layers()[layer_name] as Dictionary).get("models", []) as Array).has(NATURE + form):
					listed = true
			assert_true(listed or not HARVEST.sibling_fixups(_layers(), NATURE + form).is_empty(), "%s in %s has a leaf fixup" % [form, band])
