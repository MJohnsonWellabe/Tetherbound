extends "res://tests/test_case.gd"

const PRESENTATION := preload("res://scripts/world/cloudreach_flight_aerie_presentation.gd")
const WORLD_PATH := "res://scripts/world/cloudreach_world.gd"
const DEBUG_SPOTS_PATH := "res://data/config/debug_teleport_spots.json"


func test_flight_aerie_identity_layer_is_installed_visual_only_and_player_scale() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PRESENTATION.CONFIG_PATH))
	assert_true(parsed is Dictionary)
	var cfg := parsed as Dictionary
	assert_true(ResourceLoader.exists(str(cfg.get("banner_scene", ""))))
	assert_true(ResourceLoader.exists(str(cfg.get("signal_scene", ""))))
	assert_between(float(cfg.get("signal_height_m", 0.0)), 2.0, 2.2,
		"landing signal must clear grass without becoming a competing tower")
	assert_between(float(cfg.get("signal_light_energy", 0.0)), 2.0, 2.5,
		"landing signals no longer carry a readable warm night pool")
	assert_true(float(cfg.get("signal_light_range_m", 99.0)) <= 11.0,
		"landing signals spill beyond the local launch composition")
	assert_eq(Color(str(cfg.get("signal_colour", ""))), Color("#f0a057"),
		"landing light matches the shipped torch's visible flame family")
	var presentation := PRESENTATION.new()
	presentation.build({})
	var roles := {}
	var collisions := 0
	for child: Node in presentation.get_children():
		var role := str(child.get_meta("flight_aerie_role", ""))
		if not role.is_empty():
			roles[role] = int(roles.get(role, 0)) + 1
		if child.name in [&"AerieOuterCompass", &"AerieInnerCompass"]:
			assert_almost_eq((child as Node3D).rotation.x, 0.0, 0.001,
				"launch compass rings remain flat in the X/Z lesson floor")
			assert_almost_eq((child as Node3D).position.y, 0.14, 0.001,
				"launch compass rings remain a visual paving layer")
		if child is CollisionObject3D:
			collisions += 1
		collisions += child.find_children("*", "CollisionObject3D", true, false).size()
	assert_eq(int(roles.get("launch_compass", 0)), 10)
	assert_eq(int(roles.get("wind_banner", 0)), 3)
	assert_eq(int(roles.get("landing_signal", 0)), 3)
	assert_eq(int(roles.get("landing_light", 0)), 3)
	assert_eq(collisions, 0)
	for index in 3:
		var signal_node := presentation.get_node_or_null("AerieLandingSignal%02d" % (index + 1)) as Node3D
		var light := presentation.get_node_or_null("AerieLandingLight%02d" % (index + 1)) as OmniLight3D
		assert_true(signal_node != null and signal_node.has_method("flame_local_position"),
			"landing signal uses the shipped visible torch source")
		assert_true(light != null and light.position.y > signal_node.position.y,
			"landing light originates at the visible flame")
	presentation.free()


func test_flight_aerie_roadside_wildlife_no_longer_occupies_the_lesson_dais() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_encounters.json"))
	assert_true(parsed is Dictionary)
	var found := {}
	var ravine_pair := {}
	for raw: Variant in (parsed as Dictionary).get("wild_sites", []):
		var site := raw as Dictionary
		if str(site.get("id", "")) == "road_visibility_windscar_floor_loop_15":
			found = site
		elif str(site.get("id", "")) == "ravine_wind":
			ravine_pair = site
	assert_false(found.is_empty())
	assert_eq(found.get("position", []), [445.0, 610.0, 3335.0])
	assert_eq(int(found.get("count", 0)), 2)
	assert_true(Vector2(445.0, 3335.0).distance_to(Vector2(400.0, 3250.0)) - float(found.get("radius_m", 0.0)) > 90.0)
	assert_false(ravine_pair.is_empty(), "the original Windscar wildlife pair disappeared")
	assert_eq(ravine_pair.get("position", []), [220.0, 556.0, 3333.0])
	assert_eq(int(ravine_pair.get("count", 0)), 2)
	assert_true(Vector2(220.0, 3333.0).distance_to(Vector2(400.0, 3250.0))
		- float(ravine_pair.get("radius_m", 0.0)) > 185.0,
		"large Windscar wildlife still owns the Aerie's route-arrival composition")


