extends "res://tests/test_case.gd"

const MERGE := preload("res://scripts/world/cloudreach_visual_candidate.gd")
const AVIARY := preload("res://scripts/world/cloudreach_aviary.gd")
const CROWN := preload("res://scripts/world/cloudreach_aviary_crown.gd")
const SANCTUARY := preload("res://scripts/world/cloudreach_aviary_sanctuary.gd")


func test_candidate_keeps_collision_contract_and_baseline_immutable() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MERGE.PATH))
	var combined := MERGE._merge(base, candidate.aviary)
	assert_true(candidate.enabled)
	assert_true(base.crown_arcade.enabled)
	assert_true(combined.towers.enabled)
	for field: String in ["throat", "drum", "arches", "footprint", "dome", "pylon_anchor"]:
		assert_eq(combined[field], base[field], "candidate preserves " + field)
	assert_true(AVIARY.throat_clear(combined))


func test_crown_and_garden_are_repeatable_without_new_collision() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_aviary.json"))
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MERGE.PATH))
	var spec := MERGE._merge(base, candidate.aviary)
	var root := Node3D.new()
	var material := StandardMaterial3D.new()
	var materials := {"stone": material, "masonry": material}
	var built := AVIARY.build(root, materials, spec)
	var original_collision := root.find_children("*", "CollisionObject3D", true, false).size()
	var crown := CROWN.build(root, spec.crown_arcade, spec.drum, material, material)
	SANCTUARY.build(root, spec.sanctuary, built.arches, materials)
	var child_count := root.get_child_count()
	assert_eq(crown.get_child_count(), 22)
	assert_eq(crown.find_children("CrownBay*", "Node3D", false, false).size(), 20)
	for name_key: String in ["CrownEntablature", "CrownWeatheringCourse"]:
		var cornice := crown.get_node_or_null(NodePath(name_key)) as MeshInstance3D
		assert_true(cornice != null and cornice.mesh != null, "the named cornice course exists: " + name_key)
	assert_eq(root.find_children("SanctuaryPlanter*", "Node3D", true, false).size(), 4)
	assert_eq(root.find_children("*", "CollisionObject3D", true, false).size(), original_collision)
	assert_eq(CROWN.build(root, spec.crown_arcade, spec.drum, material, material), crown)
	SANCTUARY.build(root, spec.sanctuary, built.arches, materials)
	assert_eq(root.get_child_count(), child_count, "repeated presentation build does not duplicate props/lights")
	root.free()
