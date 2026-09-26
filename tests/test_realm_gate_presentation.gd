extends "res://tests/test_case.gd"

const GATE := preload("res://scripts/world/realm_gate.gd")

func test_imported_frame_retains_matte_material_and_trainer_clearance() -> void:
	var gate := GATE.new()
	gate._build_visual()
	var frame := gate.get_node("RealmGateFrame")
	var meshes := frame.find_children("*", "MeshInstance3D", true, false)
	assert_eq(meshes.size(), 1)
	var mesh := meshes[0] as MeshInstance3D
	var material := mesh.get_active_material(0) as BaseMaterial3D
	assert_true(material != null)
	assert_true(material.albedo_texture != null)
	assert_true(material.normal_enabled)
	assert_true(material.roughness >= 0.78, "matte roughness must survive GLB import")
	if material.roughness_texture != null:
		var pixels := material.roughness_texture.get_image()
		if pixels.is_compressed():
			assert_eq(pixels.decompress(), OK)
		for y in range(0, pixels.get_height(), 32):
			for x in range(0, pixels.get_width(), 32):
				var colour := pixels.get_pixel(x, y)
				var channel := colour.g if material.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN else colour.r
				assert_true(channel * material.roughness >= 0.78,
					"texture multiplied by factor must retain matte roughness")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/props/realm_gate_meshy/models/aperture.json"))
	for row: Array in data.profile_y_left_right:
		if float(row[0]) <= 2.0:
			assert_true(float(row[2]) - float(row[1]) > 2.8, "measured opening clears the trainer")
	gate.free()

func test_sealed_unlockable_and_open_have_distinct_energy_without_mutating_frame() -> void:
	var gate := GATE.new()
	gate._build_visual()
	var frame := gate.get_node("RealmGateFrame")
	var sealed := gate.get_node("RealmSeal/EnergyVeil") as MeshInstance3D
	var opened := gate.get_node("OpenThreshold/OpenAirShimmer") as MeshInstance3D
	var sealed_material := sealed.material_override as ShaderMaterial
	var open_material := opened.material_override as ShaderMaterial
	assert_true(sealed.mesh == opened.mesh, "reuse measured aperture mesh")
	assert_true(sealed_material != open_material, "states have independent material instances")
	gate._set_open_visual(false, false)
	var locked_intensity := float(sealed_material.get_shader_parameter("intensity"))
	assert_true(gate.get_node("RealmSeal").visible)
	assert_false(gate.get_node("OpenThreshold").visible)
	gate._set_open_visual(false, true)
	assert_true(float(sealed_material.get_shader_parameter("intensity")) > locked_intensity)
	assert_true(float(sealed_material.get_shader_parameter("seal_ready")) > 0.5)
	gate._set_open_visual(true, true)
	assert_false(gate.get_node("RealmSeal").visible)
	assert_true(gate.get_node("OpenThreshold").visible)
	assert_almost_eq(float(open_material.get_shader_parameter("seal_presence")), 0.0, 0.001)
	assert_true(float(open_material.get_shader_parameter("centre_opacity")) < float(
		sealed_material.get_shader_parameter("centre_opacity")))
	assert_true(gate.get_node("RealmGateFrame") == frame)
	gate.free()
