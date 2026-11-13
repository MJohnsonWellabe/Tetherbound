extends "res://tests/test_case.gd"

## Toy pickups (LANE-BELOW6, 12 Nov 2026): `natural_cluster_1112` in
## mushroom_pickup_variants.json swaps each mushroom find for a small patch of the
## installed mushrooms. The hidden pickup mesh stays for interaction and grounding.

const PRESENTATION := preload("res://scripts/world/mushroom_pickup_presentation.gd")
const VARIANTS := "res://data/config/mushroom_pickup_variants.json"


func _arm() -> Dictionary:
	return (JSON.parse_string(FileAccess.get_file_as_string(VARIANTS)) as Dictionary).get("natural_cluster_1112", {})


func test_arm_is_declared_with_installed_models_and_no_red() -> void:
	var arm := _arm()
	assert_false(arm.is_empty(), "natural_cluster_1112 is declared")
	assert_eq(str(arm.get("scope", "")), "device_local_presentation")
	for id: String in ["speed_mushroom", "stamina_mushroom", "wild_mushroom"]:
		var spec: Dictionary = (arm.get("items", {}) as Dictionary).get(id, {})
		assert_true(ResourceLoader.exists(str(spec.get("scene", ""))), "%s uses an installed model" % id)
		assert_true(float(spec.get("height_scale", 1.0)) < 1.0, "%s is smaller than the old cap" % id)
		var tint := Color(str(spec.get("tint", "#ffffff")))
		assert_false(tint.r > 0.6 and tint.g < 0.4 and tint.b < 0.4, "%s is not red" % id)


func test_default_leaves_the_pickup_mesh_visible() -> void:
	if bool(_arm().get("enabled", false)):
		return
	var root := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	root.add_child(mesh)
	PRESENTATION.apply(root, "speed_mushroom")
	assert_true(mesh.visible, "flag off: the installed pickup mesh is what the player sees")
	assert_eq(root.find_children("MushroomVariant", "Node3D", true, false).size(), 0)
	root.free()
