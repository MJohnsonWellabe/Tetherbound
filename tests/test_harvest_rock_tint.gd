extends "res://tests/test_case.gd"

## MEADOWS-VISUAL-PASS round 5: stone deposits wear the same stone as the
## scatter boulders beside them (the presentation overlay's rock texture and
## per-model tint), never a near-black multiply.

const HARVEST_NODE := preload("res://scripts/world/harvest_node.gd")
const ROCK_2 := "res://assets/environment/stylized_nature/Rock_Medium_2.gltf"


func _rock_material(model: String) -> StandardMaterial3D:
	var node: Node3D = HARVEST_NODE.new()
	node.call("setup", {"item": "stone", "amount": 2, "at": [0.0, 0.0], "model": model, "model_scale": 1.0})
	var found: StandardMaterial3D = null
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		for surface in instance.get_surface_override_material_count():
			var material := instance.get_surface_override_material(surface) as StandardMaterial3D
			if material != null and material.albedo_texture != null:
				found = material
	node.free()
	return found


func test_every_deposit_rock_takes_a_light_presentation_tint() -> void:
	for model: String in [ROCK_2, "res://assets/environment/stylized_nature/Rock_Medium_1.gltf",
			"res://assets/environment/stylized_nature/Rock_Medium_3.gltf"]:
		var material := _rock_material(model)
		assert_true(material != null, "%s has no textured rock surface" % model)
		if material == null:
			continue
		assert_eq(material.albedo_texture.resource_path,
			"res://assets/environment/stylized_nature/Rocks_Diffuse_meadows.png", "one stone family with the scatter")
		# A multiply under ~0.8 over these mid-grey stones renders a near-black boulder.
		assert_true(material.albedo_color.v >= 0.8, "%s tint %s darkens the photo into a black block"
			% [model, material.albedo_color.to_html(false)])
