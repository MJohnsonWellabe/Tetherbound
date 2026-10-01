extends "res://tests/test_case.gd"

class CandidateTree extends "res://scripts/world/stormheart_tree.gd":
	func _read_presentation() -> Dictionary:
		var cfg: Dictionary = super._read_presentation()
		cfg.enabled = true
		cfg.core_finish.enabled = true
		return cfg


func test_release_cools_the_candidate_once_and_reactivation_is_reversible() -> void:
	var tree := CandidateTree.new()
	tree.build()
	var root := tree.get_node("ForkedHeartCharge")
	var original_count := root.get_child_count()
	var material: StandardMaterial3D = tree._core_material
	for repeat in 3:
		tree.set_core_released(true)
		assert_almost_eq(material.emission_energy_multiplier, 0.08, 0.001)
		assert_eq(material.albedo_color.to_html(false), "455568")
		for light: OmniLight3D in tree._core_lights:
			assert_false(light.visible, "no charged core light after release")
		assert_eq(root.get_child_count(), original_count, "release never duplicates art nodes")
	tree.set_core_released(false)
	assert_almost_eq(material.emission_energy_multiplier, 1.35, 0.001)
	for light: OmniLight3D in tree._core_lights:
		assert_true(light.visible)
	tree.free()


func test_host_shell_omits_all_candidate_art() -> void:
	var tree := CandidateTree.new()
	tree.simulation_only = true
	tree.build()
	assert_false(tree.has_node("ForkedHeartCharge"))
	assert_true(tree.has_node("DynamoCore"), "physical arena still exists")
	assert_true(tree.has_node("CrownChamber"), "physical chamber still exists")
	tree.free()
