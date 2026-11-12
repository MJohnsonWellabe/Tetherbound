extends "res://tests/test_case.gd"

## fly_traversal.json capabilities.galewisp (LANE-THINGS, 12 Nov 2026;
## G-faint2-medium-galecarrier.md): the carrier drawn in flight is the same
## model the species shows everywhere else, and it grips with bones that rig
## has. Before, Galewisp flew as its pre-remake mesh.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func _carriers() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json"))
	return raw.get("capabilities", {})


func test_every_carrier_flies_as_the_species_live_model() -> void:
	for id: String in _carriers():
		var capability: Dictionary = _carriers()[id]
		if not bool(capability.get("can_carry", false)):
			continue
		assert_eq(str(capability.get("model", "")), str(SPECIES.placeholder(id).get("model", "")),
			"%s carries as the model the species ships" % id)


func test_galewisp_grips_with_feet_its_rig_has() -> void:
	var capability: Dictionary = _carriers().get("galewisp", {})
	assert_eq(capability.get("grip_bones", []), ["foot_l", "foot_r"])
	var scene := load(str(capability.get("model", ""))) as PackedScene
	assert_true(scene != null, "the carrier model loads")
	if scene == null:
		return
	var art := scene.instantiate()
	var rigs := art.find_children("*", "Skeleton3D", true, false)
	assert_eq(rigs.size(), 1)
	if rigs.size() == 1:
		for bone: String in capability.get("grip_bones", []):
			assert_true((rigs[0] as Skeleton3D).find_bone(bone) >= 0, "the rig has %s" % bone)
	art.free()
