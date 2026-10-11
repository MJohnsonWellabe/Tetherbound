extends "res://tests/test_case.gd"
## P2-046: Stormwood harvest nodes carry a visual-only material cue.
const RUNS_IN_INITIALIZED_TREE := true

const RUNTIME := preload("res://scripts/world/stormwood_harvest_runtime.gd")
const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")


func test_stormglass_and_glowmoss_get_visual_only_cues() -> void:
	var cues: Dictionary = RUNTIME.read().get("material_cues", {})
	for item: String in ["stormglass", "stormglass_crown", "glowmoss"]:
		var node := Node3D.new()
		var cue := RUNTIME.add_material_cue(node, item, cues)
		assert_true(cue != null and cue.get_child_count() > 0, item + " gets a cue")
		assert_eq(cue.find_children("*", "CollisionObject3D", true, false).size(), 0, item + " cue adds no collider")
		assert_eq(RUNTIME.add_material_cue(node, item, cues), null, item + " cue is not duplicated")
		node.free()


func test_items_without_a_cue_are_unchanged() -> void:
	var node := Node3D.new()
	assert_eq(RUNTIME.add_material_cue(node, "voltcap", RUNTIME.read().get("material_cues", {})), null)
	assert_eq(node.get_child_count(), 0)
	node.free()


func test_no_cue_on_an_item_whose_model_a_fight_ring_hides() -> void:
	var catalogue: Dictionary = RUNTIME.read()
	var cues: Dictionary = catalogue.get("material_cues", {})
	var veg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/vegetation.json"))
	var occluders: Array = []
	for layer_name: String in ["bushes", "deadfall"]:
		occluders.append_array(((veg.get("layers", {}) as Dictionary).get(layer_name, {}) as Dictionary).get("models", []))
	for site: Dictionary in catalogue.get("sites", []):
		if not cues.has(str(site.get("item", ""))) or not occluders.has(str(site.get("model", ""))):
			continue
		var node := HARVEST_NODE.new()
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.add_child(node)
		node.setup({"item": site.item, "model": site.model,
			"model_scale": site.get("model_scale", 1.0), "order": site.id, "realm": "stormwood"})
		var visual := node.get("_visual") as Node3D
		var cue := RUNTIME.add_material_cue(node, str(site.item), cues)
		assert_true(visual != null and cue != null, "%s has its actual harvest model and cue" % site.item)
		if visual != null and cue != null:
			assert_true(visual.is_ancestor_of(cue), "%s cue follows its model's visibility" % site.item)
			assert_true(cue.is_visible_in_tree(), "%s cue starts visible" % site.item)
			node.set_fight_hidden(true)
			assert_false(cue.is_visible_in_tree(), "%s cue would float when a fight hides its model" % site.item)
			node.set_fight_hidden(false)
			assert_true(cue.is_visible_in_tree(), "%s cue returns with its model after the fight" % site.item)
		node.free()
