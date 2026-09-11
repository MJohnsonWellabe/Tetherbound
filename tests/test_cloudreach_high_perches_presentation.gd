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
