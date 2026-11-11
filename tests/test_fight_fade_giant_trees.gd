extends "res://tests/test_case.gd"

## F41#3 / F41#22 (LANE-MESHY): `giant_trees_1110` adds the Deepwood Meshy
## giant trees to the fight-only sight fade. Checked on enabled and disabled
## copies, so it holds whichever way the arm ships.

const FADE := preload("res://scripts/world/foliage_fight_fade.gd")
const VIS := preload("res://scripts/world/foliage_camera_visibility.gd")


func _sight(enabled: bool) -> Dictionary:
	var cfg: Dictionary = (VIS.config().get("line_of_sight_fade", {}) as Dictionary).duplicate(true)
	cfg.giant_trees_1110.enabled = enabled
	return cfg


func test_arm_is_presentation_scoped_and_lists_the_giant_trees() -> void:
	var arm: Dictionary = VIS.config().line_of_sight_fade.giant_trees_1110
	assert_eq(str(arm.get("scope", "")), "client_presentation")
	for model: String in arm.models:
		assert_true(ResourceLoader.exists(model), "%s is an installed model" % model)


func test_giant_trees_join_the_fight_fade_only_when_on() -> void:
	var models: Array = VIS.config().line_of_sight_fade.giant_trees_1110.models
	var on := _sight(true)
	var off := _sight(false)
	for model: String in models:
		assert_true(FADE.eligible(model, "stormwood", on), "%s fades in Stormwood fights when ON" % model.get_file())
		assert_false(FADE.eligible(model, "stormwood", off), "%s is untouched when OFF" % model.get_file())
	# The original list is unchanged either way.
	for model: String in off.models:
		assert_true(FADE.eligible(model, "stormwood", on))
		assert_true(FADE.eligible(model, "stormwood", off))


func test_giant_tree_materials_convert_to_the_fight_shader() -> void:
	var model: String = VIS.config().line_of_sight_fade.giant_trees_1110.models[0]
	var node: Node = (load(model) as PackedScene).instantiate()
	var mesh: Mesh = (node.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var fade := FADE.new()
	var faded := fade.apply(mesh, model, "stormwood", _sight(true))
	assert_true(faded.surface_get_material(0) is ShaderMaterial, "the giant tree surface gains the fight fade")
	assert_true(fade.has_materials())
	node.free()