func test_production_world_mounts_the_visual_layer_and_catalogue_uses_the_route_arrival() -> void:
	var world_source := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(world_source.contains('const FLIGHT_AERIE_PRESENTATION := preload("res://scripts/world/cloudreach_flight_aerie_presentation.gd")'),
		"the production Cloudreach world does not preload the isolated Aerie presentation")
	assert_true(world_source.contains('presentation.name = "FlightAeriePresentation"'),
		"the production Aerie builder does not mount a named presentation node")
	assert_true(world_source.find('func _build_flight_aerie(root: Node3D)') < world_source.find('presentation.name = "FlightAeriePresentation"'),
		"the presentation mount drifted outside the existing flight-aerie builder")
	assert_true(world_source.contains('Vector3(5.4,0.38,0.86)'),
		"the five perch heads have collapsed back to thin unreadable sticks")
	assert_true(world_source.contains('"PerchOuterStop"') and world_source.contains('"PerchInnerStop"'),
		"perch arms have no readable terminal silhouette")
	assert_true(world_source.contains('"half":Vector2(11.35,11.35)') and world_source.contains('"half":Vector2(6.2,6.2)'),
		"the compass and LaunchStone no longer use bounded ground-cover exclusions")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEBUG_SPOTS_PATH))
	assert_true(parsed is Dictionary, "debug teleport catalogue remains valid JSON")
	var found := {}
	for biome_value: Variant in (parsed as Dictionary).get("biomes", []):
		if biome_value is Dictionary and str((biome_value as Dictionary).get("id", "")) == "cloudreach":
			for band_value: Variant in (biome_value as Dictionary).get("bands", []):
				for spot_value: Variant in (band_value as Dictionary).get("spots", []):
					if spot_value is Dictionary and str((spot_value as Dictionary).get("display_name", "")) == "Windscar Flight Aerie":
						found = spot_value
	assert_false(found.is_empty(), "Windscar Flight Aerie is absent from the player-facing catalogue")
	assert_eq(found.get("position", []), [373.0, 3262.5357],
		"the catalogue no longer uses the authored final ground-route approach")
	assert_almost_eq(float(found.get("view_heading_deg", 0.0)), -115.0, 0.01,
		"the route arrival no longer faces the launch compass")
	assert_between(Vector2(373.0, 3262.5357).distance_to(Vector2(400.0, 3250.0)), 29.0, 30.5,
		"the evidence arrival is either back inside the lesson or detached from the route")


func test_dedicated_capture_requires_the_mounted_identity_and_empty_lesson_floor() -> void:
	var source := FileAccess.get_file_as_string("res://tools/capture_cloudreach_flight_aerie.gd")
	assert_true(source.contains('find_child("FlightAeriePresentation"'),
		"the capture can pass without the production identity layer")
	assert_true(source.contains("_wildlife_within_aerie"),
		"the capture does not reject giant wildlife on the lesson dais")
	assert_true(source.contains("CanvasLayer"),
		"the capture does not suppress overlays for location-only review")
	assert_true(source.contains("PROCESS_MODE_DISABLED"),
		"the capture leaves the production player free to drift")
	assert_true(source.contains("cloudreach-flight-aerie-r3"),
		"the recovery harness would overwrite rejected R2 evidence")
	assert_true(source.contains('"camera_lateral_m"') and source.contains('"aim_up_m"'),
		"the recovery harness cannot compose around the trunk/pole overlap or show the perch heads")
