extends "res://tests/test_case.gd"

const CONFIG_PATH := "res://data/config/cloudreach_high_perches_visual.json"
const PRESENTATION := preload("res://scripts/world/cloudreach_high_perches_presentation.gd")
const WORLD_PATH := "res://scripts/world/cloudreach_world.gd"


func test_high_perches_config_names_a_complete_refuge_composition() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var cfg := parsed as Dictionary
	assert_eq(str(cfg.get("landmark_id", "")), "high_roost_perches")
	assert_eq((cfg.get("roost_positions", []) as Array).size(), 4)
	assert_eq((cfg.get("banner_positions", []) as Array).size(), 4)
	assert_eq((cfg.get("signal_positions", []) as Array).size(), 4)
	assert_eq((cfg.get("supply_positions", []) as Array).size(), 2)
	assert_true(float(cfg.get("survey_clear_radius_m", 0.0)) >= 4.5)
	var arch := cfg.get("arrival_arch_position", []) as Array
	assert_true(arch.size() >= 3)
	assert_true(float(arch[2]) <= -14.0, "arrival portal must frame the south Fly approach")


func test_high_perches_presentation_is_collision_free_and_player_scaled() -> void:
	var presentation := PRESENTATION.new() as Node3D
	presentation.build(_materials())
	assert_true(presentation.get_node_or_null(^"HighPerchesArrivalArch") != null)
	assert_true(presentation.get_node_or_null(^"OuterWindCompass") != null)
	assert_true(presentation.get_node_or_null(^"InnerWindCompass") != null)
	var roles := {}
	var collision_count := 0
	var stack: Array[Node] = [presentation]
	while not stack.is_empty():
		var node := stack.pop_back() as Node
		if node is CollisionObject3D or node is CollisionShape3D:
			collision_count += 1
		if node.has_meta("high_perches_role"):
			var role := str(node.get_meta("high_perches_role"))
			roles[role] = int(roles.get(role, 0)) + 1
		for child: Node in node.get_children():
			stack.append(child)
	assert_eq(collision_count, 0, "identity art must not change Fly or landing collision")
	assert_true(int(roles.get("arrival_portal", 0)) >= 2)
	assert_true(int(roles.get("wind_compass", 0)) >= 10)
	assert_true(int(roles.get("raised_roost", 0)) >= 4)
	assert_eq(int(roles.get("wind_banner", 0)), 4)
	assert_eq(int(roles.get("landing_signal", 0)), 4)
	assert_eq(int(roles.get("landing_light", 0)), 4)
	assert_true(int(roles.get("keeper_supplies", 0)) >= 2)
	presentation.free()


func test_every_high_perches_banner_hangs_from_a_mast_or_the_arch() -> void:
	# M1 (frame 20): the side banners were cloth floating in the sky.
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	var presentation := PRESENTATION.new() as Node3D
	presentation.build(_materials())
	var arch_at := _v3(cfg.arrival_arch_position)
	var arch_size := _v3(cfg.arrival_arch_size_m)
	var arch_face_z := arch_at.z + arch_size.z * 0.5
	var half_height := float(cfg.get("banner_height_m", 3.8)) * 0.5
	var positions := cfg.banner_positions as Array
	for index in positions.size():
		var at := _v3(positions[index])
		var banner_top := at.y + half_height
		var label := "HighPerchesWindBanner%02d" % (index + 1)
		assert_true(presentation.get_node_or_null(NodePath(label)) != null, label)
		var mast := presentation.get_node_or_null(
			NodePath("HighPerchesBannerMast%02d" % (index + 1))) as MeshInstance3D
		var on_arch := absf(at.x) + 0.5 <= arch_size.x * 0.5 and banner_top <= arch_size.y \
			and absf(at.z - arch_face_z) <= 0.3
		if mast != null:
			var mast_top := mast.position.y + (mast.mesh as CylinderMesh).height * 0.5
			var mast_bottom := mast.position.y - (mast.mesh as CylinderMesh).height * 0.5
			assert_true(mast_top >= banner_top, "%s mast reaches the cloth's top edge" % label)
			assert_almost_eq(mast_bottom, 0.0, 0.02, "%s mast stands on the ground" % label)
			assert_true(Vector2(mast.position.x - at.x, mast.position.z - at.z).length() <= 0.6,
				"%s mast is within reach of the cloth" % label)
			assert_true(presentation.get_node_or_null(
				NodePath("HighPerchesBannerCrossbar%02d" % (index + 1))) != null,
				"%s has a crossbar" % label)
		else:
			assert_true(on_arch, "%s neither hangs on the arch face nor has a mast" % label)
	presentation.free()


static func _v3(raw: Variant) -> Vector3:
	var values := raw as Array
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


func test_high_perches_mount_preserves_the_survey_disc_and_clears_only_local_cover() -> void:
	var source := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(source.contains("HIGH_PERCHES_PRESENTATION.new()"))
	assert_true(source.contains("presentation.name = \"HighPerchesPresentation\""))
	assert_true(source.contains("Vector2(17.5,17.5)"), "the occupied court gets one bounded cover exclusion")
	assert_true(source.contains("Vector3(0.0,0.0,-20.0)"), "the south arrival apron gets a bounded cover exclusion")
	assert_true(source.contains("survey/landing disc"), "mount documents the retained traversal ownership")


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["masonry", "masonry_trim", "weathered_timber", "bronze"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#8a755a")
		result[key] = material
	return result
