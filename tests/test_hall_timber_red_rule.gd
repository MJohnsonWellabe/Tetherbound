extends "res://tests/test_case.gd"

## Red rule (coordinator audit, 10 Nov): red and oxblood belong to Team
## Tether. The Hall's timber nave post (MI_WoodTrim under the hall_waymark
## timber multiply) read as a red curtain at golden hour. `timber_1110` must
## land the same wood outside the red family, on an ochre-brown hue.

const POST := "res://assets/buildings/quaternius_medieval/Corner_Exterior_Wood.gltf"


func _wood_mean() -> Color:
	var node: Node = (load(POST) as PackedScene).instantiate()
	var mean := Color(0, 0, 0)
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if material == null or material.resource_name != "MI_WoodTrim":
				continue
			var image := material.albedo_texture.get_image()
			if image.is_compressed():
				image.decompress()
			image.resize(32, 32)
			var sum := Vector3.ZERO
			for y in 32:
				for x in 32:
					var c := image.get_pixel(x, y)
					sum += Vector3(c.r, c.g, c.b)
			sum /= 1024.0
			mean = Color(sum.x, sum.y, sum.z)
	node.free()
	return mean


func _lit(multiply: String) -> Color:
	var wood := _wood_mean()
	var tint := Color(multiply)
	return Color(wood.r * tint.r, wood.g * tint.g, wood.b * tint.b)


func test_timber_1110_is_presentation_scoped() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	var arm: Dictionary = cfg.hall_waymark.materials.timber_1110
	assert_eq(str(arm.get("scope", "")), "client_presentation")
	assert_true(arm.has("color"))


func test_ochre_timber_is_outside_the_red_family() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/crossing_hall.json"))
	var materials: Dictionary = cfg.hall_waymark.materials
	var wood := _wood_mean()
	assert_true(wood.v > 0.05, "the WoodTrim sheet was read")
	var before := _lit(str(materials.timber.color))
	var after := _lit(str(materials.timber_1110.color))
	var hue := after.h * 360.0
	assert_between(hue, 25.0, 50.0, "ochre-brown hue (%.1f, was %.1f)" % [hue, before.h * 360.0])
	assert_true(after.h > before.h, "the arm moves the wood away from red")
	assert_between(after.v, before.v * 0.8, before.v * 1.2, "about the same value")
