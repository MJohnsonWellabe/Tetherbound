extends "res://tests/test_case.gd"

const CONFIG_PATH := "res://data/config/cloudreach_old_wind_observatory_visual.json"
const WORLD_CONFIG_PATH := "res://data/config/cloudreach_world.json"
const PHYSICAL_CONFIG_PATH := "res://data/config/cloudreach_physical_runtime.json"
const NPC_CONFIG_PATH := "res://data/config/cloudreach_npc_runtime.json"
const PRESENTATION := preload("res://scripts/world/cloudreach_old_wind_observatory_presentation.gd")


func test_observatory_visual_build_has_a_complete_collisionless_hierarchy() -> void:
	var visual := PRESENTATION.new() as Node3D
	visual.build(_materials(), false)
	assert_true(visual.get_node_or_null(^"ObservatoryDialCourt") != null)
	assert_true(visual.get_node_or_null(^"OuterCompassCourse") != null)
	assert_true(visual.get_node_or_null(^"ArmillaryHorizon") != null)
	assert_true(visual.get_node_or_null(^"ArmillaryMeridian") != null)
	assert_true(visual.get_node_or_null(^"ArmillaryWindPlane") != null)
	assert_true(visual.get_node_or_null(^"WindReadingCore") != null)
	assert_true(visual.get_node_or_null(^"ObservatoryKeeperDoorway") != null)
	assert_eq(visual.find_children("WindLedgerWindow*", "Node3D", true, false).size(), 2)
	assert_eq(visual.find_children("TowerRib*", "MeshInstance3D", true, false).size(), 8)
	assert_eq(visual.find_children("ObservatoryWindBanner*", "Node3D", true, false).size(), 4)
	assert_eq(visual.find_children("WindKeeperStation*", "Node3D", true, false).size(), 3)
	assert_eq(visual.find_children("ObservatoryWarmPool*", "OmniLight3D", true, false).size(), 4)
	assert_eq(visual.find_children("ObservatoryWindTree*", "Node3D", true, false).size(), 4)
	assert_eq(visual.find_children("ObservatoryEdgeRock*", "Node3D", true, false).size(), 6)
	assert_true(visual.find_children("*", "CollisionObject3D", true, false).is_empty(),
		"observatory presentation must not change route, survey, Fly, or crown collision")
	assert_true(visual.find_children("*", "CollisionShape3D", true, false).is_empty(),
		"observatory presentation must not introduce hidden collision shapes")
	for light: Node in visual.find_children("ObservatoryWarmPool*", "OmniLight3D", true, false):
		assert_true((light as OmniLight3D).light_energy <= 1.05)
		assert_true((light as OmniLight3D).omni_range <= 11.5)
	visual.free()


func test_observatory_config_stays_inside_the_existing_crown() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_eq(cfg.landmark_id, "old_wind_observatory")
	assert_eq(cfg.landmark_position, [430.0, 920.0, 4500.0])
	assert_eq(cfg.crown_half_extents_m, [19.0, 18.0])
	assert_true(float(cfg.dial_radius_m) <= 15.0)
	for key: String in ["banner_positions", "lantern_positions", "instrument_positions", "rock_positions"]:
		for raw: Array in cfg.get(key, []):
			assert_true(absf(float(raw[0])) <= 17.0 and absf(float(raw[2])) <= 15.0,
				"%s dressing escaped the supported crown" % key)
	for raw: Dictionary in cfg.twisted_trees:
		assert_true(absf(float(raw.at[0])) <= 17.0 and absf(float(raw.at[2])) <= 17.0,
			"wind-shaped edge ecology escaped the supported crown")


func test_observatory_identity_preserves_route_survey_lift_and_pickup_contracts() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD_CONFIG_PATH))
	var landmark := _entry(world.landmarks, "old_wind_observatory")
	assert_eq(landmark.position, [430.0, 920.0, 4500.0])
	assert_eq(landmark.requires_traversal, "ground")
	assert_eq(landmark.requires_unlock, "cloudreach_upper_route_unlocked")
	var route := _entry(world.routes, "upper_plateau_circuit")
	assert_true((route.polyline as Array).has([430.0, 920.0, 4500.0]))
	var physical: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PHYSICAL_CONFIG_PATH))
	var survey := _entry(physical.landing_objectives, "survey_observatory")
	assert_eq(survey.position, [430.0, 920.0, 4500.0])
	assert_eq(survey.approach_position, [430.0, 1000.0, 4500.0])
	assert_eq(survey.completion_flag, "side_aerie_observatory_surveyed")
	var lift := _entry(physical.updrafts, "cloudreach_observatory_lift")
	assert_eq(lift.position, [370.0, 900.0, 4440.0])
	assert_eq(lift.requires_flag, "cloudreach_upper_route_unlocked")
	assert_eq(physical.pickup_overrides.cr_pickup_observatory_potion, [425.0, 920.0, 4505.0])
	var npc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(NPC_CONFIG_PATH))
	assert_true(_has_marker(npc.world_payoffs.survey_markers, "observatory", [430.0, 920.0, 4500.0]))


func _entry(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == wanted:
			return raw as Dictionary
	return {}


func _has_marker(entries: Array, wanted: String, position: Array) -> bool:
	for raw: Dictionary in entries:
		if str(raw.get("id", "")) == wanted and raw.get("position", []) == position:
			return true
	return false


func _materials() -> Dictionary:
	var result := {}
	for key: String in ["masonry", "masonry_trim", "weathered_timber"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#817661")
		result[key] = material
	return result
