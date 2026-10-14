extends "res://tests/test_case.gd"

const DETAIL := preload("res://scripts/world/cloudreach_cliffhold_detail.gd")


func test_preview_requires_both_flags_and_a_receipted_capture() -> void:
	var script_args := PackedStringArray(["--script", "res://tools/capture_cloudreach_biome_look.gd"])
	var both := PackedStringArray(["--cloudreach-look-candidate", "--cloudreach-cliffhold-detail-candidate"])
	assert_true(DETAIL.preview_allowed(script_args, both))
	assert_false(DETAIL.preview_allowed(script_args, PackedStringArray([both[0]])))
	assert_false(DETAIL.preview_allowed(script_args, PackedStringArray([both[1]])))
	assert_false(DETAIL.preview_allowed(PackedStringArray(), both))
	assert_false(DETAIL.preview_allowed(PackedStringArray(["--script", "tools/capture_cloudreach_settlement_identity.gd"]), both))
	assert_false(DETAIL.preview_allowed(PackedStringArray(["--script",
		"tools/capture_cloudreach_settlement_identity.gd", "--path", "tools/capture_cloudreach_biome_look.gd"]), both))
	assert_false(DETAIL.preview_allowed(PackedStringArray(["tools/capture_cloudreach_biome_look.gd"]), both))
	assert_true(DETAIL.preview_allowed(PackedStringArray(["-s", "tools/capture_cloudreach_f40_matrix.gd"]), both))
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DETAIL.PATH))
	assert_false(spec.enabled)


func test_wall_profile_preserves_boundary_and_stays_inside_original_wall() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DETAIL.PATH))
	var top := Vector3(180, 530, 150)
	var outward := Vector3(top.x, 0, top.z).normalized()
	# The shallow case guards equal neighboring edge counts if dimensions change.
	for height: float in [8.0, 252.6, 298.6]:
		var bottom := top + Vector3(15, -height, 18)
		var profile := DETAIL.wall_profile(top, bottom, outward, spec.plateau_wall)
		assert_eq(profile.size(), 6)
		assert_eq(profile[0], top)
		assert_eq(profile[-1], bottom)
		for index in range(1, profile.size() - 1):
			assert_true(profile[index].y < profile[index - 1].y)
			assert_true(profile[index].y > bottom.y)
			var original := top.lerp(bottom, (top.y - profile[index].y) / height)
			assert_between((original - profile[index]).dot(outward), 0.0, 2.501)
		assert_eq(DETAIL.wall_profile(top, bottom, outward, {}), PackedVector3Array([top, bottom]))


func test_door_lantern_uses_facade_plane_and_scaled_back_face() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DETAIL.PATH))
	var recipes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DETAIL.PREFABS_PATH))
	for prefab: String in ["cottage_a", "cottage_b"]:
		var position := DETAIL.door_fixture_position(recipes.prefabs[prefab], spec.door_lantern)
		var door: Array = recipes.prefabs[prefab].door.at
		assert_almost_eq(position.z - float(door[2]), 0.10)
		assert_almost_eq(position.x - float(door[0]), 0.85)
		assert_almost_eq(position.y - float(door[1]), 1.7)
	# Non-centred model bounds catch confusing the original minimum with its
	# centre; both sizes must land the back face on the same mounting plane.
	var bounds := AABB(Vector3(-0.2, 0.08, -0.05), Vector3(0.4, 1.34, 1.30))
	for height: float in [0.7, 1.8]:
		var scale := height / bounds.size.y
		var centred_z := -bounds.get_center().z * scale
		var shift := DETAIL.lantern_back_shift(bounds, height, true)
		assert_almost_eq(centred_z + shift + bounds.position.z * scale, 0.0)
		assert_eq(DETAIL.lantern_back_shift(bounds, height, false), 0.0, "old fixtures keep their original anchor")


func test_glass_override_is_local_and_shared_prefab_material_is_unchanged() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DETAIL.PATH))
	var world := Node3D.new()
	var landmarks := Node3D.new()
	landmarks.name = "Landmarks"
	world.add_child(landmarks)
	var settlement := Node3D.new()
	settlement.name = "CliffholdSettlement"
	landmarks.add_child(settlement)
	var house := Node3D.new()
	house.name = "Terrace_cottage_a_12"
	settlement.add_child(house)
	var shared := StandardMaterial3D.new()
	shared.resource_name = "MI_WindowGlass"
	shared.albedo_color = Color("#f0c684")
	shared.emission_enabled = true
	shared.emission_energy_multiplier = 0.85
	for index in 2:
		var pane := MeshInstance3D.new()
		pane.mesh = BoxMesh.new()
		pane.mesh.surface_set_material(0, shared)
		house.add_child(pane)
	assert_eq(DETAIL.window_lamps(world, {}).size(), 0)
	var lamps := DETAIL.window_lamps(world, spec)
	assert_eq(lamps.size(), 1, "one material binding per shared source within a cottage")
	var first := house.get_child(0) as MeshInstance3D
	var second := house.get_child(1) as MeshInstance3D
	var glass := first.get_active_material(0) as StandardMaterial3D
	assert_ne(glass, shared)
	assert_eq(second.get_active_material(0), glass)
	assert_eq(glass.albedo_color, shared.albedo_color)
	assert_almost_eq(shared.emission_energy_multiplier, 0.85)
	assert_eq(shared.emission, Color.BLACK)
	assert_eq(DETAIL.lighting_sites(world, spec).size(), 1)
	world.free()
